#!/bin/bash

# Script to verify all required files exist before deployment

echo "🔍 Checking required files for deployment..."

# Check if we're in the right directory
if [ ! -f "docker-compose.prod.yml" ]; then
    echo "❌ Error: docker-compose.prod.yml not found. Are you in the project root?"
    exit 1
fi

# Check frontend files
echo "📁 Checking frontend files..."
if [ ! -d "frontend" ]; then
    echo "❌ Error: frontend/ directory not found!"
    exit 1
fi

if [ ! -f "frontend/package.json" ]; then
    echo "❌ Error: frontend/package.json not found!"
    exit 1
fi

if [ ! -d "frontend/public" ]; then
    echo "❌ Error: frontend/public/ directory not found!"
    exit 1
fi

if [ ! -f "frontend/public/index.html" ]; then
    echo "❌ Error: frontend/public/index.html not found!"
    exit 1
fi

if [ ! -d "frontend/src" ]; then
    echo "❌ Error: frontend/src/ directory not found!"
    exit 1
fi

# Check backend files
echo "📁 Checking backend files..."
if [ ! -d "backend" ]; then
    echo "❌ Error: backend/ directory not found!"
    exit 1
fi

if [ ! -f "backend/requirements.txt" ]; then
    echo "❌ Error: backend/requirements.txt not found!"
    exit 1
fi

# Check other required files
echo "📁 Checking configuration files..."
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found! Copy from env.example"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Dockerfile not found!"
    exit 1
fi

echo "✅ All required files found!"
echo ""
echo "📊 File structure:"
echo "  frontend/"
echo "    ├── package.json ✅"
echo "    ├── public/ ✅"
echo "    │   └── index.html ✅"
echo "    └── src/ ✅"
echo "  backend/"
echo "    └── requirements.txt ✅"
echo "  .env ✅"
echo "  Dockerfile ✅"
echo ""
echo "🚀 Ready for deployment!"
