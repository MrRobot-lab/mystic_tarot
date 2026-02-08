# Telegram Share Backend - Установка

## Шаг 1: Подключение к серверу и установка Python

```bash
ssh root@104.238.24.57
# Пароль: PcYQNDoa3VPi

# Обновляем систему и ставим Python
apt update && apt upgrade -y
apt install python3 python3-pip python3-venv nginx certbot python3-certbot-nginx -y
```

## Шаг 2: Создаём директорию проекта

```bash
mkdir -p /opt/intarius-api
cd /opt/intarius-api
python3 -m venv venv
source venv/bin/activate
pip install flask gunicorn python-telegram-bot requests
```

## Шаг 3: Создаём файл бота

Создай файл `/opt/intarius-api/app.py`:

```bash
nano /opt/intarius-api/app.py
```

Вставь содержимое из файла `server/app.py` в этом репозитории.

## Шаг 4: Создаём systemd сервис

```bash
nano /etc/systemd/system/intarius-api.service
```

Вставь:
```ini
[Unit]
Description=Intarius Share API
After=network.target

[Service]
User=root
WorkingDirectory=/opt/intarius-api
Environment="PATH=/opt/intarius-api/venv/bin"
ExecStart=/opt/intarius-api/venv/bin/gunicorn --workers 2 --bind 127.0.0.1:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
```

## Шаг 5: Запускаем сервис

```bash
systemctl daemon-reload
systemctl enable intarius-api
systemctl start intarius-api
systemctl status intarius-api
```

## Шаг 6: Настраиваем Nginx

```bash
nano /etc/nginx/sites-available/intarius-api
```

Вставь:
```nginx
server {
    listen 80;
    server_name 104.238.24.57;

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }
}
```

```bash
ln -s /etc/nginx/sites-available/intarius-api /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

## Шаг 7: Проверяем

```bash
curl http://104.238.24.57/api/health
```

Должен ответить: `{"status": "ok"}`

## Для HTTPS (позже, если будет домен)

```bash
certbot --nginx -d yourdomain.com
```
