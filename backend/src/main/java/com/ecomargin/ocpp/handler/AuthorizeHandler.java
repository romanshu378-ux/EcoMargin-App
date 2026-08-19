package com.ecomargin.ocpp.handler;

import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.Duration;

@Slf4j
@Component
public class AuthorizeHandler implements OcppRequestHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcppAction getAction() {
        return OcppAction.Authorize;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.info("Handling Authorize for charger: {}", chargeBoxId);

        JsonNode payload = message.getPayload();
        String idTag = (payload != null && payload.has("idTag")) ? payload.get("idTag").asText().trim() : null;

        ObjectNode idTagInfo = objectMapper.createObjectNode();

        if (idTag == null || idTag.isEmpty()) {
            log.warn("[OCPP-SECURITY] Authorize rejected: missing or empty idTag for charger {}", chargeBoxId);
            idTagInfo.put("status", "Invalid");
        } else {
            idTagInfo.put("status", "Accepted");
            idTagInfo.put("expiryDate", Instant.now().plus(Duration.ofDays(365)).toString());
            idTagInfo.put("parentIdTag", "");
        }

        ObjectNode responsePayload = objectMapper.createObjectNode();
        responsePayload.set("idTagInfo", idTagInfo);

        return OcppMessage.builder()
                .messageTypeId(3)
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
