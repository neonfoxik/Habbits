# Habits Tracker - Приложение для отслеживания привычек

## Описание проекта
Приложение для отслеживания ежедневных привычек с веб-интерфейсом. Состоит из Django REST API backend и React frontend.

## Архитектура
- **Backend**: Django 5.2 + Django REST Framework
- **Frontend**: React 18
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **API**: RESTful API с CORS поддержкой

## Основные возможности
- Отслеживание ежедневных привычек
- Веб-интерфейс для отметки выполненных задач
- REST API для интеграции
- Админ панель Django

## Установка и запуск

### Для разработки

1. **Клонируйте репозиторий:**
   ```bash
   git clone <your-repo-url>
   cd habbits-main
   ```

2. **Backend (Django):**
   ```bash
   cd backend
   pip install -r requirements.txt
   python manage.py migrate
   python manage.py runserver
   ```

3. **Frontend (React):**
   ```bash
   cd frontend
   npm install
   npm start
   ```

4. **Откройте в браузере:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000/api/

### Использование Docker (рекомендуется)

```bash
# Запуск в режиме разработки
docker-compose up --build

# Или запуск в production режиме
docker build -t habits-tracker .
docker run -p 8000:8000 habits-tracker
```

## API Endpoints

- `GET/POST /api/v1/habits/` - Управление привычками
- `GET/POST /api/v1/dates/` - Даты выполнения привычек
- `GET/POST /api/v1/userall/` - Пользователи
- `GET /admin/` - Админ панель

## Структура проекта

```
habbits-main/
├── backend/                 # Django проект
│   ├── api/                # REST API приложение
│   ├── backend/            # Настройки Django
│   ├── main/               # Главное приложение
│   ├── manage.py
│   └── requirements.txt
├── frontend/               # React приложение
│   ├── src/
│   ├── public/
│   └── package.json
├── Dockerfile             # Docker для production
├── docker-compose.yml    # Docker Compose для разработки
└── DEPLOYMENT.md         # Инструкция по развертыванию
```

## Переменные окружения

Создайте файл `.env` в корне проекта:

```bash
DEBUG=True
SECRET_KEY=your-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3
REACT_APP_API_URL=http://localhost:8000/api
```

## Развертывание

Подробная инструкция по развертыванию на различных платформах находится в файле `DEPLOYMENT.md`.

### Кратко о вариантах развертывания:

1. **Docker** - самый простой способ
2. **VPS** - для полного контроля
3. **Heroku** - для быстрого старта
4. **Railway** - современная платформа

## Безопасность

- В production установите `DEBUG=False`
- Используйте сильный `SECRET_KEY`
- Настройте `ALLOWED_HOSTS`
- Включите HTTPS
- Регулярно обновляйте зависимости

## Разработка

### Добавление новой привычки:
1. Создайте объект Habit через API или админку
2. Он автоматически появится в интерфейсе

### Кастомизация интерфейса:
- Редактируйте `frontend/src/App.js`
- Стили в `frontend/src/App.css`

### Расширение API:
- Добавляйте новые эндпоинты в `backend/api/`
- Обновляйте сериализаторы в `backend/api/serializers.py`

## Поддержка

При возникновении проблем:
1. Проверьте логи сервера
2. Убедитесь, что все зависимости установлены
3. Проверьте настройки CORS
4. Ознакомьтесь с `DEPLOYMENT.md`

## Лицензия

MIT License
