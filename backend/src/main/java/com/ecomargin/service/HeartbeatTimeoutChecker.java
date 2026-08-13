package com.ecomargin.service;

import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.websocket.telemetry.LiveTelemetryBroadcaster;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class HeartbeatTimeoutChecker {

    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;
    private final LiveTelemetryBroadcaster telemetryBroadcaster;

    @Scheduled(fixedRate = 30000)
    @Transactional
    public void checkHeartbeatTimeouts() {
        LocalDateTime threshold = LocalDateTime.now().minusSeconds(120);

        List<Charger> activeChargers = chargerRepository.findAll().stream()
                .filter(c -> !"UNAVAILABLE".equalsIgnoreCase(c.getStatus()) && !"OFFLINE".equalsIgnoreCase(c.getStatus()))
                .filter(c -> c.getUpdatedAt() != null && c.getUpdatedAt().isBefore(threshold))
                .toList();

        for (Charger charger : activeChargers) {
            log.warn("[HEARTBEAT-TIMEOUT] Charger {} timed out (last update {}). Marking UNAVAILABLE.",
                    charger.getOcppId(), charger.getUpdatedAt());

            charger.setStatus("UNAVAILABLE");
            chargerRepository.save(charger);

            List<Connector> connectors = connectorRepository.findByCharger(charger);
            for (Connector connector : connectors) {
                connector.setStatus("UNAVAILABLE");
                connectorRepository.save(connector);
            }

            Long vendorId = null;
            if (charger.getStation() != null && charger.getStation().getVendor() != null) {
                vendorId = charger.getStation().getVendor().getId();
            }

            Map<String, Object> eventData = Map.of(
                    "eventType", "CHARGER_OFFLINE",
                    "chargePointId", charger.getOcppId(),
                    "status", "UNAVAILABLE",
                    "lastUpdate", LocalDateTime.now().toString()
            );

            telemetryBroadcaster.broadcastEvent(null, vendorId, "CHARGER_OFFLINE", eventData);
        }
    }
}
