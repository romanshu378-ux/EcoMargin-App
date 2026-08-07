package com.ecomargin.ocpp.handler;

import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
public class HeartbeatHandler implements OcppRequestHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcppAction getAction() {
        return OcppAction.Heartbeat;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        ObjectNode responsePayload = objectMapper.createObjectNode();
        responsePayload.put("currentTime", Instant.now().toString());

        return OcppMessage.builder()
                .messageTypeId(3) // CallResult
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
