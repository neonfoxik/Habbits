# Makefile for Habits App

.PHONY: help build up down restart logs migrate collectstatic shell clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build all services
	docker compose build

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## Show logs from all services
	docker compose logs -f

migrate: ## Run database migrations
	docker compose exec backend python manage.py migrate

collectstatic: ## Collect static files
	docker compose exec backend python manage.py collectstatic --noinput

shell: ## Open Django shell
	docker compose exec backend python manage.py shell

dbshell: ## Open database shell
	docker compose exec db psql -U habits_user -d habits_db

frontend-install: ## Install frontend dependencies
	cd frontend && npm install

frontend-build: ## Build frontend for production
	docker build -t habits-frontend ./frontend

backend-test: ## Run backend tests
	docker compose exec backend python manage.py test

clean: ## Remove all containers, volumes, and images
	docker compose down -v --rmi all

deploy: ## Full deployment (build, migrate, collect static)
	@echo "🚀 Starting full deployment..."
	make build
	make up
	@echo "⏳ Waiting for services to be ready..."
	@sleep 30
	make migrate
	make collectstatic
	@echo "✅ Deployment completed! App should be available at http://localhost"
