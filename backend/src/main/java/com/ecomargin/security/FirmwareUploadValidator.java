package com.ecomargin.security;

import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;

@Component
public class FirmwareUploadValidator {

    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB maximum
    private static final List<String> ALLOWED_EXTENSIONS = Arrays.asList("bin", "hex", "tar");

    // Whitelist magic numbers (first 4 bytes of files) to prevent extension spoofing
    private static final List<byte[]> ALLOWED_MAGIC_NUMBERS = Arrays.asList(
            new byte[]{(byte) 0x7F, 'E', 'L', 'F'}, // ELF executable header
            new byte[]{(byte) 0x1F, (byte) 0x8B, 0x08, 0x00} // gzip compressed tar archive
    );

    public void validate(MultipartFile file) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("Upload failed: File is empty");
        }

        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("Upload failed: File size exceeds the maximum limit of 10MB");
        }

        String filename = file.getOriginalFilename();
        if (filename == null || !filename.contains(".")) {
            throw new IllegalArgumentException("Upload failed: Invalid file extension configuration");
        }

        String extension = filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new IllegalArgumentException("Upload failed: File type not supported. Allowed formats: .bin, .hex, .tar");
        }

        try (InputStream is = file.getInputStream()) {
            byte[] fileHeader = new byte[4];
            int bytesRead = is.read(fileHeader);
            
            if (bytesRead < 4) {
                throw new IllegalArgumentException("Upload failed: File structure is corrupted");
            }

            // In a production setup, we compare headers against whitelist magic numbers
            // bypassing strict byte checks for text-based hex files but raising alarms if mismatch
            boolean isAllowedMagicNumber = false;
            for (byte[] magicNumber : ALLOWED_MAGIC_NUMBERS) {
                if (Arrays.equals(magicNumber, fileHeader)) {
                    isAllowedMagicNumber = true;
                    break;
                }
            }

            // We permit .hex files to bypass magic byte arrays since they start as textual lines
            if (!isAllowedMagicNumber && !"hex".equals(extension)) {
                throw new IllegalArgumentException("Upload failed: File content validation failed (MIME type mismatch)");
            }

        } catch (IOException e) {
            throw new RuntimeException("Upload failed: Could not read file content stream", e);
        }
    }
}
