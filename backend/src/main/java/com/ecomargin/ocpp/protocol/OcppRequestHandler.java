package com.ecomargin.ocpp.protocol;

public interface OcppRequestHandler {
    OcppMessage handle(String chargeBoxId, OcppMessage message);
    OcppAction getAction();
}
