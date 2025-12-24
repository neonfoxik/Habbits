# Multi-stage build for Django + React app

# Stage 1: Build React app
FROM node:18-alpine AS frontend-build

WORKDIR /app

# Copy package.json only (exclude package-lock.json)
COPY frontend/package.json ./

# Copy all frontend files
COPY frontend/ ./

# Debug: list files to verify structure
RUN ls -la && echo "--- public folder ---" && ls -la public/

# Install dependencies (production only)
RUN npm install --omit=dev --no-package-lock

# Build the app
RUN npm run build

# Stage 2: Setup Python environment
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django project
COPY backend/ .

# Copy React build from previous stage (relative to project root)
COPY --from=frontend-build /app/build ../frontend/build

# Create staticfiles directory
RUN mkdir -p staticfiles

# Collect static files
RUN python manage.py collectstatic --noinput

# Create a non-root user
RUN adduser --disabled-password --gecos '' django && chown -R django:django /app
USER django

# Expose port
EXPOSE 8000

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "backend.wsgi:application"]
