#!/bin/bash
# INTARIUS - Обновление API (Webhooks + Inline)
# Запуск: bash update_api.sh

echo "📝 Обновление app.py..."

cat > /opt/intarius-api/app.py << 'PYTHON_APP'
from flask import Flask, request, jsonify
import requests
import hashlib

app = Flask(__name__)

# Telegram Bot Token
BOT_TOKEN = "8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"
TELEGRAM_API = f"https://api.telegram.org/bot{BOT_TOKEN}"

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
    query_text = inline_query.get('query', '')
    
    if not query_text:
        return

    # Create a unique ID for the result
    result_id = hashlib.md5(query_text.encode()).hexdigest()
    
    # Format message content
    advice = escape_markdown(query_text)
    message_text = f"""🔮 *INTARIUS* — приоткрыл мне завесу

*Судьба мне благоволит — пожелай, чтобы это исполнилось\\.*

Мой совет на день: *{advice}*"""

    results = [{
        "type": "article",
        "id": result_id,
        "title": "Поделиться предсказанием",
        "description": query_text,
        "input_message_content": {
            "message_text": message_text,
            "parse_mode": "MarkdownV2"
        },
        "reply_markup": {
            "inline_keyboard": [[
                {
                    "text": "✨ Узнай свою судьбу",
                    "url": "https://t.me/Intarius_bot"
                }
            ]]
        },
        "thumb_url": "https://raw.githubusercontent.com/imrro/mystic_tarot/main/icon.png" # Optional: Update with real icon URL if available
    }]
    
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
    
    try:
        data = request.json
        chat_id = data.get('chat_id')
        advice = data.get('advice', 'Доверься своей интуиции')
        
        if not chat_id:
            return jsonify({"error": "chat_id required"}), 400
        
        # Format message with MarkdownV2
        text = f"""🔮 *INTARIUS* — приоткрыл мне завесу

*Судьба мне благоволит — пожелай, чтобы это исполнилось\\.*

Мой совет на день: *{escape_markdown(advice)}*"""

        # Inline keyboard with button
        keyboard = {
            "inline_keyboard": [[
                {
                    "text": "✨ Узнай свою судьбу",
                    "url": "https://t.me/Intarius_bot"
                }
            ]]
        }
        
        # Send message via Telegram Bot API
        response = requests.post(f"{TELEGRAM_API}/sendMessage", json={
            "chat_id": chat_id,
            "text": text,
            "parse_mode": "MarkdownV2",
            "reply_markup": keyboard
        })
        
        result = response.json()
        
        if result.get('ok'):
            return jsonify({"success": True, "message_id": result['result']['message_id']})
        else:
            return jsonify({"error": result.get('description', 'Unknown error')}), 400
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

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
echo "✅ API обновлен!"
