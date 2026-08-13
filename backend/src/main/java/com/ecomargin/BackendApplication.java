package com.ecomargin;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableAsync
@EnableScheduling
@SpringBootApplication
public class BackendApplication {
    public static void main(String[] args) {
        String dbUrl = System.getenv("SPRING_DATASOURCE_URL");
        if (dbUrl != null && !dbUrl.isBlank()) {
            if (dbUrl.startsWith("postgres://")) {
                dbUrl = "jdbc:postgresql://" + dbUrl.substring(11);
                System.setProperty("SPRING_DATASOURCE_URL", dbUrl);
                System.setProperty("spring.datasource.url", dbUrl);
            } else if (dbUrl.startsWith("postgresql://")) {
                dbUrl = "jdbc:postgresql://" + dbUrl.substring(13);
                System.setProperty("SPRING_DATASOURCE_URL", dbUrl);
                System.setProperty("spring.datasource.url", dbUrl);
            }
        }
        SpringApplication.run(BackendApplication.class, args);
    }
}
