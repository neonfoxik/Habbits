# Multi-stage build for Django + React app

# Stage 1: Build React app
FROM node:18-alpine AS frontend-build

# Copy package files first (for better Docker layer caching)
COPY frontend/package.json frontend/package-lock.json ./

# Install dependencies (production only) - use npm ci for faster, reliable builds
RUN npm ci --only=production --no-audit --no-fund --prefer-offline --no-progress

# Copy rest of frontend source
COPY frontend/public ./public
COPY frontend/src ./src
COPY frontend/README.md ./

# Verify React project structure
RUN echo "=== VERIFYING REACT PROJECT STRUCTURE ===" && \
    pwd && \
    ls -la && \
    test -f package.json && echo "✅ package.json found" || echo "❌ package.json missing" && \
    test -f package-lock.json && echo "✅ package-lock.json found" || echo "❌ package-lock.json missing" && \
    test -d public && echo "✅ public/ directory exists" || echo "❌ public/ directory missing" && \
    test -d src && echo "✅ src/ directory exists" || echo "❌ src/ directory missing" && \
    test -d node_modules && echo "✅ node_modules exists" || echo "❌ node_modules missing" && \
    test -f public/index.html && echo "✅ public/index.html found" || echo "❌ public/index.html missing"

# Build the app
RUN npm run build

# Verify build output
RUN echo "=== BUILD OUTPUT VERIFICATION ===" && \
    ls -la build/ && \
    test -f build/index.html && echo "✅ build/index.html exists" || (echo "❌ build/index.html missing" && exit 1) && \
    find build -name "*.js" | head -3 | xargs ls -la && \
    echo "✅ React build successful"

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

# Copy React build from previous stage
COPY --from=frontend-build /app/frontend/build ../frontend/build

# Verify React build was copied
RUN echo "=== REACT BUILD VERIFICATION ===" && \
    ls -la ../frontend/build/ && \
    test -f ../frontend/build/index.html && echo "✅ React build copied successfully" || echo "❌ React build copy failed"

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
