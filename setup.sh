#!/bin/bash

# Update system packages
apt-get update

# Install build essentials
apt-get install -y build-essential

# Install Python 3.8 and pip
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
apt-get install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.8 python3-pip

# Install NodeJS 18.X and npm
apt-get install -y curl dirmngr apt-transport-https lsb-release ca-certificates
curl -sL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install -g npm@latest

# Clone the repository
git clone https://github.com/miroslavpejic85/mirotalksfu.git

# Go to the mirotalksfu directory
cd mirotalksfu

# Copy the configuration file
cp app/src/config.template.js app/src/config.js

# Get the server's public IP address
server_ip=$(curl -s ifconfig.me)

# Replace 'getLocalIp()' with the server's IP address in app/src/config.js
sed -i "s/getLocalIp()/'$server_ip'/g" app/src/config.js

# Install dependencies
npm install

# Install Nginx
apt-get install -y nginx

# Install Certbot (SSL certificates)
apt-get install -y snapd
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# Configure Nginx sites
cat > /etc/nginx/sites-available/mirotalk << EOF
server {
    if (\$host = sfu.mirotalk.haiphong.online) {
        return 301 https://\$host\$request_uri;
    }

    listen 80;
    listen [::]:80;

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
    listen [::]:443 ssl http2;

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

# Create a symbolic link for the Nginx site
ln -s /etc/nginx/sites-available/mirotalk /etc/nginx/sites-enabled/mirotalk

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx

# Allow ports for Mirotalk and SSH
ufw allow 3010
ufw allow 22

# Enable UFW firewall
ufw enable

# Install PM2
npm install pm2 -g

# Start the application with PM2
pm2 start server.js

# Save the PM2 process list and enable auto-start on boot
pm2 save
pm2 startup

# Renew SSL certificate
certbot renew --dry-run

echo "Mirotalk SFU setup completed successfully."
