# Multi-stage Docker build for Standalone Java 21 OCPP 1.6-J Server
FROM maven:3.9.6-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copy POM and download dependencies
COPY pom.xml .
COPY src src
RUN mvn clean package -DskipTests

# Runtime Stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy compiled jar from build stage
COPY --from=build /app/target/ocpp-server-1.0.0.jar app.jar

EXPOSE 8081 10000

ENV PORT=10000

ENTRYPOINT ["java", "-jar", "app.jar"]
