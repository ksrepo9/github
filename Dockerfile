FROM openjdk:17-jdk-slim

# Create non-root user for security
RUN groupadd -r spring && useradd -r -g spring spring

# Create app directory
WORKDIR /app

# Copy JAR file
COPY target/app-ver.jar app.jar

# Change ownership to spring user
RUN chown -R spring:spring /app

# Switch to non-root user
USER spring

# Expose port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the application with optimized JVM settings
ENTRYPOINT ["java", "-jar", \
            "-Dspring.profiles.active=docker", \
            "-Djava.security.egd=file:/dev/./urandom", \
            "-XX:+UseContainerSupport", \
            "-XX:MaxRAMPercentage=75.0", \
            "app.jar"]
