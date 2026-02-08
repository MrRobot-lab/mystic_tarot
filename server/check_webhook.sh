#!/bin/bash
# INTARIUS - Расширенная проверка
# Запуск: bash check_webhook.sh

BOT_TOKEN="8367087520:AAGbp4dtdOKHKQ6N5vUg7TFzQTJVXeFVAiI"

echo "🔍 1. Проверка портов:"
netstat -tulnp | grep -E ':(80|443|8443|5000)'

echo ""
echo "🔍 2. Статус Webhook:"
curl -s "https://api.telegram.org/bot$BOT_TOKEN/getWebhookInfo" | python3 -m json.tool

echo ""
echo "🔍 3. Логи ошибок (последние 20):"
journalctl -u intarius-api -n 20 --no-pager
