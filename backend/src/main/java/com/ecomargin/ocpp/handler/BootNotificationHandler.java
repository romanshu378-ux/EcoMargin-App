package com.ecomargin.ocpp.handler;

import com.ecomargin.model.Charger;
import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.ecomargin.repository.ChargerRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
@Transactional
public class BootNotificationHandler implements OcppRequestHandler {

    private final ChargerRepository chargerRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcppAction getAction() {
        return OcppAction.BootNotification;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.info("Handling BootNotification for charger: {}", chargeBoxId);

        Optional<Charger> chargerOpt = chargerRepository.findByOcppId(chargeBoxId);
        ObjectNode responsePayload = objectMapper.createObjectNode();

        if (chargerOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] BootNotification rejected for unknown charger: {}", chargeBoxId);
            responsePayload.put("status", "Rejected");
            responsePayload.put("currentTime", Instant.now().toString());
            responsePayload.put("interval", 300);

            return OcppMessage.builder()
                    .messageTypeId(3)
                    .uniqueId(message.getUniqueId())
                    .payload(responsePayload)
                    .build();
        }

        Charger charger = chargerOpt.get();
        JsonNode payload = message.getPayload();

        if (payload != null && payload.isObject()) {
            if (payload.has("chargePointVendor")) {
                charger.setBrand(payload.get("chargePointVendor").asText());
            }
            if (payload.has("chargePointModel")) {
                charger.setModel(payload.get("chargePointModel").asText());
            }
            if (payload.has("firmwareVersion")) {
                charger.setFirmwareVersion(payload.get("firmwareVersion").asText());
            }
        }

        charger.setStatus("AVAILABLE");
        charger.setUpdatedAt(LocalDateTime.now());
        chargerRepository.save(charger);

        responsePayload.put("status", "Accepted");
        responsePayload.put("currentTime", Instant.now().toString());
        responsePayload.put("interval", 300);

        return OcppMessage.builder()
                .messageTypeId(3)
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
