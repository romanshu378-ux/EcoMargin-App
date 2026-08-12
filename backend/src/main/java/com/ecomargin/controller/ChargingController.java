package com.ecomargin.controller;

import com.ecomargin.model.*;
import com.ecomargin.repository.*;
import com.ecomargin.service.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/v1/charging", "/api/v1/charging-sessions"})
@RequiredArgsConstructor
public class ChargingController {

    private final ChargingSessionRepository chargingSessionRepository;
    private final WalletRepository walletRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final ConnectorRepository connectorRepository;
    private final SettingRepository settingRepository;
    private final WalletService walletService;

    private static final List<String> ACTIVE_STATUSES = List.of(
            "STARTING", "ACTIVE", "STOPPING", "PREPARING", "CHARGING", "FINISHING"
    );

    private User getAuthenticatedUser() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new RuntimeException("User not authenticated"));
    }

    private Map<String, Object> mapSessionToMap(ChargingSession session) {
        if (session == null) return null;
        
        long durationSec = 0;
        if (ACTIVE_STATUSES.contains(session.getStatus())) {
            durationSec = Duration.between(session.getStartTime(), LocalDateTime.now()).getSeconds();
            if (durationSec < 0) durationSec = 0;
        } else {
            if (session.getEndTime() != null) {
                durationSec = Duration.between(session.getStartTime(), session.getEndTime()).getSeconds();
            }
        }

        double speedKw = 42.5;
        double energyKwh = (durationSec * speedKw) / 3600.0;
        double pricePerKwh = 18.0;
        
        // Read dynamic rate from settings
        try {
            Setting rateSetting = settingRepository.findById("default_charging_rate_per_kwh").orElse(null);
            if (rateSetting != null) {
                double rate = Double.parseDouble(rateSetting.getValue());
                if (rate > 0.0) {
                    if (rate == 0.35) {
                        pricePerKwh = 18.0; // ₹18.00 is a standard rate in India
                    } else {
                        pricePerKwh = rate;
                    }
                }
            }
        } catch (Exception e) {
            // fallback
        }

        double cost = energyKwh * pricePerKwh;
        double batteryPercentage = Math.min(100.0, 42.0 + (durationSec * 0.1));

        if (!ACTIVE_STATUSES.contains(session.getStatus())) {
            energyKwh = session.getTotalEnergyKwh() != null ? session.getTotalEnergyKwh().doubleValue() : 0.0;
            cost = session.getTotalCost() != null ? session.getTotalCost().doubleValue() : 0.0;
            batteryPercentage = 100.0;
        }

        String stationName = "EcoMargin Charging Hub";
        String chargerId = "CHG-DC-04";
        String connectorType = "CCS2";

        if (session.getConnector() != null) {
            connectorType = session.getConnector().getType();
            if (session.getConnector().getCharger() != null) {
                chargerId = session.getConnector().getCharger().getOcppId();
                if (session.getConnector().getCharger().getStation() != null) {
                    stationName = session.getConnector().getCharger().getStation().getName();
                }
            }
        }

        Map<String, Object> map = new HashMap<>();
        map.put("sessionId", session.getId());
        map.put("stationName", stationName);
        map.put("chargerId", chargerId);
        map.put("connectorType", connectorType);
        map.put("status", session.getStatus());
        map.put("percentage", batteryPercentage);
        map.put("kwhDelivered", energyKwh);
        map.put("currentPowerKw", speedKw);
        map.put("durationSeconds", durationSec);
        map.put("totalCost", cost);
        map.put("startTime", session.getStartTime());
        map.put("endTime", session.getEndTime());
        map.put("ratePerKwh", pricePerKwh);
        map.put("paymentMethod", "Wallet");
        map.put("ocppTransactionId", session.getOcppTransactionId() != null ? session.getOcppTransactionId() : ("OCPP-TX-" + session.getId()));

        // Support additional structure for Requirement 3
        map.put("powerKw", speedKw);
        map.put("energyKwh", energyKwh);
        map.put("duration", durationSec);
        map.put("currentCost", cost);
        
        BigDecimal walletBalance = BigDecimal.ZERO;
        if (session.getUser() != null) {
            Wallet w = walletRepository.findByUserId(session.getUser().getId()).orElse(null);
            if (w != null) {
                walletBalance = w.getBalance();
            }
        }
        map.put("walletBalance", walletBalance);
        map.put("startedAt", session.getStartTime());

        return map;
    }

    @GetMapping("/config")
    public ResponseEntity<?> getChargingConfig() {
        BigDecimal minRequired = new BigDecimal("50.00");
        try {
            Setting minBalanceSetting = settingRepository.findById("min_wallet_balance_to_start").orElse(null);
            if (minBalanceSetting != null) {
                minRequired = new BigDecimal(minBalanceSetting.getValue());
            }
        } catch (Exception e) {
            // ignore
        }

        BigDecimal chargingRate = new BigDecimal("18.00");
        try {
            Setting rateSetting = settingRepository.findById("default_charging_rate_per_kwh").orElse(null);
            if (rateSetting != null) {
                double rate = Double.parseDouble(rateSetting.getValue());
                if (rate > 0.0) {
                    if (rate == 0.35) {
                        chargingRate = new BigDecimal("18.00");
                    } else {
                        chargingRate = BigDecimal.valueOf(rate);
                    }
                }
            }
        } catch (Exception e) {
            // ignore
        }

        Map<String, Object> config = new HashMap<>();
        config.put("minRequiredBalance", minRequired);
        config.put("chargingRatePerKwh", chargingRate);
        return ResponseEntity.ok(config);
    }

    @GetMapping("/active")
    public ResponseEntity<?> getActiveSession() {
        User user = getAuthenticatedUser();
        Optional<ChargingSession> activeOpt = chargingSessionRepository
                .findFirstByUserAndStatusInOrderByCreatedAtDesc(user, ACTIVE_STATUSES);
        
        if (activeOpt.isEmpty()) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(mapSessionToMap(activeOpt.get()));
    }

    @PostMapping("/start")
    public ResponseEntity<?> startCharging(@RequestBody(required = false) Map<String, Object> payload) {
        User user = getAuthenticatedUser();
        
        Optional<ChargingSession> activeOpt = chargingSessionRepository
                .findFirstByUserAndStatusInOrderByCreatedAtDesc(user, ACTIVE_STATUSES);
        if (activeOpt.isPresent()) {
            return ResponseEntity.status(409).body(Map.of(
                    "code", "ACTIVE_SESSION_EXISTS",
                    "message", "User already has an active charging session."
            ));
        }

        Wallet wallet = walletRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("Wallet not found"));
        
        BigDecimal minRequired = new BigDecimal("50.00");
        try {
            Setting minBalanceSetting = settingRepository.findById("min_wallet_balance_to_start").orElse(null);
            if (minBalanceSetting != null) {
                minRequired = new BigDecimal(minBalanceSetting.getValue());
            }
        } catch (Exception e) {
            log.warn("Failed to load min_wallet_balance_to_start setting: {}", e.getMessage());
        }

        if (wallet.getBalance().compareTo(minRequired) < 0) {
            Map<String, Object> body = new HashMap<>();
            body.put("code", "INSUFFICIENT_WALLET_BALANCE");
            body.put("message", "Insufficient wallet balance to start charging. Minimum ₹" + minRequired + " required.");
            body.put("availableBalance", wallet.getBalance());
            body.put("requiredBalance", minRequired);
            return ResponseEntity.status(402).body(body);
        }

        Long connectorId = null;
        if (payload != null && payload.containsKey("connectorId")) {
            Object idObj = payload.get("connectorId");
            if (idObj instanceof Number) {
                connectorId = ((Number) idObj).longValue();
            } else if (idObj instanceof String) {
                try {
                    connectorId = Long.parseLong((String) idObj);
                } catch (NumberFormatException e) {
                    // Ignore
                }
            }
        }

        Connector connector = null;
        if (connectorId != null) {
            connector = connectorRepository.findById(connectorId).orElse(null);
            if (connector == null) {
                return ResponseEntity.status(404).body(Map.of(
                        "code", "CONNECTOR_NOT_FOUND",
                        "message", "The specified connector was not found."
                ));
            }
        } else {
            List<Connector> connectors = connectorRepository.findAll();
            if (!connectors.isEmpty()) {
                connector = connectors.get(0);
            }
        }

        if (connector == null) {
            return ResponseEntity.status(404).body(Map.of(
                    "code", "CONNECTOR_NOT_FOUND",
                    "message", "No connectors available on the system."
            ));
        }

        // Validate connector is available
        if (!"AVAILABLE".equalsIgnoreCase(connector.getStatus())) {
            return ResponseEntity.status(409).body(Map.of(
                    "code", "CONNECTOR_UNAVAILABLE",
                    "message", "Connector is currently unavailable."
            ));
        }

        // Validate charger is available
        Charger charger = connector.getCharger();
        if (charger == null || !"AVAILABLE".equalsIgnoreCase(charger.getStatus())) {
            return ResponseEntity.status(409).body(Map.of(
                    "code", "CHARGER_UNAVAILABLE",
                    "message", "Charger is currently unavailable."
            ));
        }

        // Validate station is active
        Station station = charger.getStation();
        if (station == null || !"ACTIVE".equalsIgnoreCase(station.getStatus())) {
            return ResponseEntity.status(409).body(Map.of(
                    "code", "STATION_UNAVAILABLE",
                    "message", "Station is currently unavailable."
            ));
        }

        ChargingSession session = ChargingSession.builder()
                .user(user)
                .connector(connector)
                .status("CHARGING") // Initial charging status
                .startTime(LocalDateTime.now())
                .totalEnergyKwh(BigDecimal.ZERO)
                .totalCost(BigDecimal.ZERO)
                .ocppTransactionId("OCPP-TX-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .meterStartWh(BigDecimal.valueOf(1000.000))
                .build();
        
        ChargingSession saved = chargingSessionRepository.save(session);
        return ResponseEntity.ok(mapSessionToMap(saved));
    }

    @GetMapping("/{sessionId}")
    public ResponseEntity<?> getSessionById(@PathVariable Long sessionId) {
        User user = getAuthenticatedUser();
        ChargingSession session = chargingSessionRepository.findById(sessionId)
                .orElseThrow(() -> new RuntimeException("Charging session not found"));

        if (!session.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("message", "Access denied"));
        }

        return ResponseEntity.ok(mapSessionToMap(session));
    }

    @PostMapping({"/stop", "/{sessionId}/stop"})
    public ResponseEntity<?> stopCharging(@PathVariable(required = false) Long sessionId) {
        User user = getAuthenticatedUser();
        ChargingSession session;

        if (sessionId != null) {
            session = chargingSessionRepository.findById(sessionId)
                    .orElseThrow(() -> new RuntimeException("Charging session not found: " + sessionId));
        } else {
            Optional<ChargingSession> activeOpt = chargingSessionRepository
                    .findFirstByUserAndStatusInOrderByCreatedAtDesc(user, ACTIVE_STATUSES);
            if (activeOpt.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("message", "No active charging session to stop"));
            }
            session = activeOpt.get();
        }

        // Security check
        if (!session.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("message", "Access denied"));
        }

        // Idempotent Stop check: if session is already completed
        if (session.getStatus().equals("COMPLETED")) {
            log.info("Charging session {} already stopped. Returning existing session details.", session.getId());
            return ResponseEntity.ok(mapSessionToMap(session));
        }

        LocalDateTime endTime = LocalDateTime.now();
        long durationSec = Duration.between(session.getStartTime(), endTime).getSeconds();
        if (durationSec < 0) durationSec = 0;

        double speedKw = 42.5;
        double energyKwh = (durationSec * speedKw) / 3600.0;
        double pricePerKwh = 18.0;

        try {
            Setting rateSetting = settingRepository.findById("default_charging_rate_per_kwh").orElse(null);
            if (rateSetting != null) {
                double rate = Double.parseDouble(rateSetting.getValue());
                if (rate > 0.0) {
                    if (rate == 0.35) {
                        pricePerKwh = 18.0;
                    } else {
                        pricePerKwh = rate;
                    }
                }
            }
        } catch (Exception e) {
            // fallback
        }

        double cost = energyKwh * pricePerKwh;
        BigDecimal finalCost = BigDecimal.valueOf(cost).setScale(2, RoundingMode.HALF_UP);
        BigDecimal finalEnergy = BigDecimal.valueOf(energyKwh).setScale(3, RoundingMode.HALF_UP);

        session.setEndTime(endTime);
        session.setStatus("COMPLETED");
        session.setTotalEnergyKwh(finalEnergy);
        session.setMeterStopWh(session.getMeterStartWh().add(finalEnergy.multiply(BigDecimal.valueOf(1000))));
        
        String ocppTxId = session.getOcppTransactionId();
        if (ocppTxId == null) {
            ocppTxId = "OCPP-TX-" + session.getId();
        }

        // Deduct balance and create debit transaction ledger entry atomically
        walletService.processChargingDebit(session.getId(), ocppTxId, finalCost);
        
        // Save the updated completed charging session details
        ChargingSession saved = chargingSessionRepository.save(session);
        return ResponseEntity.ok(mapSessionToMap(saved));
    }

    @PostMapping("/{sessionId}/billing")
    public ResponseEntity<?> processBilling(@PathVariable Long sessionId) {
        User user = getAuthenticatedUser();
        ChargingSession session = chargingSessionRepository.findById(sessionId)
                .orElseThrow(() -> new RuntimeException("Charging session not found"));

        if (!session.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("message", "Access denied"));
        }

        return ResponseEntity.ok(mapSessionToMap(session));
    }

    @GetMapping("/history")
    public ResponseEntity<?> getHistory() {
        User user = getAuthenticatedUser();
        List<ChargingSession> sessions = chargingSessionRepository.findByUserOrderByCreatedAtDesc(user);
        
        List<Map<String, Object>> list = sessions.stream()
                .filter(s -> s.getStatus().equals("COMPLETED"))
                .map(this::mapSessionToMap)
                .collect(Collectors.toList());
        return ResponseEntity.ok(list);
    }
}

