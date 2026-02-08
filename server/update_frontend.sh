#!/bin/bash
# INTARIUS - Обновление Frontend (GitHub -> Server)
# Запуск: bash update_frontend.sh

echo "📥 Обновление Frontend..."

cd /var/www/html || exit
git pull

echo ""
echo "✅ Frontend обновлен!"
