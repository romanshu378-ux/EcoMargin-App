package com.ecomargin.repository;

import com.ecomargin.model.AuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, AuditLog.AuditLogId> {
    List<AuditLog> findTop100ByOrderByCreatedAtDesc();
    List<AuditLog> findByUserIdOrderByCreatedAtDesc(Long userId);
}
