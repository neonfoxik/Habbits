# Multi-stage build for Django + React app

# Stage 1: Build React app
FROM node:18-alpine AS frontend-build

# Set working directory for React build
WORKDIR /app

# Verify working directory
RUN echo "Working directory: $(pwd)"

# Copy frontend files to root (not in subfolder)
COPY frontend/package.json ./
COPY frontend/public ./public
COPY frontend/src ./src
COPY frontend/README.md ./
# Copy any other files that might be needed
COPY frontend/*.* ./ 2>/dev/null || true

# Verify that all files were copied correctly
RUN echo "=== VERIFYING COPIED FILES ===" && \
    echo "Current directory: $(pwd)" && \
    echo "Root files:" && ls -la && \
    echo "Package.json exists:" && test -f package.json && echo "✅ package.json found" || echo "❌ package.json missing" && \
    echo "Public folder:" && ls -la public/ && \
    echo "Index.html exists:" && test -f public/index.html && echo "✅ index.html found" || echo "❌ index.html missing" && \
    echo "Src folder:" && ls -la src/

# Install dependencies (production only)
RUN npm install --omit=dev --no-package-lock

# Final verification before build
RUN echo "=== FINAL CHECK BEFORE BUILD ===" && \
    echo "Working directory: $(pwd)" && \
    echo "Files in /app:" && ls -la && \
    echo "Files in public:" && ls -la public/ && \
    echo "Package.json content:" && cat package.json | head -10

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
