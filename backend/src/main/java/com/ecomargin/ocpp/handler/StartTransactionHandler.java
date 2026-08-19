package com.ecomargin.ocpp.handler;

import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.ChargingSession;
import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.ChargingSessionRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
@Transactional
public class StartTransactionHandler implements OcppRequestHandler {

    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;
    private final ChargingSessionRepository chargingSessionRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final List<String> ACTIVE_STATUSES = List.of("STARTING", "ACTIVE", "CHARGING");

    @Override
    public OcppAction getAction() {
        return OcppAction.StartTransaction;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.info("Handling StartTransaction for charger: {}", chargeBoxId);

        Optional<Charger> chargerOpt = chargerRepository.findByOcppId(chargeBoxId);
        ObjectNode responsePayload = objectMapper.createObjectNode();
        ObjectNode idTagInfo = objectMapper.createObjectNode();

        if (chargerOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] StartTransaction rejected for unknown charger: {}", chargeBoxId);
            idTagInfo.put("status", "Invalid");
            responsePayload.set("idTagInfo", idTagInfo);
            responsePayload.put("transactionId", 0);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        Charger charger = chargerOpt.get();
        JsonNode payload = message.getPayload();
        int connectorIndex = (payload != null && payload.has("connectorId")) ? payload.get("connectorId").asInt() : 1;
        String idTag = (payload != null && payload.has("idTag")) ? payload.get("idTag").asText() : "";
        BigDecimal meterStart = (payload != null && payload.has("meterStart")) ? BigDecimal.valueOf(payload.get("meterStart").asDouble()) : BigDecimal.ZERO;

        Optional<Connector> connectorOpt = connectorRepository.findByChargerAndConnectorIndex(charger, connectorIndex);
        if (connectorOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] StartTransaction rejected: Connector {} does not belong to charger {}", connectorIndex, chargeBoxId);
            idTagInfo.put("status", "Invalid");
            responsePayload.set("idTagInfo", idTagInfo);
            responsePayload.put("transactionId", 0);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        Connector connector = connectorOpt.get();

        // 1. Concurrency / Duplicate StartTransaction Protection
        List<ChargingSession> activeSessions = chargingSessionRepository.findByStatus("ACTIVE");
        for (ChargingSession s : activeSessions) {
            if (s.getConnector() != null && s.getConnector().getId().equals(connector.getId())) {
                log.info("[OCPP-SECURITY] Active session already exists for connector {}. Returning existing transaction ID {}", connector.getId(), s.getId());
                idTagInfo.put("status", "Accepted");
                responsePayload.set("idTagInfo", idTagInfo);
                responsePayload.put("transactionId", s.getId().intValue());
                return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
            }
        }

        // 2. Create new active charging session
        ChargingSession session = ChargingSession.builder()
                .connector(connector)
                .status("ACTIVE")
                .startTime(LocalDateTime.now())
                .meterStartWh(meterStart)
                .totalEnergyKwh(BigDecimal.ZERO)
                .totalCost(BigDecimal.ZERO)
                .ocppTransactionId("OCPP-TX-" + System.currentTimeMillis())
                .build();

        ChargingSession savedSession = chargingSessionRepository.save(session);

        connector.setStatus("CHARGING");
        connector.setUpdatedAt(LocalDateTime.now());
        connectorRepository.save(connector);

        charger.setStatus("CHARGING");
        charger.setUpdatedAt(LocalDateTime.now());
        chargerRepository.save(charger);

        idTagInfo.put("status", "Accepted");
        responsePayload.set("idTagInfo", idTagInfo);
        responsePayload.put("transactionId", savedSession.getId().intValue());

        log.info("[OCPP-SECURITY] StartTransaction accepted: Charger={}, SessionId={}", chargeBoxId, savedSession.getId());

        return OcppMessage.builder()
                .messageTypeId(3)
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
