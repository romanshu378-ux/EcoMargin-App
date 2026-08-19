package com.ecomargin.ocpp.handler;

import com.ecomargin.model.Charger;
import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.ocpp.protocol.OcppRequestHandler;
import com.ecomargin.repository.ChargerRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
@Transactional
public class HeartbeatHandler implements OcppRequestHandler {

    private final ChargerRepository chargerRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcppAction getAction() {
        return OcppAction.Heartbeat;
    }

    @Override
    public OcppMessage handle(String chargeBoxId, OcppMessage message) {
        log.debug("Handling Heartbeat for charger: {}", chargeBoxId);

        chargerRepository.findByOcppId(chargeBoxId).ifPresent(charger -> {
            charger.setUpdatedAt(LocalDateTime.now());
            chargerRepository.save(charger);
        });

        ObjectNode responsePayload = objectMapper.createObjectNode();
        responsePayload.put("currentTime", Instant.now().toString());

        return OcppMessage.builder()
                .messageTypeId(3)
                .uniqueId(message.getUniqueId())
                .payload(responsePayload)
                .build();
    }
}
