#!/bin/bash
# INTARIUS - Удаление Webhook
# Запуск: bash unset_webhook.sh

BOT_TOKEN="8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"

echo "🗑️ Удаление Webhook..."

curl -X POST "https://api.telegram.org/bot$BOT_TOKEN/deleteWebhook"

echo ""
echo "✅ Webhook удален!"
