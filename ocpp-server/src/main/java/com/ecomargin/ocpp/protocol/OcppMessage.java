package com.ecomargin.ocpp.protocol;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OcppMessage {
    private int messageType; // 2=CALL, 3=CALLRESULT, 4=CALLERROR
    private String messageId;
    private String action; // For CALL
    private JsonNode payload; // For CALL & CALLRESULT
    private String errorCode; // For CALLERROR
    private String errorDescription; // For CALLERROR
}
