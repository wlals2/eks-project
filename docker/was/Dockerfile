FROM maven:3.8-amazoncorretto-17 AS builder

WORKDIR /build

COPY pom.xml .
COPY src ./src

RUN mvn clean package -P MySQL -DskipTests

FROM tomcat:9.0.110-jre17

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=builder /build/target/*.war /usr/local/tomcat/webapps/petclinic.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
