#!/bin/bash

# Update system packages
sudo apt-get update

# Install build essentials
sudo apt-get install -y build-essential

# Install Python 3.8 and pip
sudo apt-get install -y python3.8 python3-pip

# Install NodeJS 18.X and npm
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone the repository
git clone https://github.com/miroslavpejic85/mirotalksfu.git

# Navigate to the mirotalksfu directory
cd mirotalksfu

# Copy app/src/config.template.js to app/src/config.js
cp app/src/config.template.js app/src/config.js

# Update the announcedIp in app/src/config.js
sed -i "s/'Server Public IPv4'/'$(curl -s ifconfig.me)'/" app/src/config.js

# Install dependencies
npm install

# Install Nginx
sudo apt-get install -y nginx

# Configure Nginx
sudo tee /etc/nginx/sites-available/mirotalk <<EOF
server {
    listen 80;
    server_name sfu.mirotalk.haiphong.online;

    location / {
        proxy_pass http://localhost:3010;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}

server {
    listen 443 ssl http2;
    server_name sfu.mirotalk.haiphong.online;

    ssl_certificate /etc/letsencrypt/live/sfu.mirotalk.haiphong.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sfu.mirotalk.haiphong.online/privkey.pem;

    location / {
        proxy_pass http://localhost:3010;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable the site
sudo ln -s /etc/nginx/sites-available/mirotalk /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Obtain SSL certificate with Certbot
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d sfu.mirotalk.haiphong.online

# Auto renew SSL certificate
sudo certbot renew --dry-run

# Check the installed certificates
sudo certbot certificates
