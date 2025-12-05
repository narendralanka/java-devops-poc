# Use a small JRE base image
FROM eclipse-temurin:17-jre-alpine

# Argument to find the built jar
ARG JAR_FILE=target/*.jar

# Copy the jar into the image
COPY ${JAR_FILE} app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","/app.jar"]
