#!/bin/bash
# INTARIUS - Проверка Webhook и Версии
# Запуск: bash check_webhook.sh

BOT_TOKEN="8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"

echo "🔍 Проверка версии app.py..."
if grep -q "webhook" /opt/intarius-api/app.py; then
    echo "✅ app.py содержит webhook (ОК)"
else
    echo "❌ app.py УСТАРЕЛ! (Нет webhook). Запусти bash update_api.sh"
fi

echo ""
echo "🔍 Статус Webhook в Telegram:"
curl -s "https://api.telegram.org/bot$BOT_TOKEN/getWebhookInfo" | python3 -m json.tool
