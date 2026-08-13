package com.ecomargin.ocpp.protocol;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class OcppJsonParser {

    private final ObjectMapper objectMapper = new ObjectMapper();

    public OcppMessage parse(String text) throws Exception {
        JsonNode root = objectMapper.readTree(text);
        if (!root.isArray() || root.size() < 3) {
            throw new IllegalArgumentException("Invalid OCPP JSON array payload format");
        }

        int msgType = root.get(0).asInt();
        String msgId = root.get(1).asText();

        if (msgType == 2) { // CALL
            String action = root.get(2).asText();
            JsonNode payload = root.size() > 3 ? root.get(3) : objectMapper.createObjectNode();
            return OcppMessage.builder()
                    .messageType(2)
                    .messageId(msgId)
                    .action(action)
                    .payload(payload)
                    .build();
        } else if (msgType == 3) { // CALLRESULT
            JsonNode payload = root.get(2);
            return OcppMessage.builder()
                    .messageType(3)
                    .messageId(msgId)
                    .payload(payload)
                    .build();
        } else if (msgType == 4) { // CALLERROR
            String errorCode = root.get(2).asText();
            String errorDesc = root.size() > 3 ? root.get(3).asText() : "";
            return OcppMessage.builder()
                    .messageType(4)
                    .messageId(msgId)
                    .errorCode(errorCode)
                    .errorDescription(errorDesc)
                    .build();
        } else {
            throw new IllegalArgumentException("Unsupported OCPP message type: " + msgType);
        }
    }

    public String buildCallResultJson(String messageId, Object payloadObj) throws Exception {
        ArrayNode array = objectMapper.createArrayNode();
        array.add(3);
        array.add(messageId);
        if (payloadObj != null) {
            array.add(objectMapper.valueToTree(payloadObj));
        } else {
            array.add(objectMapper.createObjectNode());
        }
        return objectMapper.writeValueAsString(array);
    }

    public String buildCallJson(String messageId, String action, Object payloadObj) throws Exception {
        ArrayNode array = objectMapper.createArrayNode();
        array.add(2);
        array.add(messageId);
        array.add(action);
        if (payloadObj != null) {
            array.add(objectMapper.valueToTree(payloadObj));
        } else {
            array.add(objectMapper.createObjectNode());
        }
        return objectMapper.writeValueAsString(array);
    }

    public String buildCallErrorJson(String messageId, String errorCode, String description) throws Exception {
        ArrayNode array = objectMapper.createArrayNode();
        array.add(4);
        array.add(messageId);
        array.add(errorCode);
        array.add(description);
        array.add(objectMapper.createObjectNode());
        return objectMapper.writeValueAsString(array);
    }

    public ObjectMapper getObjectMapper() {
        return objectMapper;
    }
}
