// TEMPORARY STARTUP DIAGNOSTIC
package com.ecomargin.config;

import lombok.extern.slf4j.Slf4j;
import org.flywaydb.core.api.callback.Callback;
import org.flywaydb.core.api.callback.Context;
import org.flywaydb.core.api.callback.Event;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.boot.autoconfigure.flyway.FlywayConfigurationCustomizer;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.boot.web.context.WebServerInitializedEvent;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;

import java.lang.management.ManagementFactory;

/**
 * TEMPORARY STARTUP DIAGNOSTIC
 * Measures exact millisecond timestamps across all Spring Boot deployment lifecycle stages.
 */
@Slf4j
@Configuration
public class StartupTimingDiagnostic implements BeanPostProcessor {

    private final long startTimeMs = ManagementFactory.getRuntimeMXBean().getStartTime();

    private long getElapsed() {
        return System.currentTimeMillis() - startTimeMs;
    }

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        if ("dataSource".equals(beanName) || beanName.toLowerCase().contains("hikari")) {
            log.info("[TIMING] Hikari start elapsed={}ms", getElapsed());
        } else if ("entityManagerFactory".equals(beanName) || beanName.toLowerCase().contains("entitymanagerfactory")) {
            log.info("[TIMING] EntityManagerFactory initialization start elapsed={}ms", getElapsed());
        } else if (beanName.toLowerCase().contains("tomcat") || beanName.toLowerCase().contains("servletwebserverfactory")) {
            log.info("[TIMING] Tomcat initialization elapsed={}ms", getElapsed());
        }
        return bean;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        if ("entityManagerFactory".equals(beanName) || beanName.toLowerCase().contains("entitymanagerfactory")) {
            log.info("[TIMING] EntityManagerFactory initialization completion elapsed={}ms", getElapsed());
        }
        return bean;
    }

    @Bean
    public FlywayConfigurationCustomizer flywayTimingCustomizer() {
        return configuration -> configuration.callbacks(new Callback() {
            @Override
            public boolean supports(Event event, Context context) {
                return event == Event.BEFORE_MIGRATE || event == Event.AFTER_MIGRATE;
            }

            @Override
            public boolean canHandleInTransaction(Event event, Context context) {
                return true;
            }

            @Override
            public void handle(Event event, Context context) {
                if (event == Event.BEFORE_MIGRATE) {
                    log.info("[TIMING] Flyway migration start elapsed={}ms", getElapsed());
                } else if (event == Event.AFTER_MIGRATE) {
                    log.info("[TIMING] Flyway migration completion elapsed={}ms", getElapsed());
                }
            }

            @Override
            public String getCallbackName() {
                return "FlywayTimingDiagnosticCallback";
            }
        });
    }

    @EventListener
    public void onContextRefreshed(ContextRefreshedEvent event) {
        log.info("[TIMING] Context refresh completion elapsed={}ms", getElapsed());
    }

    @EventListener
    public void onWebServerInitialized(WebServerInitializedEvent event) {
        log.info("[TIMING] Tomcat actually started / connector bound on port {} elapsed={}ms",
                event.getWebServer().getPort(), getElapsed());
    }

    @EventListener
    public void onApplicationReady(ApplicationReadyEvent event) {
        log.info("[TIMING] ApplicationReadyEvent elapsed={}ms (Total Startup Time)", getElapsed());
    }
}
