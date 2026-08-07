package com.ecomargin.ocpp.protocol;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
public class OcppMessageDispatcher {

    private final Map<OcppAction, OcppRequestHandler> handlers = new HashMap<>();

    public OcppMessageDispatcher(List<OcppRequestHandler> requestHandlers) {
        for (OcppRequestHandler handler : requestHandlers) {
            handlers.put(handler.getAction(), handler);
        }
    }

    public OcppMessage dispatch(String chargeBoxId, OcppMessage message) {
        if (message.getMessageTypeId() != 2) {
            log.warn("Dispatcher only handles call requests (type 2). Message type: {}", message.getMessageTypeId());
            return OcppMessage.builder()
                    .messageTypeId(4)
                    .uniqueId(message.getUniqueId())
                    .errorCode("FormationViolation")
                    .errorDescription("Expected Call Request (TypeId 2)")
                    .build();
        }

        try {
            OcppAction action = OcppAction.valueOf(message.getAction());
            OcppRequestHandler handler = handlers.get(action);
            
            if (handler == null) {
                log.warn("No handler registered for action: {}", action);
                return OcppMessage.builder()
                        .messageTypeId(4)
                        .uniqueId(message.getUniqueId())
                        .errorCode("NotImplemented")
                        .errorDescription("Action handler not implemented: " + action)
                        .build();
            }

            return handler.handle(chargeBoxId, message);

        } catch (IllegalArgumentException e) {
            log.warn("Unknown OCPP Action: {}", message.getAction());
            return OcppMessage.builder()
                    .messageTypeId(4)
                    .uniqueId(message.getUniqueId())
                    .errorCode("NotSupported")
                    .errorDescription("Action not supported: " + message.getAction())
                    .build();
        } catch (Exception e) {
            log.error("Error dispatching OCPP message for {}: {}", chargeBoxId, e.getMessage(), e);
            return OcppMessage.builder()
                    .messageTypeId(4)
                    .uniqueId(message.getUniqueId())
                    .errorCode("InternalError")
                    .errorDescription(e.getMessage())
                    .build();
        }
    }
}
