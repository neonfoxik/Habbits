#!/bin/bash

# Script to check server setup and files

echo "🔍 Checking server setup for Habits Tracker deployment..."
echo "======================================================"

# Check if we're in the right directory
if [ ! -f "docker-compose.prod.yml" ]; then
    echo "❌ ERROR: Not in project root directory!"
    echo "Please cd to the habits-tracker directory"
    exit 1
fi

echo "✅ In project root directory"

# Check git status
echo ""
echo "📋 Git status:"
git status --porcelain
if [ $? -eq 0 ]; then
    echo "✅ Git repository is clean"
else
    echo "⚠️  Git repository has issues"
fi

# Check file structure
echo ""
echo "📁 File structure check:"

files_to_check=(
    "Dockerfile"
    "docker-compose.prod.yml"
    "deploy.sh"
    ".env"
    "frontend/package.json"
    "frontend/public/index.html"
    "frontend/src/App.js"
    "backend/requirements.txt"
    "backend/manage.py"
    "nginx/nginx.conf"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file MISSING!"
    fi
done

# Check directories
directories_to_check=(
    "frontend/public"
    "frontend/src"
    "backend"
    "nginx"
)

echo ""
echo "📁 Directory structure check:"
for dir in "${directories_to_check[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/ exists"
    else
        echo "❌ $dir/ MISSING!"
    fi
done

# Check file sizes
echo ""
echo "📊 File sizes:"
if [ -f "frontend/public/index.html" ]; then
    size=$(stat -f%z frontend/public/index.html 2>/dev/null || stat -c%s frontend/public/index.html 2>/dev/null)
    echo "✅ frontend/public/index.html: $size bytes"
fi

if [ -f "frontend/package.json" ]; then
    size=$(stat -f%z frontend/package.json 2>/dev/null || stat -c%s frontend/package.json 2>/dev/null)
    echo "✅ frontend/package.json: $size bytes"
fi

# Docker check
echo ""
echo "🐳 Docker status:"
if command -v docker &> /dev/null; then
    echo "✅ Docker is installed"
    docker --version
else
    echo "❌ Docker is not installed!"
fi

if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose is installed"
    docker-compose --version
else
    echo "❌ Docker Compose is not installed!"
fi

# Check if Docker daemon is running
if docker info &> /dev/null; then
    echo "✅ Docker daemon is running"
else
    echo "❌ Docker daemon is not running!"
fi

echo ""
echo "🎯 Summary:"
echo "If all checks passed, run: ./deploy.sh"
echo "If files are missing, check your git clone or repository"
echo "======================================================"
