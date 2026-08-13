package com.ecomargin.ocpp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class OcppServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(OcppServerApplication.class, args);
    }
}
