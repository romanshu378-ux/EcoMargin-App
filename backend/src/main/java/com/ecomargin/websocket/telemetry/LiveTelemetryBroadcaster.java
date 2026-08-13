package com.ecomargin.websocket.telemetry;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

@Slf4j
@Component
@RequiredArgsConstructor
public class LiveTelemetryBroadcaster {

    private final RealtimeWebSocketHandler webSocketHandler;

    // Subscriptions for SSE
    private final Map<Long, Set<SseEmitter>> customerEmitters = new ConcurrentHashMap<>();
    private final Map<Long, Set<SseEmitter>> vendorEmitters = new ConcurrentHashMap<>();
    private final Set<SseEmitter> adminEmitters = new CopyOnWriteArraySet<>();

    public SseEmitter subscribeCustomer(Long userId) {
        SseEmitter emitter = new SseEmitter(0L); // Infinite timeout
        customerEmitters.computeIfAbsent(userId, k -> new CopyOnWriteArraySet<>()).add(emitter);

        emitter.onCompletion(() -> removeCustomerEmitter(userId, emitter));
        emitter.onTimeout(() -> removeCustomerEmitter(userId, emitter));
        emitter.onError(e -> removeCustomerEmitter(userId, emitter));

        try {
            emitter.send(SseEmitter.event().name("INIT").data(Map.of("status", "CONNECTED", "userId", userId)));
        } catch (IOException e) {
            removeCustomerEmitter(userId, emitter);
        }
        return emitter;
    }

    public SseEmitter subscribeVendor(Long vendorId) {
        SseEmitter emitter = new SseEmitter(0L);
        vendorEmitters.computeIfAbsent(vendorId, k -> new CopyOnWriteArraySet<>()).add(emitter);

        emitter.onCompletion(() -> removeVendorEmitter(vendorId, emitter));
        emitter.onTimeout(() -> removeVendorEmitter(vendorId, emitter));
        emitter.onError(e -> removeVendorEmitter(vendorId, emitter));

        try {
            emitter.send(SseEmitter.event().name("INIT").data(Map.of("status", "CONNECTED", "vendorId", vendorId)));
        } catch (IOException e) {
            removeVendorEmitter(vendorId, emitter);
        }
        return emitter;
    }

    public SseEmitter subscribeAdmin() {
        SseEmitter emitter = new SseEmitter(0L);
        adminEmitters.add(emitter);

        emitter.onCompletion(() -> adminEmitters.remove(emitter));
        emitter.onTimeout(() -> adminEmitters.remove(emitter));
        emitter.onError(e -> adminEmitters.remove(emitter));

        try {
            emitter.send(SseEmitter.event().name("INIT").data(Map.of("status", "CONNECTED", "role", "ADMIN")));
        } catch (IOException e) {
            adminEmitters.remove(emitter);
        }
        return emitter;
    }

    private void removeCustomerEmitter(Long userId, SseEmitter emitter) {
        Set<SseEmitter> emitters = customerEmitters.get(userId);
        if (emitters != null) {
            emitters.remove(emitter);
        }
    }

    private void removeVendorEmitter(Long vendorId, SseEmitter emitter) {
        Set<SseEmitter> emitters = vendorEmitters.get(vendorId);
        if (emitters != null) {
            emitters.remove(emitter);
        }
    }

    public void broadcastEvent(Long userId, Long vendorId, String eventName, Map<String, Object> data) {
        // 1. Send to specific customer (if matching session)
        if (userId != null && userId > 0) {
            Set<SseEmitter> emitters = customerEmitters.get(userId);
            if (emitters != null) {
                for (SseEmitter emitter : emitters) {
                    try {
                        emitter.send(SseEmitter.event().name(eventName).data(data));
                    } catch (Exception e) {
                        removeCustomerEmitter(userId, emitter);
                    }
                }
            }
        }

        // 2. Send to assigned vendor
        if (vendorId != null && vendorId > 0) {
            Set<SseEmitter> emitters = vendorEmitters.get(vendorId);
            if (emitters != null) {
                for (SseEmitter emitter : emitters) {
                    try {
                        emitter.send(SseEmitter.event().name(eventName).data(data));
                    } catch (Exception e) {
                        removeVendorEmitter(vendorId, emitter);
                    }
                }
            }
        }

        // 3. Send to admins (Admin sees all events)
        for (SseEmitter emitter : adminEmitters) {
            try {
                emitter.send(SseEmitter.event().name(eventName).data(data));
            } catch (Exception e) {
                adminEmitters.remove(emitter);
            }
        }

        // 4. Also broadcast to WebSocket topics if active
        String chargePointId = (String) data.get("chargePointId");
        if (chargePointId != null) {
            webSocketHandler.broadcastToTopic("charger:" + chargePointId, data.toString());
        }
        if (vendorId != null) {
            webSocketHandler.broadcastToTopic("vendor:" + vendorId, data.toString());
        }
        webSocketHandler.broadcastToTopic("global", data.toString());
    }
}
