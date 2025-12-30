#!/bin/bash

# Deployment script for Habits App
# This script sets up the production environment

set -e

echo "🚀 Starting deployment of Habits App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker and Docker Compose are installed
check_dependencies() {
    print_status "Checking dependencies..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
        print_error "Docker Compose V2 is not available. Please install Docker Desktop or Docker Engine with Compose V2."
        exit 1
    fi

    print_status "Dependencies check passed."
}

# Check if .env file exists
check_env_file() {
    if [ ! -f .env ]; then
        print_warning ".env file not found. Copying from env.example..."
        cp env.example .env
        print_error "Please edit .env file with your production settings before running this script again."
        print_error "Especially change SECRET_KEY and database credentials."
        exit 1
    fi
}

# Build and start services
deploy_services() {
    print_status "Building and starting services..."

    # Build frontend using Docker
    print_status "Building frontend..."
    docker build -t habits-frontend ./frontend

    # Start all services
    print_status "Starting Docker services..."
    docker compose up -d --build

    print_status "Waiting for services to be ready..."
    sleep 30

    # Run database migrations
    print_status "Running database migrations..."
    docker compose exec -T backend python manage.py migrate

    # Collect static files
    print_status "Collecting static files..."
    docker compose exec -T backend python manage.py collectstatic --noinput

    print_status "Deployment completed successfully!"
    print_status "Your app should be available at http://localhost"
}

# Show logs
show_logs() {
    print_status "Showing service logs (press Ctrl+C to exit)..."
    docker compose logs -f
}

# Main menu
show_menu() {
    echo "======================================"
    echo "    Habits App Deployment Script"
    echo "======================================"
    echo "1. Deploy application"
    echo "2. Show logs"
    echo "3. Restart services"
    echo "4. Stop services"
    echo "5. Update application"
    echo "6. Exit"
    echo "======================================"
    read -p "Choose an option (1-6): " choice
}

# Restart services
restart_services() {
    print_status "Restarting services..."
    docker compose restart
    print_status "Services restarted."
}

# Stop services
stop_services() {
    print_status "Stopping services..."
    docker compose down
    print_status "Services stopped."
}

# Update application
update_application() {
    print_status "Updating application..."
    git pull origin main 2>/dev/null || print_warning "No git repository found, skipping pull."

    # Build frontend
    print_status "Building frontend..."
    docker build -t habits-frontend ./frontend

    # Rebuild and restart
    docker compose down
    docker compose up -d --build

    # Run migrations and collect static
    docker compose exec -T backend python manage.py migrate
    docker compose exec -T backend python manage.py collectstatic --noinput

    print_status "Application updated successfully!"
}

# Main script logic
main() {
    check_dependencies
    check_env_file

    while true; do
        show_menu

        case $choice in
            1)
                deploy_services
                ;;
            2)
                show_logs
                ;;
            3)
                restart_services
                ;;
            4)
                stop_services
                ;;
            5)
                update_application
                ;;
            6)
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-6."
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main
