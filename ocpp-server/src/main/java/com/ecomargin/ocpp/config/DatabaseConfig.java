package com.ecomargin.ocpp.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.net.URI;
import java.net.URISyntaxException;

@Configuration
public class DatabaseConfig {

    @Value("${SPRING_DATASOURCE_URL:#{null}}")
    private String springDatasourceUrl;

    @Value("${DATABASE_URL:#{null}}")
    private String databaseUrl;

    @Value("${SPRING_DATASOURCE_USERNAME:#{null}}")
    private String springDatasourceUsername;

    @Value("${SPRING_DATASOURCE_PASSWORD:#{null}}")
    private String springDatasourcePassword;

    @Bean
    @Primary
    public DataSource dataSource() {
        String rawUrl = StringUtils.hasText(databaseUrl) ? databaseUrl : springDatasourceUrl;

        // Fallback to H2 in-memory DB ONLY when no external DB URL is provided
        if (!StringUtils.hasText(rawUrl)) {
            HikariConfig h2Config = new HikariConfig();
            h2Config.setDriverClassName("org.h2.Driver");
            h2Config.setJdbcUrl("jdbc:h2:mem:ocppdevdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL");
            h2Config.setUsername("sa");
            h2Config.setPassword("sa");
            return new HikariDataSource(h2Config);
        }

        HikariConfig config = new HikariConfig();

        // Check if raw URL is PostgreSQL (postgresql://, postgres://, or jdbc:postgresql:)
        boolean isPostgres = rawUrl.startsWith("postgres://") || 
                             rawUrl.startsWith("postgresql://") || 
                             rawUrl.startsWith("jdbc:postgresql:");

        if (isPostgres) {
            config.setDriverClassName("org.postgresql.Driver");

            String username = springDatasourceUsername;
            String password = springDatasourcePassword;

            if (rawUrl.startsWith("postgres://") || rawUrl.startsWith("postgresql://")) {
                try {
                    String uriString = rawUrl;
                    if (uriString.startsWith("postgresql://")) {
                        uriString = "http://" + uriString.substring(13);
                    } else if (uriString.startsWith("postgres://")) {
                        uriString = "http://" + uriString.substring(11);
                    }

                    URI uri = new URI(uriString);
                    String host = uri.getHost();
                    int port = uri.getPort() == -1 ? 5432 : uri.getPort();
                    String path = uri.getPath();
                    String query = uri.getQuery();

                    // Extract credentials embedded in DATABASE_URL URI
                    if (uri.getUserInfo() != null) {
                        String[] userInfo = uri.getUserInfo().split(":", 2);
                        username = userInfo[0];
                        if (userInfo.length > 1) {
                            password = userInfo[1];
                        }
                    }

                    StringBuilder jdbcUrl = new StringBuilder();
                    jdbcUrl.append("jdbc:postgresql://").append(host).append(":").append(port).append(path);
                    if (StringUtils.hasText(query)) {
                        jdbcUrl.append("?").append(query);
                        if (!query.contains("sslmode=")) {
                            jdbcUrl.append("&sslmode=require");
                        }
                    } else {
                        jdbcUrl.append("?sslmode=require");
                    }

                    config.setJdbcUrl(jdbcUrl.toString());
                    org.slf4j.LoggerFactory.getLogger(DatabaseConfig.class)
                            .info("[DATABASE-CONFIG] Connecting to PostgreSQL at host={}, db={}, user={}", host, path, username);
                } catch (URISyntaxException e) {
                    String jdbcUrl = rawUrl;
                    if (!jdbcUrl.startsWith("jdbc:")) {
                        jdbcUrl = "jdbc:" + jdbcUrl;
                    }
                    if (!jdbcUrl.contains("sslmode=")) {
                        jdbcUrl += (jdbcUrl.contains("?") ? "&" : "?") + "sslmode=require";
                    }
                    config.setJdbcUrl(jdbcUrl);
                }
            } else {
                // Already jdbc:postgresql:
                String jdbcUrl = rawUrl;
                if (!jdbcUrl.contains("sslmode=")) {
                    jdbcUrl += (jdbcUrl.contains("?") ? "&" : "?") + "sslmode=require";
                }
                config.setJdbcUrl(jdbcUrl);
            }

            if (StringUtils.hasText(username)) {
                config.setUsername(username);
            }
            if (StringUtils.hasText(password)) {
                config.setPassword(password);
            }
        } else {
            // H2 or other JDBC fallback
            config.setDriverClassName("org.h2.Driver");
            config.setJdbcUrl(rawUrl);
            if (StringUtils.hasText(springDatasourceUsername)) {
                config.setUsername(springDatasourceUsername);
            }
            if (StringUtils.hasText(springDatasourcePassword)) {
                config.setPassword(springDatasourcePassword);
            }
        }

        config.setMaximumPoolSize(10);
        config.setMinimumIdle(2);
        config.setIdleTimeout(30000);
        config.setConnectionTimeout(20000);

        return new HikariDataSource(config);
    }
}
