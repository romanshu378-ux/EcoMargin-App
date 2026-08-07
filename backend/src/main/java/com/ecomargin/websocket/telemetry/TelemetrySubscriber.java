package com.ecomargin.websocket.telemetry;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

@Slf4j
@Component
@ConditionalOnProperty(name = "spring.redis.enabled", havingValue = "true", matchIfMissing = false)
@RequiredArgsConstructor
public class TelemetrySubscriber implements MessageListener {

    private final RealtimeWebSocketHandler webSocketHandler;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void onMessage(Message message, byte[] pattern) {
        String body = new String(message.getBody(), StandardCharsets.UTF_8);
        log.debug("Received raw telemetry update from Redis: {}", body);

        try {
            JsonNode payload = objectMapper.readTree(body);
            String type = payload.get("type").asText();
            String resourceId = payload.get("resourceId").asText();

            // Broadcast to specific channels based on resource IDs
            if (type.startsWith("CHARGER_")) {
                webSocketHandler.broadcastToTopic("charger:" + resourceId, body);
            } else if (type.startsWith("VENDOR_") || type.startsWith("REVENUE_")) {
                webSocketHandler.broadcastToTopic("vendor:" + resourceId, body);
            } else {
                // Global broadcast topic
                webSocketHandler.broadcastToTopic("global", body);
            }

        } catch (Exception e) {
            log.error("Failed to process telemetry message from Redis Pub/Sub", e);
        }
    }
}
