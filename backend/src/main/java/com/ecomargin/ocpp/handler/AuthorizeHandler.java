package com.ecomargin.ocpp.handler;

import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.stereotype.Component;

@Component
public class AuthorizeHandler implements OcppRequestHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcppAction getAction() {
        return OcppAction.Authorize;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        // payload: { "idTag": "RFID_TAG_STRING" }
        String idTag = message.getPayload().get("idTag").asText();

        // In a real application, query the database/cache for user/wallet status
        // and check if they have enough balance or are authorized.

        ObjectNode idTagInfo = objectMapper.createObjectNode();
        idTagInfo.put("status", "Accepted"); // Accepted, Blocked, Expired, Invalid, ConcurrentTx
        idTagInfo.put("expiryDate", java.time.Instant.now().plus(java.time.Duration.ofDays(305)).toString());
        idTagInfo.put("parentIdTag", "");

        ObjectNode responsePayload = objectMapper.createObjectNode();
        responsePayload.set("idTagInfo", idTagInfo);

        return OcppMessage.builder()
                .messageTypeId(3) // CallResult
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
