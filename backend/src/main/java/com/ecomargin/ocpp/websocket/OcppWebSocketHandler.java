package com.ecomargin.ocpp.websocket;

import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppMessageParser;
import com.ecomargin.ocpp.protocol.OcppMessageDispatcher;
import com.ecomargin.ocpp.protocol.OcppResponseEvent;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
@RequiredArgsConstructor
public class OcppWebSocketHandler extends TextWebSocketHandler {

    private final OcppMessageParser messageParser;
    private final OcppMessageDispatcher messageDispatcher;
    private final ApplicationEventPublisher eventPublisher;
    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String chargeBoxId = getChargeBoxId(session);
        if (chargeBoxId == null) {
            log.warn("Connection attempt without chargeBoxId. Closing session {}", session.getId());
            session.close(CloseStatus.BAD_DATA);
            return;
        }

        sessions.put(chargeBoxId, session);
        log.info("Charger connected: {} (Session ID: {})", chargeBoxId, session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String chargeBoxId = getChargeBoxId(session);
        String payload = message.getPayload();
        
        log.debug("Received OCPP message from {}: {}", chargeBoxId, payload);

        try {
            OcppMessage ocppMessage = messageParser.parse(payload);
            
            if (ocppMessage.getMessageTypeId() == 2) {
                // Dispatch Call Request
                OcppMessage responseMessage = messageDispatcher.dispatch(chargeBoxId, ocppMessage);
                String rawResponse;
                
                if (responseMessage.getMessageTypeId() == 3) {
                    rawResponse = messageParser.toRawCallResult(responseMessage.getUniqueId(), responseMessage.getPayload());
                } else {
                    rawResponse = messageParser.toRawCallError(
                            responseMessage.getUniqueId(),
                            responseMessage.getErrorCode(),
                            responseMessage.getErrorDescription(),
                            responseMessage.getErrorDetails()
                    );
                }
                
                session.sendMessage(new TextMessage(rawResponse));
            } else {
                // If it's type 3 or 4, it's a response to a command we sent.
                boolean isError = ocppMessage.getMessageTypeId() == 4;
                ObjectNode responsePayload = null;
                
                if (ocppMessage.getPayload() != null && ocppMessage.getPayload().isObject()) {
                    responsePayload = (ObjectNode) ocppMessage.getPayload();
                } else if (ocppMessage.getErrorDetails() != null && ocppMessage.getErrorDetails().isObject()) {
                    responsePayload = (ObjectNode) ocppMessage.getErrorDetails();
                }

                eventPublisher.publishEvent(new OcppResponseEvent(
                        this,
                        chargeBoxId,
                        ocppMessage.getUniqueId(),
                        responsePayload,
                        isError
                ));
            }
        } catch (IllegalArgumentException e) {
            log.error("Invalid OCPP packet from {}: {}", chargeBoxId, e.getMessage());
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String chargeBoxId = getChargeBoxId(session);
        if (chargeBoxId != null) {
            sessions.remove(chargeBoxId);
            log.info("Charger disconnected: {} (Status: {})", chargeBoxId, status);
        }
    }

    public WebSocketSession getSession(String chargeBoxId) {
        return sessions.get(chargeBoxId);
    }

    private String getChargeBoxId(WebSocketSession session) {
        String path = session.getUri().getPath();
        // Path format is expected to be "/ocpp/{chargeBoxId}"
        String[] parts = path.split("/");
        if (parts.length > 0) {
            return parts[parts.length - 1];
        }
        return null;
    }

    // Dummy class just to serialize heartbeat response
    private static class HeartbeatResponse {
        public final String currentTime = java.time.Instant.now().toString();
    }
}
