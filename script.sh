#!/bin/bash

# Update and install basic dependencies
echo "Updating system and installing basic tools..."
apt update && apt upgrade -y
apt install -y curl wget git sudo software-properties-common apt-transport-https lsb-release ca-certificates

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker
systemctl enable docker --now
echo "Docker installed successfully!"

# Install sysmactl and sysmact
echo "Installing sysmactl and sysmact..."
curl -fsSL https://raw.githubusercontent.com/steeldev0/sysmactl/main/install.sh | bash

# Clone and set up the port script
echo "Setting up the port script..."
apt update && apt install git -y && cd && git clone https://github.com/steeldev0/port && chmod +x port/port && mv port/port /bin && rm -rf ~/port
echo "Port script installed successfully!"

# Install dependencies for Pterodactyl Panel and Wings
echo "Installing dependencies for Pterodactyl Panel and Wings..."
apt install -y unzip zip tar nginx mariadb-server mariadb-client php8.1 php8.1-cli php8.1-fpm \
php8.1-mysql php8.1-mbstring php8.1-xml php8.1-curl php8.1-zip php8.1-bcmath composer

# Set up MariaDB
echo "Configuring MariaDB..."
systemctl start mariadb
systemctl enable mariadb
mysql_secure_installation <<EOF

y
root
root
y
y
y
y
EOF
echo "MariaDB configured successfully!"

# Download and set up Pterodactyl Panel
echo "Downloading and setting up Pterodactyl Panel..."
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# Install Panel Dependencies
cp .env.example .env
composer install --no-dev --optimize-autoloader

# Configure Pterodactyl
php artisan p:environment:setup <<EOF
https://localhost
admin@admin.com
admin
admin
EOF
php artisan migrate --force
php artisan p:user:make <<EOF
user
admin@admin.com
root
EOF
echo "Pterodactyl Panel installed successfully!"

# Set Permissions and Enable Services
chown -R www-data:www-data /var/www/pterodactyl
systemctl enable --now nginx

# Install Wings
echo "Installing Pterodactyl Wings..."
curl -Lo /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod +x /usr/local/bin/wings

# Done
echo "Pterodactyl setup completed successfully!"