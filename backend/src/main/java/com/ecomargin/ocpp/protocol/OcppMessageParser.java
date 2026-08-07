package com.ecomargin.ocpp.protocol;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class OcppMessageParser {

    private final ObjectMapper objectMapper = new ObjectMapper();

    public OcppMessage parse(String rawMessage) throws IOException {
        JsonNode jsonNode = objectMapper.readTree(rawMessage);
        
        if (!jsonNode.isArray() || jsonNode.size() < 3) {
            throw new IllegalArgumentException("Invalid OCPP Message format. Must be an array of size >= 3");
        }

        int messageTypeId = jsonNode.get(0).asInt();
        String uniqueId = jsonNode.get(1).asText();
        
        OcppMessage.OcppMessageBuilder builder = OcppMessage.builder()
                .messageTypeId(messageTypeId)
                .uniqueId(uniqueId);

        if (messageTypeId == 2) { // Request (Call)
            if (jsonNode.size() < 4) {
                throw new IllegalArgumentException("OCPP Call must contain 4 elements");
            }
            builder.action(jsonNode.get(2).asText());
            builder.payload(jsonNode.get(3));
        } else if (messageTypeId == 3) { // Response (CallResult)
            builder.payload(jsonNode.get(2));
        } else if (messageTypeId == 4) { // Error (CallError)
            if (jsonNode.size() < 5) {
                throw new IllegalArgumentException("OCPP CallError must contain at least 4 elements");
            }
            builder.errorCode(jsonNode.get(2).asText());
            builder.errorDescription(jsonNode.get(3).asText());
            if (jsonNode.size() > 4) {
                builder.errorDetails(jsonNode.get(4));
            }
        } else {
            throw new IllegalArgumentException("Unknown OCPP Message Type ID: " + messageTypeId);
        }

        return builder.build();
    }

    public String toRawCall(String uniqueId, OcppAction action, Object payload) throws IOException {
        ArrayNode arrayNode = objectMapper.createArrayNode();
        arrayNode.add(2);
        arrayNode.add(uniqueId);
        arrayNode.add(action.name());
        arrayNode.addPOJO(payload);
        return objectMapper.writeValueAsString(arrayNode);
    }

    public String toRawCallResult(String uniqueId, Object payload) throws IOException {
        ArrayNode arrayNode = objectMapper.createArrayNode();
        arrayNode.add(3);
        arrayNode.add(uniqueId);
        arrayNode.addPOJO(payload);
        return objectMapper.writeValueAsString(arrayNode);
    }

    public String toRawCallError(String uniqueId, String errorCode, String errorDescription, Object errorDetails) throws IOException {
        ArrayNode arrayNode = objectMapper.createArrayNode();
        arrayNode.add(4);
        arrayNode.add(uniqueId);
        arrayNode.add(errorCode);
        arrayNode.add(errorDescription);
        arrayNode.addPOJO(errorDetails);
        return objectMapper.writeValueAsString(arrayNode);
    }
}
