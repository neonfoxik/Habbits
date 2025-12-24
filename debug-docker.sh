#!/bin/bash

# Debug script to test Docker build locally

echo "🐳 Testing Docker build locally..."

# Build with no cache to see all steps
docker build --no-cache --progress=plain -t habits-debug .

echo "✅ Docker build completed!"

# Optional: run container to inspect
echo "🔍 To inspect the built container, run:"
echo "docker run -it --rm habits-debug /bin/sh"
echo "Then check: ls -la /app && ls -la /app/public"
