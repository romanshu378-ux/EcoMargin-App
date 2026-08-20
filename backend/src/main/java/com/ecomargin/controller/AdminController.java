package com.ecomargin.controller;

import com.ecomargin.controller.dto.StationRequest;
import com.ecomargin.controller.dto.UserSummaryDto;
import jakarta.validation.Valid;
import com.ecomargin.model.*;
import com.ecomargin.model.enums.RoleType;
import com.ecomargin.repository.*;
import com.ecomargin.service.AuditLogService;
import com.ecomargin.service.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import com.ecomargin.ocpp.websocket.OcppWebSocketHandler;
import com.ecomargin.ocpp.service.OcppRemoteOperationsService;
import com.ecomargin.service.NotificationService;
import org.springframework.http.HttpStatus;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final SettingRepository settingRepository;
    private final StationRepository stationRepository;
    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final ChargingSessionRepository chargingSessionRepository;
    private final AuditLogService auditLogService;
    private final WalletService walletService;
    private final OcppWebSocketHandler ocppWebSocketHandler;
    private final OcppRemoteOperationsService ocppRemoteOperationsService;
    private final NotificationService notificationService;

    // --- 1. SYSTEM SETTINGS CONTROL ---

    @GetMapping("/settings")
    public ResponseEntity<Map<String, String>> getAllSettings() {
        Map<String, String> settingsMap = new HashMap<>();
        settingRepository.findAll().forEach(s -> settingsMap.put(s.getKey(), s.getValue()));
        return ResponseEntity.ok(settingsMap);
    }

    @PutMapping("/settings/{key}")
    public ResponseEntity<Setting> updateSetting(
            @PathVariable String key,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetails principal
    ) {
        String newValue = body.get("value");
        if (newValue == null) {
            return ResponseEntity.badRequest().build();
        }

        Setting existing = settingRepository.findById(key).orElse(null);
        String previousValue = existing != null ? existing.getValue() : null;

        Setting setting = Setting.builder()
                .key(key)
                .value(newValue)
                .description(body.getOrDefault("description", existing != null ? existing.getDescription() : key))
                .build();

        Setting saved = settingRepository.save(setting);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "UPDATE_SETTING",
                "Setting",
                key,
                previousValue,
                newValue,
                "127.0.0.1",
                "Updated setting key: " + key
        );

        return ResponseEntity.ok(saved);
    }

    @PostMapping("/settings/batch")
    public ResponseEntity<Map<String, String>> updateSettingsBatch(
            @RequestBody Map<String, String> settingsMap,
            @AuthenticationPrincipal UserDetails principal
    ) {
        settingsMap.forEach((key, val) -> {
            Setting existing = settingRepository.findById(key).orElse(null);
            String prevVal = existing != null ? existing.getValue() : null;

            Setting setting = Setting.builder()
                    .key(key)
                    .value(val)
                    .description(existing != null ? existing.getDescription() : key)
                    .build();
            settingRepository.save(setting);

            auditLogService.logAction(
                    null,
                    principal != null ? principal.getUsername() : "ADMIN",
                    "UPDATE_SETTING_BATCH",
                    "Setting",
                    key,
                    prevVal,
                    val,
                    "127.0.0.1",
                    "Batch update setting key: " + key
            );
        });

        return ResponseEntity.ok(settingsMap);
    }

    // --- 2. STATIONS, CHARGERS & CONNECTORS ---

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @GetMapping("/stations")
    public ResponseEntity<List<Station>> getStations() {
        return ResponseEntity.ok(stationRepository.findAll());
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @GetMapping("/stations/detailed")
    public ResponseEntity<List<Map<String, Object>>> getDetailedStations(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status
    ) {
        List<Station> stations = stationRepository.findAll();
        List<Map<String, Object>> result = new ArrayList<>();

        for (Station station : stations) {
            if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) {
                String st = station.getStatus() != null ? station.getStatus().toUpperCase() : "ACTIVE";
                if ("DISABLED".equalsIgnoreCase(status) || "INACTIVE".equalsIgnoreCase(status)) {
                    if (!"INACTIVE".equals(st) && !"DISABLED".equals(st)) continue;
                } else if ("MAINTENANCE".equalsIgnoreCase(status) || "UNDER_MAINTENANCE".equalsIgnoreCase(status)) {
                    if (!"UNDER_MAINTENANCE".equals(st) && !"MAINTENANCE".equals(st)) continue;
                } else if (!st.equalsIgnoreCase(status)) {
                    continue;
                }
            }

            if (search != null && !search.isBlank()) {
                String q = search.toLowerCase();
                boolean match = (station.getName() != null && station.getName().toLowerCase().contains(q)) ||
                                (station.getId() != null && station.getId().toString().contains(q)) ||
                                (station.getCity() != null && station.getCity().toLowerCase().contains(q)) ||
                                (station.getAddress() != null && station.getAddress().toLowerCase().contains(q));
                if (!match) continue;
            }

            result.add(buildDetailedStationDto(station));
        }

        return ResponseEntity.ok(result);
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @GetMapping("/stations/{id}")
    public ResponseEntity<?> getDetailedStationById(@PathVariable Long id) {
        Station station = stationRepository.findById(id).orElse(null);
        if (station == null) return ResponseEntity.notFound().build();

        return ResponseEntity.ok(buildDetailedStationDto(station));
    }

    @org.springframework.transaction.annotation.Transactional
    @PostMapping("/stations")
    public ResponseEntity<?> createStation(
            @Valid @RequestBody StationRequest request,
            @AuthenticationPrincipal UserDetails principal
    ) {
        if (request.getLatitude() == null || request.getLatitude().compareTo(new BigDecimal("-90.0")) < 0 || request.getLatitude().compareTo(new BigDecimal("90.0")) > 0) {
            return ResponseEntity.badRequest().body(Map.of("code", "INVALID_COORDINATES", "message", "Latitude must be between -90 and 90"));
        }
        if (request.getLongitude() == null || request.getLongitude().compareTo(new BigDecimal("-180.0")) < 0 || request.getLongitude().compareTo(new BigDecimal("180.0")) > 0) {
            return ResponseEntity.badRequest().body(Map.of("code", "INVALID_COORDINATES", "message", "Longitude must be between -180 and 180"));
        }

        Station station = Station.builder()
                .name(request.getName())
                .address(request.getAddress())
                .city(request.getCity() != null ? request.getCity() : "Jaipur")
                .state(request.getState() != null ? request.getState() : "Rajasthan")
                .country(request.getCountry() != null ? request.getCountry() : "India")
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .status(request.getStatus() != null ? request.getStatus().toUpperCase() : "ACTIVE")
                .build();

        Station saved = stationRepository.save(station);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "STATION_CREATED",
                "Station",
                saved.getId().toString(),
                null,
                saved.getName(),
                "127.0.0.1",
                "Created station: " + saved.getName()
        );

        return ResponseEntity.ok(buildDetailedStationDto(saved));
    }

    @org.springframework.transaction.annotation.Transactional
    @PutMapping("/stations/{id}")
    public ResponseEntity<?> updateStation(
            @PathVariable Long id,
            @Valid @RequestBody StationRequest request,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Station station = stationRepository.findById(id).orElse(null);
        if (station == null) return ResponseEntity.notFound().build();

        if (request.getLatitude() == null || request.getLatitude().compareTo(new BigDecimal("-90.0")) < 0 || request.getLatitude().compareTo(new BigDecimal("90.0")) > 0) {
            return ResponseEntity.badRequest().body(Map.of("code", "INVALID_COORDINATES", "message", "Latitude must be between -90 and 90"));
        }
        if (request.getLongitude() == null || request.getLongitude().compareTo(new BigDecimal("-180.0")) < 0 || request.getLongitude().compareTo(new BigDecimal("180.0")) > 0) {
            return ResponseEntity.badRequest().body(Map.of("code", "INVALID_COORDINATES", "message", "Longitude must be between -180 and 180"));
        }

        String prevName = station.getName();
        station.setName(request.getName());
        station.setAddress(request.getAddress());
        if (request.getCity() != null) station.setCity(request.getCity());
        if (request.getState() != null) station.setState(request.getState());
        if (request.getCountry() != null) station.setCountry(request.getCountry());
        station.setLatitude(request.getLatitude());
        station.setLongitude(request.getLongitude());
        if (request.getStatus() != null) station.setStatus(request.getStatus().toUpperCase());

        Station updated = stationRepository.save(station);

        // Process Chargers & Connectors if present in request
        if (request.getChargers() != null) {
            List<Charger> existingChargers = chargerRepository.findByStation(updated);
            Set<Long> processedChargerIds = new HashSet<>();

            for (int i = 0; i < request.getChargers().size(); i++) {
                StationRequest.ChargerConfigRequest cReq = request.getChargers().get(i);
                Charger charger = null;

                if (cReq.getId() != null) {
                    charger = chargerRepository.findById(cReq.getId()).orElse(null);
                }

                if (charger == null) {
                    String ocppId = cReq.getOcppId() != null && !cReq.getOcppId().isBlank()
                            ? cReq.getOcppId().trim()
                            : ("STN-" + updated.getId() + "-CHG-" + (i + 1));
                    charger = Charger.builder()
                            .station(updated)
                            .ocppId(ocppId)
                            .brand(cReq.getBrand() != null ? cReq.getBrand() : "EcoMargin")
                            .model(cReq.getModel() != null ? cReq.getModel() : "EV-Fast-60")
                            .status(cReq.getStatus() != null && !cReq.getStatus().isBlank() ? cReq.getStatus().toUpperCase() : "AVAILABLE")
                            .build();
                } else {
                    if (cReq.getOcppId() != null && !cReq.getOcppId().isBlank()) {
                        charger.setOcppId(cReq.getOcppId().trim());
                    }
                    if (cReq.getBrand() != null) charger.setBrand(cReq.getBrand());
                    if (cReq.getModel() != null) charger.setModel(cReq.getModel());
                    if (cReq.getStatus() != null && !cReq.getStatus().isBlank()) {
                        charger.setStatus(cReq.getStatus().toUpperCase());
                    }
                }

                Charger savedCharger = chargerRepository.save(charger);
                processedChargerIds.add(savedCharger.getId());

                auditLogService.logAction(
                        null,
                        principal != null ? principal.getUsername() : "ADMIN",
                        "CHARGER_UPDATED",
                        "Charger",
                        savedCharger.getId().toString(),
                        null,
                        savedCharger.getOcppId(),
                        "127.0.0.1",
                        "Updated charger: " + savedCharger.getOcppId()
                );

                if (cReq.getConnectors() != null) {
                    List<Connector> existingConnectors = connectorRepository.findByCharger(savedCharger);
                    Set<Long> processedConnectorIds = new HashSet<>();

                    for (int j = 0; j < cReq.getConnectors().size(); j++) {
                        StationRequest.ConnectorConfigRequest connReq = cReq.getConnectors().get(j);
                        Connector connector = null;

                        if (connReq.getId() != null) {
                            connector = connectorRepository.findById(connReq.getId()).orElse(null);
                        }

                        BigDecimal kw = connReq.getMaxPowerKw() != null && connReq.getMaxPowerKw().compareTo(BigDecimal.ZERO) > 0
                                ? connReq.getMaxPowerKw() : new BigDecimal("60.00");
                        BigDecimal rate = connReq.getUnitRate() != null && connReq.getUnitRate().compareTo(BigDecimal.ZERO) > 0
                                ? connReq.getUnitRate() : new BigDecimal("18.00");

                        if (connector == null) {
                            connector = Connector.builder()
                                    .charger(savedCharger)
                                    .connectorIndex(j + 1)
                                    .type(connReq.getType() != null ? connReq.getType().toUpperCase() : "CCS2")
                                    .maxPowerKw(kw)
                                    .unitRate(rate)
                                    .status(connReq.getStatus() != null && !connReq.getStatus().isBlank() ? connReq.getStatus().toUpperCase() : "AVAILABLE")
                                    .build();
                        } else {
                            if (connReq.getType() != null) connector.setType(connReq.getType().toUpperCase());
                            connector.setMaxPowerKw(kw);
                            connector.setUnitRate(rate);
                            if (connReq.getStatus() != null && !connReq.getStatus().isBlank()) {
                                connector.setStatus(connReq.getStatus().toUpperCase());
                            }
                        }

                        Connector savedConn = connectorRepository.save(connector);
                        processedConnectorIds.add(savedConn.getId());

                        auditLogService.logAction(
                                null,
                                principal != null ? principal.getUsername() : "ADMIN",
                                "CONNECTOR_UPDATED",
                                "Connector",
                                savedConn.getId().toString(),
                                null,
                                savedConn.getType() + " (" + kw + " kW @ ₹" + rate + "/kWh)",
                                "127.0.0.1",
                                "Updated connector #" + savedConn.getConnectorIndex()
                        );
                    }

                    for (Connector conn : existingConnectors) {
                        if (!processedConnectorIds.contains(conn.getId())) {
                            List<ChargingSession> sessions = chargingSessionRepository.findByConnectorAndStatusIn(conn, List.of("CHARGING", "STARTING", "PREPARING"));
                            if (!sessions.isEmpty()) {
                                log.warn("[ADMIN-SAFETY] Cannot hard delete connector {} with active session. Soft-deactivating.", conn.getId());
                                conn.setStatus("UNAVAILABLE");
                                conn.setDeletedAt(LocalDateTime.now());
                                connectorRepository.save(conn);
                            } else {
                                try {
                                    connectorRepository.delete(conn);
                                } catch (Exception e) {
                                    log.warn("[ADMIN-SAFETY] Soft-deactivating connector {} due to historical data constraint: {}", conn.getId(), e.getMessage());
                                    conn.setStatus("UNAVAILABLE");
                                    conn.setDeletedAt(LocalDateTime.now());
                                    connectorRepository.save(conn);
                                }
                            }
                        }
                    }
                }
            }

            for (Charger chg : existingChargers) {
                if (!processedChargerIds.contains(chg.getId())) {
                    List<Connector> chgConns = connectorRepository.findByCharger(chg);
                    boolean hasActive = chgConns.stream().anyMatch(c -> !chargingSessionRepository.findByConnectorAndStatusIn(c, List.of("CHARGING", "STARTING", "PREPARING")).isEmpty());
                    if (hasActive) {
                        log.warn("[ADMIN-SAFETY] Cannot hard delete charger {} with active sessions. Soft-deactivating.", chg.getOcppId());
                        chg.setStatus("UNAVAILABLE");
                        chg.setDeletedAt(LocalDateTime.now());
                        for (Connector c : chgConns) {
                            c.setStatus("UNAVAILABLE");
                            c.setDeletedAt(LocalDateTime.now());
                            connectorRepository.save(c);
                        }
                        chargerRepository.save(chg);
                    } else {
                        try {
                            chargerRepository.delete(chg);
                        } catch (Exception e) {
                            log.warn("[ADMIN-SAFETY] Soft-deactivating charger {} due to historical constraint: {}", chg.getOcppId(), e.getMessage());
                            chg.setStatus("UNAVAILABLE");
                            chg.setDeletedAt(LocalDateTime.now());
                            for (Connector c : chgConns) {
                                c.setStatus("UNAVAILABLE");
                                c.setDeletedAt(LocalDateTime.now());
                                connectorRepository.save(c);
                            }
                            chargerRepository.save(chg);
                        }
                    }
                }
            }
        }

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "STATION_UPDATED",
                "Station",
                id.toString(),
                prevName,
                updated.getName(),
                "127.0.0.1",
                "Updated station: " + updated.getName()
        );

        return ResponseEntity.ok(buildDetailedStationDto(updated));
    }

    @org.springframework.transaction.annotation.Transactional
    @PutMapping("/stations/{id}/disable")
    public ResponseEntity<?> disableStation(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Station station = stationRepository.findById(id).orElse(null);
        if (station == null) return ResponseEntity.notFound().build();

        String prevStatus = station.getStatus();
        station.setStatus("INACTIVE");
        Station updated = stationRepository.save(station);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "STATION_DISABLED",
                "Station",
                id.toString(),
                prevStatus,
                "INACTIVE",
                "127.0.0.1",
                "Disabled station: " + station.getName()
        );

        return ResponseEntity.ok(buildDetailedStationDto(updated));
    }

    @org.springframework.transaction.annotation.Transactional
    @PutMapping("/stations/{id}/enable")
    public ResponseEntity<?> enableStation(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Station station = stationRepository.findById(id).orElse(null);
        if (station == null) return ResponseEntity.notFound().build();

        String prevStatus = station.getStatus();
        station.setStatus("ACTIVE");
        Station updated = stationRepository.save(station);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "STATION_ENABLED",
                "Station",
                id.toString(),
                prevStatus,
                "ACTIVE",
                "127.0.0.1",
                "Enabled station: " + station.getName()
        );

        return ResponseEntity.ok(buildDetailedStationDto(updated));
    }

    @org.springframework.transaction.annotation.Transactional
    @PutMapping("/stations/{id}/status")
    public ResponseEntity<?> changeStationStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Station station = stationRepository.findById(id).orElse(null);
        if (station == null) return ResponseEntity.notFound().build();

        String newStatus = body.get("status");
        if (newStatus == null || newStatus.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("code", "INVALID_STATUS", "message", "Status is required"));
        }

        String formattedStatus = newStatus.toUpperCase();
        if ("DISABLED".equals(formattedStatus)) formattedStatus = "INACTIVE";
        if ("MAINTENANCE".equals(formattedStatus)) formattedStatus = "UNDER_MAINTENANCE";

        String prevStatus = station.getStatus();
        station.setStatus(formattedStatus);
        Station updated = stationRepository.save(station);

        String auditAction = "STATION_STATUS_CHANGED";
        if ("INACTIVE".equals(formattedStatus)) {
            auditAction = "STATION_DISABLED";
        } else if ("ACTIVE".equals(formattedStatus)) {
            auditAction = "STATION_ENABLED";
        }

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                auditAction,
                "Station",
                id.toString(),
                prevStatus,
                formattedStatus,
                "127.0.0.1",
                "Changed status of station: " + station.getName() + " to " + formattedStatus
        );

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "STATION_STATUS_CHANGED",
                "Station",
                id.toString(),
                prevStatus,
                formattedStatus,
                "127.0.0.1",
                "Status changed from " + prevStatus + " to " + formattedStatus
        );

        return ResponseEntity.ok(buildDetailedStationDto(updated));
    }

    @org.springframework.transaction.annotation.Transactional
    @DeleteMapping("/stations/{id}")
    public ResponseEntity<?> deleteStation(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Station station = stationRepository.findById(id).orElse(null);
        if (station == null) return ResponseEntity.notFound().build();

        List<Charger> chargers = chargerRepository.findByStation(station);
        if (chargers != null && !chargers.isEmpty()) {
            station.setStatus("INACTIVE");
            stationRepository.save(station);
            auditLogService.logAction(
                    null,
                    principal != null ? principal.getUsername() : "ADMIN",
                    "STATION_DISABLE_FAILED",
                    "Station",
                    id.toString(),
                    station.getName(),
                    "INACTIVE",
                    "127.0.0.1",
                    "Station has chargers; soft-disabled instead of hard delete"
            );
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                    "code", "STATION_HAS_CHARGERS",
                    "message", "Cannot hard delete station with associated chargers/history. Station has been deactivated."
            ));
        }

        stationRepository.delete(station);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "STATION_DELETED",
                "Station",
                id.toString(),
                station.getName(),
                null,
                "127.0.0.1",
                "Deleted station id: " + id
        );

        return ResponseEntity.ok(Map.of("message", "Station deleted successfully"));
    }

    private Map<String, Object> buildDetailedStationDto(Station station) {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", station.getId());
        dto.put("name", station.getName());
        dto.put("address", station.getAddress() != null ? station.getAddress() : "");
        dto.put("city", station.getCity() != null ? station.getCity() : "Jaipur");
        dto.put("state", station.getState() != null ? station.getState() : "Rajasthan");
        dto.put("country", station.getCountry() != null ? station.getCountry() : "India");
        dto.put("latitude", station.getLatitude());
        dto.put("longitude", station.getLongitude());
        dto.put("status", station.getStatus() != null ? station.getStatus() : "ACTIVE");
        dto.put("createdAt", station.getCreatedAt() != null ? station.getCreatedAt().toString() : LocalDateTime.now().toString());
        dto.put("updatedAt", station.getUpdatedAt() != null ? station.getUpdatedAt().toString() : LocalDateTime.now().toString());

        List<Charger> chargers = chargerRepository.findByStation(station);
        int totalChargers = chargers.size();
        int onlineChargers = 0;
        int offlineChargers = 0;
        int totalConnectors = 0;
        int availableConnectors = 0;
        int chargingConnectors = 0;
        int faultedConnectors = 0;

        List<Map<String, Object>> chargerDtos = new ArrayList<>();
        for (Charger charger : chargers) {
            Map<String, Object> cDto = new HashMap<>();
            cDto.put("id", charger.getId());
            cDto.put("ocppId", charger.getOcppId());
            cDto.put("brand", charger.getBrand() != null ? charger.getBrand() : "EcoMargin");
            cDto.put("model", charger.getModel() != null ? charger.getModel() : "EV-Fast-100");
            cDto.put("status", charger.getStatus() != null ? charger.getStatus() : "AVAILABLE");
            boolean online = ocppWebSocketHandler.isChargerConnected(charger.getOcppId());
            cDto.put("online", online);
            if (online) onlineChargers++; else offlineChargers++;

            List<Connector> connectors = connectorRepository.findByCharger(charger);
            cDto.put("connectorCount", connectors.size());
            totalConnectors += connectors.size();

            List<Map<String, Object>> connDtos = new ArrayList<>();
            for (Connector conn : connectors) {
                Map<String, Object> connMap = new HashMap<>();
                connMap.put("id", conn.getId());
                connMap.put("connectorId", conn.getConnectorIndex() != null ? conn.getConnectorIndex() : conn.getId());
                connMap.put("type", conn.getType() != null ? conn.getType() : "CCS2");
                connMap.put("maxPowerKw", conn.getMaxPowerKw() != null ? conn.getMaxPowerKw() : new BigDecimal("60.0"));
                connMap.put("unitRate", conn.getUnitRate() != null ? conn.getUnitRate() : new BigDecimal("18.00"));
                String cStat = conn.getStatus() != null ? conn.getStatus() : "AVAILABLE";
                connMap.put("status", cStat);

                if ("AVAILABLE".equalsIgnoreCase(cStat)) availableConnectors++;
                else if ("CHARGING".equalsIgnoreCase(cStat) || "OCCUPIED".equalsIgnoreCase(cStat)) chargingConnectors++;
                else if ("FAULTED".equalsIgnoreCase(cStat)) faultedConnectors++;

                List<ChargingSession> activeSessions = chargingSessionRepository.findByConnectorAndStatusIn(conn, List.of("CHARGING", "STARTING", "PREPARING"));
                if (!activeSessions.isEmpty()) {
                    ChargingSession active = activeSessions.get(0);
                    Map<String, Object> sessMap = new HashMap<>();
                    sessMap.put("sessionId", active.getId());
                    sessMap.put("userEmail", active.getUser() != null ? active.getUser().getEmail() : "customer@ecomargin.com");
                    sessMap.put("energyKwh", active.getTotalEnergyKwh());
                    sessMap.put("startedAt", active.getStartTime() != null ? active.getStartTime().toString() : null);
                    connMap.put("activeSession", sessMap);
                } else {
                    connMap.put("activeSession", null);
                }
                connDtos.add(connMap);
            }
            cDto.put("connectors", connDtos);
            chargerDtos.add(cDto);
        }

        dto.put("totalChargers", totalChargers);
        dto.put("onlineChargers", onlineChargers);
        dto.put("offlineChargers", offlineChargers);
        dto.put("totalConnectors", totalConnectors);
        dto.put("availableConnectors", availableConnectors);
        dto.put("chargingConnectors", chargingConnectors);
        dto.put("faultedConnectors", faultedConnectors);
        dto.put("chargers", chargerDtos);

        return dto;
    }

    @org.springframework.transaction.annotation.Transactional
    @PostMapping("/chargers")
    public ResponseEntity<Charger> createCharger(
            @RequestBody Charger charger,
            @AuthenticationPrincipal UserDetails principal
    ) {
        if (charger.getStatus() == null || charger.getStatus().isBlank()) {
            charger.setStatus("AVAILABLE");
        }
        Charger saved = chargerRepository.save(charger);

        List<Connector> existingConnectors = connectorRepository.findByCharger(saved);
        if (existingConnectors == null || existingConnectors.isEmpty()) {
            Connector defaultConnector = Connector.builder()
                    .charger(saved)
                    .connectorIndex(1)
                    .type("CCS2")
                    .maxPowerKw(new BigDecimal("60.00"))
                    .status("AVAILABLE")
                    .build();
            connectorRepository.save(defaultConnector);
        }

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "CREATE_CHARGER",
                "Charger",
                saved.getId() != null ? saved.getId().toString() : saved.getOcppId(),
                null,
                saved.getOcppId(),
                "127.0.0.1",
                "Created charger: " + saved.getOcppId()
        );

        return ResponseEntity.ok(saved);
    }

    @PutMapping("/chargers/{id}/status")
    public ResponseEntity<Charger> updateChargerStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Charger charger = chargerRepository.findById(id).orElse(null);
        if (charger == null) return ResponseEntity.notFound().build();

        String prevStatus = charger.getStatus();
        String newStatus = body.get("status");
        if (newStatus == null) return ResponseEntity.badRequest().build();

        charger.setStatus(newStatus);
        Charger updated = chargerRepository.save(charger);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "UPDATE_CHARGER_STATUS",
                "Charger",
                id.toString(),
                prevStatus,
                newStatus,
                "127.0.0.1",
                "Changed status for charger " + charger.getOcppId() + " to " + newStatus
        );

        return ResponseEntity.ok(updated);
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @GetMapping("/dashboard")
    public ResponseEntity<Map<String, Object>> getAdminDashboardStats() {
        long totalStations = stationRepository.count();
        List<Charger> chargers = chargerRepository.findAll();
        long totalChargers = chargers.size();

        long onlineChargers = chargers.stream()
                .filter(c -> c.getOcppId() != null && ocppWebSocketHandler.isChargerConnected(c.getOcppId()))
                .count();
        long offlineChargers = totalChargers - onlineChargers;

        long chargingChargers = chargers.stream()
                .filter(c -> "CHARGING".equalsIgnoreCase(c.getStatus()))
                .count();

        long faultedChargers = chargers.stream()
                .filter(c -> "FAULTED".equalsIgnoreCase(c.getStatus()) || "ERROR".equalsIgnoreCase(c.getStatus()))
                .count();

        long availableConnectors = connectorRepository.findAll().stream()
                .filter(conn -> "AVAILABLE".equalsIgnoreCase(conn.getStatus()))
                .count();

        long activeSessions = chargingSessionRepository.findByStatus("CHARGING").size();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalStations", totalStations);
        stats.put("totalChargers", totalChargers);
        stats.put("onlineChargers", onlineChargers);
        stats.put("offlineChargers", offlineChargers);
        stats.put("chargingChargers", chargingChargers);
        stats.put("faultedChargers", faultedChargers);
        stats.put("availableConnectors", availableConnectors);
        stats.put("activeSessions", activeSessions);

        return ResponseEntity.ok(stats);
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @GetMapping("/chargers/detailed")
    public ResponseEntity<List<Map<String, Object>>> getDetailedChargers() {
        List<Charger> chargers = chargerRepository.findAll();
        List<Map<String, Object>> result = new ArrayList<>();

        for (Charger charger : chargers) {
            Map<String, Object> dto = new HashMap<>();
            dto.put("id", charger.getId());
            dto.put("ocppId", charger.getOcppId());
            dto.put("brand", charger.getBrand() != null ? charger.getBrand() : "EcoMargin");
            dto.put("model", charger.getModel() != null ? charger.getModel() : "FastCharger");

            List<Connector> connectors = connectorRepository.findByCharger(charger);
            double totalPowerKw = connectors.stream()
                    .mapToDouble(c -> c.getMaxPowerKw() != null ? c.getMaxPowerKw().doubleValue() : 50.0)
                    .max().orElse(50.0);

            dto.put("powerKw", totalPowerKw);
            dto.put("status", charger.getStatus() != null ? charger.getStatus() : "AVAILABLE");

            boolean isOnline = charger.getOcppId() != null && ocppWebSocketHandler.isChargerConnected(charger.getOcppId());
            dto.put("online", isOnline);
            dto.put("lastSeen", charger.getUpdatedAt() != null ? charger.getUpdatedAt().toString() : LocalDateTime.now().toString());

            if (charger.getStation() != null) {
                dto.put("stationId", charger.getStation().getId());
                dto.put("stationName", charger.getStation().getName());
            } else {
                dto.put("stationId", null);
                dto.put("stationName", "Unassigned Station");
            }

            List<Map<String, Object>> connectorDtos = new ArrayList<>();
            for (Connector conn : connectors) {
                Map<String, Object> connMap = new HashMap<>();
                connMap.put("id", conn.getId());
                connMap.put("connectorId", conn.getConnectorIndex() != null ? conn.getConnectorIndex() : conn.getId().intValue());
                connMap.put("type", conn.getType());
                connMap.put("maxPowerKw", conn.getMaxPowerKw() != null ? conn.getMaxPowerKw().doubleValue() : 50.0);
                connMap.put("status", conn.getStatus() != null ? conn.getStatus() : "AVAILABLE");

                List<ChargingSession> activeSessions = chargingSessionRepository.findByConnectorAndStatusIn(conn, List.of("CHARGING", "STARTED"));
                if (!activeSessions.isEmpty()) {
                    ChargingSession active = activeSessions.get(0);
                    Map<String, Object> activeSessionMap = new HashMap<>();
                    activeSessionMap.put("sessionId", active.getId());
                    activeSessionMap.put("userEmail", active.getUser() != null ? active.getUser().getEmail() : "anonymous");
                    activeSessionMap.put("energyKwh", active.getTotalEnergyKwh() != null ? active.getTotalEnergyKwh().doubleValue() : 0.0);
                    activeSessionMap.put("startedAt", active.getStartTime() != null ? active.getStartTime().toString() : null);
                    connMap.put("activeSession", activeSessionMap);
                } else {
                    connMap.put("activeSession", null);
                }
                connectorDtos.add(connMap);
            }
            dto.put("connectors", connectorDtos);
            result.add(dto);
        }
        return ResponseEntity.ok(result);
    }

    @org.springframework.transaction.annotation.Transactional
    @PutMapping("/chargers/{id}/disable")
    public ResponseEntity<?> disableCharger(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Charger charger = chargerRepository.findById(id).orElse(null);
        if (charger == null) return ResponseEntity.notFound().build();

        String prevStatus = charger.getStatus();
        charger.setStatus("DISABLED");
        Charger updated = chargerRepository.save(charger);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "CHARGER_DISABLED",
                "Charger",
                id.toString(),
                prevStatus,
                "DISABLED",
                "127.0.0.1",
                "Admin disabled charger: " + charger.getOcppId()
        );

        Map<String, Object> resp = new HashMap<>();
        resp.put("id", updated.getId());
        resp.put("ocppId", updated.getOcppId());
        resp.put("status", updated.getStatus());
        return ResponseEntity.ok(resp);
    }

    @org.springframework.transaction.annotation.Transactional
    @PutMapping("/chargers/{id}/enable")
    public ResponseEntity<?> enableCharger(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Charger charger = chargerRepository.findById(id).orElse(null);
        if (charger == null) return ResponseEntity.notFound().build();

        String prevStatus = charger.getStatus();
        charger.setStatus("AVAILABLE");
        Charger updated = chargerRepository.save(charger);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "CHARGER_ENABLED",
                "Charger",
                id.toString(),
                prevStatus,
                "AVAILABLE",
                "127.0.0.1",
                "Admin enabled charger: " + charger.getOcppId()
        );

        Map<String, Object> resp = new HashMap<>();
        resp.put("id", updated.getId());
        resp.put("ocppId", updated.getOcppId());
        resp.put("status", updated.getStatus());
        return ResponseEntity.ok(resp);
    }

    @org.springframework.transaction.annotation.Transactional
    @DeleteMapping("/chargers/{id}")
    public ResponseEntity<?> deleteCharger(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Charger charger = chargerRepository.findById(id).orElse(null);
        if (charger == null) return ResponseEntity.notFound().build();

        List<Connector> connectors = connectorRepository.findByCharger(charger);
        LocalDateTime now = LocalDateTime.now();

        charger.setStatus("DELETED");
        charger.setDeletedAt(now);

        for (Connector conn : connectors) {
            conn.setStatus("DELETED");
            conn.setDeletedAt(now);
            connectorRepository.save(conn);
        }

        Charger saved = chargerRepository.save(charger);

        log.info("[ADMIN-DELETE-CHARGER] stationId={}, chargerId={}, ocppId={}, status=DELETED, deletedAt={}",
                charger.getStation() != null ? charger.getStation().getId() : null,
                charger.getId(), charger.getOcppId(), now);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "CHARGER_DELETED",
                "Charger",
                id.toString(),
                saved.getOcppId(),
                "DELETED",
                "127.0.0.1",
                "Deleted charger " + saved.getOcppId()
        );

        return ResponseEntity.ok(Map.of("message", "Charger deleted successfully", "id", id));
    }

    @org.springframework.transaction.annotation.Transactional
    @PostMapping("/sessions/{sessionId}/force-stop")
    public ResponseEntity<?> forceStopSession(
            @PathVariable Long sessionId,
            @RequestBody(required = false) Map<String, String> body,
            @AuthenticationPrincipal UserDetails principal
    ) {
        String adminUsername = principal != null ? principal.getUsername() : "ADMIN";
        String reason = body != null ? body.getOrDefault("reason", "Admin Force Stop") : "Admin Force Stop";

        ChargingSession session = chargingSessionRepository.findById(sessionId).orElse(null);
        if (session == null) {
            auditLogService.logAction(null, adminUsername, "FORCE_STOP_FAILED", "ChargingSession", sessionId.toString(), null, null, "127.0.0.1", "Session not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "code", "SESSION_NOT_FOUND",
                    "message", "Charging session not found."
            ));
        }

        if (!"CHARGING".equalsIgnoreCase(session.getStatus()) && !"STARTED".equalsIgnoreCase(session.getStatus())) {
            auditLogService.logAction(session.getUser() != null ? session.getUser().getId() : null, adminUsername, "FORCE_STOP_FAILED", "ChargingSession", sessionId.toString(), session.getStatus(), null, "127.0.0.1", "Session is already stopped");
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                    "code", "SESSION_ALREADY_STOPPED",
                    "message", "Charging session is already in status " + session.getStatus()
            ));
        }

        auditLogService.logAction(session.getUser() != null ? session.getUser().getId() : null, adminUsername, "FORCE_STOP_REQUESTED", "ChargingSession", sessionId.toString(), session.getStatus(), "STOPPING", "127.0.0.1", "Force stop requested by admin: " + reason);

        // Send OCPP RemoteStopTransaction if charger is online
        if (session.getConnector() != null && session.getConnector().getCharger() != null) {
            Charger charger = session.getConnector().getCharger();
            if (charger.getOcppId() != null && ocppWebSocketHandler.isChargerConnected(charger.getOcppId())) {
                try {
                    int txIdHash = session.getId().intValue();
                    ocppRemoteOperationsService.sendRemoteStop(charger.getOcppId(), txIdHash);
                } catch (Exception e) {
                    log.warn("Failed to send OCPP RemoteStop command to charger {}: {}", charger.getOcppId(), e.getMessage());
                }
            }
        }

        // Process stopping, calculation & wallet debit safely without double debit
        LocalDateTime now = LocalDateTime.now();
        session.setEndTime(now);
        session.setStatus("COMPLETED");

        long durationSec = session.getStartTime() != null ? java.time.Duration.between(session.getStartTime(), now).getSeconds() : 0;
        double energyKwh = session.getTotalEnergyKwh() != null ? session.getTotalEnergyKwh().doubleValue() : (durationSec * 0.005);
        double cost = energyKwh * 12.0;

        session.setTotalEnergyKwh(BigDecimal.valueOf(energyKwh).setScale(3, RoundingMode.HALF_UP));
        session.setTotalCost(BigDecimal.valueOf(cost).setScale(2, RoundingMode.HALF_UP));
        chargingSessionRepository.save(session);

        if (session.getConnector() != null) {
            Connector conn = session.getConnector();
            conn.setStatus("AVAILABLE");
            connectorRepository.save(conn);
        }

        // Debit wallet cleanly
        if (session.getUser() != null && cost > 0) {
            String ocppTxId = session.getOcppTransactionId() != null ? session.getOcppTransactionId() : ("FORCE-STOP-" + session.getId());
            walletService.processChargingDebit(session.getId(), ocppTxId, BigDecimal.valueOf(cost));
            notificationService.createNotification(
                    session.getUser(),
                    "Charging Force Stopped",
                    "Your charging session #" + session.getId() + " was stopped by system admin. Total cost: ₹" + String.format(java.util.Locale.US, "%.2f", cost),
                    "CHARGING"
            );
        }

        auditLogService.logAction(
                session.getUser() != null ? session.getUser().getId() : null,
                adminUsername,
                "FORCE_STOP_COMPLETED",
                "ChargingSession",
                sessionId.toString(),
                "CHARGING",
                "COMPLETED",
                "127.0.0.1",
                "Force stop completed for session #" + session.getId() + ". Total cost: ₹" + cost
        );

        Map<String, Object> res = new HashMap<>();
        res.put("sessionId", session.getId());
        res.put("status", "COMPLETED");
        res.put("durationSeconds", durationSec);
        res.put("totalEnergyKwh", energyKwh);
        res.put("totalCost", cost);
        res.put("message", "Session successfully force-stopped by admin.");

        return ResponseEntity.ok(res);
    }

    // --- 3. USER MANAGEMENT & RBAC ---

    @GetMapping("/users")
    public ResponseEntity<List<UserSummaryDto>> getUsers() {
        List<UserSummaryDto> dtos = userRepository.findAll().stream()
                .map(UserSummaryDto::fromEntity)
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @PutMapping("/users/{id}/status")
    public ResponseEntity<UserSummaryDto> updateUserStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> body,
            @AuthenticationPrincipal UserDetails principal
    ) {
        User user = userRepository.findById(id).orElse(null);
        if (user == null) return ResponseEntity.notFound().build();

        Boolean isLocked = body.get("isLocked");
        Boolean isVerified = body.get("isVerified");

        String prevVal = "locked=" + (!user.isAccountNonLocked()) + ", verified=" + user.isVerified();

        if (isLocked != null) user.setAccountNonLocked(!isLocked);
        if (isVerified != null) user.setVerified(isVerified);

        User saved = userRepository.save(user);

        String newVal = "locked=" + (!saved.isAccountNonLocked()) + ", verified=" + saved.isVerified();

        auditLogService.logAction(
                saved.getId(),
                principal != null ? principal.getUsername() : "ADMIN",
                "UPDATE_USER_STATUS",
                "User",
                id.toString(),
                prevVal,
                newVal,
                "127.0.0.1",
                "Updated user account status for " + saved.getEmail()
        );

        return ResponseEntity.ok(UserSummaryDto.fromEntity(saved));
    }

    @PutMapping("/users/{id}/role")
    public ResponseEntity<UserSummaryDto> updateUserRole(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetails principal
    ) {
        User user = userRepository.findById(id).orElse(null);
        if (user == null) return ResponseEntity.notFound().build();

        String roleStr = body.get("role");
        if (roleStr == null) return ResponseEntity.badRequest().build();

        try {
            RoleType roleType = RoleType.valueOf(roleStr.startsWith("ROLE_") ? roleStr : "ROLE_" + roleStr.toUpperCase());
            Role role = roleRepository.findByName(roleType).orElse(null);
            if (role == null) {
                role = roleRepository.save(Role.builder().name(roleType).permissions(Collections.emptySet()).build());
            }

            String prevRole = user.getRoles().stream().map(r -> r.getName().name()).findFirst().orElse("NONE");
            user.setRoles(Collections.singleton(role));
            User saved = userRepository.save(user);

            auditLogService.logAction(
                    saved.getId(),
                    principal != null ? principal.getUsername() : "ADMIN",
                    "UPDATE_USER_ROLE",
                    "User",
                    id.toString(),
                    prevRole,
                    roleType.name(),
                    "127.0.0.1",
                    "Assigned role " + roleType.name() + " to user " + saved.getEmail()
            );

            return ResponseEntity.ok(UserSummaryDto.fromEntity(saved));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/users/{id}/wallet/credit")
    public ResponseEntity<Map<String, Object>> creditUserWallet(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal UserDetails principal
    ) {
        User user = userRepository.findById(id).orElse(null);
        if (user == null) return ResponseEntity.notFound().build();

        Object amountObj = body.get("amount");
        if (amountObj == null) return ResponseEntity.badRequest().build();

        BigDecimal amount = new BigDecimal(amountObj.toString());
        String reason = body.getOrDefault("reason", "Admin manual wallet credit").toString();

        Wallet wallet = walletRepository.findByUserId(user.getId())
                .orElseGet(() -> walletRepository.save(Wallet.builder().user(user).balance(BigDecimal.ZERO).currency("INR").build()));

        BigDecimal prevBalance = wallet.getBalance();
        BigDecimal newBalance = prevBalance.add(amount);

        wallet.setBalance(newBalance);
        walletRepository.save(wallet);

        Transaction txn = Transaction.builder()
                .wallet(wallet)
                .amount(amount)
                .type("CREDIT")
                .status("SUCCESS")
                .referenceId("ADMIN-TOPUP-" + System.currentTimeMillis())
                .referenceType("ADMIN_ADJUSTMENT")
                .balanceBefore(prevBalance)
                .balanceAfter(newBalance)
                .build();
        transactionRepository.save(txn);

        auditLogService.logAction(
                user.getId(),
                principal != null ? principal.getUsername() : "ADMIN",
                "ADMIN_WALLET_CREDIT",
                "Wallet",
                wallet.getId() != null ? wallet.getId().toString() : user.getId().toString(),
                prevBalance.toString(),
                newBalance.toString(),
                "127.0.0.1",
                "Admin credited ₹" + amount + " to user " + user.getEmail() + ": " + reason
        );

        return ResponseEntity.ok(Map.of(
                "userId", user.getId(),
                "creditedAmount", amount,
                "previousBalance", prevBalance,
                "newBalance", newBalance,
                "status", "SUCCESS"
        ));
    }

    // --- 4. CHARGING SESSIONS ---

    @GetMapping("/sessions/active")
    public ResponseEntity<List<ChargingSession>> getActiveSessions() {
        return ResponseEntity.ok(chargingSessionRepository.findByStatus("CHARGING"));
    }

    @GetMapping("/sessions/history")
    public ResponseEntity<List<ChargingSession>> getSessionHistory() {
        return ResponseEntity.ok(chargingSessionRepository.findAll());
    }

    // --- 5. AUDIT LOGS & TRANSACTIONS ---

    @GetMapping("/audit-logs")
    public ResponseEntity<List<AuditLog>> getAuditLogs() {
        return ResponseEntity.ok(auditLogService.getRecentAuditLogs());
    }

    @GetMapping("/transactions")
    public ResponseEntity<List<Transaction>> getTransactions() {
        return ResponseEntity.ok(transactionRepository.findAll());
    }
}
