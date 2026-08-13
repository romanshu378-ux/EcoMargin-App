package com.ecomargin.ocpp.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
public class MainBackendEventPublisher {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${ocpp.main-backend-url:https://ecomargin-app.onrender.com}")
    private String mainBackendUrl;

    @Value("${ocpp.internal-api-secret:ecomargin-internal-secret-key-2026}")
    private String internalApiSecret;

    @Async
    public void publishEvent(String eventType, String chargePointId, Map<String, Object> payload) {
        if (mainBackendUrl == null || mainBackendUrl.isBlank()) {
            return;
        }

        try {
            Map<String, Object> body = new HashMap<>();
            body.put("eventType", eventType);
            body.put("chargePointId", chargePointId);
            body.put("timestamp", Instant.now().toString());
            if (payload != null) {
                body.putAll(payload);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("X-Internal-Secret", internalApiSecret);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            String url = mainBackendUrl.replaceAll("/+$", "") + "/api/v1/ocpp/internal/events";

            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);
            log.debug("[EVENT-PUB] Forwarded event {} for charger {} to main backend. Response status: {}",
                    eventType, chargePointId, response.getStatusCode());
        } catch (Exception e) {
            log.warn("[EVENT-PUB-WARN] Non-fatal: Failed to forward event {} for charger {} to main backend: {}",
                    eventType, chargePointId, e.getMessage());
        }
    }
}
