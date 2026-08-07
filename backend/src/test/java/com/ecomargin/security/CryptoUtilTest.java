package com.ecomargin.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

class CryptoUtilTest {

    private CryptoUtil cryptoUtil;
    private static final String SECRET_KEY = "404E635266556A586E3272357538782F"; // 32-byte key (256-bit)

    @BeforeEach
    void setUp() {
        cryptoUtil = new CryptoUtil();
        // Manually inject value normally wired by Spring property sources
        ReflectionTestUtils.setField(cryptoUtil, "secretKey", SECRET_KEY);
    }

    @Test
    void testEncryptDecryptSuccessful() {
        String originalText = "Sensitive-Tax-ID-12345";
        
        String encrypted = cryptoUtil.encrypt(originalText);
        assertNotNull(encrypted);
        assertNotEquals(originalText, encrypted);

        String decrypted = cryptoUtil.decrypt(encrypted);
        assertEquals(originalText, decrypted);
    }

    @Test
    void testDecryptFailsForModifiedCiphertext() {
        String originalText = "TestValue";
        String encrypted = cryptoUtil.encrypt(originalText);
        
        // Corrupt the ciphertext to trigger validation exception on decrypt
        String corrupted = encrypted.substring(0, encrypted.length() - 4) + "AAAA";

        assertThrows(RuntimeException.class, () -> cryptoUtil.decrypt(corrupted));
    }
}
