package com.ecomargin.ocpp.protocol;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonFormat(shape = JsonFormat.Shape.ARRAY)
public class OcppMessage {
    
    private int messageTypeId; // 2 = Call, 3 = CallResult, 4 = CallError
    private String uniqueId;
    
    // Fields for Call (Request)
    private String action;
    private JsonNode payload;

    // Fields for CallError
    private String errorCode;
    private String errorDescription;
    private JsonNode errorDetails;
}
