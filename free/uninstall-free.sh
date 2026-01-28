#!/usr/bin/env bash
set -e

INSTALL_DIR="/opt/n8n"

echo "⚠️  n8n Free Uninstaller"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "This will remove:"
echo "  • n8n and PostgreSQL containers"
echo "  • All workflows and data"
echo "  • Installation directory: $INSTALL_DIR"
echo
echo "⚠️  WARNING: This action is PERMANENT!"
echo "   All your workflows will be DELETED."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

read -rp "Type UNINSTALL to continue: " CONFIRM

if [ "$CONFIRM" != "UNINSTALL" ]; then
  echo "❌ Uninstall cancelled"
  exit 0
fi

echo
echo "🔄 Starting uninstall process..."

# Navigate to install directory
if [ -d "$INSTALL_DIR" ]; then
  cd "$INSTALL_DIR"
  
  echo "🛑 Stopping containers..."
  docker compose down -v 2>/dev/null || true
else
  echo "⚠️  Install directory not found, cleaning up orphaned containers..."
fi

# Remove any lingering containers
echo "🧹 Removing containers..."
docker ps -a --filter "name=n8n" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true

# Remove volumes
echo "🗑️  Removing volumes..."
docker volume ls --filter "name=n8n" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true

# Remove networks
echo "🌐 Removing networks..."
docker network ls --filter "name=n8n" --format "{{.Name}}" | xargs -r docker network rm 2>/dev/null || true

# Clean up dangling volumes
docker volume prune -f >/dev/null 2>&1 || true

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
  echo "📁 Removing installation directory..."
  rm -rf "$INSTALL_DIR"
fi

# Verify cleanup
echo
echo "🔍 Verifying cleanup..."

REMAINING_CONTAINERS=$(docker ps -a --filter "name=n8n" --format "{{.Names}}" 2>/dev/null | wc -l)
REMAINING_VOLUMES=$(docker volume ls --filter "name=n8n" --format "{{.Name}}" 2>/dev/null | wc -l)

if [ "$REMAINING_CONTAINERS" -eq 0 ] && [ "$REMAINING_VOLUMES" -eq 0 ] && [ ! -d "$INSTALL_DIR" ]; then
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ n8n Free has been completely uninstalled"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  echo "   ✓ No containers remaining"
  echo "   ✓ No volumes remaining"
  echo "   ✓ Installation directory removed"
  echo
  echo "🚀 Need Production n8n with HTTPS?"
  echo "   Check out n8n PRO Installer"
  echo "   Visit: [your-gumroad-link]"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  echo
  echo "⚠️  Some items may still remain:"
  [ "$REMAINING_CONTAINERS" -gt 0 ] && echo "   • Containers: $REMAINING_CONTAINERS"
  [ "$REMAINING_VOLUMES" -gt 0 ] && echo "   • Volumes: $REMAINING_VOLUMES"
  [ -d "$INSTALL_DIR" ] && echo "   • Directory: $INSTALL_DIR still exists"
  echo
  echo "Run: docker ps -a | grep n8n"
  echo "     docker volume ls | grep n8n"
fi
