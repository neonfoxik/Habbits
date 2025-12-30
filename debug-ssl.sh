#!/bin/bash

echo "=== SSL Debug Information ==="
echo ""

echo "1. Checking DNS resolution:"
nslookup ter.actiontest.ru
echo ""

echo "2. Checking HTTP connectivity:"
curl -I http://ter.actiontest.ru/
echo ""

echo "3. Checking if port 80 is open:"
nc -zv ter.actiontest.ru 80
echo ""

echo "4. Checking nginx status:"
docker compose ps nginx
echo ""

echo "5. Checking nginx logs:"
docker compose logs nginx | tail -20
echo ""

echo "6. Checking certbot logs:"
docker compose logs certbot | tail -20
echo ""

echo "=== End Debug ==="
