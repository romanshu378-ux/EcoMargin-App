package com.ecomargin.controller;

import com.ecomargin.model.RfidCard;
import com.ecomargin.model.User;
import com.ecomargin.repository.RfidCardRepository;
import com.ecomargin.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/v1/rfid")
@RequiredArgsConstructor
public class RfidCardController {

    private final RfidCardRepository rfidCardRepository;
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

    @GetMapping
    public ResponseEntity<?> getRfidCard() {
        User user = getAuthenticatedUser();
        Optional<RfidCard> cardOpt = rfidCardRepository.findByUser(user);
        if (cardOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "No RFID card linked to this account."));
        }
        return ResponseEntity.ok(mapCardToMap(cardOpt.get()));
    }

    @PostMapping("/link")
    public ResponseEntity<?> linkRfidCard(@RequestBody Map<String, String> body) {
        User user = getAuthenticatedUser();

        String cardNumber = body.get("cardNumber");
        String cardUid = body.get("cardUid");
        String linkedVehicle = body.get("linkedVehicle");

        if (cardNumber == null || cardNumber.trim().isEmpty() ||
            cardUid == null || cardUid.trim().isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Card Number and Card UID are required."));
        }

        cardNumber = cardNumber.trim();
        cardUid = cardUid.trim();

        // 1. Check if this user already has a card linked
        if (rfidCardRepository.findByUser(user).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("message", "You already have an RFID card linked. Please unlink it first."));
        }

        // 2. Check if the card number is linked to another user
        Optional<RfidCard> existingByNo = rfidCardRepository.findByCardNumber(cardNumber);
        if (existingByNo.isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("message", "This Card Number is already registered to another account."));
        }

        // 3. Check if the card UID is linked to another user
        Optional<RfidCard> existingByUid = rfidCardRepository.findByCardUid(cardUid);
        if (existingByUid.isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("message", "This Card UID is already registered to another account."));
        }

        RfidCard card = RfidCard.builder()
                .user(user)
                .cardNumber(cardNumber)
                .cardUid(cardUid)
                .status("ACTIVE")
                .linkedVehicle(linkedVehicle != null && !linkedVehicle.trim().isEmpty() ? linkedVehicle.trim() : null)
                .issuedDate(LocalDate.now())
                .build();

        RfidCard saved = rfidCardRepository.save(card);
        log.info("[RFID] Linked RFID Card successfully: card_number={}", cardNumber);
        return ResponseEntity.status(HttpStatus.CREATED).body(mapCardToMap(saved));
    }

    @PostMapping("/unlink")
    public ResponseEntity<?> unlinkRfidCard() {
        User user = getAuthenticatedUser();
        Optional<RfidCard> cardOpt = rfidCardRepository.findByUser(user);
        if (cardOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "No RFID card found to unlink."));
        }

        rfidCardRepository.delete(cardOpt.get());
        log.info("[RFID] Unlinked RFID Card for user_id={}", user.getId());
        return ResponseEntity.ok(Map.of("message", "RFID card unlinked successfully."));
    }

    @PostMapping("/block")
    public ResponseEntity<?> blockRfidCard() {
        User user = getAuthenticatedUser();
        Optional<RfidCard> cardOpt = rfidCardRepository.findByUser(user);
        if (cardOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "No RFID card found to block."));
        }

        RfidCard card = cardOpt.get();
        card.setStatus("BLOCKED");
        rfidCardRepository.save(card);
        log.info("[RFID] Blocked RFID Card for user_id={}", user.getId());
        return ResponseEntity.ok(mapCardToMap(card));
    }

    private Map<String, Object> mapCardToMap(RfidCard card) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", card.getId());
        map.put("cardNumber", card.getCardNumber());
        map.put("cardUid", card.getCardUid());
        map.put("status", card.getStatus());
        map.put("linkedVehicle", card.getLinkedVehicle() != null ? card.getLinkedVehicle() : "");
        map.put("issuedDate", card.getIssuedDate() != null ? card.getIssuedDate().toString() : "");
        map.put("lastUsed", card.getLastUsed() != null ? card.getLastUsed().toString() : "");
        map.put("createdAt", card.getCreatedAt());
        map.put("updatedAt", card.getUpdatedAt());
        return map;
    }
}
