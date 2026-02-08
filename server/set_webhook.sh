#!/bin/bash
# INTARIUS - Установка Webhook для Inline Mode
# Запуск: bash set_webhook.sh

BOT_TOKEN="8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"
WEBHOOK_URL="https://104.238.24.57.nip.io:8443/api/webhook"

echo "🔗 Установка Webhook: $WEBHOOK_URL"

curl -X POST "https://api.telegram.org/bot$BOT_TOKEN/setWebhook" \
     -H "Content-Type: application/json" \
     -d "{\"url\": \"$WEBHOOK_URL\"}"

echo ""
echo "✅ Webhook установлен!"
echo "Теперь перезапусти бота:"
echo "systemctl restart intarius-api"
