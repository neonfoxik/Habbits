# Habits App - Deployment Guide

Это Django + React приложение для отслеживания привычек. Руководство по развертыванию на сервере.

## ⚡ Оптимизация производительности

**После первого деплоя выполните для ускорения будущих сборок:**

```bash
# 1. Создайте package-lock.json для быстрой сборки frontend (~10x ускорение)
docker run --rm -v $(pwd)/frontend:/app -w /app node:18-alpine sh -c "npm install"

# 2. Создайте .env файл с настройками
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=your-unique-secret-key-change-this-please
ALLOWED_HOSTS=localhost,127.0.0.1,your-server-ip
DB_NAME=habits_db
DB_USER=habits_user
DB_PASSWORD=your-secure-password-here
CORS_ALLOWED_ORIGINS=http://localhost,http://your-server-ip
SECURE_SSL_REDIRECT=False
SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False
EOF

# 3. Добавьте в git (опционально)
git add frontend/package-lock.json
```

**Результат:** Сборки ускорятся с 5+ минут до 30-60 секунд!

## 🚀 Быстрый старт с Docker

### Предварительные требования

- Docker и Docker Compose установлены на сервере
- Минимум 2GB RAM, 20GB дискового пространства
- Git для клонирования репозитория

### Шаг 1: Клонирование и настройка

```bash
git clone <your-repo-url>
cd habits-app

# Копируем файл с переменными окружения
cp env.example .env
```

### Шаг 2: Настройка переменных окружения

Отредактируйте файл `.env`:

```bash
# ОБЯЗАТЕЛЬНО измените эти значения!
SECRET_KEY=your-unique-secret-key-here-please-generate-new-one
ALLOWED_HOSTS=your-domain.com,www.your-domain.com,your-server-ip

# Настройки базы данных
DB_NAME=habits_db
DB_USER=habits_user
DB_PASSWORD=your-secure-password-here

# CORS настройки
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com
```

### Шаг 3: Запуск приложения

```bash
# Используйте скрипт деплоя
./deploy.sh

# Или вручную:
docker compose up -d --build

# Примените миграции базы данных
docker compose exec backend python manage.py migrate

# Соберите статические файлы
docker compose exec backend python manage.py collectstatic --noinput
```

**Для оптимизации сборки** (опционально):
```bash
# Создайте package-lock.json внутри Docker (для быстрой сборки)
docker run --rm -v $(pwd)/frontend:/app -w /app node:18-alpine sh -c "npm install && cp package-lock.json ."

# Добавьте в git
git add frontend/package-lock.json
```

### Шаг 4: Проверка развертывания

```bash
# Проверьте статус контейнеров
docker compose ps

# Посмотрите логи
docker compose logs -f

# Приложение будет доступно по адресу:
# http://your-server-ip
```

## 🔧 Ручная настройка (без Docker)

### Настройка сервера

1. **Установите необходимые пакеты:**
```bash
sudo apt update
sudo apt install python3 python3-pip postgresql postgresql-contrib nginx
```

2. **Настройте PostgreSQL:**
```bash
sudo -u postgres createdb habits_db
sudo -u postgres createuser habits_user
sudo -u postgres psql -c "ALTER USER habits_user PASSWORD 'your-password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE habits_db TO habits_user;"
```

3. **Настройте проект:**
```bash
cd /path/to/your/project

# Backend
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Создайте .env файл в папке backend
cp ../env.example .env
# Отредактируйте .env файл

# Frontend
cd ../frontend
npm install
npm run build
```

4. **Настройте systemd сервисы:**

Создайте файл `/etc/systemd/system/gunicorn.service`:
```ini
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=your-user
Group=www-data
WorkingDirectory=/path/to/your/project/backend
Environment="PATH=/path/to/your/project/backend/venv/bin"
ExecStart=/path/to/your/project/backend/venv/bin/gunicorn --workers 3 --bind unix:/tmp/gunicorn.sock backend.wsgi:application

[Install]
WantedBy=multi-user.target
```

5. **Настройте Nginx:**

Скопируйте конфигурационные файлы:
```bash
sudo cp nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp nginx/sites-enabled/habits-app /etc/nginx/sites-enabled/
sudo mkdir -p /etc/nginx/sites-enabled

# Создайте символические ссылки для статических файлов
sudo ln -s /path/to/your/project/backend/staticfiles /var/www/html/static
sudo ln -s /path/to/your/project/backend/media /var/www/html/media
```

6. **Запустите сервисы:**
```bash
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx
```

## 🔒 Безопасность

### Генерация SECRET_KEY

```python
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
```

### SSL/TLS сертификаты

Для продакшена настройте HTTPS:

1. Получите сертификаты (Let's Encrypt):
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

2. Обновите настройки в `.env`:
```bash
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

## 📊 Мониторинг и обслуживание

### Просмотр логов

```bash
# Docker
docker compose logs -f

# Системные логи
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/nginx/error.log

# Docker логи
docker compose logs -f
```

### Резервное копирование базы данных

```bash
# Docker
docker compose exec db pg_dump -U habits_user habits_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Ручная настройка
pg_dump -U habits_user -h localhost habits_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Обновление приложения

```bash
# Docker
./deploy.sh
# Выберите опцию 5 (Update application)

# Ручная настройка
cd /path/to/project
git pull
source backend/venv/bin/activate
pip install -r backend/requirements.txt
python backend/manage.py migrate
python backend/manage.py collectstatic --noinput
sudo systemctl restart gunicorn
sudo systemctl restart nginx
```

## 🐛 Устранение неполадок

### Проблемы с базой данных

```bash
# Проверьте подключение
docker compose exec backend python manage.py dbshell

# Проверьте логи базы данных
docker compose logs db
```

### Проблемы с Nginx

```bash
# Проверьте конфигурацию
sudo nginx -t

# Перезапустите Nginx
sudo systemctl restart nginx

# Проверьте логи
sudo tail -f /var/log/nginx/error.log
```

### Проблемы с Gunicorn

```bash
# Проверьте статус
sudo systemctl status gunicorn

# Перезапустите
sudo systemctl restart gunicorn

# Проверьте логи
sudo journalctl -u gunicorn -f
```

## 📞 Поддержка

Если возникли проблемы с развертыванием, проверьте:
1. Все переменные окружения настроены правильно
2. Порты 80 и 443 свободны
3. Секретный ключ Django изменен
4. База данных доступна и миграции применены
