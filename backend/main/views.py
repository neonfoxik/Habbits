import os
from django.http import HttpResponse
from django.shortcuts import render
from django.conf import settings
from django.templatetags.static import static


def index(request):
    """
    Serve the React app in production, or show API info in development
    """
    try:
        # Try to serve the React build index.html
        react_index_path = os.path.join(settings.REACT_APP_DIR, 'index.html')
        if os.path.exists(react_index_path):
            with open(react_index_path, 'r', encoding='utf-8') as f:
                return HttpResponse(f.read(), content_type='text/html')
    except:
        pass

    # Fallback for development or when React build doesn't exist
    return HttpResponse('''
    <h1>Habbits Tracker API</h1>
    <p>API endpoints:</p>
    <ul>
        <li><a href="/api/v1/habits/">Habits API</a></li>
        <li><a href="/api/v1/dates/">Dates API</a></li>
        <li><a href="/api/v1/userall/">Users API</a></li>
        <li><a href="/admin/">Admin Panel</a></li>
    </ul>
    <p>React app will be served here in production.</p>
    ''', content_type='text/html')
