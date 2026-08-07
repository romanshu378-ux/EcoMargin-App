package com.ecomargin.ocpp.protocol;

import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class OcppResponseEvent extends ApplicationEvent {

    private final String chargeBoxId;
    private final String uniqueId;
    private final ObjectNode payload;
    private final boolean isError;

    public OcppResponseEvent(Object source, String chargeBoxId, String uniqueId, ObjectNode payload, boolean isError) {
        super(source);
        this.chargeBoxId = chargeBoxId;
        this.uniqueId = uniqueId;
        this.payload = payload;
        this.isError = isError;
    }
}
