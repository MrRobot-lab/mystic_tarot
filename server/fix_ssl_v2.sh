#!/bin/bash
# INTARIUS - Исправление SSL v2 (Hard Reset)
# Запуск: bash fix_ssl_v2.sh

DOMAIN="104.238.24.57.nip.io"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

echo "🔧 Исправление SSL (v2)..."

echo "1. Остановка Nginx:"
systemctl stop nginx

echo "2. Создание минималистичного конфига..."
cat > /etc/nginx/sites-available/intarius-api << NGINX
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_PATH/fullchain.pem;
    ssl_certificate_key $CERT_PATH/privkey.pem;

    # Минимальные настройки SSL (Без файлов certbot)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        
        # CORS
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type' always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
}
NGINX

echo "3. Включение конфига:"
ln -sf /etc/nginx/sites-available/intarius-api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t

echo "4. Запуск Nginx:"
systemctl start nginx
systemctl status nginx --no-pager

echo ""
echo "5. Тест HTTPS:"
curl -v https://$DOMAIN/api/health
echo ""
