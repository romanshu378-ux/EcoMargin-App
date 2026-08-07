package com.ecomargin.ocpp;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class OcppServerIntegrationTest {

    @LocalServerPort
    private int port;

    @Test
    void testOcppHandshakeAndBootNotification() throws Exception {
        URI uri = new URI("ws://localhost:" + port + "/ocpp/TX_TEST_CHARGER");
        StandardWebSocketClient client = new StandardWebSocketClient();
        
        // OCPP 1.6J demands the ocpp1.6 sub-protocol selection
        WebSocketHttpHeaders headers = new WebSocketHttpHeaders();
        headers.setSecWebSocketProtocol("ocpp1.6");

        CompletableFuture<String> responseFuture = new CompletableFuture<>();

        CompletableFuture<WebSocketSession> sessionFuture = client.execute(new TextWebSocketHandler() {
            @Override
            public void afterConnectionEstablished(WebSocketSession session) throws Exception {
                // Send standard OCPP 1.6J BootNotification array packet
                String bootNotificationCall = "[2, \"10001\", \"BootNotification\", {\"chargePointVendor\": \"Tritium\", \"chargePointModel\": \"RT50\"}]";
                session.sendMessage(new TextMessage(bootNotificationCall));
            }

            @Override
            protected void handleTextMessage(WebSocketSession session, TextMessage message) {
                responseFuture.complete(message.getPayload());
            }
        }, headers, uri);

        WebSocketSession session = sessionFuture.get(5, TimeUnit.SECONDS);
        assertNotNull(session);
        assertTrue(session.isOpen());

        String rawResponse = responseFuture.get(5, TimeUnit.SECONDS);
        assertNotNull(rawResponse);
        
        // Assert that the response matches OCPP CallResult format (messageTypeId = 3) with accepted state
        assertTrue(rawResponse.startsWith("[3,\"10001\""));
        assertTrue(rawResponse.contains("\"status\":\"Accepted\""));

        session.close();
    }
}
