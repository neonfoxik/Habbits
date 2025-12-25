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

    # Build images with timeout
    log_info "Building Docker images..."
    timeout 300 docker-compose -f "$COMPOSE_FILE" build --no-cache || {
        log_error "Build timed out after 5 minutes"
        exit 1
    }

    # Start containers
    log_info "Starting containers..."
    docker-compose -f "$COMPOSE_FILE" up -d

    log_success "Containers deployed successfully"
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."

    # Wait for backend container to be ready (reduced timeout)
    log_info "Waiting for backend container to be ready..."
    for i in {1..15}; do
        # Check if container is running
        if docker-compose -f "$COMPOSE_FILE" ps backend 2>/dev/null | grep -q "Up"; then
            log_info "Container is up, testing connectivity..."
            # Try to execute a simple command in the container
            if timeout 5 docker-compose -f "$COMPOSE_FILE" exec -T backend echo "test" &>/dev/null 2>&1; then
                log_success "Backend container is ready!"
                break
            else
                log_info "Container not responsive yet..."
            fi
        else
            log_info "Container not started yet..."
        fi
        sleep 1
        log_info "Still waiting for backend... ($i/15)"
    done

    # Final check
    if ! docker-compose -f "$COMPOSE_FILE" ps backend 2>/dev/null | grep -q "Up"; then
        log_error "Backend container failed to start!"
        log_info "Container logs:"
        docker-compose -f "$COMPOSE_FILE" logs backend | tail -10
        return 1
    fi

    log_info "Proceeding with migrations..."

    # Run migrations with timeout
    if timeout 60 docker-compose -f "$COMPOSE_FILE" exec -T backend python manage.py migrate; then
        log_success "Database migrations completed"
    else
        log_error "Database migrations failed or timed out"
        return 1
    fi
}

# Collect static files
collect_static() {
    log_info "Collecting static files..."
    if timeout 30 docker-compose -f "$COMPOSE_FILE" exec -T backend python manage.py collectstatic --noinput --clear; then
        log_success "Static files collected"
    else
        log_error "Static files collection failed or timed out"
        return 1
    fi
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
        # Check Django backend directly on port 8000
        if curl -f --max-time 10 http://localhost:8000/health/ &>/dev/null; then
            log_success "Application is healthy!"
            return 0
        fi

        # On first few attempts, also check if backend is responding at all
        if [ $attempt -le 3 ] && curl -f --max-time 5 http://localhost:8000/ &>/dev/null; then
            log_info "Backend is responding, waiting for health endpoint..."
        fi

        log_info "Waiting for application to be ready... (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    # Additional check: verify nginx configuration
    log_info "Checking nginx configuration..."
    if docker-compose -f "$COMPOSE_FILE" exec -T nginx nginx -t &>/dev/null; then
        log_success "Nginx configuration is valid"
    else
        log_warning "Nginx configuration has errors - check logs"
        docker-compose -f "$COMPOSE_FILE" logs nginx | tail -10
    fi

    log_error "Health check failed after $max_attempts attempts"
    log_info "🔍 Debugging information:"
    log_info "Container status:"
    docker-compose -f "$COMPOSE_FILE" ps
    log_info "Backend logs:"
    docker-compose -f "$COMPOSE_FILE" logs --tail=20 backend
    log_info "Check manually: curl http://localhost:8000/health/"
    return 1
}

# Show status
show_status() {
    log_info "Container status:"
    docker-compose -f "$COMPOSE_FILE" ps

    # Get server IP address
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "your-server-ip")

    log_info "Application URLs:"
    echo "  - Frontend: http://$SERVER_IP"
    echo "  - API: http://$SERVER_IP/api/"
    echo "  - Admin: http://$SERVER_IP/admin/"
    echo "  - Backend direct: http://$SERVER_IP:8000/"
    echo "  - Health check: http://$SERVER_IP:8000/health/"
    echo ""
    echo "  📋 Server Info:"
    echo "  - IP Address: $SERVER_IP"
    echo "  - Nginx Port: 80"
    echo "  - Backend Port: 8000"
}

# Main deployment function
main() {
    echo -e "${BLUE}🚀 Starting deployment of Habits Tracker${NC}"
    echo

    # Show server info
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "localhost")
    echo -e "${BLUE}📋 Server Information:${NC}"
    echo "   IP Address: $SERVER_IP"
    echo "   Domain: Check ALLOWED_HOSTS in .env"
    echo

    check_dependencies
    check_env_file
    pull_latest_changes
    deploy_containers
    # Check if we should skip migrations
    if [ "${SKIP_MIGRATIONS:-false}" = "true" ]; then
        log_warning "Skipping database migrations (SKIP_MIGRATIONS=true)"
        collect_static
    else
        if run_migrations; then
            collect_static
            create_superuser
        else
            log_error "Migration failed, but continuing with deployment..."
            collect_static
        fi
    fi

    if health_check; then
        show_status
        log_success "🎉 Deployment completed successfully!"
        echo
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "your-server-ip")
        log_info "Your application is now running at: http://$SERVER_IP"
        echo
        echo -e "${GREEN}📱 Access your application:${NC}"
        echo "   Frontend: http://$SERVER_IP"
        echo "   Admin: http://$SERVER_IP/admin/"
        echo "   API: http://$SERVER_IP/api/"
        echo
        echo -e "${YELLOW}🔧 Management commands:${NC}"
        echo "   View logs: ./deploy.sh logs"
        echo "   Restart: ./deploy.sh restart"
        echo "   Reload nginx: ./deploy.sh reload-nginx"
        echo "   Fix nginx: ./deploy.sh fix-nginx"
        echo "   Quick rebuild: ./deploy.sh rebuild-frontend"
        echo "   Full rebuild: ./deploy.sh rebuild"
        echo "   Stop build: ./deploy.sh stop-build"
        echo "   Check build: ./deploy.sh check-build"
        echo "   Run migrations: ./deploy.sh migrate-only"
        echo "   Skip migrations: ./deploy.sh skip-migrations"
        echo "   Quick deploy: ./deploy.sh quick-deploy"
        echo "   Backend status: ./deploy.sh backend-status"
        echo "   Stop: ./deploy.sh down"
        echo "   Diagnose: ./diagnose.sh"
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
    "reload-nginx")
        log_info "Testing nginx configuration..."
        if docker-compose -f "$COMPOSE_FILE" exec -T nginx nginx -t; then
            log_success "Nginx configuration is valid, reloading..."
            docker-compose -f "$COMPOSE_FILE" exec nginx nginx -s reload
            log_success "Nginx reloaded successfully"
        else
            log_error "Nginx configuration has errors!"
            exit 1
        fi
        ;;
    "fix-nginx")
        log_info "Recreating nginx container with new configuration..."
        docker-compose -f "$COMPOSE_FILE" up -d --force-recreate nginx
        ;;
    "network-test")
        log_info "Testing network connectivity between containers..."
        echo "Testing backend connectivity:"
        docker-compose -f "$COMPOSE_FILE" exec -T backend curl -f --max-time 5 http://localhost:8000/health/ && echo "✅ Backend self-test passed" || echo "❌ Backend self-test failed"
        echo "Testing nginx to backend connectivity:"
        docker-compose -f "$COMPOSE_FILE" exec -T nginx curl -f --max-time 5 http://habits-backend:8000/health/ && echo "✅ Nginx to backend connection works" || echo "❌ Nginx to backend connection failed"
        ;;
    "rebuild")
        log_info "Full rebuild: stopping, cleaning, rebuilding..."
        docker-compose -f "$COMPOSE_FILE" down
        docker system prune -f
        docker volume prune -f
        docker-compose -f "$COMPOSE_FILE" build --no-cache --parallel
        docker-compose -f "$COMPOSE_FILE" up -d
        ;;
    "rebuild-frontend")
        log_info "Fast frontend rebuild..."
        timeout 120 docker-compose -f "$COMPOSE_FILE" build --no-cache backend || {
            log_error "Frontend rebuild timed out"
            exit 1
        }
        docker-compose -f "$COMPOSE_FILE" up -d
        ;;
    "stop-build")
        log_info "Stopping any running builds..."
        docker-compose -f "$COMPOSE_FILE" down
        docker buildx prune -f 2>/dev/null || true
        log_success "Build stopped"
        ;;
    "clean-db")
        log_warning "This will DELETE all database data!"
        read -p "Are you sure? (yes/no): " -r
        if [[ $REPLY =~ ^yes$ ]]; then
            log_info "Stopping containers and removing database volume..."
            docker-compose -f "$COMPOSE_FILE" down -v
            log_success "Database cleaned. Run './deploy.sh' to restart."
        fi
        exit 0
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
    "clean-db")
        log_warning "This will DELETE all database data!"
        read -p "Are you sure? (yes/no): " -r
        if [[ $REPLY =~ ^yes$ ]]; then
            log_info "Stopping containers and removing database volume..."
            docker-compose -f "$COMPOSE_FILE" down -v
            log_success "Database cleaned. Run './deploy.sh' to restart."
        fi
        exit 0
        ;;
    "check-build")
        log_info "Checking Docker build setup..."
        echo "Docker version:"
        docker --version 2>/dev/null || echo "Docker not found"
        echo "Docker Compose version:"
        docker-compose --version 2>/dev/null || echo "Docker Compose not found"
        echo "Checking Dockerfile:"
        test -f Dockerfile && echo "✅ Dockerfile exists" || echo "❌ Dockerfile missing"
        echo "Checking docker-compose.prod.yml:"
        test -f docker-compose.prod.yml && echo "✅ docker-compose.prod.yml exists" || echo "❌ docker-compose.prod.yml missing"
        echo "Checking .env:"
        test -f .env && echo "✅ .env exists" || echo "❌ .env missing"
        ;;
    "migrate-only")
        log_info "Running database migrations only..."
        run_migrations
        ;;
    "skip-migrations")
        log_warning "Skipping database migrations..."
        log_info "Note: This may cause issues if database schema is outdated"
        SKIP_MIGRATIONS=true main
        exit 0
        ;;
    "quick-deploy")
        log_info "Quick deployment (skip migrations and static collection)..."
        SKIP_MIGRATIONS=true
        deploy_containers
        # Skip migrations, static collection, and superuser creation
        if health_check; then
            show_status
            log_success "🎉 Quick deployment completed!"
            echo
            log_info "Note: Database migrations were skipped. Run './deploy.sh migrate-only' if needed."
        fi
        exit 0
        ;;
    "backend-status")
        log_info "Checking backend container status..."
        echo "Container status:"
        docker-compose -f "$COMPOSE_FILE" ps backend 2>/dev/null || echo "No containers running"
        echo ""
        echo "Backend container details:"
        docker ps --filter "name=habits-backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Container not found"
        echo ""
        echo "Backend logs (last 10 lines):"
        docker-compose -f "$COMPOSE_FILE" logs --tail=10 backend 2>/dev/null || echo "No logs available"
        echo ""
        echo "Testing backend connectivity:"
        if docker-compose -f "$COMPOSE_FILE" exec -T backend echo "Container is accessible" 2>/dev/null; then
            echo "✅ Backend container is accessible"
            echo "Testing Django health:"
            docker-compose -f "$COMPOSE_FILE" exec -T backend python manage.py check 2>/dev/null && echo "✅ Django check passed" || echo "❌ Django check failed"
        else
            echo "❌ Backend container is not accessible"
        fi
        ;;
    *)
        main
        ;;
esac
