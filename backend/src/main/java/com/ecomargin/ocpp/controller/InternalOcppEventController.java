package com.ecomargin.ocpp.controller;

import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.ChargingSession;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.ChargingSessionRepository;
import com.ecomargin.websocket.telemetry.LiveTelemetryBroadcaster;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/v1/ocpp/internal")
@RequiredArgsConstructor
public class InternalOcppEventController {

    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;
    private final ChargingSessionRepository chargingSessionRepository;
    private final LiveTelemetryBroadcaster telemetryBroadcaster;

    @Value("${ocpp.internal-api-secret:ecomargin-internal-secret-key-2026}")
    private String internalApiSecret;

    @PostMapping("/events")
    public ResponseEntity<?> receiveInternalEvent(
            @RequestHeader(value = "X-Internal-Secret", required = false) String secret,
            @RequestBody Map<String, Object> payload) {

        // 1. Secret & Authentication Verification
        boolean hasValidSecret = secret != null && secret.equals(internalApiSecret);
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if (!hasValidSecret) {
            if (auth == null || !auth.isAuthenticated() || "anonymousUser".equalsIgnoreCase(auth.getName())) {
                log.warn("[OCPP-SECURITY] Unauthenticated attempt to access internal simulator endpoint");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Unauthorized internal event request"));
            }

            // Customer users cannot control simulator state
            boolean isCustomerOnly = auth.getAuthorities().stream()
                    .anyMatch(a -> "ROLE_CUSTOMER".equalsIgnoreCase(a.getAuthority())) &&
                    auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().contains("ADMIN") || a.getAuthority().contains("OPERATOR"));

            if (isCustomerOnly) {
                log.warn("[OCPP-SECURITY] CUSTOMER user {} attempted to access simulator endpoint", auth.getName());
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "CUSTOMER users cannot access simulator endpoints"));
            }
        }

        String eventType = (String) payload.getOrDefault("eventType", "UNKNOWN");
        String chargePointId = (String) payload.get("chargePointId");

        if (chargePointId == null || chargePointId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "chargePointId is required"));
        }

        log.debug("[OCPP-EVENT-RECV] Type={}, Charger={}", eventType, chargePointId);

        // Find charger & vendor
        Optional<Charger> chargerOpt = chargerRepository.findByOcppId(chargePointId);
        Charger charger = chargerOpt.orElse(null);
        Long vendorId = null;
        if (charger != null && charger.getStation() != null && charger.getStation().getVendor() != null) {
            vendorId = charger.getStation().getVendor().getId();
        }

        Long userId = null;
        if (payload.containsKey("userId") && payload.get("userId") != null) {
            try {
                userId = Long.parseLong(payload.get("userId").toString());
            } catch (Exception e) {
                // Ignore
            }
        }

        // Update database records based on event type
        if (charger != null) {
            charger.setUpdatedAt(LocalDateTime.now());

            if (payload.containsKey("status")) {
                String status = (String) payload.get("status");
                if ("AVAILABLE".equalsIgnoreCase(status) || "CHARGING".equalsIgnoreCase(status) || "PREPARING".equalsIgnoreCase(status) || "FAULTED".equalsIgnoreCase(status)) {
                    charger.setStatus(status);
                }
            }
            if (payload.containsKey("firmwareVersion")) {
                charger.setFirmwareVersion((String) payload.get("firmwareVersion"));
            }
            chargerRepository.save(charger);
        }

        // Prepare live event payload for client broadcast
        Map<String, Object> broadcastData = new HashMap<>(payload);
        broadcastData.put("chargePointId", chargePointId);
        broadcastData.put("lastUpdate", LocalDateTime.now().toString());
        if (vendorId != null) {
            broadcastData.put("vendorId", vendorId);
        }

        // Broadcast live telemetry with RBAC
        telemetryBroadcaster.broadcastEvent(userId, vendorId, eventType, broadcastData);

        return ResponseEntity.ok(Map.of("status", "SUCCESS", "eventType", eventType));
    }
}
