# Инструкция по развертыванию приложения "Habbits Tracker"

## Обзор
Приложение состоит из:
- Backend: Django 5.2.8 REST API
- Frontend: React 18.2.0 приложение
- Database: PostgreSQL (рекомендуется для production)
- Контейнеризация: Docker + Docker Compose

## Важные замечания перед развертыванием

### Безопасность
1. **Сгенерируйте секретный ключ Django:**
   ```bash
   # На вашем сервере или локально
   python3 -c "import secrets; print(secrets.token_urlsafe(50))"
   # Скопируйте результат и используйте как SECRET_KEY в .env файле
   ```

2. **Пароли базы данных:**
   - Используйте сложные пароли (минимум 16 символов)
   - Не используйте дефолтные пароли из docker-compose.yml

3. **Резервное копирование:**
   - Настройте автоматическое бэкапирование базы данных
   - Сохраняйте копии .env файла в безопасном месте

### Файлы для production развертывания
- `docker-compose.prod.yml` - Production конфигурация Docker
- `deploy.sh` - Скрипт для автоматизации развертывания
- `nginx/` - Конфигурации веб-сервера
- Обновленный `Dockerfile` с Gunicorn

### Проверка перед развертыванием
```bash
# На локальном компьютере протестируйте сборку
docker-compose build
docker-compose up -d
# Проверьте работу: http://localhost:8000 и http://localhost:3000
docker-compose down
```

## 🚀 ПРОСТОЕ РАЗВЕРТЫВАНИЕ (Docker Only)

### Что нужно сделать на сервере (всего 4 команды):
```bash
# 1. Установка зависимостей
sudo apt update && sudo apt install -y docker.io docker-compose git curl

# 2. Клонирование проекта
git clone https://github.com/your-username/habits-tracker.git
cd habits-tracker

# 3. Настройка переменных окружения
cp env.example .env
nano .env  # Отредактируйте: SECRET_KEY, ALLOWED_HOSTS, DATABASE_URL

# 4. Запуск приложения
./deploy.sh

# ✅ Готово! Приложение доступно на http://your-server-ip
```

### Управление приложением:
```bash
# Остановить
./deploy.sh down

# Перезапустить
./deploy.sh restart

# Посмотреть логи
./deploy.sh logs

# Проверить статус
./deploy.sh status

# Обновить приложение
git pull && ./deploy.sh
```

### Архитектура production развертывания:
- **Backend**: Django + Gunicorn (3 workers)
- **Database**: PostgreSQL
- **Web Server**: Nginx (reverse proxy + static files)
- **Cache**: Redis (опционально)
- **Health Check**: `/health/` endpoint

## Быстрое развертывание с локального компьютера на сервер

### Предварительные требования на сервере:
- Ubuntu 20.04+ или Debian 11+
- Минимум 1GB RAM, 2GB рекомендуется
- 5GB свободного места
- Root доступ или sudo

### Шаг 1: Подготовка сервера
```bash
# Обновите систему
sudo apt update && sudo apt upgrade -y

# Установите необходимые пакеты
sudo apt install -y curl wget git htop ufw

# Настройте firewall (разрешите SSH, HTTP, HTTPS)
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Установите Docker и Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Добавьте пользователя в группу docker (замените 'user' на ваше имя пользователя)
sudo usermod -aG docker user
```

### Шаг 2: Загрузка проекта на сервер
```bash
# На вашем локальном компьютере (в директории проекта)
# Убедитесь, что .gitignore создан и добавлен в репозиторий
git add .gitignore
git commit -m "Add .gitignore file"

# Если у вас еще нет репозитория, создайте его:
git init
git add .
git commit -m "Initial commit"

# Создайте репозиторий на GitHub/GitLab и запушьте:
# git remote add origin https://github.com/your-username/habits-tracker.git
# git push -u origin main

# На сервере:
git clone https://github.com/your-username/habits-tracker.git
cd habits-tracker
```

### Шаг 3: Настройка переменных окружения
```bash
# Скопируйте файл с примером настроек
cp env.example .env

# Отредактируйте настройки (замените значения на реальные)
nano .env

# Минимально необходимые изменения:
# DEBUG=False
# SECRET_KEY=ваш-секретный-ключ-минимум-50-символов
# ALLOWED_HOSTS=ваш-домен.com,www.ваш-домен.com,ip-адрес-сервера
# DATABASE_URL=postgresql://habits_user:ваш_пароль@localhost:5432/habits_db
# REACT_APP_API_URL=https://ваш-домен.com/api
```

### Шаг 4: Запуск приложения
```bash
# Запустите приложение в фоне
docker-compose up -d --build

# Проверьте статус контейнеров
docker-compose ps

# Посмотрите логи для проверки запуска
docker-compose logs -f
```

### Шаг 5: Настройка домена и SSL (опционально)
```bash
# Установите Nginx (если нужен реверс-прокси)
sudo apt install nginx -y

# Создайте конфигурацию Nginx
sudo nano /etc/nginx/sites-available/habits-tracker

# Добавьте:
server {
    listen 80;
    server_name ваш-домен.com www.ваш-домен.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /path/to/your/project/backend/staticfiles/;
    }
}

# Активируйте сайт
sudo ln -s /etc/nginx/sites-available/habits-tracker /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Установите SSL сертификат (Let's Encrypt)
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d ваш-домен.com -d www.ваш-домен.com
```

### Шаг 6: Финальная проверка
```bash
# Проверьте, что приложение работает
curl http://localhost:8000/api/
curl http://ваш-домен.com/api/

# Создайте суперпользователя
docker-compose exec backend python manage.py createsuperuser

# Выполните миграции базы данных (если нужно)
docker-compose exec backend python manage.py migrate
```

## Варианты развертывания

### 1. Развертывание с помощью Docker (Рекомендуемый способ)

#### Требования:
- Docker и Docker Compose
- Минимум 1GB RAM
- 5GB свободного места

#### Шаги:

1. **Клонируйте репозиторий:**
   ```bash
   git clone <your-repo-url>
   cd habbits-main
   ```

2. **Создайте файл окружения:**
   ```bash
   cp env.example .env
   # Отредактируйте .env файл с вашими настройками
   ```

3. **Запустите приложение:**
   ```bash
   # Для разработки (с отдельными контейнерами)
   docker-compose up --build

   # Для production (один контейнер)
   docker build -t habits-tracker .
   docker run -p 8000:8000 habits-tracker
   ```

4. **Проверьте работу:**
   - Frontend: http://localhost:3000 (в dev режиме)
   - Backend API: http://localhost:8000/api/
   - Admin panel: http://localhost:8000/admin/

### 2. Развертывание на VPS (Ubuntu/Debian)

#### Требования:
- Ubuntu 20.04+ или Debian 11+
- Python 3.11+
- Node.js 18+
- Nginx
- PostgreSQL (рекомендуется)

#### Шаги установки:

1. **Обновите систему:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Установите зависимости:**
   ```bash
   # Python и pip
   sudo apt install python3 python3-pip python3-venv -y

   # Node.js
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs

   # PostgreSQL
   sudo apt install postgresql postgresql-contrib -y

   # Nginx
   sudo apt install nginx -y
   ```

3. **Настройте базу данных:**
   ```bash
   sudo -u postgres psql
   CREATE DATABASE habits_db;
   CREATE USER habits_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE habits_db TO habits_user;
   \q
   ```

4. **Настройте проект:**

   ```bash
   # Клонируйте репозиторий
   git clone <your-repo-url>
   cd habbits-main

   # Настройте backend
   cd backend
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt

   # Настройте переменные окружения
   cp ../env.example ../.env
   # Отредактируйте .env файл

   # Выполните миграции
   python manage.py migrate
   python manage.py collectstatic --noinput

   # Создайте суперпользователя
   python manage.py createsuperuser
   ```

5. **Соберите React приложение:**
   ```bash
   cd ../frontend
   npm install
   npm run build
   ```

6. **Настройте Nginx:**
   ```bash
   sudo nano /etc/nginx/sites-available/habits-tracker
   ```

   Добавьте конфигурацию:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location = /favicon.ico { access_log off; log_not_found off; }

       location /static/ {
           alias /path/to/your/project/backend/staticfiles/;
       }

       location / {
           include proxy_params;
           proxy_pass http://127.0.0.1:8000;
       }
   }
   ```

   ```bash
   sudo ln -s /etc/nginx/sites-available/habits-tracker /etc/nginx/sites-enabled
   sudo nginx -t
   sudo systemctl restart nginx
   ```

7. **Настройте Gunicorn:**
   ```bash
   # Установите gunicorn
   source /path/to/your/project/backend/venv/bin/activate
   pip install gunicorn

   # Создайте systemd service
   sudo nano /etc/systemd/system/habits-tracker.service
   ```

   Добавьте:
   ```ini
   [Unit]
   Description=Habits Tracker Django App
   After=network.target

   [Service]
   User=your-user
   Group=www-data
   WorkingDirectory=/path/to/your/project/backend
   Environment="PATH=/path/to/your/project/backend/venv/bin"
   ExecStart=/path/to/your/project/backend/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 backend.wsgi:application

   [Install]
   WantedBy=multi-user.target
   ```

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl start habits-tracker
   sudo systemctl enable habits-tracker
   ```

### 3. Развертывание на Heroku

1. **Установите Heroku CLI и войдите:**
   ```bash
   # Скачайте и установите Heroku CLI
   heroku login
   ```

2. **Создайте приложение:**
   ```bash
   heroku create your-app-name
   ```

3. **Настройте переменные окружения:**
   ```bash
   heroku config:set DEBUG=False
   heroku config:set SECRET_KEY=your-secret-key
   heroku config:set ALLOWED_HOSTS=your-app-name.herokuapp.com
   ```

4. **Создайте Procfile:**
   ```Procfile
   web: gunicorn backend.wsgi --log-file -
   ```

5. **Закоммитьте и запушьте:**
   ```bash
   git add .
   git commit -m "Deploy to Heroku"
   git push heroku main
   ```

6. **Выполните миграции:**
   ```bash
   heroku run python backend/manage.py migrate
   heroku run python backend/manage.py createsuperuser
   ```

### 4. Развертывание на Railway

1. **Создайте аккаунт на Railway**
2. **Подключите GitHub репозиторий**
3. **Railway автоматически обнаружит и развернет приложение**
4. **Настройте переменные окружения в Railway dashboard**

## После развертывания

### Проверка работоспособности:
1. Откройте приложение в браузере
2. Проверьте API endpoints: `/api/v1/habits/`, `/api/v1/dates/`
3. Войдите в админку: `/admin/`

### Безопасность:
1. **Измените SECRET_KEY** на случайную строку
2. **Установите DEBUG=False** в production
3. **Настройте ALLOWED_HOSTS** только для вашего домена
4. **Используйте HTTPS** (Let's Encrypt для Nginx)
5. **Регулярно обновляйте зависимости**

### Мониторинг:
- Настройте логирование
- Мониторьте использование ресурсов
- Настройте бэкапы базы данных

## Troubleshooting

### Проблемы с CORS:
- Проверьте настройки CORS_ALLOWED_ORIGINS в settings.py
- Убедитесь, что django-cors-headers установлен

### Статические файлы не загружаются:
```bash
python manage.py collectstatic --noinput
```

### База данных не работает:
- Проверьте DATABASE_URL
- Выполните миграции: `python manage.py migrate`

### React не собирается:
```bash
cd frontend
npm install
npm run build
```
