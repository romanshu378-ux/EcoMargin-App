package com.ecomargin.controller;

import com.ecomargin.model.PrivacySettings;
import com.ecomargin.model.User;
import com.ecomargin.repository.PrivacySettingsRepository;
import com.ecomargin.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/privacy")
@RequiredArgsConstructor
public class PrivacySettingsController {

    private final PrivacySettingsRepository privacySettingsRepository;
    private final UserRepository userRepository;

    private User getAuthenticatedUser() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new RuntimeException("User not authenticated"));
    }

    @GetMapping
    public ResponseEntity<?> getPrivacySettings() {
        User user = getAuthenticatedUser();
        PrivacySettings settings = privacySettingsRepository.findByUser(user)
                .orElseGet(() -> {
                    log.info("[PRIVACY] No privacy settings found for user_id={}; creating default settings", user.getId());
                    PrivacySettings defaultSettings = PrivacySettings.builder()
                            .user(user)
                            .locationPermission(true)
                            .locationSharing(true)
                            .nearbyChargerPersonalization(true)
                            .pushNotifications(true)
                            .chargingActivityVisibility(true)
                            .usageAnalytics(true)
                            .personalizedRecommendations(true)
                            .build();
                    return privacySettingsRepository.save(defaultSettings);
                });
        return ResponseEntity.ok(mapSettingsToMap(settings));
    }

    @PutMapping
    public ResponseEntity<?> updatePrivacySettings(@RequestBody Map<String, Object> body) {
        User user = getAuthenticatedUser();
        PrivacySettings settings = privacySettingsRepository.findByUser(user)
                .orElseGet(() -> PrivacySettings.builder().user(user).build());

        if (body.containsKey("locationPermission")) settings.setLocationPermission(Boolean.parseBoolean(body.get("locationPermission").toString()));
        if (body.containsKey("locationSharing")) settings.setLocationSharing(Boolean.parseBoolean(body.get("locationSharing").toString()));
        if (body.containsKey("nearbyChargerPersonalization")) settings.setNearbyChargerPersonalization(Boolean.parseBoolean(body.get("nearbyChargerPersonalization").toString()));
        if (body.containsKey("pushNotifications")) settings.setPushNotifications(Boolean.parseBoolean(body.get("pushNotifications").toString()));
        if (body.containsKey("chargingActivityVisibility")) settings.setChargingActivityVisibility(Boolean.parseBoolean(body.get("chargingActivityVisibility").toString()));
        if (body.containsKey("usageAnalytics")) settings.setUsageAnalytics(Boolean.parseBoolean(body.get("usageAnalytics").toString()));
        if (body.containsKey("personalizedRecommendations")) settings.setPersonalizedRecommendations(Boolean.parseBoolean(body.get("personalizedRecommendations").toString()));

        PrivacySettings saved = privacySettingsRepository.save(settings);
        log.info("[PRIVACY] Updated privacy settings for user_id={}", user.getId());
        return ResponseEntity.ok(mapSettingsToMap(saved));
    }

    private Map<String, Object> mapSettingsToMap(PrivacySettings settings) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", settings.getId());
        map.put("locationPermission", settings.isLocationPermission());
        map.put("locationSharing", settings.isLocationSharing());
        map.put("nearbyChargerPersonalization", settings.isNearbyChargerPersonalization());
        map.put("pushNotifications", settings.isPushNotifications());
        map.put("chargingActivityVisibility", settings.isChargingActivityVisibility());
        map.put("usageAnalytics", settings.isUsageAnalytics());
        map.put("personalizedRecommendations", settings.isPersonalizedRecommendations());
        map.put("createdAt", settings.getCreatedAt());
        map.put("updatedAt", settings.getUpdatedAt());
        return map;
    }
}
