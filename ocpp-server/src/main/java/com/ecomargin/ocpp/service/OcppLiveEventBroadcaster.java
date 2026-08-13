package com.ecomargin.ocpp.service;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@Slf4j
@Component
public class OcppLiveEventBroadcaster {

    private final Map<Long, CopyOnWriteArrayList<SseEmitter>> emitters = new ConcurrentHashMap<>();

    public SseEmitter subscribeSession(Long sessionId) {
        SseEmitter emitter = new SseEmitter(1800000L); // 30 minutes timeout
        emitters.computeIfAbsent(sessionId, k -> new CopyOnWriteArrayList<>()).add(emitter);

        emitter.onCompletion(() -> removeEmitter(sessionId, emitter));
        emitter.onTimeout(() -> removeEmitter(sessionId, emitter));
        emitter.onError((e) -> removeEmitter(sessionId, emitter));

        log.info("[SSE-SUB] Client subscribed to live session stream: sessionId={}", sessionId);
        return emitter;
    }

    private void removeEmitter(Long sessionId, SseEmitter emitter) {
        CopyOnWriteArrayList<SseEmitter> list = emitters.get(sessionId);
        if (list != null) {
            list.remove(emitter);
            if (list.isEmpty()) {
                emitters.remove(sessionId);
            }
        }
    }

    public void broadcastLiveMetrics(Long sessionId, Long userId, String chargerId, String status,
                                     double percentage, double kwhDelivered, double currentPowerKw,
                                     long durationSeconds, double totalCost) {
        CopyOnWriteArrayList<SseEmitter> list = emitters.get(sessionId);
        LiveChargingMetric metric = LiveChargingMetric.builder()
                .sessionId(sessionId)
                .userId(userId)
                .chargerId(chargerId)
                .status(status)
                .percentage(percentage)
                .kwhDelivered(kwhDelivered)
                .currentPowerKw(currentPowerKw)
                .durationSeconds(durationSeconds)
                .totalCost(totalCost)
                .timestamp(System.currentTimeMillis())
                .build();

        if (list != null && !list.isEmpty()) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("charging-update").data(metric));
                } catch (Exception e) {
                    removeEmitter(sessionId, emitter);
                }
            }
        }

        log.debug("[LIVE-METRIC] Session {}: {}%, {} kWh, {} kW, ₹{}", sessionId, percentage, kwhDelivered, currentPowerKw, totalCost);
    }

    public void broadcastConnectorStatus(String chargePointId, int connectorIndex, String status) {
        log.info("[STATUS-BROADCAST] Charger {} connector {} status changed to {}", chargePointId, connectorIndex, status);
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LiveChargingMetric {
        private Long sessionId;
        private Long userId;
        private String chargerId;
        private String status;
        private double percentage;
        private double kwhDelivered;
        private double currentPowerKw;
        private long durationSeconds;
        private double totalCost;
        private long timestamp;
    }
}
