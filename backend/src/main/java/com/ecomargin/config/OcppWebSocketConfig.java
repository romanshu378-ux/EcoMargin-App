package com.ecomargin.config;

import com.ecomargin.ocpp.websocket.OcppWebSocketHandler;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;

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
                .setHandshakeHandler(new DefaultHandshakeHandler() {
                    @Override
                    public String[] getSupportedProtocols() {
                        return new String[]{"ocpp1.6", "ocpp2.0.1"};
                    }
                });
    }
}
