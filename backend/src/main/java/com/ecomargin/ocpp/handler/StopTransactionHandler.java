package com.ecomargin.ocpp.handler;

import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.ChargingSession;
import com.ecomargin.model.Setting;
import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.ChargingSessionRepository;
import com.ecomargin.repository.SettingRepository;
import com.ecomargin.service.WalletService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
@Transactional
public class StopTransactionHandler implements OcppRequestHandler {

    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;
    private final ChargingSessionRepository chargingSessionRepository;
    private final SettingRepository settingRepository;
    private final WalletService walletService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcppAction getAction() {
        return OcppAction.StopTransaction;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.info("Handling StopTransaction for charger: {}", chargeBoxId);

        Optional<Charger> chargerOpt = chargerRepository.findByOcppId(chargeBoxId);
        ObjectNode responsePayload = objectMapper.createObjectNode();
        ObjectNode idTagInfo = objectMapper.createObjectNode();

        if (chargerOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] StopTransaction rejected for unknown charger: {}", chargeBoxId);
            idTagInfo.put("status", "Invalid");
            responsePayload.set("idTagInfo", idTagInfo);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        Charger charger = chargerOpt.get();
        JsonNode payload = message.getPayload();
        Long transactionId = (payload != null && payload.has("transactionId")) ? payload.get("transactionId").asLong() : 0L;
        BigDecimal meterStop = (payload != null && payload.has("meterStop")) ? BigDecimal.valueOf(payload.get("meterStop").asDouble()) : BigDecimal.ZERO;
        String reason = (payload != null && payload.has("reason")) ? payload.get("reason").asText() : "Local";

        Optional<ChargingSession> sessionOpt = chargingSessionRepository.findById(transactionId);
        if (sessionOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] StopTransaction rejected: Charging session {} not found", transactionId);
            idTagInfo.put("status", "Invalid");
            responsePayload.set("idTagInfo", idTagInfo);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        ChargingSession session = sessionOpt.get();

        // 1. Session Ownership Protection: Verify session belongs to this charger
        if (session.getConnector() == null || session.getConnector().getCharger() == null ||
                !session.getConnector().getCharger().getOcppId().equalsIgnoreCase(chargeBoxId)) {
            log.warn("[OCPP-SECURITY] StopTransaction Security Alert: Charger {} attempted to stop session {} belonging to another charger!",
                    chargeBoxId, transactionId);
            idTagInfo.put("status", "Invalid");
            responsePayload.set("idTagInfo", idTagInfo);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        // 2. Idempotency Check: Prevent duplicate stop events from double-completing or double-debiting
        if ("COMPLETED".equalsIgnoreCase(session.getStatus()) || "FAILED".equalsIgnoreCase(session.getStatus())) {
            log.info("[OCPP-SECURITY] Session {} already stopped/completed (idempotent response)", transactionId);
            idTagInfo.put("status", "Accepted");
            responsePayload.set("idTagInfo", idTagInfo);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        // Calculate final energy & cost server-side
        BigDecimal meterStartWh = session.getMeterStartWh() != null ? session.getMeterStartWh() : BigDecimal.ZERO;
        BigDecimal deltaWh = meterStop.subtract(meterStartWh);
        if (deltaWh.compareTo(BigDecimal.ZERO) < 0) deltaWh = BigDecimal.ZERO;

        BigDecimal energyKwh = deltaWh.divide(BigDecimal.valueOf(1000.0), 3, RoundingMode.HALF_UP);

        double rate = 18.0;
        if (session.getConnector() != null && session.getConnector().getUnitRate() != null && session.getConnector().getUnitRate().doubleValue() > 0) {
            rate = session.getConnector().getUnitRate().doubleValue();
        } else {
            try {
                Setting rateSetting = settingRepository.findById("default_charging_rate_per_kwh").orElse(null);
                if (rateSetting != null) {
                    double r = Double.parseDouble(rateSetting.getValue());
                    if (r > 0.0) rate = (r == 0.35 ? 18.0 : r);
                }
            } catch (Exception e) {
                // fallback
            }
        }

        BigDecimal totalCost = energyKwh.multiply(BigDecimal.valueOf(rate)).setScale(2, RoundingMode.HALF_UP);

        session.setStatus("COMPLETED");
        session.setEndTime(LocalDateTime.now());
        session.setMeterStopWh(meterStop);
        session.setTotalEnergyKwh(energyKwh);
        session.setTotalCost(totalCost);
        session.setStopReason(reason);
        session.setUpdatedAt(LocalDateTime.now());
        chargingSessionRepository.save(session);

        // 3. Safe Wallet Debit Integration
        if (session.getUser() != null && totalCost.compareTo(BigDecimal.ZERO) > 0) {
            try {
                walletService.processChargingDebit(
                        session.getId(),
                        session.getOcppTransactionId() != null ? session.getOcppTransactionId() : ("TX-" + session.getId()),
                        totalCost
                );
            } catch (Exception e) {
                log.warn("[OCPP-SECURITY] Wallet debit warning for session {}: {}", session.getId(), e.getMessage());
            }
        }

        // Restore connector & charger status
        Connector connector = session.getConnector();
        if (connector != null) {
            connector.setStatus("AVAILABLE");
            connector.setUpdatedAt(LocalDateTime.now());
            connectorRepository.save(connector);
        }
        charger.setStatus("AVAILABLE");
        charger.setUpdatedAt(LocalDateTime.now());
        chargerRepository.save(charger);

        idTagInfo.put("status", "Accepted");
        responsePayload.set("idTagInfo", idTagInfo);

        log.info("[OCPP-SECURITY] StopTransaction completed: SessionId={}, TotalEnergy={}kWh, TotalCost=₹{}",
                session.getId(), energyKwh, totalCost);

        return OcppMessage.builder()
                .messageTypeId(3)
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
