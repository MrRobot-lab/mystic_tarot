#!/bin/bash
# INTARIUS - Исправление ошибки "Address in use"
# Запуск: bash fix_bind_error.sh

echo "📦 Установка утилит..."
apt update && apt install -y psmisc net-tools

echo "🛑 ПРИНУДИТЕЛЬНАЯ ОСТАНОВКА..."
service nginx stop
systemctl stop nginx
killall -9 nginx 2>/dev/null

echo "🛑 Освобождение портов 80 и 443..."
fuser -k 80/tcp
fuser -k 443/tcp

echo "🔍 Проверка портов (должна быть пустота):"
netstat -tulnp | grep -E ':(80|443)'

echo "🚀 Запуск Nginx..."
systemctl start nginx
systemctl status nginx --no-pager

echo ""
echo "🔍 Тест HTTPS:"
curl -v https://104.238.24.57.nip.io/api/health
