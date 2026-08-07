package com.ecomargin.websocket.telemetry;

import com.ecomargin.config.RedisPubSubConfig;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class TelemetryPublisher {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public void publish(String type, String resourceId, Map<String, Object> data) {
        try {
            Map<String, Object> payload = Map.of(
                    "type", type, // CHARGER_STATUS, METER_VALUES, REVENUE_UPDATE
                    "resourceId", resourceId, // chargeBoxId or vendorId
                    "timestamp", java.time.Instant.now().toString(),
                    "data", data
            );
            
            String rawPayload = objectMapper.writeValueAsString(payload);
            log.debug("Publishing telemetry to Redis channel: {}", rawPayload);
            redisTemplate.convertAndSend(RedisPubSubConfig.TELEMETRY_TOPIC, rawPayload);
        } catch (Exception e) {
            log.error("Failed to publish telemetry event to Redis", e);
        }
    }
}
