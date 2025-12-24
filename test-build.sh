#!/bin/bash

# Test script to verify React build works locally

echo "🧪 Testing React build locally..."

# Go to frontend directory
cd frontend

# Clean any existing build
rm -rf build/

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Try to build
echo "🔨 Building React app..."
npm run build

# Check if build succeeded
if [ -d "build" ] && [ -f "build/index.html" ]; then
    echo "✅ React build successful!"
    echo "📁 Build files created in: $(pwd)/build/"
    ls -la build/
else
    echo "❌ React build failed!"
    exit 1
fi
