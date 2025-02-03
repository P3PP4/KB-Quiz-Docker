#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# MySQL 설정 파일 생성 함수
create_mysql_configs() {
    log_info "Creating MySQL configurations..."
    
    mkdir -p configs
    cat > configs/my.cnf << EOF
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
skip-character-set-client-handshake
default-storage-engine=INNODB
explicit_defaults_for_timestamp=1
max_connections=100
default-time-zone='+09:00'

[mysql]
default-character-set=utf8mb4

[client]
default-character-set=utf8mb4
EOF

    log_info "Created MySQL configuration files"
}

# Dockerfile 생성 함수
create_dockerfiles() {
    # Service Discovery Dockerfile
    cat > KB-Quiz-ServiceDiscovery/ServiceDiscovery/Dockerfile << EOF
FROM azul/zulu-openjdk:21.0.6
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8761
RUN apt update && apt install -y curl
ENTRYPOINT ["java", "--enable-preview", "-jar", "app.jar"]
EOF

    # API Gateway Dockerfile
    cat > KB-Quiz-APIGateway/APIGateway/Dockerfile << EOF
FROM azul/zulu-openjdk:21.0.6
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 9000
RUN apt update && apt install -y curl
ENTRYPOINT ["java", "--enable-preview", "-jar", "app.jar"]
EOF

    # User Service Dockerfile
    cat > KB-Quiz-UserService/UserService/Dockerfile << EOF
FROM azul/zulu-openjdk:21.0.6
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8081
RUN apt update && apt install -y curl
ENTRYPOINT ["java", "--enable-preview", "-jar", "app.jar"]
EOF

    # Quiz Service Dockerfile
    cat > KB-Quiz-QuizService/QuizService/Dockerfile << EOF
FROM azul/zulu-openjdk:21.0.6
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8082
RUN apt update && apt install -y curl
ENTRYPOINT ["java", "--enable-preview", "-jar", "app.jar"]
EOF

    log_info "Created Dockerfiles for all services with Azul Zulu JDK 21"
}

# docker-compose.yml 생성 함수
create_docker_compose() {
    cat > docker-compose.yml << EOF
version: "3.8"

services:
  mysql:
    image: mysql:8.0
    container_name: mysql_db
    platform: linux/amd64
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: userdb
      MYSQL_USER: myuser
      MYSQL_PASSWORD: mypassword
      MYSQL_ROOT_HOST: "%"
      TZ: Asia/Seoul
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./configs/my.cnf:/etc/mysql/conf.d/my.cnf
      - ./init:/docker-entrypoint-initdb.d
    networks:
      - microservice-network
    healthcheck:
      test:
        [
          "CMD",
          "mysqladmin",
          "ping",
          "-h",
          "localhost",
          "-u",
          "root",
          "-p${MYSQL_ROOT_PASSWORD}",
        ]
      interval: 30s
      timeout: 10s
      retries: 5

  service-discovery:
    build:
      context: ./KB-Quiz-ServiceDiscovery/ServiceDiscovery
      dockerfile: Dockerfile
    container_name: service-discovery
    ports:
      - "8761:8761"
    networks:
      - microservice-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8761/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5

  api-gateway:
    build:
      context: ./KB-Quiz-APIGateway/APIGateway
      dockerfile: Dockerfile
    container_name: api-gateway
    ports:
      - "9000:9000"
    environment:
      - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-discovery:8761/eureka/
    networks:
      - microservice-network
    depends_on:
      service-discovery:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5

  user-service:
    build:
      context: ./KB-Quiz-UserService/UserService
      dockerfile: Dockerfile
    container_name: user-service
    ports:
      - "8081:8081"
    environment:
      - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-discovery:8761/eureka/
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/userdb
      - SPRING_DATASOURCE_USERNAME=myuser
      - SPRING_DATASOURCE_PASSWORD=mypassword
    networks:
      - microservice-network
    depends_on:
      mysql:
        condition: service_healthy
      api-gateway:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5

  quiz-service:
    build:
      context: ./KB-Quiz-QuizService/QuizService
      dockerfile: Dockerfile
    container_name: quiz-service
    ports:
      - "8082:8082"
    environment:
      - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-discovery:8761/eureka/
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/
      - SPRING_DATASOURCE_USERNAME=myuser
      - SPRING_DATASOURCE_PASSWORD=mypassword
    networks:
      - microservice-network
    depends_on:
      mysql:
        condition: service_healthy
      user-service:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8082/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5

networks:
  microservice-network:
    driver: bridge

volumes:
  mysql_data:
    driver: local
EOF

    log_info "Created docker-compose.yml"
}

# Gradle 빌드 함수
build_services() {
    log_info "Building services with Java 21..."

    # Service Discovery 빌드
    cd KB-Quiz-ServiceDiscovery/ServiceDiscovery
    ./gradlew clean build -x test
    cd ../..

    # API Gateway 빌드
    cd KB-Quiz-APIGateway/APIGateway
    ./gradlew clean build -x test
    cd ../..

    # User Service 빌드
    cd KB-Quiz-UserService/UserService
    ./gradlew clean build -x test
    cd ../..

    # Quiz Service 빌드
    cd KB-Quiz-QuizService/QuizService
    ./gradlew clean build -x test
    cd ../..

    log_info "All services built successfully"
}

# 메인 실행 함수
main() {
    log_info "Starting Docker setup for Quiz microservices with Azul Zulu JDK 21..."

    create_mysql_configs
    create_dockerfiles
    create_docker_compose
    build_services
    
    echo
    log_info "Setup complete! Follow these steps to run your services:"
    echo
    echo "1. Start all services:"
    echo "   docker-compose up -d"
    echo
    echo "2. Check the status:"
    echo "   docker-compose ps"
    echo "   docker-compose logs -f"
    echo
    echo "3. To stop the services:"
    echo "   docker-compose down"
    echo
    echo "4. MySQL connection info:"
    echo "   Host: localhost"
    echo "   Port: 3306"
    echo "   User: myuser"
    echo "   Password: mypassword"
    echo "   Databases: userdb, quizdb"
}

# 스크립트 실행
main
