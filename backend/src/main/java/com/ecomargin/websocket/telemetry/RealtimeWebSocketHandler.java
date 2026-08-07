package com.ecomargin.websocket.telemetry;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

@Slf4j
@Component
public class RealtimeWebSocketHandler extends TextWebSocketHandler {

    // Maps WebSocket session ID to the session object
    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    // Maps topic (e.g. "charger:TX_AUS_DWTN_01", "vendor:1") to set of session IDs subscribed to it
    private final Map<String, Set<String>> topicSubscriptions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        sessions.put(session.getId(), session);
        log.info("Client connected to Realtime Gateway: {}", session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();
        log.debug("Received command from client {}: {}", session.getId(), payload);

        // Simple custom protocol: SUBSCRIBE <topic> or UNSUBSCRIBE <topic>
        String[] parts = payload.split(" ");
        if (parts.length >= 2) {
            String command = parts[0].toUpperCase();
            String topic = parts[1];

            if ("SUBSCRIBE".equals(command)) {
                topicSubscriptions.computeIfAbsent(topic, k -> new CopyOnWriteArraySet<>()).add(session.getId());
                session.sendMessage(new TextMessage("SUBSCRIBED " + topic));
                log.info("Client {} subscribed to topic: {}", session.getId(), topic);
            } else if ("UNSUBSCRIBE".equals(command)) {
                Set<String> subs = topicSubscriptions.get(topic);
                if (subs != null) {
                    subs.remove(session.getId());
                }
                session.sendMessage(new TextMessage("UNSUBSCRIBED " + topic));
                log.info("Client {} unsubscribed from topic: {}", session.getId(), topic);
            }
        } else if ("PING".equalsIgnoreCase(payload)) {
            session.sendMessage(new TextMessage("PONG"));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String sessionId = session.getId();
        sessions.remove(sessionId);

        // Clean up subscriptions
        topicSubscriptions.values().forEach(subscribers -> subscribers.remove(sessionId));
        log.info("Client disconnected from Realtime Gateway: {} (Status: {})", sessionId, status);
    }

    public void broadcastToTopic(String topic, String message) {
        Set<String> sessionIds = topicSubscriptions.get(topic);
        if (sessionIds == null || sessionIds.isEmpty()) return;

        log.debug("Broadcasting telemetry to topic {}: {}", topic, message);
        for (String sessionId : sessionIds) {
            WebSocketSession session = sessions.get(sessionId);
            if (session != null && session.isOpen()) {
                try {
                    session.sendMessage(new TextMessage(message));
                } catch (IOException e) {
                    log.error("Failed to send realtime update to session {}", sessionId, e);
                }
            }
        }
    }
}
