#!/bin/bash

# Script to fix missing files on server

echo "🔧 Fixing missing files on server..."
echo "===================================="

# Check current directory
if [ ! -f "README_PROJECT.md" ]; then
    echo "❌ ERROR: Not in project root directory!"
    echo "Please run this script from the habits-tracker directory"
    exit 1
fi

echo "✅ In project root directory"

# Check what files exist
echo ""
echo "📁 Current file structure:"
ls -la

echo ""
echo "📁 Frontend directory:"
if [ -d "frontend" ]; then
    ls -la frontend/
else
    echo "❌ frontend/ directory missing!"
fi

# Try to restore from git
echo ""
echo "🔄 Attempting to restore files from git..."

# Check git status
echo "Git status:"
git status

echo ""
echo "Git ls-files (checking tracked files):"
git ls-files | grep frontend | head -10

# If files are missing, try to checkout
if [ ! -f "frontend/package.json" ]; then
    echo ""
    echo "🔧 Attempting to checkout frontend files..."
    git checkout HEAD -- frontend/

    if [ -f "frontend/package.json" ]; then
        echo "✅ Frontend files restored from git"
    else
        echo "❌ Failed to restore from git"
    fi
fi

# Check again
echo ""
echo "📁 Checking files after restore:"
if [ -f "frontend/package.json" ]; then
    echo "✅ frontend/package.json exists"
else
    echo "❌ frontend/package.json still missing"
fi

if [ -d "frontend/public" ]; then
    echo "✅ frontend/public/ exists"
    ls -la frontend/public/ | head -5
else
    echo "❌ frontend/public/ still missing"
fi

if [ -d "frontend/src" ]; then
    echo "✅ frontend/src/ exists"
else
    echo "❌ frontend/src/ still missing"
fi

# Final instructions
echo ""
echo "🎯 Next steps:"
if [ -f "frontend/package.json" ] && [ -d "frontend/public" ] && [ -d "frontend/src" ]; then
    echo "✅ All files present! Run: ./deploy.sh"
else
    echo "❌ Some files still missing. Try:"
    echo "  1. Check your git repository"
    echo "  2. Re-clone the repository"
    echo "  3. Check if files exist in the remote repository"
fi

echo "===================================="
