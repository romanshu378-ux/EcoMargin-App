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
import org.springframework.data.repository.Repository;
import org.springframework.security.web.SecurityFilterChain;

import java.lang.management.ManagementFactory;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * TEMPORARY STARTUP DIAGNOSTIC
 * Deduplicated, millisecond-accurate timing logger across all Spring Boot deployment lifecycle stages.
 */
@Slf4j
@Configuration
public class StartupTimingDiagnostic implements BeanPostProcessor {

    private final long startTimeMs = ManagementFactory.getRuntimeMXBean().getStartTime();
    private final Map<String, Long> beanStartTimes = new ConcurrentHashMap<>();
    private final AtomicInteger repositoryCount = new AtomicInteger(0);
    private long firstRepoStartMs = -1;
    private long lastRepoEndMs = -1;

    private long getElapsed() {
        return System.currentTimeMillis() - startTimeMs;
    }

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        long now = getElapsed();
        beanStartTimes.put(beanName, now);

        if ("entityManagerFactory".equals(beanName)) {
            log.info("[TIMING] EntityManagerFactory initialization START elapsed={}ms", now);
        } else if ("dataSource".equals(beanName)) {
            log.info("[TIMING] Hikari DataSource initialization START elapsed={}ms", now);
        } else if ("securityFilterChain".equals(beanName)) {
            log.info("[TIMING] SecurityFilterChain initialization START elapsed={}ms", now);
        } else if ("redisConnectionFactory".equals(beanName) || "stringRedisTemplate".equals(beanName)) {
            log.info("[TIMING] Redis Component '{}' initialization START elapsed={}ms", beanName, now);
        } else if (bean instanceof Repository || beanName.endsWith("Repository")) {
            int count = repositoryCount.incrementAndGet();
            if (firstRepoStartMs < 0) {
                firstRepoStartMs = now;
                log.info("[TIMING] Repository Proxy Initialization START elapsed={}ms (First Repo: {})", now, beanName);
            }
        }
        return bean;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        long now = getElapsed();
        Long startMs = beanStartTimes.remove(beanName);
        long duration = (startMs != null) ? (now - startMs) : 0;

        if ("entityManagerFactory".equals(beanName)) {
            log.info("[TIMING] EntityManagerFactory initialization COMPLETE elapsed={}ms (Duration: {}ms)", now, duration);
        } else if ("securityFilterChain".equals(beanName)) {
            log.info("[TIMING] SecurityFilterChain initialization COMPLETE elapsed={}ms (Duration: {}ms)", now, duration);
        } else if ("redisConnectionFactory".equals(beanName) || "stringRedisTemplate".equals(beanName)) {
            log.info("[TIMING] Redis Component '{}' initialization COMPLETE elapsed={}ms (Duration: {}ms)", beanName, now, duration);
        } else if (bean instanceof Repository || beanName.endsWith("Repository")) {
            lastRepoEndMs = now;
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
                    log.info("[TIMING] Flyway migration START elapsed={}ms", getElapsed());
                } else if (event == Event.AFTER_MIGRATE) {
                    log.info("[TIMING] Flyway migration COMPLETE elapsed={}ms", getElapsed());
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
        long now = getElapsed();
        log.info("[TIMING] Context refresh COMPLETE elapsed={}ms", now);
        if (firstRepoStartMs > 0 && lastRepoEndMs > 0) {
            log.info("[TIMING] Total Repository Initialization: {} repos processed in {}ms (From {}ms to {}ms)",
                    repositoryCount.get(), (lastRepoEndMs - firstRepoStartMs), firstRepoStartMs, lastRepoEndMs);
        }
    }

    @EventListener
    public void onWebServerInitialized(WebServerInitializedEvent event) {
        log.info("[TIMING] Tomcat HTTP Connector BOUND on port {} elapsed={}ms",
                event.getWebServer().getPort(), getElapsed());
    }

    @EventListener
    public void onApplicationReady(ApplicationReadyEvent event) {
        log.info("[TIMING] ApplicationReadyEvent elapsed={}ms (TOTAL STARTUP TIME)", getElapsed());
    }
}
