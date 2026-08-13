package com.ecomargin.ocpp.simulator;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class OcppSimulator {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    public static void main(String[] args) throws Exception {
        String serverUrl = args.length > 0 ? args[0] : "ws://localhost:8081/ocpp/CHG-DC-04";
        System.out.println("==================================================");
        System.out.println("   ECOMARGIN OCPP 1.6-J CHARGE POINT SIMULATOR    ");
        System.out.println("   Target URL: " + serverUrl);
        System.out.println("==================================================");

        StandardWebSocketClient client = new StandardWebSocketClient();
        WebSocketHttpHeaders headers = new WebSocketHttpHeaders();
        headers.add("Sec-WebSocket-Protocol", "ocpp1.6j");

        CountDownLatch latch = new CountDownLatch(1);

        WebSocketSession session = client.execute(new TextWebSocketHandler() {
            @Override
            public void afterConnectionEstablished(WebSocketSession session) throws Exception {
                System.out.println("[SIMULATOR] Connected to OCPP Server successfully!");

                // 1. BootNotification
                String bootMsgId = UUID.randomUUID().toString();
                String bootCall = createCallJson(bootMsgId, "BootNotification", MapOf(
                        "chargePointVendor", "EcoMargin-Hardware",
                        "chargePointModel", "SuperFast-DC-60KW",
                        "firmwareVersion", "v2.4.12"
                ));
                System.out.println("[SIMULATOR -> SERVER] BootNotification: " + bootCall);
                session.sendMessage(new TextMessage(bootCall));

                Thread.sleep(1000);

                // 2. StatusNotification (Preparing)
                String statusMsgId1 = UUID.randomUUID().toString();
                String statusCall1 = createCallJson(statusMsgId1, "StatusNotification", MapOf(
                        "connectorId", 1,
                        "errorCode", "NoError",
                        "status", "Preparing"
                ));
                System.out.println("[SIMULATOR -> SERVER] StatusNotification (Preparing): " + statusCall1);
                session.sendMessage(new TextMessage(statusCall1));

                Thread.sleep(1000);

                // 3. StartTransaction
                String startMsgId = UUID.randomUUID().toString();
                String startCall = createCallJson(startMsgId, "StartTransaction", MapOf(
                        "connectorId", 1,
                        "idTag", "TAG-SIMULATOR-001",
                        "meterStart", 1000,
                        "timestamp", Instant.now().toString()
                ));
                System.out.println("[SIMULATOR -> SERVER] StartTransaction: " + startCall);
                session.sendMessage(new TextMessage(startCall));

                Thread.sleep(1000);

                // 4. StatusNotification (Charging)
                String statusMsgId2 = UUID.randomUUID().toString();
                String statusCall2 = createCallJson(statusMsgId2, "StatusNotification", MapOf(
                        "connectorId", 1,
                        "errorCode", "NoError",
                        "status", "Charging"
                ));
                System.out.println("[SIMULATOR -> SERVER] StatusNotification (Charging): " + statusCall2);
                session.sendMessage(new TextMessage(statusCall2));

                // 5. Send periodic MeterValues
                for (int i = 1; i <= 3; i++) {
                    Thread.sleep(2000);
                    double currentWh = 1000 + (i * 500); // 500Wh per step
                    double currentKw = 42.5;
                    double soc = 40.0 + (i * 10.0);

                    String meterMsgId = UUID.randomUUID().toString();
                    String meterCall = createMeterValueJson(meterMsgId, 1, currentWh, currentKw, soc);
                    System.out.println("[SIMULATOR -> SERVER] MeterValues step " + i + ": " + meterCall);
                    session.sendMessage(new TextMessage(meterCall));
                }

                Thread.sleep(2000);

                // 6. StopTransaction
                String stopMsgId = UUID.randomUUID().toString();
                String stopCall = createCallJson(stopMsgId, "StopTransaction", MapOf(
                        "connectorId", 1,
                        "idTag", "TAG-SIMULATOR-001",
                        "meterStop", 2500, // Delivered 1.5 kWh
                        "timestamp", Instant.now().toString(),
                        "reason", "Local"
                ));
                System.out.println("[SIMULATOR -> SERVER] StopTransaction: " + stopCall);
                session.sendMessage(new TextMessage(stopCall));

                Thread.sleep(1000);

                // 7. StatusNotification (Available)
                String statusMsgId3 = UUID.randomUUID().toString();
                String statusCall3 = createCallJson(statusMsgId3, "StatusNotification", MapOf(
                        "connectorId", 1,
                        "errorCode", "NoError",
                        "status", "Available"
                ));
                System.out.println("[SIMULATOR -> SERVER] StatusNotification (Available): " + statusCall3);
                session.sendMessage(new TextMessage(statusCall3));

                System.out.println("[SIMULATOR] Simulation sequence completed successfully!");
                if (session != null && session.isOpen()) {
                    session.close();
                }
                System.exit(0);
            }

            @Override
            protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
                System.out.println("[SERVER -> SIMULATOR] " + message.getPayload());
            }
        }, headers, URI.create(serverUrl)).get(10, TimeUnit.SECONDS);

        latch.await(30, TimeUnit.SECONDS);
        session.close();
        System.out.println("[SIMULATOR] Process finished.");
    }

    private static String createCallJson(String msgId, String action, java.util.Map<String, Object> payloadMap) throws Exception {
        ArrayNode arr = objectMapper.createArrayNode();
        arr.add(2);
        arr.add(msgId);
        arr.add(action);
        arr.add(objectMapper.valueToTree(payloadMap));
        return objectMapper.writeValueAsString(arr);
    }

    private static String createMeterValueJson(String msgId, int connectorId, double energyWh, double powerKw, double soc) throws Exception {
        ArrayNode arr = objectMapper.createArrayNode();
        arr.add(2);
        arr.add(msgId);
        arr.add("MeterValues");

        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("connectorId", connectorId);

        ArrayNode mvArr = objectMapper.createArrayNode();
        ObjectNode mvObj = objectMapper.createObjectNode();
        mvObj.put("timestamp", Instant.now().toString());

        ArrayNode sampledArr = objectMapper.createArrayNode();

        ObjectNode sample1 = objectMapper.createObjectNode();
        sample1.put("measurand", "Energy.Active.Import.Register");
        sample1.put("value", String.valueOf(energyWh));
        sample1.put("unit", "Wh");
        sampledArr.add(sample1);

        ObjectNode sample2 = objectMapper.createObjectNode();
        sample2.put("measurand", "Power.Active.Import");
        sample2.put("value", String.valueOf(powerKw));
        sample2.put("unit", "kW");
        sampledArr.add(sample2);

        ObjectNode sample3 = objectMapper.createObjectNode();
        sample3.put("measurand", "SoC");
        sample3.put("value", String.valueOf(soc));
        sample3.put("unit", "Percent");
        sampledArr.add(sample3);

        mvObj.set("sampledValue", sampledArr);
        mvArr.add(mvObj);
        payload.set("meterValue", mvArr);

        arr.add(payload);
        return objectMapper.writeValueAsString(arr);
    }

    private static java.util.Map<String, Object> MapOf(Object... kvs) {
        java.util.Map<String, Object> map = new java.util.HashMap<>();
        for (int i = 0; i < kvs.length; i += 2) {
            map.put((String) kvs[i], kvs[i + 1]);
        }
        return map;
    }
}
