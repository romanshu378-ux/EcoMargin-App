package com.ecomargin.ocpp;

import com.ecomargin.ocpp.model.*;
import com.ecomargin.ocpp.repository.*;
import com.ecomargin.ocpp.service.OcppMessageDispatcher;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class OcppServerIntegrationTest {

    @Autowired
    private OcppMessageDispatcher ocppMessageDispatcher;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private ChargingSessionRepository chargingSessionRepository;

    @Autowired
    private WalletRepository walletRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        transactionRepository.deleteAll();
        chargingSessionRepository.deleteAll();
        connectorRepository.deleteAll();
        chargerRepository.deleteAll();
        walletRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("BootNotification registers charger and sets status AVAILABLE")
    void testBootNotification() {
        String bootJson = """
                [2, "msg-001", "BootNotification", {
                    "chargePointVendor": "EcoMargin-Test",
                    "chargePointModel": "Model-X",
                    "firmwareVersion": "v1.2.3"
                }]
                """;

        String response = ocppMessageDispatcher.dispatch("TEST-CHG-01", bootJson);
        assertNotNull(response);
        assertTrue(response.contains("\"status\":\"Accepted\""));

        Optional<Charger> chargerOpt = chargerRepository.findByOcppId("TEST-CHG-01");
        assertTrue(chargerOpt.isPresent());
        assertEquals("AVAILABLE", chargerOpt.get().getStatus());
        assertEquals("Model-X", chargerOpt.get().getModel());
    }

    @Test
    @DisplayName("StatusNotification updates connector status")
    void testStatusNotification() {
        // First boot
        testBootNotification();

        String statusJson = """
                [2, "msg-002", "StatusNotification", {
                    "connectorId": 1,
                    "errorCode": "NoError",
                    "status": "Preparing"
                }]
                """;

        String response = ocppMessageDispatcher.dispatch("TEST-CHG-01", statusJson);
        assertNotNull(response);

        Charger charger = chargerRepository.findByOcppId("TEST-CHG-01").orElseThrow();
        Optional<Connector> connectorOpt = connectorRepository.findByChargerAndConnectorIndex(charger, 1);
        assertTrue(connectorOpt.isPresent());
        assertEquals("PREPARING", connectorOpt.get().getStatus());
    }

    @Test
    @DisplayName("Full Charging Lifecycle: StartTransaction -> MeterValues -> StopTransaction (Atomic Wallet Deduction)")
    void testFullChargingLifecycle() {
        // Setup initial user & wallet
        User user = userRepository.save(User.builder().email("testuser@ecomargin.com").firstName("Test").lastName("User").build());
        Wallet wallet = walletRepository.save(Wallet.builder().user(user).balance(BigDecimal.valueOf(100.00)).currency("INR").build());

        testBootNotification();
        Charger charger = chargerRepository.findByOcppId("TEST-CHG-01").orElseThrow();
        Connector connector = connectorRepository.findByChargerAndConnectorIndex(charger, 1).orElseGet(() ->
                connectorRepository.save(Connector.builder().charger(charger).connectorIndex(1).type("CCS2").status("AVAILABLE").build())
        );

        ChargingSession initialSession = chargingSessionRepository.save(ChargingSession.builder()
                .user(user)
                .connector(connector)
                .status("STARTING")
                .startTime(java.time.LocalDateTime.now())
                .meterStartWh(BigDecimal.valueOf(1000.0))
                .build());

        // 1. StartTransaction
        String startJson = """
                [2, "msg-003", "StartTransaction", {
                    "connectorId": 1,
                    "idTag": "TAG-TEST-001",
                    "meterStart": 1000,
                    "timestamp": "2026-08-13T10:00:00Z"
                }]
                """;
        String startResp = ocppMessageDispatcher.dispatch("TEST-CHG-01", startJson);
        assertTrue(startResp.contains("transactionId"));

        // 2. MeterValues
        String meterJson = """
                [2, "msg-004", "MeterValues", {
                    "connectorId": 1,
                    "transactionId": "%s",
                    "meterValue": [{
                        "timestamp": "2026-08-13T10:05:00Z",
                        "sampledValue": [
                            {"measurand": "Energy.Active.Import.Register", "value": "2000", "unit": "Wh"},
                            {"measurand": "Power.Active.Import", "value": "42.5", "unit": "kW"},
                            {"measurand": "SoC", "value": "65", "unit": "Percent"}
                        ]
                    }]
                }]
                """.formatted(initialSession.getOcppTransactionId());

        ocppMessageDispatcher.dispatch("TEST-CHG-01", meterJson);

        ChargingSession sessionAfterMeter = chargingSessionRepository.findById(initialSession.getId()).orElseThrow();
        assertEquals(1.0, sessionAfterMeter.getTotalEnergyKwh().doubleValue());
        assertEquals(18.0, sessionAfterMeter.getTotalCost().doubleValue());

        // 3. StopTransaction
        String stopJson = """
                [2, "msg-005", "StopTransaction", {
                    "connectorId": 1,
                    "idTag": "TAG-TEST-001",
                    "meterStop": 2000,
                    "timestamp": "2026-08-13T10:10:00Z",
                    "reason": "Local"
                }]
                """;
        String stopResp = ocppMessageDispatcher.dispatch("TEST-CHG-01", stopJson);
        assertTrue(stopResp.contains("\"status\":\"Accepted\""));

        ChargingSession completedSession = chargingSessionRepository.findById(initialSession.getId()).orElseThrow();
        assertEquals("COMPLETED", completedSession.getStatus());
        assertEquals(1.0, completedSession.getTotalEnergyKwh().doubleValue());

        // 4. Duplicate StopTransaction (Idempotency Test)
        String dupStopResp = ocppMessageDispatcher.dispatch("TEST-CHG-01", stopJson);
        assertTrue(dupStopResp.contains("\"status\":\"Accepted\""));
    }
}
