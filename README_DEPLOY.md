# 🚀 Быстрое развертывание Habits Tracker

## Для нетерпеливых (3 минуты на сервер)

```bash
# На сервере:
sudo apt update && sudo apt install -y docker.io docker-compose git curl
git clone <ваш-репозиторий>
cd habits-tracker
cp env.example .env
# Отредактируйте .env файл (минимум SECRET_KEY и ALLOWED_HOSTS)
nano .env
./deploy.sh
```

**Готово!** Приложение работает на `http://your-server-ip`

## Что делает deploy.sh

Скрипт автоматически:
- ✅ Проверяет зависимости
- ✅ Собирает Docker образы
- ✅ Запускает все сервисы
- ✅ Выполняет миграции БД
- ✅ Собирает статические файлы
- ✅ Проверяет здоровье приложения

## Команды управления

```bash
./deploy.sh        # Полное развертывание
./deploy.sh down   # Остановить
./deploy.sh logs   # Логи
./deploy.sh status # Статус
```

## Переменные окружения (.env)

Обязательные:
```bash
DEBUG=False
SECRET_KEY=ваш-секретный-ключ
ALLOWED_HOSTS=your-domain.com,server-ip
DATABASE_URL=postgresql://user:password@db:5432/habits_db
```

## Архитектура

```
Internet → Nginx (80/443) → Gunicorn → Django → PostgreSQL
                     ↓
                Static Files
                     ↓
                  Redis Cache
```

## Мониторинг

- Health check: `http://your-server/health/`
- Логи: `docker-compose -f docker-compose.prod.yml logs`
- Метрики: `docker stats`

## Безопасность

- [ ] Измените SECRET_KEY
- [ ] Настройте ALLOWED_HOSTS
- [ ] Добавьте HTTPS (Let's Encrypt)
- [ ] Настройте firewall
- [ ] Регулярно обновляйте образы

## Troubleshooting

**Приложение не запускается:**
```bash
./deploy.sh logs
```

**Проблемы с БД:**
```bash
docker-compose -f docker-compose.prod.yml exec db psql -U habits_user -d habits_db
```

**Пересборка:**
```bash
docker-compose -f docker-compose.prod.yml build --no-cache
./deploy.sh
```
