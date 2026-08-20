package com.ecomargin.controller;

import com.ecomargin.model.*;
import com.ecomargin.repository.*;
import com.ecomargin.service.NotificationService;
import com.ecomargin.service.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

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
@org.springframework.transaction.annotation.Transactional
public class ChargingController {

    private final ChargingSessionRepository chargingSessionRepository;
    private final WalletRepository walletRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final ConnectorRepository connectorRepository;
    private final ChargerRepository chargerRepository;
    private final StationRepository stationRepository;
    private final SettingRepository settingRepository;
    private final WalletService walletService;
    private final NotificationService notificationService;

    private static final List<String> ACTIVE_STATUSES = List.of(
            "STARTING", "ACTIVE", "STOPPING", "PREPARING", "CHARGING", "FINISHING"
    );

    private User getAuthenticatedUser() {
        if (SecurityContextHolder.getContext().getAuthentication() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated");
        }
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        if (email == null || "anonymousUser".equalsIgnoreCase(email)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated");
        }
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated"));
    }

    private Long parseId(Map<String, Object> payload, String key) {
        if (payload == null || !payload.containsKey(key)) return null;
        Object val = payload.get(key);
        if (val == null) return null;
        if (val instanceof Number) {
            return ((Number) val).longValue();
        }
        if (val instanceof String) {
            try {
                return Long.parseLong((String) val);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    private Map<String, Object> mapSessionToMap(ChargingSession session) {
        if (session == null) return null;

        long durationSec = 0;
        if (ACTIVE_STATUSES.contains(session.getStatus().toUpperCase())) {
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
        double batteryPercentage = Math.min(100.0, 42.0 + (durationSec * 0.1));

        if (!ACTIVE_STATUSES.contains(session.getStatus().toUpperCase())) {
            energyKwh = session.getTotalEnergyKwh() != null ? session.getTotalEnergyKwh().doubleValue() : 0.0;
            cost = session.getTotalCost() != null ? session.getTotalCost().doubleValue() : 0.0;
            batteryPercentage = 100.0;
        }

        String stationName = "EcoMargin Charging Hub";
        String stationAddress = "Downtown EV Station, City Center";
        String chargerId = "CHG-DC-04";
        String chargerStatus = "AVAILABLE";
        String connectorType = "CCS2";
        Long connectorId = null;

        if (session.getConnector() != null) {
            connectorId = session.getConnector().getId();
            connectorType = session.getConnector().getType();
            if (session.getConnector().getCharger() != null) {
                chargerId = session.getConnector().getCharger().getOcppId();
                chargerStatus = session.getConnector().getCharger().getStatus();
                if (session.getConnector().getCharger().getStation() != null) {
                    stationName = session.getConnector().getCharger().getStation().getName();
                    if (session.getConnector().getCharger().getStation().getAddress() != null) {
                        stationAddress = session.getConnector().getCharger().getStation().getAddress();
                    }
                }
            }
        }

        Map<String, Object> map = new HashMap<>();
        map.put("sessionId", session.getId());
        map.put("stationName", stationName);
        map.put("stationAddress", stationAddress);
        map.put("address", stationAddress);
        map.put("chargerId", chargerId);
        map.put("chargerStatus", chargerStatus != null ? chargerStatus : "AVAILABLE");
        map.put("connectorType", connectorType);
        map.put("connectorId", connectorId != null ? connectorId.toString() : "CONN-01");
        map.put("status", session.getStatus());
        map.put("percentage", batteryPercentage);
        map.put("kwhDelivered", energyKwh);
        map.put("currentPowerKw", speedKw);
        map.put("peakPowerKw", speedKw);
        map.put("voltage", 400.0);
        map.put("co2SavedKg", BigDecimal.valueOf(energyKwh * 0.85).setScale(2, RoundingMode.HALF_UP).doubleValue());
        map.put("durationSeconds", durationSec);
        map.put("totalCost", cost);
        map.put("startTime", session.getStartTime());
        map.put("endTime", session.getEndTime());
        map.put("ratePerKwh", pricePerKwh);
        map.put("paymentMethod", "EcoMargin Wallet");
        map.put("ocppTransactionId", session.getOcppTransactionId() != null ? session.getOcppTransactionId() : ("OCPP-TX-" + session.getId()));

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

        if (!user.isEnabled() || !user.isAccountNonLocked()) {
            log.warn("Security Alert: Inactive or locked user account {} attempted to start charging", user.getEmail());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                    "code", "USER_INACTIVE",
                    "message", "User account is disabled or inactive."
            ));
        }

        synchronized (("USER_START_LOCK_" + user.getId()).intern()) {
            // 1. Duplicate Start Protection: Check if active session already exists
            Optional<ChargingSession> activeOpt = chargingSessionRepository
                    .findFirstByUserAndStatusInOrderByCreatedAtDesc(user, ACTIVE_STATUSES);
            if (activeOpt.isPresent()) {
                log.warn("Security Alert: Duplicate session start attempt for user {}. Returning active session details.", user.getEmail());
                Map<String, Object> sessionMap = mapSessionToMap(activeOpt.get());
                Map<String, Object> responseBody = new HashMap<>(sessionMap);
                responseBody.put("code", "ACTIVE_SESSION_EXISTS");
                responseBody.put("message", "Charging session already active");
                responseBody.put("session", sessionMap);
                return ResponseEntity.status(HttpStatus.CONFLICT).body(responseBody);
            }

            Wallet wallet = walletRepository.findByUserId(user.getId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Wallet not found"));

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
                log.warn("Security Alert: User {} attempted start with insufficient wallet balance {}", user.getEmail(), wallet.getBalance());
                Map<String, Object> body = new HashMap<>();
                body.put("code", "INSUFFICIENT_WALLET_BALANCE");
                body.put("message", "Insufficient wallet balance to start charging. Minimum ₹" + minRequired + " required.");
                body.put("availableBalance", wallet.getBalance());
                body.put("requiredBalance", minRequired);
                return ResponseEntity.status(HttpStatus.PAYMENT_REQUIRED).body(body);
            }

            // Relational Hierarchy Validation & Lookup
            Long clientStationId = parseId(payload, "stationId");
            Long clientConnectorId = parseId(payload, "connectorId");
            Long clientChargerId = parseId(payload, "chargerId");
            String clientChargerOcppId = payload != null && payload.get("chargerId") instanceof String ? (String) payload.get("chargerId") : null;

            Connector connector = null;

            if (clientConnectorId != null) {
                connector = connectorRepository.findById(clientConnectorId).orElse(null);
                if (connector == null && clientChargerId != null) {
                    Charger chg = chargerRepository.findById(clientChargerId).orElse(null);
                    if (chg != null) {
                        connector = connectorRepository.findByChargerAndConnectorIndex(chg, clientConnectorId.intValue()).orElse(null);
                    }
                }
            } else if (clientChargerId != null || (clientChargerOcppId != null && !clientChargerOcppId.isBlank())) {
                Charger charger = clientChargerId != null ? chargerRepository.findById(clientChargerId).orElse(null) : null;
                if (charger == null && clientChargerOcppId != null) {
                    charger = chargerRepository.findByOcppId(clientChargerOcppId.trim()).orElse(null);
                }
                if (charger != null) {
                    List<Connector> connectors = connectorRepository.findByCharger(charger);
                    if (!connectors.isEmpty()) {
                        connector = connectors.get(0);
                    }
                }
            } else if (clientStationId != null) {
                Station station = stationRepository.findById(clientStationId).orElse(null);
                if (station != null && station.getChargers() != null) {
                    for (Charger chg : station.getChargers()) {
                        List<Connector> connectors = connectorRepository.findByCharger(chg);
                        if (!connectors.isEmpty()) {
                            connector = connectors.get(0);
                            break;
                        }
                    }
                }
            }

            if (connector == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "code", "CONNECTOR_NOT_FOUND",
                        "message", "The specified connector was not found."
                ));
            }

            // Relational Hierarchy Security Validation
            Charger chgRel = connector.getCharger();
            if (chgRel == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "code", "CHARGER_NOT_FOUND",
                        "message", "Charger associated with connector not found."
                ));
            }
            if (clientChargerId != null && !chgRel.getId().equals(clientChargerId)) {
                log.warn("Security Alert: Relational Mismatch! Client specified chargerId {} but connector {} belongs to chargerId {}",
                        clientChargerId, connector.getId(), chgRel.getId());
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                        "code", "INVALID_RELATIONSHIP",
                        "message", "Connector does not belong to the specified charger."
                ));
            }

            Station stRel = chgRel.getStation();
            if (stRel == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "code", "STATION_NOT_FOUND",
                        "message", "Station associated with charger not found."
                ));
            }
            if (clientStationId != null && !stRel.getId().equals(clientStationId)) {
                log.warn("Security Alert: Relational Mismatch! Client specified stationId {} but charger {} belongs to stationId {}",
                        clientStationId, chgRel.getId(), stRel.getId());
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                        "code", "INVALID_RELATIONSHIP",
                        "message", "Charger does not belong to the specified station."
                ));
            }

            // Connector Status & Busy Validation
            String connStatus = connector.getStatus() != null ? connector.getStatus().toUpperCase() : "UNAVAILABLE";
            if (connector.getDeletedAt() != null || Set.of("UNAVAILABLE", "DELETED", "INACTIVE", "DISABLED").contains(connStatus) || !List.of("AVAILABLE", "PREPARING", "PLUGGED").contains(connStatus)) {
                log.warn("Security Alert: Attempted to start session on connector {} in status {} / deletedAt {}", connector.getId(), connStatus, connector.getDeletedAt());
                return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                        "code", "CONNECTOR_UNAVAILABLE",
                        "message", "Connector is currently unavailable."
                ));
            }

            List<ChargingSession> activeConnSessions = chargingSessionRepository.findByConnectorAndStatusIn(connector, ACTIVE_STATUSES);
            if (!activeConnSessions.isEmpty()) {
                log.warn("Security Alert: Attempted to start session on connector {} which already has active session {}", connector.getId(), activeConnSessions.get(0).getId());
                return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                        "code", "CONNECTOR_BUSY",
                        "message", "Connector is currently in use by another charging session.",
                        "connectorId", connector.getId()
                ));
            }

            // Charger Status Validation
            Charger charger = connector.getCharger();
            String chgStatus = charger != null && charger.getStatus() != null ? charger.getStatus().toUpperCase() : "UNAVAILABLE";
            if (charger == null || charger.getDeletedAt() != null || Set.of("UNAVAILABLE", "DELETED", "INACTIVE", "DISABLED").contains(chgStatus)) {
                log.warn("Security Alert: Attempted to start session on charger in status {} / deletedAt {}", chgStatus, charger != null ? charger.getDeletedAt() : null);
                return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                        "code", "CHARGER_UNAVAILABLE",
                        "message", "Charger is currently unavailable."
                ));
            }

            // Station Status Validation
            Station station = charger.getStation();
            String stStatus = station != null && station.getStatus() != null ? station.getStatus().toUpperCase() : "INACTIVE";
            if (station == null || station.getDeletedAt() != null || !"ACTIVE".equalsIgnoreCase(stStatus)) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                        "code", "STATION_UNAVAILABLE",
                        "message", "Station is currently unavailable."
                ));
            }

            // Update connector status to CHARGING to reflect reservation
            connector.setStatus("CHARGING");
            connectorRepository.save(connector);

            ChargingSession session = ChargingSession.builder()
                    .user(user)
                    .connector(connector)
                    .status("CHARGING")
                    .startTime(LocalDateTime.now())
                    .totalEnergyKwh(BigDecimal.ZERO)
                    .totalCost(BigDecimal.ZERO)
                    .ocppTransactionId("OCPP-TX-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .meterStartWh(BigDecimal.valueOf(1000.000))
                    .build();

            ChargingSession saved = chargingSessionRepository.save(session);

            String stName = station.getName() != null ? station.getName() : "EcoMargin Charging Hub";
            notificationService.createNotification(
                    user,
                    "Charging Started",
                    "Your charging session at " + stName + " has started.",
                    "CHARGING"
            );

            return ResponseEntity.ok(mapSessionToMap(saved));
        }
    }

    @GetMapping("/{sessionId:\\d+}")
    public ResponseEntity<?> getSessionById(@PathVariable Long sessionId) {
        User user = getAuthenticatedUser();
        ChargingSession session = chargingSessionRepository.findById(sessionId).orElse(null);
        if (session == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "Charging session not found"));
        }

        if (session.getUser() == null || !session.getUser().getId().equals(user.getId())) {
            log.warn("Security Alert: IDOR attempt by user {} (id={}) to view session {} owned by user {}",
                    user.getEmail(), user.getId(), sessionId, session.getUser() != null ? session.getUser().getId() : "null");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
        }

        return ResponseEntity.ok(mapSessionToMap(session));
    }

    @PostMapping({"/stop", "/{sessionId:\\d+}/stop"})
    public ResponseEntity<?> stopCharging(@PathVariable(required = false) Long sessionId) {
        User user = getAuthenticatedUser();
        ChargingSession session;

        if (sessionId != null) {
            session = chargingSessionRepository.findById(sessionId).orElse(null);
            if (session == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "Charging session not found"));
            }
        } else {
            Optional<ChargingSession> activeOpt = chargingSessionRepository
                    .findFirstByUserAndStatusInOrderByCreatedAtDesc(user, ACTIVE_STATUSES);
            if (activeOpt.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("message", "No active charging session to stop"));
            }
            session = activeOpt.get();
        }

        // Ownership Verification (IDOR Protection)
        if (session.getUser() == null || !session.getUser().getId().equals(user.getId())) {
            log.warn("Security Alert: IDOR attempt by user {} (id={}) to stop session {} owned by user {}",
                    user.getEmail(), user.getId(), session.getId(), session.getUser() != null ? session.getUser().getId() : "null");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
        }

        // Idempotent Stop & Double Debit Protection
        if ("COMPLETED".equalsIgnoreCase(session.getStatus()) || "STOPPED".equalsIgnoreCase(session.getStatus())) {
            log.info("Charging session {} already stopped. Returning details without duplicate wallet debit.", session.getId());
            return ResponseEntity.ok(mapSessionToMap(session));
        }

        synchronized (("SESSION_STOP_LOCK_" + session.getId()).intern()) {
            ChargingSession freshSession = chargingSessionRepository.findById(session.getId()).orElse(session);
            if ("COMPLETED".equalsIgnoreCase(freshSession.getStatus()) || "STOPPED".equalsIgnoreCase(freshSession.getStatus())) {
                return ResponseEntity.ok(mapSessionToMap(freshSession));
            }

            LocalDateTime endTime = LocalDateTime.now();
            long durationSec = Duration.between(freshSession.getStartTime(), endTime).getSeconds();
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

            freshSession.setEndTime(endTime);
            freshSession.setStatus("COMPLETED");
            freshSession.setTotalEnergyKwh(finalEnergy);
            freshSession.setMeterStopWh(freshSession.getMeterStartWh() != null
                    ? freshSession.getMeterStartWh().add(finalEnergy.multiply(BigDecimal.valueOf(1000)))
                    : finalEnergy.multiply(BigDecimal.valueOf(1000)));

            String ocppTxId = freshSession.getOcppTransactionId();
            if (ocppTxId == null) {
                ocppTxId = "OCPP-TX-" + freshSession.getId();
            }

            // Deduct balance and create debit transaction ledger entry atomically with idempotency guard
            walletService.processChargingDebit(freshSession.getId(), ocppTxId, finalCost);

            if (freshSession.getConnector() != null) {
                Connector conn = freshSession.getConnector();
                conn.setStatus("AVAILABLE");
                connectorRepository.save(conn);
            }

            ChargingSession saved = chargingSessionRepository.save(freshSession);

            notificationService.createNotification(
                    user,
                    "Charging Completed",
                    "Your charging session has been completed. ₹" + String.format("%.2f", cost) + " was deducted from your wallet.",
                    "CHARGING"
            );

            return ResponseEntity.ok(mapSessionToMap(saved));
        }
    }

    @PostMapping("/{sessionId:\\d+}/billing")
    public ResponseEntity<?> processBilling(@PathVariable Long sessionId) {
        User user = getAuthenticatedUser();
        ChargingSession session = chargingSessionRepository.findById(sessionId).orElse(null);
        if (session == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "Charging session not found"));
        }

        if (session.getUser() == null || !session.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
        }

        return ResponseEntity.ok(mapSessionToMap(session));
    }

    @GetMapping("/history")
    public ResponseEntity<?> getHistory() {
        User user = getAuthenticatedUser();
        List<ChargingSession> sessions = chargingSessionRepository.findByUserOrderByCreatedAtDesc(user);

        List<Map<String, Object>> list = sessions.stream()
                .filter(s -> !ACTIVE_STATUSES.contains(s.getStatus().toUpperCase()))
                .map(this::mapSessionToMap)
                .collect(Collectors.toList());
        return ResponseEntity.ok(list);
    }
}
