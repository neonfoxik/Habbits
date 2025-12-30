#!/bin/bash

# Script to initialize SSL certificate for actiontest.ru

echo "Starting SSL certificate initialization for ter.actiontest.ru..."

# Create certbot www directory
mkdir -p certbot/www

# Start nginx temporarily for certbot challenge
docker compose up -d nginx

# Wait for nginx to start
sleep 10

# Get SSL certificate
echo "Requesting SSL certificate from Let's Encrypt..."
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  --email admin@actiontest.ru \
  --agree-tos \
  --no-eff-email \
  -d ter.actiontest.ru 

# Check if certificate was obtained successfully
if [ $? -eq 0 ]; then
    echo "SSL certificate obtained successfully!"
    echo "Restarting nginx with SSL configuration..."
    docker compose restart nginx
    echo "SSL setup complete! Your site should now be available at https://ter.actiontest.ru"
else
    echo "Failed to obtain SSL certificate. Please check the errors above."
    exit 1
fi
