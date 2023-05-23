#!/bin/bash

# Set hostname
hostnamectl set-hostname sfu.mirotalk.haiphong.online

# Update package lists
apt-get update

# Install essential build tools
apt-get install -y build-essential

# Install Python 3.8 and pip
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
apt install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa
apt update
apt install -y python3.8 python3-pip

# Install Node.js 18.x and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs
npm install -g npm@latest

# Clone the Git repository
git clone https://github.com/miroslavpejic85/mirotalksfu.git

# Change to the mirotalksfu directory
cd mirotalksfu

# Copy app/src/config.template.js to app/src/config.js
cp app/src/config.template.js app/src/config.js

# Replace 'Server Public IPv4' with your server's public IPv4 address in app/src/config.js
sed -i "s/'Server Public IPv4'/'$(curl -s ipinfo.io/ip)'/" app/src/config.js

# Install Nginx
apt-get install -y nginx

# Install Certbot (SSL certificates)
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# Configure Nginx sites
echo '
# HTTP — redirect all traffic to HTTPS
server {
    if ($host = sfu.mirotalk.haiphong.online) {
        return 301 https://$host$request_uri;
    }
    listen 80;
    listen [::]:80;
    server_name sfu.mirotalk.haiphong.online;
    return 404;
}

# MiroTalk SFU - HTTPS — proxy all requests to the Node app
server {
    # Enable HTTP/2
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name sfu.mirotalk.haiphong.online;

    # Use the Let’s Encrypt certificates
    ssl_certificate /etc/letsencrypt/live/sfu.mirotalk.haiphong.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sfu.mirotalk.haiphong.online/privkey.pem;

    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_pass http://localhost:3010/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
' > /etc/nginx/sites-enabled/default

# Check Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx

# Install PM2
npm install -g pm2

# Start the application using PM2
pm2 start npm --name "mirotalksfu" -- start

# Save the PM2 process list for automatic startup on system reboot
pm2 save

# Auto renew SSL certificate
certbot renew --dry-run

# Show certificates
certbot certificates
