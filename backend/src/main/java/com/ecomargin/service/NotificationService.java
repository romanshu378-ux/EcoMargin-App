package com.ecomargin.service;

import com.ecomargin.model.Notification;
import com.ecomargin.model.User;
import com.ecomargin.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    @Transactional
    public Notification createNotification(User user, String title, String message, String type) {
        if (user == null) return null;
        try {
            Notification notification = Notification.builder()
                    .user(user)
                    .title(title)
                    .message(message)
                    .type(type != null ? type : "SYSTEM")
                    .isRead(false)
                    .createdAt(LocalDateTime.now())
                    .build();
            Notification saved = notificationRepository.save(notification);
            log.info("Created notification [id={}, type={}] for user {}", saved.getId(), type, user.getEmail());
            return saved;
        } catch (Exception e) {
            log.error("Failed to create notification for user {}: {}", user.getEmail(), e.getMessage());
            return null;
        }
    }

    public List<Notification> getUserNotifications(User user) {
        try {
            return notificationRepository.findByUserOrderByCreatedAtDesc(user);
        } catch (Exception e) {
            log.error("Failed to fetch notifications for user {}: {}", user != null ? user.getEmail() : "null", e.getMessage());
            return Collections.emptyList();
        }
    }

    public long getUnreadCount(User user) {
        try {
            return notificationRepository.countUnreadForUser(user);
        } catch (Exception e) {
            log.error("Failed to count unread notifications for user {}: {}", user != null ? user.getEmail() : "null", e.getMessage());
            return 0;
        }
    }

    @Transactional
    public Notification markAsRead(User user, Long notificationId) {
        Notification notification = notificationRepository.findByIdAndUser(notificationId, user)
                .orElseThrow(() -> new RuntimeException("Notification not found or access denied"));
        notification.setRead(true);
        return notificationRepository.save(notification);
    }

    @Transactional
    public void markAllAsRead(User user) {
        try {
            notificationRepository.markAllAsReadForUser(user);
        } catch (Exception e) {
            log.error("Failed to mark all notifications as read for user {}: {}", user != null ? user.getEmail() : "null", e.getMessage());
        }
    }
}
