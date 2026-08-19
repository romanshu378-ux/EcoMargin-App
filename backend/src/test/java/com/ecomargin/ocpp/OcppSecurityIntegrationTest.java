package com.ecomargin.ocpp;

import com.ecomargin.model.*;
import com.ecomargin.ocpp.handler.*;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppMessageParser;
import com.ecomargin.ocpp.websocket.OcppWebSocketHandler;
import com.ecomargin.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.WebSocketSession;

import java.math.BigDecimal;
import java.net.URI;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OcppSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private StationRepository stationRepository;

    @Autowired
    private ChargingSessionRepository chargingSessionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private OcppWebSocketHandler ocppWebSocketHandler;

    @Autowired
    private BootNotificationHandler bootNotificationHandler;

    @Autowired
    private HeartbeatHandler heartbeatHandler;

    @Autowired
    private StatusNotificationHandler statusNotificationHandler;

    @Autowired
    private MeterValuesHandler meterValuesHandler;

    @Autowired
    private StartTransactionHandler startTransactionHandler;

    @Autowired
    private StopTransactionHandler stopTransactionHandler;

    @Autowired
    private OcppMessageParser messageParser;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private Station testStation;
    private Charger knownCharger;
    private Charger disabledCharger;
    private Charger otherCharger;
    private Connector connector1;
    private Connector connector2;
    private Connector otherConnector;

    @BeforeEach
    void setUp() {
        chargingSessionRepository.deleteAll();
        connectorRepository.deleteAll();
        chargerRepository.deleteAll();

        testStation = stationRepository.findAll().stream().findFirst().orElseGet(() -> stationRepository.save(
                Station.builder()
                        .name("OCPP Security Test Hub")
                        .latitude(new BigDecimal("26.9124"))
                        .longitude(new BigDecimal("75.7873"))
                        .address("Jaipur Tech Hub")
                        .status("ACTIVE")
                        .build()
        ));

        knownCharger = chargerRepository.save(Charger.builder()
                .station(testStation)
                .ocppId("CHG-SEC-KNOWN-01")
                .brand("ABB")
                .model("Terra 54")
                .status("AVAILABLE")
                .firmwareVersion("1.0.0")
                .build());

        connector1 = connectorRepository.save(Connector.builder()
                .charger(knownCharger)
                .connectorIndex(1)
                .type("CCS2")
                .status("AVAILABLE")
                .maxPowerKw(BigDecimal.valueOf(50.0))
                .build());

        connector2 = connectorRepository.save(Connector.builder()
                .charger(knownCharger)
                .connectorIndex(2)
                .type("TYPE2")
                .status("AVAILABLE")
                .maxPowerKw(BigDecimal.valueOf(22.0))
                .build());

        disabledCharger = chargerRepository.save(Charger.builder()
                .station(testStation)
                .ocppId("CHG-SEC-DISABLED-02")
                .brand("ABB")
                .model("Terra 54")
                .status("DISABLED")
                .build());

        otherCharger = chargerRepository.save(Charger.builder()
                .station(testStation)
                .ocppId("CHG-SEC-OTHER-03")
                .brand("Delta")
                .model("City 200")
                .status("AVAILABLE")
                .build());

        otherConnector = connectorRepository.save(Connector.builder()
                .charger(otherCharger)
                .connectorIndex(1)
                .type("CCS2")
                .status("AVAILABLE")
                .maxPowerKw(BigDecimal.valueOf(60.0))
                .build());
    }

    // A. Known charger can connect
    @Test
    void testKnownCharger_CanConnect() throws Exception {
        WebSocketSession session = mock(WebSocketSession.class);
        when(session.getUri()).thenReturn(URI.create("/ocpp/CHG-SEC-KNOWN-01"));
        when(session.getId()).thenReturn("SESS-KNOWN-01");

        ocppWebSocketHandler.afterConnectionEstablished(session);

        verify(session, never()).close(any());
        assertNotNull(ocppWebSocketHandler.getSession("CHG-SEC-KNOWN-01"));
    }

    // B. Unknown charger is rejected
    @Test
    void testUnknownCharger_IsRejected() throws Exception {
        WebSocketSession session = mock(WebSocketSession.class);
        when(session.getUri()).thenReturn(URI.create("/ocpp/CHG-UNKNOWN-999"));
        when(session.getId()).thenReturn("SESS-UNKNOWN-999");

        ocppWebSocketHandler.afterConnectionEstablished(session);

        verify(session).close(argThat(status -> status.getCode() == CloseStatus.POLICY_VIOLATION.getCode()));
        assertNull(ocppWebSocketHandler.getSession("CHG-UNKNOWN-999"));
    }

    // C. Unauthorized/disabled charger connection is rejected
    @Test
    void testDisabledCharger_IsRejected() throws Exception {
        WebSocketSession session = mock(WebSocketSession.class);
        when(session.getUri()).thenReturn(URI.create("/ocpp/CHG-SEC-DISABLED-02"));
        when(session.getId()).thenReturn("SESS-DISABLED-02");

        ocppWebSocketHandler.afterConnectionEstablished(session);

        verify(session).close(argThat(status -> status.getCode() == CloseStatus.POLICY_VIOLATION.getCode()));
        assertNull(ocppWebSocketHandler.getSession("CHG-SEC-DISABLED-02"));
    }

    // D. Duplicate charger connection is handled safely
    @Test
    void testDuplicateChargerConnection_IsHandledSafely() throws Exception {
        WebSocketSession session1 = mock(WebSocketSession.class);
        when(session1.getUri()).thenReturn(URI.create("/ocpp/CHG-SEC-KNOWN-01"));
        when(session1.getId()).thenReturn("SESS-01");
        when(session1.isOpen()).thenReturn(true);

        ocppWebSocketHandler.afterConnectionEstablished(session1);

        WebSocketSession session2 = mock(WebSocketSession.class);
        when(session2.getUri()).thenReturn(URI.create("/ocpp/CHG-SEC-KNOWN-01"));
        when(session2.getId()).thenReturn("SESS-02");

        ocppWebSocketHandler.afterConnectionEstablished(session2);

        verify(session1).close(argThat(status -> status.getCode() == CloseStatus.SERVER_ERROR.getCode()));
        assertEquals(session2, ocppWebSocketHandler.getSession("CHG-SEC-KNOWN-01"));
    }

    // E. Invalid connector ID is rejected in StatusNotification
    @Test
    void testInvalidConnectorId_IsRejectedInStatusNotification() {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("connectorId", 99); // Non-existent connector
        payload.put("status", "Available");

        OcppMessage request = OcppMessage.builder().messageTypeId(2).uniqueId("REQ-01").action("StatusNotification").payload(payload).build();
        OcppMessage response = statusNotificationHandler.handle("CHG-SEC-KNOWN-01", request);

        assertEquals(3, response.getMessageTypeId());
        assertEquals("REQ-01", response.getUniqueId());
    }

    // F. Connector belonging to another charger is rejected
    @Test
    void testConnectorBelongingToAnotherCharger_IsRejected() {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("connectorId", otherConnector.getConnectorIndex());
        payload.put("status", "Charging");

        OcppMessage request = OcppMessage.builder().messageTypeId(2).uniqueId("REQ-02").action("StatusNotification").payload(payload).build();
        OcppMessage response = statusNotificationHandler.handle("CHG-SEC-KNOWN-01", request);

        assertEquals(3, response.getMessageTypeId());
        // Verify otherConnector status was not mutated by knownCharger
        Connector reloadedOther = connectorRepository.findById(otherConnector.getId()).orElseThrow();
        assertNotEquals("CHARGING", reloadedOther.getStatus());
    }

    // G. Malformed OCPP message does not crash server
    @Test
    void testMalformedOcppMessage_DoesNotCrashServer() {
        assertThrows(Exception.class, () -> {
            messageParser.parse("{ invalid_json }");
        });
        assertThrows(Exception.class, () -> {
            messageParser.parse("[2, \"123\"]"); // Array size < 3
        });
    }

    // H. Duplicate StartTransaction does not create duplicate session
    @Test
    void testDuplicateStartTransaction_DoesNotCreateDuplicateSession() {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("connectorId", 1);
        payload.put("idTag", "RFID-001");
        payload.put("meterStart", 1000);

        OcppMessage request = OcppMessage.builder().messageTypeId(2).uniqueId("REQ-START-01").action("StartTransaction").payload(payload).build();

        // First StartTransaction
        OcppMessage response1 = startTransactionHandler.handle("CHG-SEC-KNOWN-01", request);
        int txId1 = response1.getPayload().get("transactionId").asInt();

        long countAfterFirst = chargingSessionRepository.count();

        // Duplicate StartTransaction
        OcppMessage response2 = startTransactionHandler.handle("CHG-SEC-KNOWN-01", request);
        int txId2 = response2.getPayload().get("transactionId").asInt();

        long countAfterSecond = chargingSessionRepository.count();

        assertEquals(txId1, txId2);
        assertEquals(countAfterFirst, countAfterSecond);
    }

    // I. Duplicate StopTransaction does not double-complete session
    @Test
    void testDuplicateStopTransaction_DoesNotDoubleCompleteSession() {
        ChargingSession session = chargingSessionRepository.save(ChargingSession.builder()
                .connector(connector1)
                .status("ACTIVE")
                .startTime(LocalDateTime.now().minusMinutes(15))
                .meterStartWh(new BigDecimal("1000"))
                .ocppTransactionId("OCPP-TX-DUPL-STOP")
                .build());

        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("transactionId", session.getId());
        payload.put("meterStop", 5000);
        payload.put("reason", "Local");

        OcppMessage request = OcppMessage.builder().messageTypeId(2).uniqueId("REQ-STOP-01").action("StopTransaction").payload(payload).build();

        // First StopTransaction
        OcppMessage response1 = stopTransactionHandler.handle("CHG-SEC-KNOWN-01", request);
        assertEquals("Accepted", response1.getPayload().get("idTagInfo").get("status").asText());

        ChargingSession completed1 = chargingSessionRepository.findById(session.getId()).orElseThrow();
        assertEquals("COMPLETED", completed1.getStatus());

        // Second StopTransaction
        OcppMessage response2 = stopTransactionHandler.handle("CHG-SEC-KNOWN-01", request);
        assertEquals("Accepted", response2.getPayload().get("idTagInfo").get("status").asText());

        ChargingSession completed2 = chargingSessionRepository.findById(session.getId()).orElseThrow();
        assertEquals(completed1.getUpdatedAt(), completed2.getUpdatedAt());
    }

    // J. One charger cannot modify another charger's session
    @Test
    void testOneCharger_CannotModifyAnotherChargersSession() {
        ChargingSession otherSession = chargingSessionRepository.save(ChargingSession.builder()
                .connector(otherConnector)
                .status("ACTIVE")
                .startTime(LocalDateTime.now().minusMinutes(10))
                .meterStartWh(new BigDecimal("2000"))
                .ocppTransactionId("OCPP-TX-OTHER")
                .build());

        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("transactionId", otherSession.getId());
        payload.put("meterStop", 6000);

        OcppMessage request = OcppMessage.builder().messageTypeId(2).uniqueId("REQ-STOP-ATTACK").action("StopTransaction").payload(payload).build();

        // Charger CHG-SEC-KNOWN-01 attempts to stop otherSession belonging to CHG-SEC-OTHER-03
        OcppMessage response = stopTransactionHandler.handle("CHG-SEC-KNOWN-01", request);
        assertEquals("Invalid", response.getPayload().get("idTagInfo").get("status").asText());

        ChargingSession reloaded = chargingSessionRepository.findById(otherSession.getId()).orElseThrow();
        assertEquals("ACTIVE", reloaded.getStatus());
    }

    // K. Invalid MeterValues are rejected safely
    @Test
    void testInvalidMeterValues_AreRejectedSafely() {
        ArrayNode sampledValues = objectMapper.createArrayNode();
        ObjectNode sample = objectMapper.createObjectNode();
        sample.put("value", "-50.0"); // Negative energy!
        sample.put("unit", "kWh");
        sample.put("measurand", "Energy.Active.Import.Register");
        sampledValues.add(sample);

        ArrayNode meterValues = objectMapper.createArrayNode();
        ObjectNode mv = objectMapper.createObjectNode();
        mv.set("sampledValue", sampledValues);
        meterValues.add(mv);

        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("connectorId", 1);
        payload.set("meterValue", meterValues);

        OcppMessage request = OcppMessage.builder().messageTypeId(2).uniqueId("REQ-MV-01").action("MeterValues").payload(payload).build();
        OcppMessage response = meterValuesHandler.handle("CHG-SEC-KNOWN-01", request);

        assertEquals(3, response.getMessageTypeId());
    }

    // L. Heartbeat updates lastSeen
    @Test
    void testHeartbeat_UpdatesLastSeen() throws Exception {
        LocalDateTime before = LocalDateTime.now().minusSeconds(1);

        OcppMessage request = OcppMessage.builder().messageTypeId(2).uniqueId("REQ-HB-01").action("Heartbeat").build();
        heartbeatHandler.handle("CHG-SEC-KNOWN-01", request);

        Charger reloaded = chargerRepository.findByOcppId("CHG-SEC-KNOWN-01").orElseThrow();
        assertTrue(reloaded.getUpdatedAt().isAfter(before));
    }

    // N. Disconnect does not incorrectly complete active charging session
    @Test
    void testDisconnect_DoesNotPrematurelyCompleteActiveSession() throws Exception {
        ChargingSession activeSession = chargingSessionRepository.save(ChargingSession.builder()
                .connector(connector1)
                .status("ACTIVE")
                .startTime(LocalDateTime.now().minusMinutes(5))
                .meterStartWh(new BigDecimal("1000"))
                .build());

        WebSocketSession session = mock(WebSocketSession.class);
        when(session.getUri()).thenReturn(URI.create("/ocpp/CHG-SEC-KNOWN-01"));
        when(session.getId()).thenReturn("SESS-ACTIVE-01");

        ocppWebSocketHandler.afterConnectionEstablished(session);
        ocppWebSocketHandler.afterConnectionClosed(session, CloseStatus.NORMAL);

        ChargingSession reloaded = chargingSessionRepository.findById(activeSession.getId()).orElseThrow();
        assertEquals("ACTIVE", reloaded.getStatus());
    }

    // P. Simulator endpoints cannot be accessed by CUSTOMER role
    @Test
    @WithMockUser(username = "customer@ecomargin.com", roles = {"CUSTOMER"})
    void testSimulatorEndpoint_CannotBeAccessedByCustomer() throws Exception {
        String payload = "{\"eventType\": \"STATUS\", \"chargePointId\": \"CHG-SEC-KNOWN-01\", \"status\": \"AVAILABLE\"}";

        mockMvc.perform(post("/api/v1/ocpp/internal/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isForbidden());
    }
}
