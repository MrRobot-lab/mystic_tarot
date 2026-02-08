#!/bin/bash
# INTARIUS - Настройка приветствия (/start) с картинкой
# Запуск: bash update_api_start.sh

echo "🚀 Настройка Start Message..."

# 1. Обновляем app.py
cat > /opt/intarius-api/app.py << 'PYTHON_APP'
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

# Config
BOT_TOKEN = "8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"
TELEGRAM_API = f"https://api.telegram.org/bot{BOT_TOKEN}"
DOMAIN = "104.238.24.57.nip.io"
PORT = "8443"
BASE_URL = f"https://{DOMAIN}:{PORT}"

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

@app.route('/webhook', methods=['POST'])
def webhook():
    try:
        data = request.json
        if not data:
            return jsonify({"status": "no data"}), 200
        
        # Handle '/start' command
        if 'message' in data:
            chat_id = data['message']['chat']['id']
            text = data['message'].get('text', '')
            
            if text.startswith('/start'):
                send_welcome(chat_id)
                
        return jsonify({"status": "ok"})
    except Exception as e:
        print(f"Webhook Error: {e}")
        return jsonify({"error": str(e)}), 500

def send_welcome(chat_id):
    # Image URL (hosted in assets folder)
    photo_url = f"{BASE_URL}/assets/start_bg.jpg?v=1"
    
    caption = """✨ *Здравствуй, ищущая ответы.*

Ты здесь не случайно. Вселенная привела тебя в это место, чтобы открыть тайны, скрытые за пеленой обыденности.

🔮 **INTARIUS** — твой проводник в мир древних знаний.
Здесь карты Таро говорят на языке твоей души, раскрывая то, что было скрыто, и освещая путь.

*Готова ли ты заглянуть в свою судьбу?*
Нажми кнопку ниже, и позволь картам поведать тебе истину..."""
    
    # Send Photo with Button
    try:
        r = requests.post(f"{TELEGRAM_API}/sendPhoto", json={
            "chat_id": chat_id,
            "photo": photo_url,
            "caption": caption,
            "parse_mode": "Markdown",
            "reply_markup": {
                "inline_keyboard": [[
                    {"text": "✨ Узнать судьбу", "web_app": {"url": BASE_URL}}
                ]]
            }
        })
        print(f"Welcome sent: {r.status_code}")
    except Exception as e:
        print(f"Failed to send welcome: {e}")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYTHON_APP

# 2. Перезапуск сервиса
echo "⚙️ Перезапуск сервиса..."
systemctl restart intarius-api

# 3. Установка Webhook (на всякий случай)
WEBHOOK_URL="https://104.238.24.57.nip.io:8443/api/webhook"
echo "🔗 Установка Webhook: $WEBHOOK_URL"
curl -F "url=$WEBHOOK_URL" "https://api.telegram.org/bot$BOT_TOKEN/setWebhook"

echo ""
echo "✅ Start Message настроен!"
