package com.ecomargin.controller;

import com.ecomargin.model.User;
import com.ecomargin.model.Vendor;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.VendorRepository;
import com.ecomargin.websocket.telemetry.LiveTelemetryBroadcaster;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/v1/events")
@RequiredArgsConstructor
public class LiveEventController {

    private final LiveTelemetryBroadcaster telemetryBroadcaster;
    private final UserRepository userRepository;
    private final VendorRepository vendorRepository;

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamEvents() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = null;
        if (principal instanceof User) {
            user = (User) principal;
        } else {
            String email = SecurityContextHolder.getContext().getAuthentication().getName();
            user = userRepository.findByEmailIgnoreCase(email).orElse(null);
        }

        if (user == null) {
            log.warn("[SSE-STREAM] Unauthenticated client subscription attempt.");
            SseEmitter emitter = new SseEmitter(1000L);
            emitter.completeWithError(new RuntimeException("Unauthorized"));
            return emitter;
        }

        boolean isAdmin = user.getRoles().stream().anyMatch(r -> "ROLE_ADMIN".equals(r.getName().name()));
        boolean isVendor = user.getRoles().stream().anyMatch(r -> "ROLE_VENDOR".equals(r.getName().name()));

        if (isAdmin) {
            log.info("[SSE-STREAM] Admin subscribed to all live telemetry events. userId={}", user.getId());
            return telemetryBroadcaster.subscribeAdmin();
        } else if (isVendor) {
            Long vendorId = user.getId();
            Optional<Vendor> vOpt = vendorRepository.findByUserId(user.getId());
            if (vOpt.isPresent()) {
                vendorId = vOpt.get().getId();
            }
            log.info("[SSE-STREAM] Vendor subscribed to live telemetry. vendorId={}, userId={}", vendorId, user.getId());
            return telemetryBroadcaster.subscribeVendor(vendorId);
        } else {
            log.info("[SSE-STREAM] Customer subscribed to live session telemetry. userId={}", user.getId());
            return telemetryBroadcaster.subscribeCustomer(user.getId());
        }
    }
}
