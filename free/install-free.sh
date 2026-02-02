#!/usr/bin/env bash
set -e

### =========
### CONFIG
### =========
INSTALL_DIR="/opt/n8n"
COMPOSE_FILE="compose.yml"
SERVER_IP=$(curl -4 -fsSL https://ifconfig.me)

### =========
### HELPERS
### =========
error() {
  echo "❌ ERROR: $1"
  exit 1
}

info() {
  echo "ℹ️  $1"
}

success() {
  echo "✅ $1"
}

### =========
### CHECKS
### =========

# Must be run as root
if [ "$EUID" -ne 0 ]; then
  error "Please run as root (sudo ./install-free.sh)"
fi

# OS check
if [ ! -f /etc/os-release ]; then
  error "Cannot detect OS"
fi

. /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
  error "This installer supports Ubuntu LTS only"
fi

if [[ "$VERSION_ID" != "22.04" && "$VERSION_ID" != "24.04" ]]; then
  error "Supported Ubuntu versions: 22.04 / 24.04"
fi

success "Ubuntu $VERSION_ID detected"

### =========
### QUESTIONS
### =========

echo
info "n8n Free Installer (HTTP Only)"
echo "--------------------------------"

# Detect timezone
TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
info "Detected timezone: $TZ"

read -rp "PostgreSQL password (leave blank to auto-generate): " DB_PASS
if [ -z "$DB_PASS" ]; then
  DB_PASS=$(openssl rand -base64 24)
  info "Generated secure PostgreSQL password"
fi

### =========
### INSTALL DOCKER
### =========

if ! command -v docker >/dev/null 2>&1; then
  info "Installing Docker..."

  apt-get update -y
  apt-get install -y ca-certificates curl gnupg

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $VERSION_CODENAME stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable docker
  systemctl start docker

  success "Docker installed"
else
  success "Docker already installed"
fi

### =========
### SETUP N8N
### =========
info "Setting up n8n in $INSTALL_DIR"

mkdir -p "$INSTALL_DIR/backup"
cd "$INSTALL_DIR"

### .env
cat > .env <<EOF
# n8n Free (HTTP)
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=$SERVER_IP
N8N_EDITOR_BASE_URL=http://$SERVER_IP:5678
WEBHOOK_URL=http://$SERVER_IP:5678
GENERIC_TIMEZONE=$TZ
N8N_SECURE_COOKIE=false

# Database
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=$DB_PASS
EOF

### docker-compose.yml
cat > "$COMPOSE_FILE" <<'EOF'
services:
  postgres:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: ${POSTGRES_DB}
      DB_POSTGRESDB_USER: ${POSTGRES_USER}
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
      N8N_PORT: ${N8N_PORT}
      N8N_PROTOCOL: ${N8N_PROTOCOL}
      N8N_HOST: ${N8N_HOST}
      GENERIC_TIMEZONE: ${GENERIC_TIMEZONE}
      N8N_SECURE_COOKIE: ${N8N_SECURE_COOKIE}
      N8N_EDITOR_BASE_URL: ${N8N_EDITOR_BASE_URL}
      WEBHOOK_URL: ${WEBHOOK_URL}
    depends_on:
      - postgres
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  postgres_data:
  n8n_data:
EOF

### =========
### START
### =========

info "Starting n8n..."
docker compose up -d

# Wait and verify
sleep 5

if docker ps | grep -q n8n-n8n; then
  success "n8n Free installation complete!"
else
  error "n8n failed to start. Check logs: docker compose -C $INSTALL_DIR logs"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ n8n is running!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "🌐 Access n8n at:"
echo "   👉 http://$SERVER_IP:5678"
echo
echo "📂 Installation directory: $INSTALL_DIR"
echo "🔐 Database password saved in: $INSTALL_DIR/.env"
echo
echo "⚠️  IMPORTANT NOTES:"
echo "   • This is HTTP-only (no SSL/HTTPS)"
echo "   • Suitable for testing and development"
echo "   • NOT recommended for production use"
echo
echo "🚀 Want Production Features?"
echo "   • Automatic HTTPS with Let's Encrypt"
echo "   • Automated backups & restore"
echo "   • Safe upgrade scripts"
echo "   • Traefik reverse proxy"
echo
echo "   👉 Upgrade to n8n PRO Installer"
echo "   Visit: gumroad.com/l/n8n-pro-installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "Quick commands:"
echo "  View logs:    cd /opt/n8n && docker compose logs -f"
echo "  Stop n8n:     cd /opt/n8n && docker compose stop"
echo "  Start n8n:    cd /opt/n8n && docker compose start"
echo "  Uninstall:    ./uninstall-free.sh"
