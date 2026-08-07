package com.ecomargin.ocpp.handler;

import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.ecomargin.websocket.telemetry.TelemetryPublisher;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class MeterValuesHandler implements OcppRequestHandler {

    private final TelemetryPublisher telemetryPublisher;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcppAction getAction() {
        return OcppAction.MeterValues;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.info("Handling MeterValues for charger: {} with payload: {}", chargeBoxId, message.getPayload());

        // OCPP Payload format example:
        // { "connectorId": 1, "transactionId": 12, "meterValue": [ ... ] }
        JsonNode payload = message.getPayload();
        int connectorId = payload.has("connectorId") ? payload.get("connectorId").asInt() : 1;
        
        // Extract recent energy value (e.g. 24.2 kWh)
        double currentKwh = 24.5; // parsed from payload in a real app

        // 1. Publish to Redis to update connected web/mobile clients in real-time
        Map<String, Object> telemetryData = new HashMap<>();
        telemetryData.put("connectorId", connectorId);
        telemetryData.put("activePowerKw", 45.2); // Current active power draw
        telemetryData.put("kwhDelivered", currentKwh);
        telemetryData.put("cost", currentKwh * 0.35); // standard rate

        telemetryPublisher.publish("CHARGER_TELEMETRY", chargeBoxId, telemetryData);

        // 2. Return standard OCPP CallResult response
        ObjectNode responsePayload = objectMapper.createObjectNode();
        // OCPP 1.6J MeterValues response is empty object: {}
        
        return OcppMessage.builder()
                .messageTypeId(3) // CallResult
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
