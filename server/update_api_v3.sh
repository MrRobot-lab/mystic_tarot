#!/bin/bash
# INTARIUS - Обновление API v3 (Исправление пустого запроса)
# Запуск: bash update_api_v3.sh

echo "📝 Обновление app.py (v3)..."

cat > /opt/intarius-api/app.py << 'PYTHON_APP'
from flask import Flask, request, jsonify
import requests
import hashlib

app = Flask(__name__)

# Telegram Bot Token
BOT_TOKEN = "8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"
TELEGRAM_API = f"https://api.telegram.org/bot{BOT_TOKEN}"

# Icon URL (можно заменить на свою ссылку)
ICON_URL = "https://cdn-icons-png.flaticon.com/512/4743/4743169.png" # Crystal ball icon

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

@app.route('/webhook', methods=['POST'])
def webhook():
    try:
        data = request.json
        if not data:
            return jsonify({"status": "no data"}), 400
            
        # Handle Inline Query
        if 'inline_query' in data:
            handle_inline_query(data['inline_query'])
            
        return jsonify({"status": "ok"})
    except Exception as e:
        print(f"Webhook Error: {e}")
        return jsonify({"error": str(e)}), 500

def handle_inline_query(inline_query):
    query_id = inline_query['id']
    query_text = inline_query.get('query', '').strip()
    
    # 1. Empty Query -> Show "Start App" button
    if not query_text:
        requests.post(f"{TELEGRAM_API}/answerInlineQuery", json={
            "inline_query_id": query_id,
            "results": [],
            "switch_pm_text": "🔮 Узнать судьбу (открыть приложение)",
            "switch_pm_parameter": "open_app",
            "cache_time": 0
        })
        return

    # 2. Prediction Query -> Show Card
    result_id = hashlib.md5(query_text.encode()).hexdigest()
    advice = escape_markdown(query_text)
    
    message_text = f"""🔮 *INTARIUS* — приоткрыл мне завесу

*Судьба мне благоволит — пожелай, чтобы это исполнилось\\.*

Мой совет на день: *{advice}*"""

    results = [{
        "type": "article",
        "id": result_id,
        "title": "Поделиться предсказанием",
        "description": query_text[:50] + "..." if len(query_text) > 50 else query_text,
        "input_message_content": {
            "message_text": message_text,
            "parse_mode": "MarkdownV2"
        },
        "reply_markup": {
            "inline_keyboard": [[
                {
                    "text": "✨ Узнай свою судьбу",
                    "url": "https://t.me/Intarius_bot/app"
                }
            ]]
        },
        "thumb_url": ICON_URL
    }]
    
    # Answer Inline Query
    try:
        r = requests.post(f"{TELEGRAM_API}/answerInlineQuery", json={
            "inline_query_id": query_id,
            "results": results,
            "cache_time": 0
        })
        print(f"Answer sent: {r.status_code} {r.text}")
    except Exception as e:
        print(f"Answer failed: {e}")

@app.route('/share', methods=['POST', 'OPTIONS'])
def share():
    if request.method == 'OPTIONS':
        return '', 204
    return jsonify({"status": "deprecated"}), 200

def escape_markdown(text):
    special_chars = ['_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '.', '!']
    for char in special_chars:
        text = text.replace(char, f'\\{char}')
    return text

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYTHON_APP

echo "⚙️ Перезапуск сервиса..."
systemctl restart intarius-api
echo "✅ API обновлен (v3)!"
