from main import views

from django.urls import path

urlpatterns = [
    path('', views.index),
    path('health/', views.health_check),
]
