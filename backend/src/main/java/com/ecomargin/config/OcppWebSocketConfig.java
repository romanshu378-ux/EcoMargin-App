package com.ecomargin.config;

import com.ecomargin.ocpp.websocket.OcppWebSocketHandler;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class OcppWebSocketConfig implements WebSocketConfigurer {

    private final OcppWebSocketHandler ocppWebSocketHandler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(ocppWebSocketHandler, "/ocpp/{chargeBoxId}")
                .setAllowedOrigins("*")
                // Register sub-protocols. OCPP 1.6J uses "ocpp1.6"
                .setHandshakeHandler(new org.springframework.web.socket.server.support.DefaultHandshakeHandler() {
                    @Override
                    protected String[] getSupportedProtocols() {
                        return new String[]{"ocpp1.6", "ocpp2.0.1"};
                    }
                });
    }
}
