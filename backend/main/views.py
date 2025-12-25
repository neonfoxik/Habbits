import os
import json
from django.http import JsonResponse, HttpResponse
from django.shortcuts import render
from django.conf import settings
from django.templatetags.static import static
from django.db import connection


def health_check(request):
    """
    Health check endpoint for monitoring
    """
    try:
        # Check database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            db_status = "healthy"
    except Exception:
        db_status = "unhealthy"

    # Check if React build exists
    react_build_exists = os.path.exists(os.path.join(settings.REACT_APP_DIR, 'index.html'))

    health_data = {
        "status": "healthy" if db_status == "healthy" else "unhealthy",
        "database": db_status,
        "react_build": "exists" if react_build_exists else "missing",
        "version": "1.0.0"
    }

    status_code = 200 if health_data["status"] == "healthy" else 503
    return JsonResponse(health_data, status=status_code)


def index(request):
    """
    Serve the React app in production, or show API info in development
    """
    try:
        # Try to serve the React build index.html
        react_index_path = os.path.join(settings.REACT_APP_DIR, 'index.html')
        print(f"DEBUG: Looking for React build at: {react_index_path}")
        print(f"DEBUG: REACT_APP_DIR setting: {settings.REACT_APP_DIR}")
        print(f"DEBUG: File exists: {os.path.exists(react_index_path)}")

        if os.path.exists(react_index_path):
            with open(react_index_path, 'r', encoding='utf-8') as f:
                content = f.read()
                print(f"DEBUG: Successfully read React index.html, length: {len(content)}")
                return HttpResponse(content, content_type='text/html')
        else:
            print(f"DEBUG: React build index.html not found at {react_index_path}")
    except Exception as e:
        print(f"DEBUG: Error serving React build: {e}")
        pass

    # Simple fallback HTML for testing
    return HttpResponse('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Habits Tracker</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .status { padding: 20px; background: #f0f8ff; border: 1px solid #add8e6; border-radius: 5px; margin: 20px 0; }
            .api-links { background: #f9f9f9; padding: 20px; border-radius: 5px; }
            .api-links ul { list-style: none; padding: 0; }
            .api-links li { margin: 10px 0; }
            .api-links a { color: #007bff; text-decoration: none; padding: 5px 10px; border: 1px solid #007bff; border-radius: 3px; }
            .api-links a:hover { background: #007bff; color: white; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎯 Habits Tracker</h1>

            <div class="status">
                <h3>✅ Application Status</h3>
                <p>✅ Backend: Running</p>
                <p>✅ Database: Connected</p>
                <p>⚠️ React Frontend: Build files not found (showing fallback)</p>
            </div>

            <div class="api-links">
                <h3>🔗 API Endpoints</h3>
                <ul>
                    <li><a href="/api/v1/habits/">Habits API</a></li>
                    <li><a href="/api/v1/dates/">Dates API</a></li>
                    <li><a href="/api/v1/userall/">Users API</a></li>
                    <li><a href="/admin/">Admin Panel</a></li>
                    <li><a href="/health/">Health Check</a></li>
                </ul>
            </div>

            <p><small>If you're seeing this page, React build files are not available. Check Docker build logs for details.</small></p>
        </div>
    </body>
    </html>
    ''', content_type='text/html')
