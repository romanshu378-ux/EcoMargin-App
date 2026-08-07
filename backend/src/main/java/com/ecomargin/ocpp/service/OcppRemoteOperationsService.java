package com.ecomargin.ocpp.service;

import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessageParser;
import com.ecomargin.ocpp.protocol.OcppResponseEvent;
import com.ecomargin.ocpp.websocket.OcppWebSocketHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class OcppRemoteOperationsService {

    private final OcppWebSocketHandler webSocketHandler;
    private final OcppMessageParser messageParser;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Map to keep track of pending outbound requests and await their responses
    private final ConcurrentHashMap<String, CompletableFuture<ObjectNode>> pendingRequests = new ConcurrentHashMap<>();

    @EventListener
    public void onOcppResponse(OcppResponseEvent event) {
        log.debug("Heard response event for request uniqueId: {}", event.getUniqueId());
        handleOutboundResponse(event.getUniqueId(), event.getPayload(), event.isError());
    }

    public CompletableFuture<ObjectNode> sendRemoteStart(String chargeBoxId, int connectorId, String idTag) {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("connectorId", connectorId);
        payload.put("idTag", idTag);
        
        return sendRequest(chargeBoxId, OcppAction.RemoteStartTransaction, payload);
    }

    public CompletableFuture<ObjectNode> sendRemoteStop(String chargeBoxId, int transactionId) {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("transactionId", transactionId);

        return sendRequest(chargeBoxId, OcppAction.RemoteStopTransaction, payload);
    }

    public CompletableFuture<ObjectNode> unlockConnector(String chargeBoxId, int connectorId) {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("connectorId", connectorId);

        return sendRequest(chargeBoxId, OcppAction.UnlockConnector, payload);
    }

    public CompletableFuture<ObjectNode> triggerFirmwareUpdate(String chargeBoxId, String retrieveUrl, String retrieveDate) {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("location", retrieveUrl);
        payload.put("retries", 3);
        payload.put("retrieveDate", retrieveDate);

        return sendRequest(chargeBoxId, OcppAction.UpdateFirmware, payload);
    }

    private CompletableFuture<ObjectNode> sendRequest(String chargeBoxId, OcppAction action, ObjectNode payload) {
        CompletableFuture<ObjectNode> future = new CompletableFuture<>();
        WebSocketSession session = webSocketHandler.getSession(chargeBoxId);

        if (session == null || !session.isOpen()) {
            future.completeExceptionally(new IllegalStateException("Charger " + chargeBoxId + " is offline"));
            return future;
        }

        String uniqueId = UUID.randomUUID().toString();
        pendingRequests.put(uniqueId, future);

        try {
            String rawMessage = messageParser.toRawCall(uniqueId, action, payload);
            log.info("Sending outbound remote request {} to {}: {}", action, chargeBoxId, rawMessage);
            session.sendMessage(new TextMessage(rawMessage));
            
            // Add a timeout fallback so requests don't hang indefinitely
            future.orTimeout(30, TimeUnit.SECONDS).whenComplete((res, ex) -> {
                pendingRequests.remove(uniqueId);
                if (ex != null) {
                    log.warn("Request {} to {} timed out or failed: {}", uniqueId, chargeBoxId, ex.getMessage());
                }
            });

        } catch (IOException e) {
            pendingRequests.remove(uniqueId);
            future.completeExceptionally(e);
        }

        return future;
    }

    // This method should be called from the WebSocketHandler when type 3 or 4 response arrives
    public void handleOutboundResponse(String uniqueId, ObjectNode responsePayload, boolean isError) {
        CompletableFuture<ObjectNode> future = pendingRequests.remove(uniqueId);
        if (future != null) {
            if (isError) {
                future.completeExceptionally(new RuntimeException("Charger returned error response"));
            } else {
                future.complete(responsePayload);
            }
        }
    }
}
