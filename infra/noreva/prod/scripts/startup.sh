#!/bin/bash
set -e

#
# Startup Script for Company A Production VM
# 
# This script runs on first boot and installs:
# - Docker
# - docker-compose
# - Creates necessary directories
# - Sets up log rotation
#

# Logging
exec > >(tee /var/log/startup-script.log)
exec 2>&1

echo "================================"
echo "Starting VM initialization"
echo "Date: $(date)"
echo "================================"

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install prerequisites
echo "Installing prerequisites..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    vim \
    htop \
    unzip

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    echo "Docker installed successfully"
    docker --version
else
    echo "Docker already installed"
fi

# Install docker-compose (standalone, for compatibility with older compose files)
echo "Installing docker-compose standalone..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "docker-compose installed successfully"
    docker-compose --version
else
    echo "docker-compose already installed"
fi

# Create application directory structure
echo "Creating application directories..."
mkdir -p /opt/app
mkdir -p /opt/app/uploads
mkdir -p /opt/app/data/postgres
mkdir -p /opt/app/data/redis
mkdir -p /opt/app/ssl
mkdir -p /opt/app/logs
mkdir -p /opt/app/backups

# Set permissions
chown -R 1000:1000 /opt/app
chmod -R 755 /opt/app

# Install Google Cloud SDK (for backups to GCS)
echo "Installing Google Cloud SDK..."
if ! command -v gcloud &> /dev/null; then
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update
    apt-get install -y google-cloud-sdk
    
    echo "Google Cloud SDK installed"
else
    echo "Google Cloud SDK already installed"
fi

# Configure log rotation for Docker containers
echo "Configuring Docker log rotation..."
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

# Create a backup script
echo "Creating backup script..."
cat > /opt/app/backup.sh <<'EOF'
#!/bin/bash
# Database backup script
# Usage: /opt/app/backup.sh

BACKUP_DIR="/opt/app/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="db_backup_${TIMESTAMP}.sql.gz"

# Backup PostgreSQL (adjust container name if different)
docker exec postgres pg_dumpall -U postgres | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

# Optional: Upload to GCS (uncomment if using GCS backups)
# gsutil cp "${BACKUP_DIR}/${BACKUP_FILE}" gs://YOUR-BACKUP-BUCKET/

# Keep only last 7 days of local backups
find ${BACKUP_DIR} -name "db_backup_*.sql.gz" -mtime +7 -delete

echo "Backup completed: ${BACKUP_FILE}"
EOF

chmod +x /opt/app/backup.sh

# Create a daily backup cron job (commented out by default)
# echo "0 2 * * * /opt/app/backup.sh >> /opt/app/logs/backup.log 2>&1" | crontab -

# Install fail2ban for SSH protection (optional but recommended)
echo "Installing fail2ban..."
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Set up firewall with ufw (defense in depth)
echo "Configuring UFW firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw reload

# Create a deployment script template
cat > /opt/app/deploy.sh <<'EOF'
#!/bin/bash
# Deployment script template
# Customize this for your application deployment process

set -e

cd /opt/app

echo "Pulling latest changes..."
# git pull origin main

echo "Pulling Docker images..."
docker-compose pull

echo "Stopping containers..."
docker-compose down

echo "Starting containers..."
docker-compose up -d

echo "Waiting for services to be ready..."
sleep 10

echo "Running migrations (if applicable)..."
# docker-compose exec -T web python manage.py migrate

echo "Collecting static files (if applicable)..."
# docker-compose exec -T web python manage.py collectstatic --noinput

echo "Deployment complete!"
docker-compose ps
EOF

chmod +x /opt/app/deploy.sh

# System tuning for production
echo "Applying system tuning..."

# Increase file descriptor limits
cat >> /etc/security/limits.conf <<EOF
* soft nofile 65536
* hard nofile 65536
EOF

# Kernel tuning for network performance
cat >> /etc/sysctl.conf <<EOF
# Network tuning
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
vm.swappiness = 10
EOF

sysctl -p

echo "================================"
echo "VM initialization complete!"
echo "Date: $(date)"
echo "================================"
echo ""
echo "Next steps:"
echo "1. SSH to the VM: gcloud compute ssh company-a-prod-app-vm --zone=us-central1-a"
echo "2. Upload your docker-compose.yaml to /opt/app/"
echo "3. Configure environment variables"
echo "4. Run: cd /opt/app && docker-compose up -d"
echo ""
echo "Useful directories:"
echo "  /opt/app              - Application root"
echo "  /opt/app/uploads      - Uploaded files"
echo "  /opt/app/data         - Database and Redis data"
echo "  /opt/app/ssl          - SSL certificates"
echo "  /opt/app/logs         - Application logs"
echo "  /opt/app/backups      - Database backups"