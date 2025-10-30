# Stage 1: Build stage
FROM maven:3.8.5-openjdk-17 AS builder

# Set working directory for build
WORKDIR /build

# Copy source code and pom.xml
COPY src ./src
COPY pom.xml .

# Package the application and copy JAR to home directory
RUN mvn clean package -DskipTests && \
cp target/*.jar /home/app.jar
# Stage 2: Runtime stage
FROM openjdk:17-jdk-slim

# Create non-root user for security
RUN groupadd -r spring && useradd -r -g spring spring

# Create app directory
WORKDIR /app

# Copy JAR file from build stage
COPY --from=builder /home/app.jar app.jar

# Change ownership to spring user
RUN chown -R spring:spring /app

# Switch to non-root user
USER spring

# Expose port
EXPOSE 8080

# Add health check (install curl first)
USER root
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
USER spring

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the application with optimized JVM settings
ENTRYPOINT ["java", "-jar", \
            "-Dspring.profiles.active=docker", \
            "-Djava.security.egd=file:/dev/./urandom", \
            "-XX:+UseContainerSupport", \
            "-XX:MaxRAMPercentage=75.0", \
            "app.jar"]
