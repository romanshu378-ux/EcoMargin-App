package com.ecomargin.service;

import com.ecomargin.model.AuditLog;
import com.ecomargin.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;

    public void logAction(Long userId, String performedBy, String action, String entityName, String entityId, String previousValue, String newValue, String ipAddress, String details) {
        try {
            AuditLog logEntry = AuditLog.builder()
                    .createdAt(LocalDateTime.now())
                    .userId(userId)
                    .performedBy(performedBy != null ? performedBy : "SYSTEM")
                    .action(action)
                    .entityName(entityName)
                    .entityId(entityId)
                    .previousValue(previousValue)
                    .newValue(newValue)
                    .ipAddress(ipAddress != null ? ipAddress : "127.0.0.1")
                    .details(details)
                    .build();
            auditLogRepository.save(logEntry);
            log.info("AUDIT LOG: [{}] by user {}: entity={} id={} prev={} new={}", action, performedBy, entityName, entityId, previousValue, newValue);
        } catch (Exception e) {
            log.error("Failed to write audit log entry: {}", e.getMessage(), e);
        }
    }

    public List<AuditLog> getRecentAuditLogs() {
        return auditLogRepository.findTop100ByOrderByCreatedAtDesc();
    }
}
