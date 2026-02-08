#!/bin/bash
# INTARIUS - Обновление API v2 (Иконки + Пустой запрос)
# Запуск: bash update_api_v2.sh

echo "📝 Обновление app.py (v2)..."

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
    
    results = []

    if not query_text:
        # 1. Empty Query (Default result)
        results.append({
            "type": "article",
            "id": "default_open",
            "title": "🔮 Узнать свою судьбу",
            "description": "Нажми, чтобы открыть карты Таро",
            "input_message_content": {
                "message_text": "🔮 *INTARIUS*\n\nХочешь узнать, что готовят тебе карты?\nНажми кнопку ниже!",
                "parse_mode": "MarkdownV2"
            },
            "reply_markup": {
                "inline_keyboard": [[
                    {
                        "text": "✨ Открыть приложение",
                        "url": "https://t.me/Intarius_bot/app" 
                    }
                ]]
            },
            "thumb_url": ICON_URL
        })
    else:
        # 2. Prediction Query
        result_id = hashlib.md5(query_text.encode()).hexdigest()
        advice = escape_markdown(query_text)
        
        message_text = f"""🔮 *INTARIUS* — приоткрыл мне завесу

*Судьба мне благоволит — пожелай, чтобы это исполнилось\\.*

Мой совет на день: *{advice}*"""

        results.append({
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
        })
    
    # Answer Inline Query
    requests.post(f"{TELEGRAM_API}/answerInlineQuery", json={
        "inline_query_id": query_id,
        "results": results,
        "cache_time": 0
    })

@app.route('/share', methods=['POST', 'OPTIONS'])
def share():
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        return '', 204
    return jsonify({"status": "deprecated"}), 200

def escape_markdown(text):
    """Escape special characters for MarkdownV2"""
    special_chars = ['_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '.', '!']
    for char in special_chars:
        text = text.replace(char, f'\\{char}')
    return text

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYTHON_APP

echo "⚙️ Перезапуск сервиса..."
systemctl restart intarius-api
echo "✅ API обновлен (v2)!"
