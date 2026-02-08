#!/bin/bash
# INTARIUS - Откат API (Без Inline)
# Запуск: bash restore_api_clean.sh

echo "🧹 Удаление Inline-функционала из app.py..."

cat > /opt/intarius-api/app.py << 'PYTHON_APP'
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

# Telegram Bot Token
BOT_TOKEN = "8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"
TELEGRAM_API = f"https://api.telegram.org/bot{BOT_TOKEN}"

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

# Webhook removed

@app.route('/share', methods=['POST', 'OPTIONS'])
def share():
    if request.method == 'OPTIONS':
        return '', 204
    return jsonify({"status": "deprecated"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYTHON_APP

echo "⚙️ Перезапуск сервиса..."
systemctl restart intarius-api
echo "✅ API очищен от Inline!"
