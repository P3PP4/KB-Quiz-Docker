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

# gradlew 권한 부여 함수
set_permissions() {
    log_info "Setting execute permissions for gradlew files..."
    
    chmod +x KB-Quiz-ServiceDiscovery/ServiceDiscovery/gradlew
    chmod +x KB-Quiz-APIGateway/APIGateway/gradlew
    chmod +x KB-Quiz-UserService/UserService/gradlew
    chmod +x KB-Quiz-QuizService/QuizService/gradlew
    
    log_info "Permissions set successfully"
}

# Gradle 빌드 함수
build_gradle() {
    local service=$1
    local path=$2
    
    log_info "Building $service..."
    cd $path
    ./gradlew clean build -x test
    if [ $? -eq 0 ]; then
        log_info "$service built successfully"
    else
        log_warning "$service build failed"
        exit 1
    fi
    cd ../..
}

# 전체 빌드 함수
build_all() {
    log_info "Starting Gradle builds..."

    # Service Discovery 빌드
    build_gradle "Service Discovery" "KB-Quiz-ServiceDiscovery/ServiceDiscovery"
    
    # API Gateway 빌드
    build_gradle "API Gateway" "KB-Quiz-APIGateway/APIGateway"
    
    # User Service 빌드
    build_gradle "User Service" "KB-Quiz-UserService/UserService"
    
    # Quiz Service 빌드
    build_gradle "Quiz Service" "KB-Quiz-QuizService/QuizService"
    
    log_info "All Gradle builds completed"
}

# Docker 빌드 및 실행
docker_build_run() {
    log_info "Starting Docker build and run..."
    docker-compose down

    
    # 특정 서비스만 재빌드
    docker-compose build service-discovery api-gateway user-service quiz-service --no-cache
    
    # 모든 서비스 시작
    docker-compose up -d
    
    log_info "Docker services are up and running"
}

# 메인 실행 함수
main() {
    log_info "Starting build process..."
    
    # gradlew 권한 부여
    set_permissions
    
    # Gradle 빌드 실행
    build_all
    
    # Docker 빌드 및 실행
    docker_build_run
    
    echo
    log_info "Build complete! Services are running."
    echo
    log_info "To check service status:"
    echo "docker-compose ps"
    echo "docker-compose logs -f"
}

# 스크립트 실행
main
