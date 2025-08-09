# JarvisJR Infrastructure Stack

Have you ever wished for your own JARVIS—an AI Second Brain that never forgets, connects all your tools, and works while you sleep? One that can transform those overwhelming 10-hour workdays into focused 4-hour sessions while making burnout obsolete?

That's the JarvisJR vision from the [AI Productivity Hub](https://www.skool.com/ai-productivity-hub/about) community, and this script builds the production-ready fortress that houses your AI Second Brain.

Think of this as constructing the perfect digital home for your AI companion—a security-hardened, self-healing infrastructure that gives JarvisJR everything it needs to orchestrate your workflows, remember your context across everything, and serve you brilliantly while keeping your data entirely under your control.

## What is JarvisJR?

JarvisJR is your AI Second Brain—a system designed to work while you sleep, making burnout obsolete and freeing up time for what matters most. Built on n8n workflows and developed by the [AI Productivity Hub](https://www.skool.com/ai-productivity-hub/about) community, it's the "one AI that runs everything."

Unlike corporate AI assistants, JarvisJR is designed with a clear mission: help business owners and professionals save 10+ hours per week through intelligent automation while maintaining complete ownership of their data. It can:

- **Never forget anything** - Persistent memory across all your tools and workflows
- **Connect everything** - Seamlessly integrate n8n, Make, Zapier, and 400+ other services  
- **Work autonomously** - Multi-agent systems that handle complex tasks without supervision
- **Learn your business** - Understand your unique workflows and optimize them continuously
- **Protect your privacy** - Everything runs on your infrastructure with military-grade security
- **Scale with you** - From personal productivity to full business automation

The AI Productivity Hub community provides the templates, workflows, and support to get your JarvisJr tailored to you in 30 days, saving 10+ hours per week by day 60, and ready to power your AI-enabled business by day 90.

This script builds the enterprise-grade technical foundation that makes all of this possible.

## Getting Started

### 1. Get a Server

We recommend Debian 12 servers from [Hetzner.com](https://hetzner.com) for their excellent performance and pricing:

- **Minimum Requirements**: 4GB RAM, 2 CPU cores, 40GB storage
- **Recommended**: 8GB RAM, 4 CPU cores, 80GB storage

### 2. Create a User Account

Once your server is running, create a non-root user with sudo access and systemd permissions:

```bash
ssh root@your-server-ip
```

```bash
adduser jarvis
```

```bash
usermod -aG sudo jarvis
```

```bash
loginctl enable-linger jarvis
```
> ℹ️ **Note**: The `enable-linger` command allows the jarvis user to run systemd services (required for Docker rootless). This prevents "Failed to connect to bus" errors during installation.

```bash
su - jarvis
```

### 3. Download the Script

```bash
curl -fsSL -H "Cache-Control: no-cache" "https://raw.githubusercontent.com/odysseyalive/JarvisJR_Stack/refs/heads/main/jj_production_stack.sh?$(date +%s)" -o jstack.sh
```

```bash
chmod +x jstack.sh
```

### 4. Configure Your DNS Records

**IMPORTANT**: Set up DNS records for your domain and subdomains before running the installation:

#### Required DNS A Records

Point these **subdomains** to your server's IP address:

```dns
supabase.your-domain.com    A    YOUR_SERVER_IP  
studio.your-domain.com      A    YOUR_SERVER_IP
n8n.your-domain.com         A    YOUR_SERVER_IP
```

**Note**: The root domain (`your-domain.com`) does **not** need to point to your server - only the subdomains are required.

#### DNS Setup Examples

**Cloudflare:**

1. Go to your domain's DNS settings
2. Click "Add record"  
3. **Enter ONLY the subdomain part** (not the full domain):

   ```
   Type: A
   Name: supabase          (NOT supabase.your-domain.com)
   IPv4 address: YOUR_SERVER_IP
   Proxy status: DNS only (gray cloud)
   ```

4. Repeat for `studio` and `n8n`

**Other DNS Providers (Namecheap, GoDaddy, etc.):**

1. Access your domain's DNS management panel
2. Add New Record for each subdomain
3. **Enter ONLY the subdomain part**:

   ```
   Type: A / A Record
   Name/Host: supabase     (NOT supabase.your-domain.com)
   Value: YOUR_SERVER_IP
   TTL: 300-600
   ```

4. Repeat for `studio` and `n8n`

**Verification:**
You can verify your DNS setup with:

```bash
nslookup supabase.your-domain.com
nslookup studio.your-domain.com  
nslookup n8n.your-domain.com
```

All subdomains should return your server's IP address. The root domain verification is optional.

#### DNS Setup Troubleshooting

**❓ Not sure which format your DNS provider uses?**

- Most providers use **subdomain only** (`supabase`)
- Look for existing DNS records to see the format
- Try subdomain format first - most common

**⏱️ DNS not updating?**

- Wait 5-15 minutes for DNS propagation
- Check TTL settings (lower = faster updates)
- Try `nslookup` from a different network/device

**🔍 Wrong format entered?**

- If you see `supabase.your-domain.com.your-domain.com`, you entered the full domain when only subdomain was needed
- Delete the record and re-add with just `supabase`

**🌐 Cloudflare Users:**

- Set proxy status to "DNS only" (gray cloud icon) during setup
- You can enable proxy (orange cloud) after installation if desired

### 5. Configure Your Settings

**IMPORTANT**: Edit the configuration at the top of the script before running:

```bash
nano jstack.sh
```

Update these required settings:

```bash
# DOMAIN CONFIGURATION - REQUIRED: CHANGE THESE VALUES
DOMAIN="your-domain.com"          # ⚠️ Replace with your actual domain
EMAIL="admin@your-domain.com"     # Email for Let's Encrypt certificates
COUNTRY_CODE="US"                  # Your country code
STATE_NAME="California"            # Your state/region
CITY_NAME="San Francisco"          # Your city
ORGANIZATION="Your Company"        # Your organization name

# SUBDOMAIN CONFIGURATION - Customize service subdomains  
SUPABASE_SUBDOMAIN="supabase"     # Supabase API (e.g., supabase.yourdomain.com)
STUDIO_SUBDOMAIN="studio"         # Supabase Studio (e.g., studio.yourdomain.com)
N8N_SUBDOMAIN="n8n"               # N8N workflows (e.g., n8n.yourdomain.com)

# TIMEZONE CONFIGURATION
N8N_TIMEZONE="America/Los_Angeles" # System and N8N timezone (e.g., "America/New_York", "Europe/London")
                                  # The script will automatically set the entire server to this timezone

# SERVICE USER CONFIGURATION
SERVICE_USER="jarvis"  # User that will run all services
SERVICE_GROUP="jarvis" # Group for the service user
SERVICE_SHELL="/bin/bash"         # Shell for service user
```

**Common timezone values:**
- `America/Los_Angeles` - US Pacific Time (default)
- `America/New_York` - US Eastern Time
- `UTC` - Universal Coordinated Time
- `America/Chicago` - US Central Time
- `Europe/London` - UK Time
- `Europe/Paris` - Central European Time
- `Asia/Tokyo` - Japan Standard Time
- `Australia/Sydney` - Australian Eastern Time

**Find your timezone:** Run `timedatectl list-timezones` on your server to see all available options.

### 6. Installation Options

### Core Commands

- `--install` - Run the installation (default)
- `--uninstall` - Remove all installed components with enhanced cleanup
- `--dry-run` - Show what would be done without executing (improved compliance)
- `--configure-ssl` - Configure SSL certificates after installation
- `--help` - Show all available options

### Backup & Restore Commands 🆕

- `--backup` - Create timestamped system backup
- `--backup [NAME]` - Create named backup (e.g., `--backup working-version`)
- `--restore [FILE]` - Restore from backup (interactive selection if no file)
- `--list-backups` - List all available backups with details

### Site Management

- `--add-site PATH` - Add a website to the stack
- `--remove-site PATH` - Remove a website from the stack

### Examples

**Installation:**

```bash
./jstack.sh                    # Normal installation
./jstack.sh --dry-run          # Test run without making changes
./jstack.sh --configure-ssl    # Configure SSL for existing installation
```

**Backup & Restore:**

```bash
./jstack.sh --backup                    # Create timestamped backup
./jstack.sh --backup working-version    # Create named backup before making changes
./jstack.sh --restore                   # Interactive restore selection
./jstack.sh --restore backup_20250107_203045.tar.gz  # Restore specific backup
./jstack.sh --list-backups              # Show all available backups
```

**Maintenance:**

```bash
./jstack.sh --uninstall        # Complete system removal
./jstack.sh --add-site sites/example.com    # Add a site
./jstack.sh --remove-site sites/example.com # Remove a site
```

## What Gets Installed

The script creates a complete AI infrastructure with:

### **System Configuration**
- **Timezone Synchronization** - Automatically sets the entire server timezone to match N8N_TIMEZONE
- **NTP Time Sync** - Ensures accurate timekeeping across all services

- **N8N Workflows** (`https://n8n.your-domain.com`) - Your AI automation brain
- **Supabase Backend** (`https://supabase.your-domain.com`) - Database and authentication
- **NGINX Reverse Proxy** - Secure web traffic routing
- **PostgreSQL Database** - Persistent data storage
- **Enhanced Security Hardening** - UFW firewall, fail2ban, AppArmor profiles, audit logging
- **Developer CLI Tools** - ripgrep, fd-find (fdfind), fzf for enhanced file search and navigation
- **Comprehensive Backup System** - Weekly encrypted backups with manual triggers
- **SSL Infrastructure** - Let's Encrypt certificates + internal certificate authority
- **Internal SSL Rotation** - Automated certificate renewal with systemd timers
- **GPG Secret Management** - Encrypted secrets with secure key management

## Adding Your Own Websites

You can add additional websites to the stack:

```bash
./jstack.sh --add-site sites/your-site.com
```

```bash
./jstack.sh --remove-site sites/your-site.com
```

### Site Configuration

Each site needs a `site.json` configuration file that defines:

- **Domain and SSL settings** - Your website's domain and certificate preferences
- **Container configuration** - Docker build context, environment variables, and volumes
- **Network integration** - How to connect to Supabase and other stack services
- **NGINX routing** - Proxy settings, caching rules, and security headers
- **Backup and monitoring** - What to backup and health check endpoints

The `sites/example.com/` directory contains a complete Next.js example with Supabase integration that you can use as a template for your own projects. Simply copy the directory, update the `site.json` with your domain and settings, and add your site files.

## Getting Help

- Run `./jstack.sh --help` for all available options
- Check the installation logs in `/tmp/setup-logs/` if issues occur
- Join the [AI Productivity Hub](https://www.skool.com/ai-productivity-hub/about) community for support and workflows

## Backup & Restore System 🆕

The JarvisJR stack includes a comprehensive backup and restore system that protects all your data and configurations:

### Automatic Backups

- **Schedule**: Weekly backups every Sunday at 2 AM
- **Location**: `/home/jarvis/backups/`
- **Retention**: Keeps 1 most recent backup (configurable)
- **Encryption**: Optional GPG encryption for sensitive data

### What Gets Backed Up

- **📊 Database dumps**: Complete Supabase and N8N data
- **💾 Volume data**: All service configurations and user data
- **🔒 SSL certificates**: Both Let's Encrypt and internal CA certificates
- **🔑 GPG secrets**: Encrypted secrets and keyring
- **⚙️ System configs**: Docker configurations, scripts, NGINX settings
- **🛡️ Security settings**: AppArmor profiles, fail2ban rules, UFW firewall rules
- **⚡ System services**: Systemd services and timers for SSL rotation

### Manual Backup Commands

**Create Backups:**

```bash
./jstack.sh --backup                    # Timestamped: backup_domain_20250107_203045.tar.gz
./jstack.sh --backup working-version    # Named: backup_domain_working-version_20250107.tar.gz
```

**When to use named backups:**

- `--backup working-version` - Before making any changes to a stable system
- `--backup before-testing` - Before testing new configurations  
- `--backup good-config` - After getting everything working perfectly
- `--backup pre-update` - Before system updates or modifications

Named backups make it easy to identify exactly what state you're restoring to!

**Restore from Backups:**

```bash
./jstack.sh --restore                   # Interactive selection menu
./jstack.sh --restore backup_file.tar.gz # Restore specific backup
```

**List Available Backups:**

```bash
./jstack.sh --list-backups
```

```
📋 Available Backups for your-domain.com:
==================================
backup_domain_20250107_203045.tar.gz | Size: 2.1G | Date: 2025-01-07 20:30:45
backup_domain_20250106_020000.tar.gz | Size: 2.0G | Date: 2025-01-06 02:00:00
```

### Interactive Restore Process

When you run `--restore` without specifying a file, you'll get an interactive menu:

1. **List all available backups** with numbers
2. **Choose by number** or enter full file path
3. **Confirmation prompt** before proceeding
4. **Automatic service management** (stop during restore, restart after)
5. **Verification checks** to ensure restore was successful

## Enhanced Uninstall System 🆕

The `--uninstall` command now provides complete system cleanup, removing **all** components including newer developments:

### What Gets Removed

- ✅ **All Docker containers, images, secrets, and custom networks**
- ✅ **Complete service data and volumes**
- ✅ **Script-created directories from user home** (services/, backups/, logs/, scripts/)
- ✅ **SSL certificates and internal certificate authority**
- ✅ **GPG encrypted secrets and keyring cleanup**
- ✅ **All systemd services, timers, and cron jobs**
- ✅ **Security configurations** (AppArmor profiles, fail2ban, UFW rules)
- ✅ **Docker installation** (optional, with confirmation)

### What Gets Preserved

- 🛡️ **User account** (`jarvis` user remains intact for safety)
- 🛡️ **User home directory structure** (only script-created content removed)
- 🛡️ **System packages** (can be removed manually if desired)

### Safe Uninstall Process

```bash
./jstack.sh --uninstall
```

1. **Warning and confirmation** - Type 'UNINSTALL-ALL' to confirm
2. **Graceful service shutdown** - Stops all containers cleanly  
3. **Complete cleanup** - Removes all script-created content
4. **User account preservation** - Keeps service user account intact
5. **Optional choices** - Keep or remove Docker installation
6. **System restoration** - Resets firewall and security settings

The uninstall process is designed to be **safe and reversible** - your user account remains intact so you can easily reinstall if needed.

## Troubleshooting & Maintenance

### Dry-Run Mode Improvements 🆕

Enhanced dry-run mode with better compliance checking:

```bash
./jstack.sh --dry-run
```

- **Zero system changes** - Guaranteed no modifications in dry-run mode
- **Comprehensive logging** - Shows exactly what would be executed
- **Compliance validation** - All commands properly wrapped and tested
- **Full configuration testing** - DNS, user, and system validations still run
- **Graceful failure handling** - Validation failures won't stop dry-run execution

**Note**: You can run dry-run mode **before** setting up DNS records or creating the service user - all validation tests will run and show you exactly what needs to be configured, but won't stop execution.

### Common Issues

**"Failed to connect to bus: No medium found" during Docker setup**

This happens with rootless Docker on Debian systems due to systemd environment issues. The script now automatically handles this by:
- Setting proper environment variables in ~/.bashrc
- Using Docker's custom runtime directory (/home/jarvis/.docker/run)
- Gracefully falling back if systemd integration isn't available

If you encounter this manually, the fix is:

```bash
sudo loginctl enable-linger jarvis
echo 'export XDG_RUNTIME_DIR=/home/jarvis/.docker/run' >> ~/.bashrc
echo 'export DOCKER_HOST=unix:///home/jarvis/.docker/run/docker.sock' >> ~/.bashrc
source ~/.bashrc
```

Docker rootless will auto-start when first used even if systemctl fails.

**"Service user 'jarvis' does not exist"**

The jarvis user wasn't created properly. Create it manually:

```bash
sudo adduser jarvis
sudo usermod -aG sudo jarvis  
sudo loginctl enable-linger jarvis
sudo su - jarvis
```

### Log Locations

- **Setup logs**: `/home/jarvis/logs/setup_YYYYMMDD_HHMMSS.log`
- **Backup logs**: `/home/jarvis/logs/backup.log`
- **Restore logs**: `/home/jarvis/logs/restore.log`
- **Service logs**: Available via `docker logs <container-name>`

### Quick Health Checks

```bash
# Check all services status
sudo -u jarvis /home/jarvis/scripts/status.sh

# View recent backup activity
tail -f /home/jarvis/logs/backup.log

# Check SSL certificate status
sudo -u jarvis /home/jarvis/scripts/ssl-status.sh
```

Installation typically takes 15-20 minutes on a good server connection. The system includes automatic health checks, self-healing capabilities, and comprehensive monitoring to keep your AI infrastructure running smoothly!
