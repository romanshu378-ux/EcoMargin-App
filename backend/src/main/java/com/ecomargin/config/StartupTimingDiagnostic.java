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

import java.lang.management.ClassLoadingMXBean;
import java.lang.management.GarbageCollectorMXBean;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.OperatingSystemMXBean;
import java.lang.management.ThreadMXBean;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * TEMPORARY STARTUP DIAGNOSTIC
 * Millisecond-accurate timing logger with JVM CPU, Thread State, GC, & Background Thread Sampler.
 */
@Slf4j
@Configuration
public class StartupTimingDiagnostic implements BeanPostProcessor {

    private final long startTimeMs = ManagementFactory.getRuntimeMXBean().getStartTime();
    private final Thread mainThread = Thread.currentThread();
    private final Map<String, Long> beanStartTimes = new ConcurrentHashMap<>();
    private final AtomicInteger repositoryCount = new AtomicInteger(0);
    private long firstRepoStartMs = -1;
    private long lastRepoEndMs = -1;
    private volatile boolean samplingActive = true;

    public StartupTimingDiagnostic() {
        Thread samplerThread = new Thread(() -> {
            String lastLoggedKey = "";
            while (samplingActive) {
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
                if (!samplingActive) break;

                try {
                    Thread.State state = mainThread.getState();
                    if (state != Thread.State.RUNNABLE) {
                        StackTraceElement[] stack = mainThread.getStackTrace();
                        if (stack != null && stack.length > 0) {
                            String topFrame = stack[0].getClassName() + "." + stack[0].getMethodName() + ":" + stack[0].getLineNumber();
                            String callingFrame = (stack.length > 1) ? stack[1].getClassName() + "." + stack[1].getMethodName() + ":" + stack[1].getLineNumber() : "";
                            String currentKey = state + "|" + topFrame;
                            if (!currentKey.equals(lastLoggedKey)) {
                                lastLoggedKey = currentKey;
                                log.info("[THREAD-WAIT-DIAGNOSTIC] elapsed={}ms | MainThreadState={} | TopFrame={} | CallingFrame={}",
                                        getElapsed(), state, topFrame, callingFrame);
                            }
                        }
                    }
                } catch (Throwable ignored) {
                }
            }
        }, "diagnostic-thread-sampler");
        samplerThread.setDaemon(true);
        samplerThread.setPriority(Thread.MIN_PRIORITY);
        samplerThread.start();
    }

    private long getElapsed() {
        return System.currentTimeMillis() - startTimeMs;
    }

    private void logJvmStats(String stage) {
        long elapsedMs = getElapsed();
        ThreadMXBean threadBean = ManagementFactory.getThreadMXBean();
        long cpuTimeMs = threadBean.isThreadCpuTimeSupported() ? threadBean.getThreadCpuTime(mainThread.getId()) / 1_000_000L : -1;
        
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
        long heapUsedMb = memoryBean.getHeapMemoryUsage().getUsed() / (1024 * 1024);
        long heapMaxMb = memoryBean.getHeapMemoryUsage().getMax() / (1024 * 1024);
        
        ClassLoadingMXBean classBean = ManagementFactory.getClassLoadingMXBean();
        int loadedClassCount = classBean.getLoadedClassCount();
        
        long totalGcCount = 0;
        long totalGcTimeMs = 0;
        for (GarbageCollectorMXBean gcBean : ManagementFactory.getGarbageCollectorMXBeans()) {
            long count = gcBean.getCollectionCount();
            long time = gcBean.getCollectionTime();
            if (count > 0) totalGcCount += count;
            if (time > 0) totalGcTimeMs += time;
        }

        double processCpuLoadPct = -1;
        double systemCpuLoadPct = -1;
        try {
            OperatingSystemMXBean osBean = ManagementFactory.getOperatingSystemMXBean();
            if (osBean instanceof com.sun.management.OperatingSystemMXBean sunOsBean) {
                processCpuLoadPct = sunOsBean.getProcessCpuLoad() * 100.0;
                systemCpuLoadPct = sunOsBean.getCpuLoad() * 100.0;
            }
        } catch (Throwable ignored) {
        }
        
        log.info("[JVM-DIAGNOSTIC] Stage='{}' elapsed={}ms | MainThreadState={} | MainThreadCpuTime={}ms | ProcessCpu={}% | SystemCpu={}% | HeapUsed={}MB/{}MB | LoadedClasses={} | TotalGcCount={} | TotalGcTime={}ms",
                stage, elapsedMs, mainThread.getState(), cpuTimeMs,
                String.format("%.1f", processCpuLoadPct), String.format("%.1f", systemCpuLoadPct),
                heapUsedMb, heapMaxMb, loadedClassCount, totalGcCount, totalGcTimeMs);
    }

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        long now = getElapsed();
        beanStartTimes.put(beanName, now);

        if ("entityManagerFactory".equals(beanName)) {
            log.info("[TIMING] EntityManagerFactory initialization START elapsed={}ms", now);
            logJvmStats("EntityManagerFactory-START");
        } else if ("dataSource".equals(beanName)) {
            log.info("[TIMING] Hikari DataSource initialization START elapsed={}ms", now);
            logJvmStats("Hikari-START");
        } else if ("securityFilterChain".equals(beanName)) {
            log.info("[TIMING] SecurityFilterChain initialization START elapsed={}ms", now);
            logJvmStats("SecurityFilterChain-START");
        } else if ("redisConnectionFactory".equals(beanName) || "stringRedisTemplate".equals(beanName)) {
            log.info("[TIMING] Redis Component '{}' initialization START elapsed={}ms", beanName, now);
        } else if (bean instanceof Repository || beanName.endsWith("Repository")) {
            int count = repositoryCount.incrementAndGet();
            if (firstRepoStartMs < 0) {
                firstRepoStartMs = now;
                log.info("[TIMING] Repository Proxy Initialization START elapsed={}ms (First Repo: {})", now, beanName);
                logJvmStats("Repositories-START");
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
            logJvmStats("EntityManagerFactory-COMPLETE");
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
                    logJvmStats("Flyway-START");
                } else if (event == Event.AFTER_MIGRATE) {
                    log.info("[TIMING] Flyway migration COMPLETE elapsed={}ms", getElapsed());
                    logJvmStats("Flyway-COMPLETE");
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
        log.info("[OCPP-STARTUP] JPA initialized");
        log.info("[OCPP-STARTUP] WebSocket initialized");
        logJvmStats("ContextRefreshed");
        if (firstRepoStartMs > 0 && lastRepoEndMs > 0) {
            log.info("[TIMING] Total Repository Initialization: {} repos processed in {}ms (From {}ms to {}ms)",
                    repositoryCount.get(), (lastRepoEndMs - firstRepoStartMs), firstRepoStartMs, lastRepoEndMs);
        }
    }

    @EventListener
    public void onWebServerInitialized(WebServerInitializedEvent event) {
        int boundPort = event.getWebServer().getPort();
        log.info("[TIMING] Tomcat HTTP Connector BOUND on port {} elapsed={}ms", boundPort, getElapsed());
        log.info("[OCPP-STARTUP] HTTP server ready");
        log.info("[OCPP-STARTUP] PORT={}", boundPort);
        log.info("[OCPP-STARTUP] HOST=0.0.0.0");
        logJvmStats("Tomcat-Bound");
    }

    @EventListener
    public void onApplicationReady(ApplicationReadyEvent event) {
        samplingActive = false;
        log.info("[OCPP-STARTUP] Application READY");
        log.info("[TIMING] ApplicationReadyEvent elapsed={}ms (TOTAL STARTUP TIME)", getElapsed());
        logJvmStats("ApplicationReady");
    }
}
