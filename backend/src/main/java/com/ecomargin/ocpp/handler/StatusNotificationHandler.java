package com.ecomargin.ocpp.handler;

import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
@Transactional
public class StatusNotificationHandler implements OcppRequestHandler {

    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final List<String> VALID_OCPP_STATUSES = List.of(
            "Available", "Preparing", "Charging", "SuspendedEV", "SuspendedEVSE",
            "Finishing", "Reserved", "Unavailable", "Faulted"
    );

    @Override
    public OcppAction getAction() {
        return OcppAction.StatusNotification;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.info("Handling StatusNotification for charger: {}", chargeBoxId);

        Optional<Charger> chargerOpt = chargerRepository.findByOcppId(chargeBoxId);
        ObjectNode responsePayload = objectMapper.createObjectNode();

        if (chargerOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] StatusNotification rejected for unknown charger: {}", chargeBoxId);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        Charger charger = chargerOpt.get();
        JsonNode payload = message.getPayload();
        int connectorIndex = (payload != null && payload.has("connectorId")) ? payload.get("connectorId").asInt() : 1;
        String ocppStatus = (payload != null && payload.has("status")) ? payload.get("status").asText() : "Available";

        if (!VALID_OCPP_STATUSES.contains(ocppStatus)) {
            log.warn("[OCPP-SECURITY] Rejecting invalid status string '{}' for charger {}", ocppStatus, chargeBoxId);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        // Validate connector belongs to this charger
        Optional<Connector> connectorOpt = connectorRepository.findByChargerAndConnectorIndex(charger, connectorIndex);
        if (connectorOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] StatusNotification rejected: Connector {} does not belong to charger {}", connectorIndex, chargeBoxId);
            return OcppMessage.builder().messageTypeId(3).uniqueId(message.getUniqueId()).payload(responsePayload).build();
        }

        Connector connector = connectorOpt.get();
        String dbStatus = mapOcppStatusToDb(ocppStatus);
        connector.setStatus(dbStatus);
        connector.setUpdatedAt(LocalDateTime.now());
        connectorRepository.save(connector);

        charger.setUpdatedAt(LocalDateTime.now());
        if ("CHARGING".equalsIgnoreCase(dbStatus) || "FAULTED".equalsIgnoreCase(dbStatus) || "AVAILABLE".equalsIgnoreCase(dbStatus) || "PREPARING".equalsIgnoreCase(dbStatus)) {
            charger.setStatus(dbStatus);
        }
        chargerRepository.save(charger);

        log.info("[OCPP-STATUS-TRANSITION] ocppId={}, connectorIndex={}, ocppStatus={}, dbStatus={}, newChargerStatus={}",
                chargeBoxId, connectorIndex, ocppStatus, dbStatus, charger.getStatus());

        return OcppMessage.builder()
                .messageTypeId(3)
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }

    private String mapOcppStatusToDb(String ocppStatus) {
        switch (ocppStatus) {
            case "Available":
                return "AVAILABLE";
            case "Preparing":
                return "PREPARING";
            case "Charging":
            case "SuspendedEV":
            case "SuspendedEVSE":
                return "CHARGING";
            case "Finishing":
                return "FINISHING";
            case "Faulted":
                return "FAULTED";
            case "Unavailable":
            default:
                return "UNAVAILABLE";
        }
    }
}
