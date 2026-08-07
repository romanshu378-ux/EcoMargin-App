package com.ecomargin.ocpp.handler;

import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Slf4j
@Component
public class BootNotificationHandler implements OcppRequestHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcppAction getAction() {
        return OcppAction.BootNotification;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.info("Handling BootNotification for charger: {} with payload: {}", chargeBoxId, message.getPayload());

        // In a real application, you would:
        // 1. Verify chargeBoxId in the database
        // 2. Register/update charger online status
        
        ObjectNode responsePayload = objectMapper.createObjectNode();
        responsePayload.put("status", "Accepted"); // Accepted, Pending, Rejected
        responsePayload.put("currentTime", Instant.now().toString());
        responsePayload.put("interval", 300); // Heartbeat interval in seconds

        return OcppMessage.builder()
                .messageTypeId(3) // CallResult
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
