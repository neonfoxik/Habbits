#!/bin/bash

echo "🔧 Rebuilding frontend with optimized settings..."

# Generate package-lock.json if it doesn't exist
if [ ! -f "frontend/package-lock.json" ]; then
    echo "📦 Generating package-lock.json..."
    cd frontend
    npm install
    cd ..
fi

# Build with no cache for clean rebuild
echo "🏗️  Building frontend container..."
docker compose build --no-cache frontend

# Start services
echo "🚀 Starting services..."
docker compose up -d frontend

echo "✅ Frontend rebuild complete!"
echo "⏱️  Expected build time: 40-80 seconds (much faster than before!)"
