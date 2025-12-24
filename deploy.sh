#!/bin/bash

# Habits Tracker - Production Deployment Script
# This script automates the deployment process for the habits tracker application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env file not found! Please create it from env.example"
        log_info "Run: cp env.example .env"
        exit 1
    fi
    log_success ".env file found"
}

# Check if required commands are available
check_dependencies() {
    local deps=("docker" "docker-compose")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "$dep is not installed or not in PATH"
            exit 1
        fi
    done
    log_success "All dependencies are available"
}

# Pull latest changes (if using git)
pull_latest_changes() {
    if [ -d ".git" ]; then
        log_info "Pulling latest changes from git..."
        git pull origin main
        log_success "Git pull completed"
    else
        log_warning "Not a git repository, skipping git pull"
    fi
}

# Build and start containers
deploy_containers() {
    log_info "Building and starting containers..."

    # Stop existing containers
    docker-compose -f "$COMPOSE_FILE" down || true

    # Build images
    docker-compose -f "$COMPOSE_FILE" build --no-cache

    # Start containers
    docker-compose -f "$COMPOSE_FILE" up -d

    log_success "Containers deployed successfully"
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    docker-compose -f "$COMPOSE_FILE" exec -T backend python manage.py migrate
    log_success "Database migrations completed"
}

# Collect static files
collect_static() {
    log_info "Collecting static files..."
    docker-compose -f "$COMPOSE_FILE" exec -T backend python manage.py collectstatic --noinput --clear
    log_success "Static files collected"
}

# Create superuser (optional)
create_superuser() {
    read -p "Do you want to create a superuser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Creating superuser..."
        docker-compose -f "$COMPOSE_FILE" exec backend python manage.py createsuperuser
    fi
}

# Health check
health_check() {
    log_info "Performing health check..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost/health/ &>/dev/null; then
            log_success "Application is healthy!"
            return 0
        fi

        log_info "Waiting for application to be ready... (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    log_error "Health check failed after $max_attempts attempts"
    return 1
}

# Show status
show_status() {
    log_info "Container status:"
    docker-compose -f "$COMPOSE_FILE" ps

    log_info "Application URLs:"
    echo "  - Frontend: http://localhost"
    echo "  - API: http://localhost/api/"
    echo "  - Admin: http://localhost/admin/"
    echo "  - Health: http://localhost/health/"
}

# Main deployment function
main() {
    echo -e "${BLUE}🚀 Starting deployment of Habits Tracker${NC}"
    echo

    check_dependencies
    check_env_file
    pull_latest_changes
    deploy_containers
    run_migrations
    collect_static
    create_superuser

    if health_check; then
        show_status
        log_success "🎉 Deployment completed successfully!"
        echo
        log_info "Your application is now running at: http://localhost"
    else
        log_error "Deployment failed during health check"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "build")
        log_info "Building images only..."
        docker-compose -f "$COMPOSE_FILE" build --no-cache
        ;;
    "up")
        log_info "Starting containers..."
        docker-compose -f "$COMPOSE_FILE" up -d
        ;;
    "down")
        log_info "Stopping containers..."
        docker-compose -f "$COMPOSE_FILE" down
        ;;
    "logs")
        log_info "Showing container logs..."
        docker-compose -f "$COMPOSE_FILE" logs -f
        ;;
    "restart")
        log_info "Restarting containers..."
        docker-compose -f "$COMPOSE_FILE" restart
        ;;
    "status")
        show_status
        ;;
    "migrate")
        run_migrations
        ;;
    "static")
        collect_static
        ;;
    *)
        main
        ;;
esac
