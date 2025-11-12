# ====================
# Stage 1: 빌드 단계
# ====================
FROM maven:3.8-amazoncorretto-17 AS builder

# 작업 디렉토리 설정
WORKDIR /build

# pom.xml과 소스 코드 복사
COPY pom.xml .
COPY src ./src

# Maven 빌드 (WAR 파일 생성)
# -DskipTests: 테스트 스킵 (빠른 빌드)
RUN mvn clean package -P MySQL -DskipTests

# 빌드 결과 확인
# target/petclinic.war 생성됨
RUN ls -lh /build/target/

# ====================
# Stage 2: 실행 단계
# ====================
FROM tomcat:9.0.110-jre17

# Tomcat 기본 앱 제거 (불필요)
RUN rm -rf /usr/local/tomcat/webapps/*

# Stage 1에서 빌드한 WAR 파일 복사
# /usr/local/tomcat/webapps/petclinic.war로 배치
COPY --from=builder /build/target/*.war /usr/local/tomcat/webapps/petclinic.war

# 포트 노출
EXPOSE 8080

# Tomcat 실행
CMD ["catalina.sh", "run"]
