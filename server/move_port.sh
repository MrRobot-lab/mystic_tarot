#!/bin/bash
# INTARIUS - Смена порта на 8443 (для совместимости с VPN)
# Запуск: bash move_port.sh

DOMAIN="104.238.24.57.nip.io"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

echo "🔌 Настройка Nginx на порту 8443..."

# 1. Обновляем конфиг Nginx
cat > /etc/nginx/sites-available/intarius-api << NGINX
server {
    listen 8443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_PATH/fullchain.pem;
    ssl_certificate_key $CERT_PATH/privkey.pem;

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

# 2. Убиваем процесс Nginx (если он висит на 443)
echo "🛑 Остановка старого Nginx..."
systemctl stop nginx
fuser -k 80/tcp
fuser -k 443/tcp

# 3. Перезапуск
echo "🚀 Запуск Nginx на новом порту..."
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/intarius-api /etc/nginx/sites-enabled/
systemctl start nginx
systemctl status nginx --no-pager

echo ""
echo "✅ Nginx перенесен на порт 8443"
echo "Теперь запусти VPN (если он не работал)!"
echo "Тест: curl -v https://$DOMAIN:8443/api/health"
