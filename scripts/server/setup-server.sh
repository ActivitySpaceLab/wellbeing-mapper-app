#!/bin/bash

# Barcelona Server Setup Script for Digital Ocean Ubuntu 22.04
# Run this script on your Digital Ocean droplet after initial login

set -e

echo "🚀 Starting Barcelona Research Server Setup..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install Node.js 18 LTS
echo "📦 Installing Node.js 18 LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# Install PostgreSQL
echo "📦 Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib

# Install Nginx
echo "📦 Installing Nginx..."
apt install -y nginx

# Install PM2 for process management
echo "📦 Installing PM2..."
npm install -g pm2

# Install Certbot for SSL certificates
echo "📦 Installing Certbot..."
apt install -y certbot python3-certbot-nginx

# Create application directory
echo "📁 Creating application directories..."
mkdir -p /opt/barcelona-server
mkdir -p /opt/keys
mkdir -p /var/log/barcelona-server

# Set up PostgreSQL
echo "🗄️  Setting up PostgreSQL database..."
sudo -u postgres psql << EOF
CREATE USER barcelona_user WITH PASSWORD 'secure_password_here';
CREATE DATABASE barcelona_research OWNER barcelona_user;
GRANT ALL PRIVILEGES ON DATABASE barcelona_research TO barcelona_user;
\q
EOF

# Configure PostgreSQL for local connections
echo "🔧 Configuring PostgreSQL..."
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" /etc/postgresql/*/main/postgresql.conf

# Configure firewall
echo "🔥 Configuring UFW firewall..."
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 3000/tcp  # Node.js app port (will be behind Nginx)

# Create system user for the application
echo "👤 Creating barcelona system user..."
useradd -r -s /bin/false -d /opt/barcelona-server barcelona
chown -R barcelona:barcelona /opt/barcelona-server
chown -R barcelona:barcelona /var/log/barcelona-server

# Copy RSA keys (you'll need to upload these)
echo "🔐 Setting up RSA keys..."
echo "⚠️  Remember to copy barcelona_private_key.pem to /opt/keys/"
echo "⚠️  Set permissions: chmod 600 /opt/keys/barcelona_private_key.pem"
echo "⚠️  Set ownership: chown barcelona:barcelona /opt/keys/barcelona_private_key.pem"

# Configure Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/barcelona-server << 'EOF'
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint (no rate limiting)
    location /api/health {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable Nginx site
ln -sf /etc/nginx/sites-available/barcelona-server /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Set up log rotation
echo "📝 Setting up log rotation..."
cat > /etc/logrotate.d/barcelona-server << 'EOF'
/var/log/barcelona-server/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 0644 barcelona barcelona
    postrotate
        pm2 reload barcelona-server
    endscript
}
EOF

echo "✅ Barcelona Research Server setup complete!"
echo ""
echo "🔧 Next steps:"
echo "1. Copy your application code to /opt/barcelona-server"
echo "2. Copy barcelona_private_key.pem to /opt/keys/"
echo "3. Create .env file with your configuration"
echo "4. Run: cd /opt/barcelona-server && npm install"
echo "5. Run: sudo -u barcelona pm2 start ecosystem.config.js"
echo "6. Set up SSL: certbot --nginx -d your-domain.com"
echo "7. Test the server: curl http://your-domain.com/api/health"
echo ""
echo "🔐 Security reminders:"
echo "- Change default PostgreSQL password"
echo "- Generate strong API key for .env file"
echo "- Verify RSA key permissions (600)"
echo "- Configure domain name and SSL certificates"
echo "- Test GDPR compliance requirements"