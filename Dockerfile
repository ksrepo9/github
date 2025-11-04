# ---- Stage 1: Build ----
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /build

# Leverage layer caching: copy pom.xml first, resolve deps
COPY pom.xml .
RUN mvn -B -q -e -DskipTests dependency:go-offline

# Copy sources and build
COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---- Stage 2: Runtime ----
FROM eclipse-temurin:17-jre-alpine

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

# Copy the fat jar from the build stage
COPY --from=builder /build/target/*-SNAPSHOT.jar /app/app.jar
# If your jar name isn’t -SNAPSHOT, use:
# COPY --from=builder /build/target/*.jar /app/app.jar

# Optional: minimal metadata
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8080

# Install curl for healthchecks only (Alpine)
RUN apk add --no-cache curl

# Healthcheck against Spring Boot Actuator (adjust path if needed)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:8080/actuator/health || exit 1

USER spring

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE -jar /app/app.jar"]
