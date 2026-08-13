package com.ecomargin.controller;

import com.ecomargin.controller.dto.UserSummaryDto;
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

import java.math.BigDecimal;
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

    @GetMapping("/stations")
    public ResponseEntity<List<Station>> getStations() {
        return ResponseEntity.ok(stationRepository.findAll());
    }

    @PostMapping("/stations")
    public ResponseEntity<Station> createStation(
            @RequestBody Station station,
            @AuthenticationPrincipal UserDetails principal
    ) {
        if (station.getStatus() == null) station.setStatus("ACTIVE");
        Station saved = stationRepository.save(station);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "CREATE_STATION",
                "Station",
                saved.getId() != null ? saved.getId().toString() : saved.getName(),
                null,
                saved.getName(),
                "127.0.0.1",
                "Created new station: " + saved.getName()
        );

        return ResponseEntity.ok(saved);
    }

    @PutMapping("/stations/{id}")
    public ResponseEntity<Station> updateStation(
            @PathVariable Long id,
            @RequestBody Station stationDetails,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Station station = stationRepository.findById(id).orElse(null);
        if (station == null) return ResponseEntity.notFound().build();

        String prevName = station.getName();
        station.setName(stationDetails.getName());
        station.setAddress(stationDetails.getAddress());
        station.setLatitude(stationDetails.getLatitude());
        station.setLongitude(stationDetails.getLongitude());
        if (stationDetails.getStatus() != null) station.setStatus(stationDetails.getStatus());

        Station updated = stationRepository.save(station);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "UPDATE_STATION",
                "Station",
                id.toString(),
                prevName,
                updated.getName(),
                "127.0.0.1",
                "Updated station id: " + id
        );

        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/stations/{id}")
    public ResponseEntity<Void> deleteStation(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails principal
    ) {
        Station station = stationRepository.findById(id).orElse(null);
        if (station == null) return ResponseEntity.notFound().build();

        stationRepository.delete(station);

        auditLogService.logAction(
                null,
                principal != null ? principal.getUsername() : "ADMIN",
                "DELETE_STATION",
                "Station",
                id.toString(),
                station.getName(),
                null,
                "127.0.0.1",
                "Deleted station id: " + id
        );

        return ResponseEntity.ok().build();
    }

    @PostMapping("/chargers")
    public ResponseEntity<Charger> createCharger(
            @RequestBody Charger charger,
            @AuthenticationPrincipal UserDetails principal
    ) {
        if (charger.getStatus() == null) charger.setStatus("AVAILABLE");
        Charger saved = chargerRepository.save(charger);

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
