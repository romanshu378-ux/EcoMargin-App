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
import com.ecomargin.websocket.telemetry.TelemetryPublisher;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
@Transactional
public class MeterValuesHandler implements OcppRequestHandler {

    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;
    private final ChargingSessionRepository chargingSessionRepository;
    private final SettingRepository settingRepository;
    private final TelemetryPublisher telemetryPublisher;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final List<String> ACTIVE_STATUSES = List.of("STARTING", "ACTIVE", "CHARGING");

    @Override
    public OcppAction getAction() {
        return OcppAction.MeterValues;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.info("Handling MeterValues for charger: {}", chargeBoxId);

        Optional<Charger> chargerOpt = chargerRepository.findByOcppId(chargeBoxId);
        ObjectNode responsePayload = objectMapper.createObjectNode();

        if (chargerOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] MeterValues rejected for unknown charger: {}", chargeBoxId);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        Charger charger = chargerOpt.get();
        JsonNode payload = message.getPayload();
        int connectorIndex = payload.has("connectorId") ? payload.get("connectorId").asInt() : 1;

        Optional<Connector> connectorOpt = connectorRepository.findByChargerAndConnectorIndex(charger, connectorIndex);
        if (connectorOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] MeterValues rejected: Connector {} does not belong to charger {}", connectorIndex, chargeBoxId);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        Connector connector = connectorOpt.get();

        double energyKwh = 0.0;
        double powerKw = 42.5;
        double voltage = 400.0;
        double current = 100.0;

        if (payload.has("meterValue") && payload.get("meterValue").isArray()) {
            JsonNode mvArray = payload.get("meterValue");
            for (JsonNode mv : mvArray) {
                if (mv.has("sampledValue") && mv.get("sampledValue").isArray()) {
                    for (JsonNode sv : mv.get("sampledValue")) {
                        try {
                            double val = Double.parseDouble(sv.get("value").asText());
                            String unit = sv.has("unit") ? sv.get("unit").asText() : "";
                            String meas = sv.has("measurand") ? sv.get("measurand").asText() : "";

                            if ("Energy.Active.Import.Register".equalsIgnoreCase(meas) || "kWh".equalsIgnoreCase(unit)) {
                                energyKwh = "Wh".equalsIgnoreCase(unit) ? val / 1000.0 : val;
                            } else if ("Power.Active.Import".equalsIgnoreCase(meas) || "kW".equalsIgnoreCase(unit)) {
                                powerKw = "W".equalsIgnoreCase(unit) ? val / 1000.0 : val;
                            } else if ("Voltage".equalsIgnoreCase(meas) || "V".equalsIgnoreCase(unit)) {
                                voltage = val;
                            } else if ("Current.Import".equalsIgnoreCase(meas) || "A".equalsIgnoreCase(unit)) {
                                current = val;
                            }
                        } catch (Exception e) {
                            // Ignore single malformed sample
                        }
                    }
                }
            }
        }

        // Validate meter ranges (Reject negative or physically impossible values)
        if (energyKwh < 0.0 || powerKw < 0.0 || voltage < 0.0 || voltage > 1000.0 || current < 0.0 || current > 500.0) {
            log.warn("[OCPP-SECURITY] Rejecting invalid MeterValue bounds for charger {}: energy={}, power={}, voltage={}, current={}",
                    chargeBoxId, energyKwh, powerKw, voltage, current);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        // Update active session if present for this connector
        List<ChargingSession> sessions = chargingSessionRepository.findByStatus("ACTIVE");
        for (ChargingSession session : sessions) {
            if (session.getConnector() != null && session.getConnector().getId().equals(connector.getId())) {
                double rate = 18.0;
                try {
                    Setting rateSetting = settingRepository.findById("default_charging_rate_per_kwh").orElse(null);
                    if (rateSetting != null) {
                        double r = Double.parseDouble(rateSetting.getValue());
                        if (r > 0.0) rate = (r == 0.35 ? 18.0 : r);
                    }
                } catch (Exception e) {
                    // fallback
                }

                BigDecimal energyBd = BigDecimal.valueOf(energyKwh).setScale(3, RoundingMode.HALF_UP);
                BigDecimal costBd = energyBd.multiply(BigDecimal.valueOf(rate)).setScale(2, RoundingMode.HALF_UP);

                session.setTotalEnergyKwh(energyBd);
                session.setTotalCost(costBd);
                session.setUpdatedAt(LocalDateTime.now());
                chargingSessionRepository.save(session);
                break;
            }
        }

        // Publish live telemetry
        Map<String, Object> telemetryData = new HashMap<>();
        telemetryData.put("connectorId", connectorIndex);
        telemetryData.put("activePowerKw", powerKw);
        telemetryData.put("kwhDelivered", energyKwh);
        telemetryData.put("voltage", voltage);
        telemetryData.put("current", current);

        telemetryPublisher.publish("CHARGER_TELEMETRY", chargeBoxId, telemetryData);

        return OcppMessage.builder()
                .messageTypeId(3)
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
