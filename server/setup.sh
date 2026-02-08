#!/bin/bash
# INTARIUS API - Автоматическая установка (с HTTPS)
# Запуск: bash setup.sh

set -e

DOMAIN="104.238.24.57.nip.io"
EMAIL="admin@example.com" # Замените на реальный email для уведомлений

echo "🔮 INTARIUS API - Установка на $DOMAIN..."

# 1. Обновление системы
echo "📦 Обновление пакетов..."
apt update && apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx

# 2. Создание директории
echo "📁 Создание директории..."
mkdir -p /opt/intarius-api
cd /opt/intarius-api

# 3. Виртуальное окружение
echo "🐍 Настройка Python..."
python3 -m venv venv
source venv/bin/activate
pip install flask gunicorn requests

# 4. Создание приложения
echo "📝 Создание приложения..."
cat > app.py << 'PYTHON_APP'
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

# Токен настроен
BOT_TOKEN = "8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"
TELEGRAM_API = f"https://api.telegram.org/bot{BOT_TOKEN}"

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

@app.route('/share', methods=['POST', 'OPTIONS'])
def share():
    if request.method == 'OPTIONS':
        return '', 204
    
    try:
        data = request.json
        chat_id = data.get('chat_id')
        advice = data.get('advice', 'Доверься своей интуиции')
        
        if not chat_id:
            # Fallback if no chat_id (e.g. browser)
            return jsonify({"error": "chat_id required"}), 400
        
        def escape_md(text):
            for c in ['_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '.', '!']:
                text = text.replace(c, f'\\{c}')
            return text
        
        text = f"""🔮 *INTARIUS* — приоткрыл мне завесу

*Судьба мне благоволит — пожелай, чтобы это исполнилось\\.*

Мой совет на день: *{escape_md(advice)}*"""

        keyboard = {"inline_keyboard": [[{"text": "✨ Узнай свою судьбу", "url": "https://t.me/Intarius_bot"}]]}
        
        response = requests.post(f"{TELEGRAM_API}/sendMessage", json={
            "chat_id": chat_id,
            "text": text,
            "parse_mode": "MarkdownV2",
            "reply_markup": keyboard
        })
        
        result = response.json()
        if result.get('ok'):
            return jsonify({"success": True})
        else:
            return jsonify({"error": result.get('description')}), 400
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYTHON_APP

# 5. Systemd сервис
echo "⚙️ Настройка systemd..."
cat > /etc/systemd/system/intarius-api.service << 'SERVICE'
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
SERVICE

systemctl daemon-reload
systemctl enable intarius-api
systemctl start intarius-api

# 6. Nginx
echo "🌐 Настройка Nginx..."
cat > /etc/nginx/sites-available/intarius-api << NGINX
server {
    listen 80;
    server_name $DOMAIN;

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type' always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
}
NGINX

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/intarius-api /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# 7. HTTPS Certbot
echo "🔒 Настройка HTTPS (Certbot)..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect

# 8. Проверка
echo ""
echo "✅ Установка завершена!"
echo ""
echo "🔗 API доступен (HTTPS): https://$DOMAIN/api/health"
echo ""
