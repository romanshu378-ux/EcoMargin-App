package com.ecomargin.security;

import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

@Service
public class TotpService {

    private static final int TIME_WINDOW_SECONDS = 30;
    private static final int CODE_LENGTH = 6;

    public String generateSecretKey() {
        SecureRandom random = new SecureRandom();
        byte[] bytes = new byte[20];
        random.nextBytes(bytes);
        // Base64 encoding for key distribution
        return Base64.getEncoder().encodeToString(bytes);
    }

    public boolean verifyCode(String secretKey, int code) {
        long currentInterval = System.currentTimeMillis() / 1000 / TIME_WINDOW_SECONDS;

        // Allow a variance window of 1 interval before and after to account for network latency
        for (int i = -1; i <= 1; i++) {
            if (generateTotp(secretKey, currentInterval + i) == code) {
                return true;
            }
        }
        return false;
    }

    private int generateTotp(String secretKey, long timeInterval) {
        try {
            byte[] key = Base64.getDecoder().decode(secretKey);
            byte[] data = new byte[8];
            long value = timeInterval;
            
            for (int i = 7; i >= 0; i--) {
                data[i] = (byte) (value & 0xFF);
                value >>= 8;
            }

            SecretKeySpec signKey = new SecretKeySpec(key, "HmacSHA1");
            Mac mac = Mac.getInstance("HmacSHA1");
            mac.init(signKey);
            byte[] hash = mac.doFinal(data);

            int offset = hash[hash.length - 1] & 0xF;
            long truncatedHash = 0;
            
            for (int i = 0; i < 4; ++i) {
                truncatedHash <<= 8;
                truncatedHash |= (hash[offset + i] & 0xFF);
            }

            truncatedHash &= 0x7FFFFFFF;
            truncatedHash %= Math.pow(10, CODE_LENGTH);

            return (int) truncatedHash;
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            throw new RuntimeException("Error generating TOTP code", e);
        }
    }
}
