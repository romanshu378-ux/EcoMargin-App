package com.ecomargin.ocpp.controller;

import com.ecomargin.ocpp.protocol.OcppJsonParser;
import com.ecomargin.ocpp.service.OcppLiveEventBroadcaster;
import com.ecomargin.ocpp.websocket.WebSocketSessionRegistry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/ocpp")
@RequiredArgsConstructor
public class OcppApiController {

    private final WebSocketSessionRegistry sessionRegistry;
    private final OcppLiveEventBroadcaster liveEventBroadcaster;
    private final OcppJsonParser ocppJsonParser;

    @GetMapping("/health")
    public ResponseEntity<?> health() {
        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "service", "EcoMargin OCPP 1.6J Server",
                "timestamp", Instant.now().toString()
        ));
    }

    @GetMapping("/stream/{sessionId}")
    public SseEmitter streamLiveSession(@PathVariable Long sessionId) {
        log.info("[API-SSE] Client opening live SSE stream for sessionId={}", sessionId);
        return liveEventBroadcaster.subscribeSession(sessionId);
    }

    @PostMapping("/remote-start")
    public ResponseEntity<?> remoteStart(@RequestBody Map<String, Object> body) {
        String chargePointId = (String) body.get("chargePointId");
        String idTag = (String) body.getOrDefault("idTag", "REMOTE-START-USER");
        Integer connectorId = (Integer) body.getOrDefault("connectorId", 1);

        if (chargePointId == null || chargePointId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "chargePointId is required"));
        }

        if (!sessionRegistry.isConnected(chargePointId)) {
            return ResponseEntity.status(404).body(Map.of(
                    "status", "REJECTED",
                    "message", "ChargePoint " + chargePointId + " is not connected via WebSocket"
            ));
        }

        try {
            String msgId = UUID.randomUUID().toString();
            Map<String, Object> payload = Map.of(
                    "connectorId", connectorId,
                    "idTag", idTag
            );
            String callJson = ocppJsonParser.buildCallJson(msgId, "RemoteStartTransaction", payload);
            boolean sent = sessionRegistry.sendTextMessage(chargePointId, callJson);

            if (sent) {
                return ResponseEntity.ok(Map.of(
                        "status", "ACCEPTED",
                        "message", "RemoteStartTransaction command sent to charger " + chargePointId,
                        "messageId", msgId
                ));
            } else {
                return ResponseEntity.status(500).body(Map.of("status", "FAILED", "message", "Failed to send command to WebSocket session"));
            }
        } catch (Exception e) {
            log.error("[REMOTE-START-ERR] Failed to build or send RemoteStartTransaction", e);
            return ResponseEntity.status(500).body(Map.of("status", "ERROR", "message", e.getMessage()));
        }
    }

    @PostMapping("/remote-stop")
    public ResponseEntity<?> remoteStop(@RequestBody Map<String, Object> body) {
        String chargePointId = (String) body.get("chargePointId");
        Object txIdObj = body.get("transactionId");

        if (chargePointId == null || txIdObj == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "chargePointId and transactionId are required"));
        }

        if (!sessionRegistry.isConnected(chargePointId)) {
            return ResponseEntity.status(404).body(Map.of(
                    "status", "REJECTED",
                    "message", "ChargePoint " + chargePointId + " is not connected via WebSocket"
            ));
        }

        try {
            String msgId = UUID.randomUUID().toString();
            Map<String, Object> payload = Map.of("transactionId", txIdObj);
            String callJson = ocppJsonParser.buildCallJson(msgId, "RemoteStopTransaction", payload);
            boolean sent = sessionRegistry.sendTextMessage(chargePointId, callJson);

            if (sent) {
                return ResponseEntity.ok(Map.of(
                        "status", "ACCEPTED",
                        "message", "RemoteStopTransaction command sent to charger " + chargePointId,
                        "messageId", msgId
                ));
            } else {
                return ResponseEntity.status(500).body(Map.of("status", "FAILED", "message", "Failed to send command to WebSocket session"));
            }
        } catch (Exception e) {
            log.error("[REMOTE-STOP-ERR] Failed to build or send RemoteStopTransaction", e);
            return ResponseEntity.status(500).body(Map.of("status", "ERROR", "message", e.getMessage()));
        }
    }
}
