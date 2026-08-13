package com.ecomargin.controller;

import com.ecomargin.model.Setting;
import com.ecomargin.repository.SettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class AppConfigController {

    private final SettingRepository settingRepository;

    @GetMapping("/app/config")
    public ResponseEntity<Map<String, Object>> getAppConfig() {
        Map<String, Object> configMap = new HashMap<>();
        settingRepository.findAll().forEach(setting -> {
            configMap.put(setting.getKey(), setting.getValue());
        });
        return ResponseEntity.ok(configMap);
    }

    @GetMapping(value = "/faqs", produces = org.springframework.http.MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> getFaqs() {
        Setting faqSetting = settingRepository.findById("faqs").orElse(null);
        String faqsJson = faqSetting != null ? faqSetting.getValue() : "[]";
        return ResponseEntity.ok().contentType(org.springframework.http.MediaType.APPLICATION_JSON).body(faqsJson);
    }

    @GetMapping(value = "/offers", produces = org.springframework.http.MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> getOffers() {
        Setting offerSetting = settingRepository.findById("offers_banners").orElse(null);
        String offersJson = offerSetting != null ? offerSetting.getValue() : "[]";
        return ResponseEntity.ok().contentType(org.springframework.http.MediaType.APPLICATION_JSON).body(offersJson);
    }

    @GetMapping(value = "/support", produces = org.springframework.http.MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> getSupportInfo() {
        Setting supportSetting = settingRepository.findById("support_info").orElse(null);
        String supportJson = supportSetting != null ? supportSetting.getValue() : "{}";
        return ResponseEntity.ok().contentType(org.springframework.http.MediaType.APPLICATION_JSON).body(supportJson);
    }
}
