# n8n Free Installer

Simple n8n installation for beginners, testing and development (HTTP-only).

## Quick Start
```bash
# 1. SSH to your Ubuntu server
ssh root@YOUR_SERVER_IP

# 2. Download scripts
wget https://github.com/subhashp/n8n-installer/raw/main/free/install-free.sh
wget https://github.com/subhashp/n8n-installer/raw/main/free/uninstall-free.sh

# 3. Make executable
chmod +x install-free.sh uninstall-free.sh

# 4. Install
./install-free.sh

# 5. Access n8n
# Visit: http://YOUR_SERVER_IP:5678
```

## Requirements

- Ubuntu 22.04 or 24.04
- 2GB RAM minimum
- 10GB disk space
- Root access

## What You Get

✅ n8n workflow automation  
✅ PostgreSQL database  
✅ Docker setup  
✅ Auto-start on reboot  

## What's NOT Included

❌ HTTPS / SSL certificates  
❌ Automatic backups  
❌ Upgrade scripts  
❌ Domain support  
❌ Traefik reverse proxy  

For production features, see [n8n PRO Installer](#upgrade-to-pro) below.

## Managing n8n
```bash
# View logs
cd /opt/n8n && docker compose logs -f

# Stop n8n
cd /opt/n8n && docker compose stop

# Start n8n
cd /opt/n8n && docker compose start

# Restart n8n
cd /opt/n8n && docker compose restart

# Check status
docker ps | grep n8n

# Uninstall
./uninstall-free.sh
```

## Basic Troubleshooting

### Can't Access n8n

**Problem:** Browser shows "Connection refused" or "Can't reach this page"

**Solutions:**
```bash
# 1. Check if containers are running
docker ps

# Should see: n8n-n8n-1 and n8n-postgres-1

# 2. Check firewall (if using UFW)
sudo ufw allow 5678/tcp
sudo ufw reload

# 3. Check cloud firewall
# Add inbound rule: Port 5678, Protocol TCP

# 4. Verify n8n is listening
ss -tlnp | grep 5678

# 5. Check logs for errors
cd /opt/n8n
docker compose logs n8n
```

### Containers Not Running

**Problem:** `docker ps` shows no n8n containers

**Solutions:**
```bash
# View what went wrong
cd /opt/n8n
docker compose logs

# Common issues:
# - Port 5678 already in use
# - Insufficient disk space
# - PostgreSQL failed to start

# Restart everything
docker compose down
docker compose up -d

# Check again
docker ps
```

### n8n Shows Database Error

**Problem:** n8n web interface shows database connection error

**Solutions:**
```bash
cd /opt/n8n

# Check PostgreSQL logs
docker compose logs postgres

# Restart PostgreSQL
docker compose restart postgres

# Wait 10 seconds, then restart n8n
sleep 10
docker compose restart n8n

# If still failing, check credentials
cat .env | grep POSTGRES
```

### Out of Disk Space

**Problem:** Installation fails or n8n stops working

**Solutions:**
```bash
# Check disk space
df -h

# Clean up Docker
docker system prune -a --volumes

# Remove old images
docker image prune -a

# Free up space on server
# Then reinstall
./uninstall-free.sh
./install-free.sh
```

### Forgot to Open Firewall

**Problem:** n8n installed but can't access from browser

**Solutions:**
```bash
# UFW (Ubuntu Firewall)
sudo ufw status
sudo ufw allow 5678/tcp
sudo ufw reload

# Check cloud provider firewall rules
# AWS: Security Groups
# DigitalOcean: Firewall settings
# Vultr: Firewall rules
# Add: Inbound TCP port 5678
```

### Port Already in Use

**Problem:** Installation fails with "port already allocated"

**Solutions:**
```bash
# Check what's using port 5678
sudo lsof -i :5678

# Stop the conflicting service, or
# Change n8n port in .env file:
nano /opt/n8n/.env
# Change: N8N_PORT=5679

# Restart
cd /opt/n8n
docker compose down
docker compose up -d

# Access at: http://YOUR_IP:5679
```

### Container Keeps Restarting

**Problem:** `docker ps` shows container restarting repeatedly

**Solutions:**
```bash
# View recent logs
cd /opt/n8n
docker compose logs --tail=50 n8n

# Common causes:
# - Database not ready (wait 30 seconds)
# - Out of memory (upgrade server)
# - Configuration error in .env

# Check for errors in logs
docker compose logs | grep -i error
```

### Need to Reset n8n

**Problem:** Want to start fresh, keep Docker

**Solutions:**
```bash
# Stop and remove everything
cd /opt/n8n
docker compose down -v

# Remove installation
rm -rf /opt/n8n

# Reinstall
./install-free.sh
```

## Manual Backup (Free Version)

Since automatic backups aren't included in the free version, here's how to backup manually:
```bash
# Export workflows
cd /opt/n8n
docker exec n8n-n8n-1 n8n export:workflow --all --output=/tmp/workflows.json
docker cp n8n-n8n-1:/tmp/workflows.json ~/n8n-workflows-backup.json

# Backup database
docker exec n8n-postgres-1 pg_dump -U n8n n8n > ~/n8n-database-backup.sql

# Download to your local machine (from your computer, not server)
scp root@YOUR_SERVER_IP:~/n8n-*.* ./backups/
```

**💡 PRO version includes automated backup/restore scripts!**

## Performance Tips
```bash
# Check resource usage
docker stats

# If high memory usage:
# - Limit concurrent workflow executions
# - Optimize workflows
# - Consider upgrading server RAM

# If high disk usage:
# - Clean up old data
# - Monitor workflow data size
# - PRO version: Use automated backups to offload old data
```

## Getting Help

### Free Version Support

This free installer is provided as-is. For issues:

1. **Check troubleshooting above** (solves 90% of issues)
2. **Docker logs**: `cd /opt/n8n && docker compose logs`
3. **n8n Community**: https://community.n8n.io
4. **GitHub Issues**: For installer bugs only

### Need More Help?

The PRO version includes:
- 📖 Comprehensive troubleshooting guide
- 💬 Community Discord access
- 🎥 Video walkthrough
- 📧 Email support (Premium tier)

## Upgrade to PRO

### Why Upgrade?

**Free Version:**
- ✅ HTTP only (no encryption)
- ❌ No domain support
- ❌ Manual backups only
- ❌ No upgrade scripts
- ❌ Basic docs

**PRO Version ($39):**
- ✅ **Automatic HTTPS** with Let's Encrypt
- ✅ **Custom domain** support (n8n.yourdomain.com)
- ✅ **Automated backups** (one command)
- ✅ **Smart restore** (with safety prompts)
- ✅ **Safe upgrades** (with auto-backup)
- ✅ **Traefik reverse proxy** (professional setup)
- ✅ **Comprehensive docs** (50+ pages)
- ✅ **Video walkthrough** (15 minutes)
- ✅ **Community Discord** (peer + creator support)

### Perfect For:

- 🏢 Production deployments
- 💼 Client projects
- 🔒 Security-conscious teams
- 📈 Growing businesses
- 🚀 Professional workflows

**[Get n8n PRO Installer →](https://gumroad.com/l/n8n-pro-installer)**

*One-time purchase. Deploy unlimited servers. Commercial use allowed.*

## FAQ

**Q: Is this really free?**  
A: Yes! Use for testing, development, or learning. No strings attached.

**Q: Can I use this in production?**  
A: Technically yes, but not recommended (no HTTPS, no backups). Use PRO for production.

**Q: Will this work on other Linux distros?**  
A: Only tested on Ubuntu 22.04 and 24.04. May work on Debian, but unsupported.

**Q: Can I upgrade from Free to PRO later?**  
A: Yes! Uninstall free version, then run PRO installer. You can backup workflows manually first.

**Q: What's my server IP?**  
A: Run: `curl ifconfig.me`

**Q: How do I add HTTPS to free version?**  
A: You can't easily. That's what PRO version provides automatically with Let's Encrypt.

## License

Free for personal and commercial use. No warranty provided.

## About

Created for beginners and developers who want to quickly test n8n without complex setup.

For production deployments with security, backups, and support, check out the PRO version.

---

**Star this repo if it helped you!** ⭐
