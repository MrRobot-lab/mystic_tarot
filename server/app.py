from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

# Telegram Bot Token
BOT_TOKEN = "8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"
TELEGRAM_API = f"https://api.telegram.org/bot{BOT_TOKEN}"

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

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
    app.run(host='0.0.0.0', port=5000, debug=True)
