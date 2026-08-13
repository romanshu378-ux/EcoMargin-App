package com.ecomargin.exception;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    private Map<String, Object> buildErrorResponse(HttpServletRequest request, String code, String message, Object details) {
        Map<String, Object> body = new HashMap<>();
        body.put("success", false);
        body.put("code", code);
        body.put("message", message);
        body.put("timestamp", LocalDateTime.now().toString());
        
        String requestId = (String) request.getAttribute("requestId");
        if (requestId == null) {
            requestId = request.getHeader("X-Request-ID");
        }
        body.put("requestId", requestId);
        
        if (details != null) {
            body.put("details", details);
        }
        return body;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationExceptions(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        return new ResponseEntity<>(buildErrorResponse(request, "VALIDATION_FAILED", "Invalid request parameters", errors), HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgumentException(IllegalArgumentException ex, HttpServletRequest request) {
        return new ResponseEntity<>(buildErrorResponse(request, "BAD_REQUEST", ex.getMessage(), null), HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(UserAlreadyExistsException.class)
    public ResponseEntity<Map<String, Object>> handleUserAlreadyExistsException(UserAlreadyExistsException ex, HttpServletRequest request) {
        log.warn("[AUTH] Registration conflict: {}", ex.getMessage());
        return new ResponseEntity<>(buildErrorResponse(request, "CONFLICT", ex.getMessage(), null), HttpStatus.CONFLICT);
    }

    @ExceptionHandler({
        BadCredentialsException.class,
        UsernameNotFoundException.class,
        DisabledException.class,
        LockedException.class,
        AuthenticationException.class
    })
    public ResponseEntity<Map<String, Object>> handleAuthenticationExceptions(Exception ex, HttpServletRequest request) {
        log.warn("[AUTH] Authentication failed: {}", ex.getMessage());
        String msg = (ex.getMessage() != null && !ex.getMessage().isBlank()) ? ex.getMessage() : "Invalid email or password";
        return new ResponseEntity<>(buildErrorResponse(request, "UNAUTHORIZED", msg, null), HttpStatus.UNAUTHORIZED);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDeniedException(AccessDeniedException ex, HttpServletRequest request) {
        log.warn("[AUTH] Access denied: {}", ex.getMessage());
        return new ResponseEntity<>(buildErrorResponse(request, "FORBIDDEN", "Access is denied", null), HttpStatus.FORBIDDEN);
    }

    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, Object>> handleDataIntegrityViolationException(org.springframework.dao.DataIntegrityViolationException ex, HttpServletRequest request) {
        log.warn("[DATABASE] Data integrity violation: {}", ex.getMessage());
        return new ResponseEntity<>(buildErrorResponse(request, "CONFLICT", "The provided information conflicts with an existing account or record.", null), HttpStatus.CONFLICT);
    }

    @ExceptionHandler({org.springframework.dao.DataAccessException.class, java.sql.SQLException.class})
    public ResponseEntity<Map<String, Object>> handleDatabaseExceptions(Exception ex, HttpServletRequest request) {
        log.error("[DATABASE ERROR] Database failure: ", ex);

        boolean isConnectionIssue = false;
        String msg = ex.getMessage() != null ? ex.getMessage() : "";
        if (ex instanceof org.springframework.dao.DataAccessResourceFailureException 
                || ex instanceof org.springframework.transaction.CannotCreateTransactionException
                || msg.contains("Connection refused")
                || msg.contains("connection timeout")
                || msg.contains("Connection timed out")
                || msg.contains("Cannot get JDBC Connection")) {
            isConnectionIssue = true;
        }

        if (isConnectionIssue) {
            return new ResponseEntity<>(buildErrorResponse(request, "SERVICE_UNAVAILABLE", "Service is temporarily unavailable. Please try again.", null), HttpStatus.SERVICE_UNAVAILABLE);
        } else {
            return new ResponseEntity<>(buildErrorResponse(request, "INTERNAL_SERVER_ERROR", "An unexpected error occurred. Please try again later.", null), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleAllOtherExceptions(Exception ex, HttpServletRequest request) {
        log.error("[SYSTEM ERROR] Unexpected internal exception: ({}: {})", ex.getClass().getName(), ex.getMessage(), ex);
        return new ResponseEntity<>(buildErrorResponse(request, "INTERNAL_SERVER_ERROR", "An unexpected error occurred. Please try again later.", null), HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
