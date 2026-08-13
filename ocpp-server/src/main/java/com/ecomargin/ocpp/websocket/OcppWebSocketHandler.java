package com.ecomargin.ocpp.websocket;

import com.ecomargin.ocpp.service.OcppMessageDispatcher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;

@Slf4j
@Component
@RequiredArgsConstructor
public class OcppWebSocketHandler extends TextWebSocketHandler {

    private final WebSocketSessionRegistry sessionRegistry;
    private final OcppMessageDispatcher messageDispatcher;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String chargePointId = extractChargePointId(session);
        if (chargePointId == null || chargePointId.isBlank()) {
            log.warn("[OCPP-WS-REJECT] WebSocket connection missing chargePointId. Closing session={}", session.getId());
            session.close(CloseStatus.BAD_DATA.withReason("ChargePointId required in URL path"));
            return;
        }

        sessionRegistry.register(chargePointId, session);
        log.info("[OCPP-WS-CONNECT] ChargePoint connected: id={}, session={}", chargePointId, session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String chargePointId = extractChargePointId(session);
        if (chargePointId == null) {
            session.close(CloseStatus.BAD_DATA);
            return;
        }

        String payload = message.getPayload();
        log.debug("[OCPP-WS-RECV] chargePointId={}: {}", chargePointId, payload);

        String responseText = messageDispatcher.dispatch(chargePointId, payload);
        if (responseText != null && !responseText.isBlank()) {
            synchronized (session) {
                session.sendMessage(new TextMessage(responseText));
            }
            log.debug("[OCPP-WS-SENT] chargePointId={}: {}", chargePointId, responseText);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String chargePointId = extractChargePointId(session);
        if (chargePointId != null) {
            sessionRegistry.unregister(chargePointId);
            log.info("[OCPP-WS-DISCONNECT] ChargePoint disconnected: id={}, status={}", chargePointId, status);
        }
    }

    private String extractChargePointId(WebSocketSession session) {
        URI uri = session.getUri();
        if (uri == null) return null;
        String path = uri.getPath();
        if (path == null) return null;

        // Path pattern: /ocpp/{chargePointId}
        int lastIndex = path.lastIndexOf('/');
        if (lastIndex >= 0 && lastIndex < path.length() - 1) {
            return path.substring(lastIndex + 1);
        }
        return null;
    }
}
