package com.ecomargin.ocpp.websocket;

import com.ecomargin.model.Charger;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppMessageParser;
import com.ecomargin.ocpp.protocol.OcppMessageDispatcher;
import com.ecomargin.ocpp.protocol.OcppResponseEvent;
import com.ecomargin.repository.ChargerRepository;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@Slf4j
@Component
@RequiredArgsConstructor
public class OcppWebSocketHandler extends TextWebSocketHandler {

    private final OcppMessageParser messageParser;
    private final OcppMessageDispatcher messageDispatcher;
    private final ApplicationEventPublisher eventPublisher;
    private final ChargerRepository chargerRepository;

    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final Map<String, List<Long>> rateTracker = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String chargeBoxId = getChargeBoxId(session);
        if (chargeBoxId == null || chargeBoxId.isBlank()) {
            log.warn("[OCPP-SECURITY] Connection attempt without chargeBoxId. Closing session {}", session.getId());
            session.close(CloseStatus.BAD_DATA);
            return;
        }

        // 1. Charger Identity Validation & Authentication
        Optional<Charger> chargerOpt = chargerRepository.findByOcppId(chargeBoxId);
        if (chargerOpt.isEmpty()) {
            log.warn("[OCPP-SECURITY] Connection rejected: Unknown charger chargeBoxId={}", chargeBoxId);
            session.close(CloseStatus.POLICY_VIOLATION.withReason("Unknown charger identity"));
            return;
        }

        Charger charger = chargerOpt.get();
        if ("DISABLED".equalsIgnoreCase(charger.getStatus()) || "INACTIVE".equalsIgnoreCase(charger.getStatus())) {
            log.warn("[OCPP-SECURITY] Connection rejected: Charger {} is disabled/inactive", chargeBoxId);
            session.close(CloseStatus.POLICY_VIOLATION.withReason("Charger is inactive"));
            return;
        }

        // 2. Duplicate Charger Connection Protection
        if (sessions.containsKey(chargeBoxId)) {
            WebSocketSession existingSession = sessions.get(chargeBoxId);
            if (existingSession != null && existingSession.isOpen() && !existingSession.getId().equals(session.getId())) {
                log.warn("[OCPP-SECURITY] Duplicate connection detected for charger {}. Closing old session {}", chargeBoxId, existingSession.getId());
                try {
                    existingSession.close(CloseStatus.SERVER_ERROR.withReason("Replaced by new connection"));
                } catch (Exception e) {
                    log.warn("[OCPP-SECURITY] Error closing duplicate session: {}", e.getMessage());
                }
            }
        }

        sessions.put(chargeBoxId, session);
        charger.setUpdatedAt(LocalDateTime.now());
        chargerRepository.save(charger);

        log.info("[OCPP-SECURITY] Charger connected & validated: {} (Session ID: {})", chargeBoxId, session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String chargeBoxId = getChargeBoxId(session);
        if (chargeBoxId == null) {
            session.close(CloseStatus.BAD_DATA);
            return;
        }

        // 3. Abuse Protection / Rate Limiting (Max 50 msgs per 10s per charger)
        long now = System.currentTimeMillis();
        List<Long> timestamps = rateTracker.computeIfAbsent(chargeBoxId, k -> new CopyOnWriteArrayList<>());
        timestamps.removeIf(t -> now - t > 10000);
        if (timestamps.size() >= 50) {
            log.warn("[OCPP-SECURITY] Rate limit exceeded for charger {}. Dropping message.", chargeBoxId);
            return;
        }
        timestamps.add(now);

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
                // CallResult (3) or CallError (4) response to server request
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
            log.error("[OCPP-SECURITY] Invalid OCPP packet from {}: {}", chargeBoxId, e.getMessage());
            try {
                String errorResponse = messageParser.toRawCallError("0", "FormationViolation", "Invalid OCPP message payload", null);
                session.sendMessage(new TextMessage(errorResponse));
            } catch (Exception ex) {
                // Ignore send error
            }
        } catch (Exception e) {
            log.error("[OCPP-SECURITY] Exception handling message from {}: {}", chargeBoxId, e.getMessage(), e);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String chargeBoxId = getChargeBoxId(session);
        if (chargeBoxId != null) {
            WebSocketSession currentSession = sessions.get(chargeBoxId);
            if (currentSession != null && currentSession.getId().equals(session.getId())) {
                sessions.remove(chargeBoxId);
                rateTracker.remove(chargeBoxId);

                // Update charger timestamp on disconnect without terminating active charging sessions prematurely
                chargerRepository.findByOcppId(chargeBoxId).ifPresent(charger -> {
                    charger.setUpdatedAt(LocalDateTime.now());
                    chargerRepository.save(charger);
                });

                log.info("[OCPP-SECURITY] Charger disconnected: {} (Status: {})", chargeBoxId, status);
            }
        }
    }

    public WebSocketSession getSession(String chargeBoxId) {
        return sessions.get(chargeBoxId);
    }

    private String getChargeBoxId(WebSocketSession session) {
        if (session.getUri() == null || session.getUri().getPath() == null) {
            return null;
        }
        String path = session.getUri().getPath();
        String[] parts = path.split("/");
        if (parts.length > 0) {
            return parts[parts.length - 1];
        }
        return null;
    }
}
