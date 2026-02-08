#!/bin/bash
# INTARIUS - Исправление SSL
# Запуск: bash fix_ssl.sh

DOMAIN="104.238.24.57.nip.io"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

echo "🔧 Исправление SSL конфигурации..."

# 1. Проверяем сертификаты
if [ ! -d "$CERT_PATH" ]; then
    echo "❌ Сертификаты не найдены! Запускаю Certbot заново..."
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email
fi

# 2. Создаем правильный конфиг Nginx
echo "📝 Перезапись конфигурации Nginx..."

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
    
    # Рекомендованные настройки SSL (если файлов нет, закомментируйте вручную или обновите certbot)
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

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

# 3. Перезапук Nginx
echo "🔄 Перезапуск Nginx..."
ln -sf /etc/nginx/sites-available/intarius-api /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# 4. Проверка
echo ""
echo "🔍 Тест HTTPS..."
curl -v https://$DOMAIN/api/health
echo ""
