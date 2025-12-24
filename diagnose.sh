#!/bin/bash

# Diagnostic script for Habits Tracker deployment

echo "🔍 Diagnostics for Habits Tracker"
echo "================================="

COMPOSE_FILE="docker-compose.prod.yml"

# Check if containers are running
echo "1. Container Status:"
docker-compose -f "$COMPOSE_FILE" ps
echo ""

# Check container health
echo "2. Container Health:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Test backend connectivity
echo "3. Backend Health Check:"
if curl -f --max-time 10 http://localhost:8000/health/ &>/dev/null; then
    echo "✅ Backend health check passed"
    curl -s http://localhost:8000/health/ | head -5
else
    echo "❌ Backend health check failed"
    echo "   Trying direct connection..."
    if curl -f --max-time 5 http://localhost:8000/ &>/dev/null; then
        echo "   ✅ Backend responds on root path"
    else
        echo "   ❌ Backend not responding"
    fi
fi
echo ""

# Test nginx
echo "4. Nginx Status:"
if docker-compose -f "$COMPOSE_FILE" exec -T nginx nginx -t &>/dev/null; then
    echo "✅ Nginx configuration is valid"
    # Check if nginx is running properly
    if curl -f --max-time 5 http://localhost/ &>/dev/null; then
        echo "✅ Nginx is responding on port 80"
    else
        echo "❌ Nginx is not responding on port 80"
    fi
else
    echo "❌ Nginx configuration has errors:"
    docker-compose -f "$COMPOSE_FILE" exec -T nginx nginx -t 2>&1
fi
echo ""

# Check logs
echo "5. Recent Logs:"
echo "   Backend logs (last 5 lines):"
docker-compose -f "$COMPOSE_FILE" logs --tail=5 backend 2>/dev/null || echo "   No backend logs available"
echo ""

echo "   Nginx logs (last 5 lines):"
docker-compose -f "$COMPOSE_FILE" logs --tail=5 nginx 2>/dev/null || echo "   No nginx logs available"
echo ""

echo "   Database logs (last 3 lines):"
docker-compose -f "$COMPOSE_FILE" logs --tail=3 db 2>/dev/null || echo "   No database logs available"
echo ""

# Network check
echo "6. Network Connectivity:"
echo "   Testing backend container reachability..."
if docker exec habits-backend curl -f --max-time 5 http://localhost:8000/health/ &>/dev/null; then
    echo "✅ Backend container can reach itself"
else
    echo "❌ Backend container connectivity issue"
fi
echo ""

# Recommendations
echo "7. Recommendations:"
if ! curl -f --max-time 5 http://localhost:8000/health/ &>/dev/null; then
    echo "   - Check backend container logs: ./deploy.sh logs"
    echo "   - Verify ALLOWED_HOSTS in .env includes server IP"
    echo "   - Check database connectivity"
fi

if ! docker-compose -f "$COMPOSE_FILE" exec -T nginx nginx -t &>/dev/null; then
    echo "   - Fix nginx configuration errors"
    echo "   - Check nginx logs for details"
fi

echo ""
echo "For more help, run: ./deploy.sh logs"
echo "================================="
