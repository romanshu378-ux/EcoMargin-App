package com.ecomargin.ocpp.websocket;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class WebSocketSessionRegistry {

    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    public void register(String chargePointId, WebSocketSession session) {
        sessions.put(chargePointId, session);
        log.info("[OCPP-REGISTRY] ChargePoint connected & registered: id={}, session={}", chargePointId, session.getId());
    }

    public void unregister(String chargePointId) {
        if (chargePointId != null) {
            sessions.remove(chargePointId);
            log.info("[OCPP-REGISTRY] ChargePoint disconnected & unregistered: id={}", chargePointId);
        }
    }

    public WebSocketSession getSession(String chargePointId) {
        return sessions.get(chargePointId);
    }

    public boolean isConnected(String chargePointId) {
        WebSocketSession session = sessions.get(chargePointId);
        return session != null && session.isOpen();
    }

    public boolean sendTextMessage(String chargePointId, String textMessage) {
        WebSocketSession session = sessions.get(chargePointId);
        if (session != null && session.isOpen()) {
            try {
                synchronized (session) {
                    session.sendMessage(new TextMessage(textMessage));
                }
                log.info("[OCPP-SEND] Message sent to chargePointId={}: {}", chargePointId, textMessage);
                return true;
            } catch (Exception e) {
                log.error("[OCPP-SEND-ERR] Failed to send message to chargePointId={}", chargePointId, e);
            }
        } else {
            log.warn("[OCPP-SEND-WARN] ChargePoint not connected or session closed: chargePointId={}", chargePointId);
        }
        return false;
    }
}
