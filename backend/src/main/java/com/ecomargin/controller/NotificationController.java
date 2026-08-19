package com.ecomargin.controller;

import com.ecomargin.model.Notification;
import com.ecomargin.model.User;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    private User getAuthenticatedUser() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new RuntimeException("User not authenticated"));
    }

    private Map<String, Object> mapNotificationToMap(Notification n) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", n.getId());
        map.put("title", n.getTitle());
        map.put("message", n.getMessage());
        map.put("isRead", n.isRead());
        map.put("read", n.isRead());
        map.put("type", n.getType());
        map.put("createdAt", n.getCreatedAt());
        return map;
    }

    @GetMapping
    public ResponseEntity<?> getNotifications() {
        try {
            User user = getAuthenticatedUser();
            List<Notification> list = notificationService.getUserNotifications(user);
            List<Map<String, Object>> response = list.stream()
                    .map(this::mapNotificationToMap)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error retrieving user notifications: {}", e.getMessage());
            return ResponseEntity.ok(Collections.emptyList());
        }
    }

    @GetMapping("/unread-count")
    public ResponseEntity<?> getUnreadCount() {
        try {
            User user = getAuthenticatedUser();
            long count = notificationService.getUnreadCount(user);
            return ResponseEntity.ok(Map.of("unreadCount", count));
        } catch (Exception e) {
            log.error("Error retrieving unread notification count: {}", e.getMessage());
            return ResponseEntity.ok(Map.of("unreadCount", 0));
        }
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long id) {
        try {
            User user = getAuthenticatedUser();
            Notification updated = notificationService.markAsRead(user, id);
            return ResponseEntity.ok(mapNotificationToMap(updated));
        } catch (Exception e) {
            log.error("Error marking notification as read: {}", e.getMessage());
            return ResponseEntity.ok(Map.of("message", "Error marking notification as read"));
        }
    }

    @PostMapping("/read-all")
    public ResponseEntity<?> markAllAsRead() {
        try {
            User user = getAuthenticatedUser();
            notificationService.markAllAsRead(user);
            return ResponseEntity.ok(Map.of("message", "All notifications marked as read"));
        } catch (Exception e) {
            log.error("Error marking all notifications as read: {}", e.getMessage());
            return ResponseEntity.ok(Map.of("message", "Error marking notifications as read"));
        }
    }
}
