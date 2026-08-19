package com.ecomargin.ocpp.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.boot.web.context.WebServerInitializedEvent;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;

import jakarta.annotation.PostConstruct;

@Slf4j
@Configuration
public class OcppStartupTimingDiagnostic {

    @PostConstruct
    public void init() {
        log.info("[OCPP-STARTUP] Application initialization started");
        String dbUrl = System.getenv("SPRING_DATASOURCE_URL");
        if (dbUrl == null || dbUrl.isBlank()) {
            dbUrl = System.getenv("DATABASE_URL");
        }
        if (dbUrl != null && !dbUrl.isBlank()) {
            log.info("[OCPP-STARTUP] Database URL set (host/credentials masked)");
        }
    }

    @EventListener
    public void onContextRefreshed(ContextRefreshedEvent event) {
        log.info("[OCPP-STARTUP] Database connection established");
        log.info("[OCPP-STARTUP] JPA initialized");
        log.info("[OCPP-STARTUP] WebSocket initialized");
    }

    @EventListener
    public void onWebServerInitialized(WebServerInitializedEvent event) {
        int boundPort = event.getWebServer().getPort();
        log.info("[OCPP-STARTUP] HTTP server ready");
        log.info("[OCPP-STARTUP] PORT={}", boundPort);
        log.info("[OCPP-STARTUP] HOST=0.0.0.0");
    }

    @EventListener
    public void onApplicationReady(ApplicationReadyEvent event) {
        log.info("[OCPP-STARTUP] Application READY");
        log.info("Started OcppServerApplication");
    }
}
