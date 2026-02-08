#!/bin/bash
# INTARIUS - Скрипт диагностики
# Запуск: bash troubleshoot.sh

echo "🔍 Диагностика сервера..."
echo "=========================="

echo "1. Статус сервиса бота:"
systemctl status intarius-api --no-pager
echo ""

echo "2. Проверка порта 5000 (Flask):"
if netstat -tuln | grep :5000 > /dev/null; then
    echo "✅ Порт 5000 слушается"
else
    echo "❌ Порт 5000 НЕ СЛУШАЕТСЯ (Бот не запущен)"
fi
echo ""

echo "3. Проверка Nginx:"
nginx -t
echo ""

echo "4. Последние логи бота (ошибки):"
journalctl -u intarius-api -n 20 --no-pager
echo ""

echo "5. Логи ошибок Nginx:"
tail -n 20 /var/log/nginx/error.log
echo ""

echo "6. Тест API (локально):"
curl -v http://127.0.0.1:5000/health
echo ""

echo "7. Тест API (через домен):"
curl -v https://104.238.24.57.nip.io/api/health
echo ""

echo "=========================="
echo "Диагностика завершена. Скинь мне вывод этого скрипта!"
