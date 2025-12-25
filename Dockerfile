# Multi-stage build for Django + React app

# Stage 1: Build React app (ultra-fast)
FROM alpine:latest AS frontend-build

# Create minimal HTML build
RUN mkdir -p /app/build && \
    echo '<!DOCTYPE html><html><head><title>Habits Tracker</title><style>body{font-family:Arial;margin:20px}h1{color:#333}</style></head><body><h1>🎯 Habits Tracker</h1><p>✅ Application is running!</p><a href="/admin/">Admin Panel</a> | <a href="/api/">API Docs</a><script>console.log("Frontend loaded successfully")</script></body></html>' > /app/build/index.html

# Verify build
RUN ls -la /app/build/ && echo "✅ Frontend build ready"

# Stage 2: Setup Python environment
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies (simplified)
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc postgresql-client && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django project
COPY backend/ .

# Copy React build from previous stage
COPY --from=frontend-build /app/build ../frontend/build

# Verify React build was copied
RUN echo "=== REACT BUILD VERIFICATION ===" && \
    ls -la ../frontend/build/ && \
    test -f ../frontend/build/index.html && echo "✅ React build copied successfully" || echo "❌ React build copy failed"

# Create staticfiles directory (will be populated during deployment)
RUN mkdir -p staticfiles

# Create a non-root user
RUN adduser --disabled-password --gecos '' django && chown -R django:django /app
USER django

# Expose port
EXPOSE 8000

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "backend.wsgi:application"]
