# JarvisJR Stack - Complete Infrastructure Guide

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Debian](https://img.shields.io/badge/Debian-D70A53?style=flat&logo=debian&logoColor=white)](https://www.debian.org/)
[![NGINX](https://img.shields.io/badge/nginx-%23009639.svg?style=flat&logo=nginx&logoColor=white)](https://nginx.org/)

> **The definitive guide to installing, configuring, and using the JarvisJR Stack - your AI Second Brain infrastructure.**

## Table of Contents

- [Project Introduction & Overview](#project-introduction--overview)
- [Prerequisites & System Requirements](#prerequisites--system-requirements)  
- [Installation Guide](#installation-guide)
- [Configuration Management](#configuration-management)
- [Usage Examples & Commands](#usage-examples--commands)
- [Service Management](#service-management)
- [Advanced Operations](#advanced-operations)
- [Maintenance & Updates](#maintenance--updates)
- [Troubleshooting](#troubleshooting)
- [Developer Information](#developer-information)

---

## Project Introduction & Overview

### What is JarvisJR?

JarvisJR is your AI Second Brain—a comprehensive system designed to work while you sleep, making burnout obsolete and freeing up time for what matters most. Built on N8N workflows and developed by the [AI Productivity Hub](https://www.skool.com/ai-productivity-hub/about) community, it's the "one AI that runs everything."

Unlike corporate AI assistants, JarvisJR is designed with a clear mission: help business owners and professionals save 10+ hours per week through intelligent automation while maintaining complete ownership of their data.

### Key Features & Benefits

**🧠 Never Forget Anything**
- Persistent memory across all your tools and workflows
- Context preservation between sessions and applications
- Intelligent data correlation and pattern recognition

**🔗 Universal Integration**  
- Seamlessly connect N8N, Make, Zapier, and 400+ other services
- Custom API integrations and webhook support
- Cross-platform data synchronization

**🤖 Autonomous Operation**
- Multi-agent systems that handle complex tasks without supervision
- Intelligent decision-making based on learned patterns
- Proactive task execution and workflow optimization

**📈 Business Intelligence**
- Learn your unique workflows and optimize them continuously
- Performance analytics and productivity insights
- Automated reporting and business intelligence

**🔒 Complete Privacy & Control**
- Everything runs on your infrastructure with military-grade security
- No data ever leaves your servers
- Full audit trails and compliance capabilities

**⚡ Scalable Architecture**
- From personal productivity to full business automation
- Handles increasing complexity and data volumes
- Enterprise-grade performance and reliability

### Target Audience & Use Cases

**Business Owners & Entrepreneurs**
- Automate repetitive business processes
- Integrate CRM, email marketing, and customer support
- Scale operations without increasing overhead

**Developers & Technical Teams**
- CI/CD pipeline automation
- Code deployment and monitoring workflows  
- Infrastructure management and alerting

**Content Creators & Marketers**
- Social media automation and scheduling
- Content distribution across multiple platforms
- Analytics aggregation and reporting

**Productivity Enthusiasts**
- Personal task management and automation
- Email processing and organization
- Calendar and meeting coordination

### Architecture Overview

The JarvisJR Stack provides the enterprise-grade technical foundation that powers your AI Second Brain:

```
┌─────────────────────────────────────────────────────────────┐
│                     Internet Traffic                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 NGINX Reverse Proxy                        │
│              (SSL Termination & Routing)                   │
└─────────────┬───────────────┬───────────────┬───────────────┘
              │               │               │
    ┌─────────▼──────┐ ┌─────▼─────┐ ┌───────▼────────┐
    │  Supabase API  │ │ N8N Flows │ │ Supabase Studio│
    │ (Port 8000)    │ │(Port 5678)│ │  (Port 3000)   │
    └─────────┬──────┘ └─────┬─────┘ └───────┬────────┘
              │              │               │
              └──────────────┼───────────────┘
                             │
                   ┌─────────▼──────────┐
                   │   PostgreSQL DB    │
                   │    (Port 5432)     │
                   └────────────────────┘
```

**Service Components:**

- **NGINX Reverse Proxy**: SSL termination, load balancing, and routing
- **Supabase API**: Database backend with real-time subscriptions
- **Supabase Studio**: Web-based database administration
- **N8N Workflows**: Visual workflow automation engine
- **PostgreSQL**: High-performance relational database
- **Internal SSL CA**: End-to-end encryption for internal services

**Security Layers:**

- **Docker Rootless Containers**: Enhanced container isolation
- **UFW Firewall**: Network traffic filtering and protection
- **fail2ban**: Intrusion detection and prevention
- **AppArmor Profiles**: Application-level security policies
- **GPG Encryption**: Secure secrets and backup management
- **Let's Encrypt SSL**: Automated certificate management

---

## Prerequisites & System Requirements

### Operating System Requirements

**Supported Platforms:**
- **Primary**: Debian 12 "Bookworm" (Recommended)
- **Alternative**: Ubuntu 22.04 LTS or newer
- **Architecture**: x86_64 (Intel/AMD 64-bit)

**Why Debian 12?**
- Latest stable packages for Docker and security tools
- Optimized for headless server deployments
- Long-term support and security updates
- Excellent compatibility with containerized workloads

### Hardware Requirements

**Minimum Configuration:**
- **RAM**: 4GB (8GB recommended)
- **CPU**: 2 cores (4 cores recommended)
- **Storage**: 40GB SSD (80GB recommended)
- **Network**: 1Gbps connection preferred

**Recommended Configuration:**
- **RAM**: 8GB+ (for heavy automation workflows)
- **CPU**: 4+ cores (for concurrent container execution)
- **Storage**: 80GB+ SSD (for database growth and backups)
- **Network**: Stable internet with low latency

**Resource Usage Breakdown:**
```
PostgreSQL Database:    4GB RAM, 2 CPU cores (highest priority)
N8N Workflow Engine:    2GB RAM, 1 CPU core
NGINX Reverse Proxy:    256MB RAM, 0.5 CPU core
Browser Automation:     4GB RAM, 1.5 CPU cores (if enabled)
System Overhead:        1GB RAM, 0.5 CPU core
```

### Network Requirements

**Domain Setup:**
- **Required**: Registered domain name with DNS control
- **Subdomains**: Ability to create A records for subdomains
- **SSL**: Let's Encrypt certificate issuance capabilities

**DNS Configuration:**
The following subdomain A records must point to your server:
```
supabase.your-domain.com → YOUR_SERVER_IP
studio.your-domain.com   → YOUR_SERVER_IP  
n8n.your-domain.com      → YOUR_SERVER_IP
```

**Port Requirements:**
- **HTTP (80)**: Let's Encrypt certificate validation
- **HTTPS (443)**: All web traffic (primary)
- **SSH (22)**: Server administration (configurable)

### Required Permissions & Access

**Server Access:**
- Root or sudo access for initial installation
- Ability to create system users and groups
- Permission to modify system configurations

**Domain Control:**
- DNS management access for your domain
- Ability to create and modify A records
- Control over subdomain creation

**Email Access:**
- Valid email address for Let's Encrypt certificates
- Email must be reachable for certificate renewal notifications

### Recommended Server Providers

**Tested & Recommended:**

**Hetzner Cloud** (Recommended)
- Excellent price/performance ratio
- Fast NVMe SSD storage
- European data centers
- Snapshots and backup capabilities
- Starting at ~$5/month for minimum specs

**DigitalOcean**
- Simple deployment and management
- Global data center coverage
- Integrated monitoring and alerting
- Starting at ~$6/month for minimum specs

**Linode/Akamai**
- High-performance compute instances  
- 24/7 technical support
- Advanced networking features
- Starting at ~$5/month for minimum specs

**VPS Configuration Tips:**
- Choose SSD storage over traditional HDD
- Select a data center close to your location
- Enable automatic backups if available
- Consider managed firewall services

---

## Installation Guide

### Step 1: Server Preparation

**Create a Fresh Debian 12 Server**

Most cloud providers offer Debian 12 as a base image. Select the minimum recommended configuration (4GB RAM, 2 CPU cores, 40GB SSD).

**Initial Server Login**
```bash
ssh root@your-server-ip
```

**Update System Packages**
```bash
apt update && apt upgrade -y
```

### Step 2: User Account Setup

**Create Service User with Proper Permissions**

The JarvisJR Stack runs under a dedicated service user for security isolation:

```bash
# Create user account
adduser jarvis

# Add to sudo group for installation permissions
usermod -aG sudo jarvis

# Enable systemd services for user (required for Docker rootless)
loginctl enable-linger jarvis
```

**Switch to Service User**
```bash
su - jarvis
```

> ⚠️ **Important**: The `enable-linger` command is critical for Docker rootless operation. It prevents "Failed to connect to bus" errors during container management.

### Step 3: DNS Configuration

**CRITICAL**: Configure DNS records before installation to ensure SSL certificate generation works correctly.

**Required Subdomain A Records**

Point these subdomains to your server's IP address:

| Subdomain | Purpose | Example |
|-----------|---------|---------|
| `supabase` | Database API | `supabase.your-domain.com` |
| `studio` | Database Admin | `studio.your-domain.com` |
| `n8n` | Workflow Engine | `n8n.your-domain.com` |

**DNS Provider Examples:**

**Cloudflare:**
1. Go to DNS settings for your domain
2. Click "Add record"
3. Enter subdomain only (e.g., `supabase`, not `supabase.your-domain.com`)
4. Set type to "A" and value to your server IP
5. Ensure proxy status is "DNS only" (gray cloud)

**Other Providers (Namecheap, GoDaddy, etc.):**
1. Access DNS management panel
2. Add new A record for each subdomain
3. Host/Name: subdomain only (e.g., `supabase`)
4. Value/Points to: your server IP address
5. TTL: 300-600 seconds for faster updates

**Verification:**
```bash
# Test DNS resolution (run from any computer)
nslookup supabase.your-domain.com
nslookup studio.your-domain.com
nslookup n8n.your-domain.com
```

All subdomains should return your server's IP address.

### Step 4: Download Installation Script

**Download Latest Version**
```bash
# Method 1: Direct download from GitHub
curl -fsSL -H "Cache-Control: no-cache" \
  "https://raw.githubusercontent.com/your-username/JarvisJR_Stack/main/jstack.sh?$(date +%s)" \
  -o jstack.sh

# Method 2: Clone repository (recommended for development)
git clone https://github.com/your-username/JarvisJR_Stack.git
cd JarvisJR_Stack
chmod +x jstack.sh
```

> **Note**: Replace `your-username` with the actual GitHub username/organization where the repository is hosted.

**Make Executable** (if using Method 1)
```bash
chmod +x jstack.sh
```

**Verify Download**
```bash
ls -la jstack.sh
head -n 10 jstack.sh  # Check script header
```

### Step 5: Configuration Customization

**Copy Default Configuration**
```bash
cp jstack.config.default jstack.config
```

**Edit Configuration**
```bash
nano jstack.config
```

**Required Configuration Changes:**

```bash
# ⚠️ MUST CHANGE THESE VALUES
DOMAIN="your-actual-domain.com"        # Your registered domain
EMAIL="admin@your-actual-domain.com"   # Your email for SSL certificates
COUNTRY_CODE="US"                       # Your country code
STATE_NAME="California"                 # Your state/region  
CITY_NAME="San Francisco"               # Your city
ORGANIZATION="Your Company Name"        # Your organization

# Timezone Configuration (Important for N8N)
N8N_TIMEZONE="America/Los_Angeles"      # Set to your timezone
```

**Common Timezone Values:**
- `America/New_York` - US Eastern Time
- `America/Chicago` - US Central Time  
- `America/Los_Angeles` - US Pacific Time
- `Europe/London` - UK Time
- `Europe/Paris` - Central European Time
- `Asia/Tokyo` - Japan Standard Time
- `UTC` - Universal Coordinated Time

**Find Your Timezone:**
```bash
timedatectl list-timezones | grep -i your_region
```

### Step 6: Pre-Installation Validation

**Test Configuration (Recommended)**
```bash
./jstack.sh --dry-run
```

This will validate your configuration without making any system changes. Review the output for any issues before proceeding.

**Validate DNS Setup**
```bash
# The script will test DNS resolution during dry-run
# Ensure all subdomains resolve correctly
```

### Step 7: Execute Installation

**Run Standard Installation**
```bash
./jstack.sh
```

**Alternative: Explicit Install Command**
```bash
./jstack.sh --install
```

**Installation Process Overview:**

1. **System Setup** (5-8 minutes)
   - User validation and permissions
   - Security hardening (UFW, fail2ban, AppArmor)
   - Docker rootless installation
   - Development tools (ripgrep, fd-find, fzf)

2. **Container Deployment** (3-5 minutes)
   - PostgreSQL database setup
   - Supabase API and Studio deployment
   - N8N workflow engine configuration
   - NGINX reverse proxy setup

3. **SSL Configuration** (2-3 minutes)
   - Let's Encrypt certificate generation
   - Internal certificate authority setup
   - SSL certificate validation

4. **Service Orchestration** (2-3 minutes)
   - Health checks and validation
   - Service startup coordination
   - Final connectivity tests

**Total Installation Time**: 15-20 minutes on a good connection

### Step 8: Verify Installation

**Check Service Status**
```bash
# All containers should be running and healthy
docker ps --format 'table {{.Names}}	{{.Status}}'

# Verify network connectivity
curl -I https://supabase.your-domain.com
curl -I https://studio.your-domain.com
curl -I https://n8n.your-domain.com
```

**Access Your Services**

- **N8N Workflows**: `https://n8n.your-domain.com`
- **Supabase Studio**: `https://studio.your-domain.com`
- **Supabase API**: `https://supabase.your-domain.com`

**Initial Setup Steps**

1. **N8N Setup**: Create your admin account at `https://n8n.your-domain.com`
2. **Supabase Setup**: Access studio at `https://studio.your-domain.com`
3. **API Keys**: Retrieve Supabase API keys from the studio for N8N integration

---

## Configuration Management

### Configuration System Overview

The JarvisJR Stack uses a two-file configuration system designed for safety and maintainability:

- **`jstack.config.default`**: Version-controlled defaults (never modify)
- **`jstack.config`**: Your customizations (created by you, not in git)

This ensures you can update the stack without losing your custom settings.

### Configuration Loading Process

1. **Defaults First**: System loads `jstack.config.default`
2. **User Overrides**: Your `jstack.config` values override defaults
3. **Validation**: Required variables (DOMAIN, EMAIL) are validated
4. **Environment Export**: Configuration exported to all scripts

### Core Configuration Sections

#### Domain & SSL Configuration

```bash
# Required - Must be customized
DOMAIN="your-domain.com"              # Your registered domain
EMAIL="admin@your-domain.com"         # Email for SSL certificates

# SSL Certificate Details
COUNTRY_CODE="US"                     # Two-letter country code
STATE_NAME="California"               # State or region
CITY_NAME="San Francisco"             # City name
ORGANIZATION="Your Company"           # Organization name

# Subdomain Customization
SUPABASE_SUBDOMAIN="supabase"         # API subdomain
STUDIO_SUBDOMAIN="studio"             # Studio subdomain
N8N_SUBDOMAIN="n8n"                   # N8N subdomain
```

#### Service Configuration

```bash
# User Account Settings
SERVICE_USER="jarvis"                 # User running all services
SERVICE_GROUP="jarvis"                # Group for service user
SERVICE_SHELL="/bin/bash"             # Shell for service user

# Directory Structure
BASE_DIR="/home/jarvis/jarvis-stack"  # Base installation directory
BACKUP_RETENTION_DAYS="1"             # How long to keep backups
LOG_RETENTION_DAYS="14"               # How long to keep logs
```

#### Network & Port Configuration

```bash
# Docker Networks
JARVIS_NETWORK="jarvis_network"       # Main Docker network
PUBLIC_TIER="public_tier"             # Public-facing services
PRIVATE_TIER="private_tier"           # Internal services

# Internal Service Ports (Docker only)
SUPABASE_API_PORT="8000"              # Supabase API internal port
SUPABASE_STUDIO_PORT="3000"           # Studio internal port
N8N_PORT="5678"                       # N8N internal port
POSTGRES_PORT="5432"                  # Database internal port
```

#### Resource Limits & Performance

```bash
# PostgreSQL (Highest Priority)
POSTGRES_MEMORY_LIMIT="4G"            # Database memory limit
POSTGRES_CPU_LIMIT="2.0"              # Database CPU cores
POSTGRES_SHARED_BUFFERS="1GB"         # Database shared buffers
POSTGRES_EFFECTIVE_CACHE_SIZE="3GB"   # Database cache size

# N8N Workflow Engine
N8N_MEMORY_LIMIT="2G"                 # N8N memory limit
N8N_CPU_LIMIT="1.0"                   # N8N CPU cores
N8N_EXECUTION_TIMEOUT="7200"          # Workflow timeout (seconds)

# NGINX Reverse Proxy
NGINX_MEMORY_LIMIT="256M"             # NGINX memory limit
NGINX_CPU_LIMIT="0.5"                 # NGINX CPU allocation
```

#### Browser Automation (Optional)

```bash
# Enable/Disable Browser Automation
ENABLE_BROWSER_AUTOMATION="true"      # Enable Chrome/Puppeteer

# Chrome Resource Limits
CHROME_MEMORY_LIMIT="4G"              # Chrome memory limit
CHROME_CPU_LIMIT="1.5"                # Chrome CPU allocation
CHROME_MAX_INSTANCES="5"              # Maximum browser instances
CHROME_INSTANCE_TIMEOUT="300"         # Instance timeout (seconds)

# Security Settings (DO NOT MODIFY)
CHROME_SECURITY_ARGS="--disable-dev-shm-usage --disable-gpu..."
```

#### Backup & Security Configuration

```bash
# Backup Settings
BACKUP_SCHEDULE="0 2 * * 0"           # Weekly backups (Sunday 2 AM)
BACKUP_ENCRYPTION="true"              # Enable GPG encryption
BACKUP_COMPRESSION_LEVEL="6"          # Compression level (1-9)

# Security Features
UFW_ENABLED="true"                    # Enable firewall
APPARMOR_ENABLED="true"               # Enable AppArmor profiles
CONTAINER_NO_NEW_PRIVS="true"         # Container security
```

### Environment-Specific Settings

#### Development Environment

```bash
# Copy config for development
cp jstack.config jstack.config.dev

# Edit development settings
DEPLOYMENT_ENVIRONMENT="development"
ENABLE_DEBUG_LOGS="true"
ENABLE_DEVELOPMENT_MODE="true"

# Use development config
export JSTACK_CONFIG="jstack.config.dev"
./jstack.sh --dry-run
```

#### Production Environment

```bash
# Production settings (recommended)
DEPLOYMENT_ENVIRONMENT="production"
ENABLE_DEBUG_LOGS="false"
ENABLE_DEVELOPMENT_MODE="false"
BACKUP_ENCRYPTION="true"
UFW_ENABLED="true"
```

#### Staging Environment

```bash
# Staging configuration
DEPLOYMENT_ENVIRONMENT="staging"
DOMAIN="staging.your-domain.com"
BACKUP_RETENTION_DAYS="3"
ENABLE_DEBUG_LOGS="true"
```

### Security Considerations

#### Required Security Settings

```bash
# These should NEVER be disabled in production
UFW_ENABLED="true"                    # Firewall protection
APPARMOR_ENABLED="true"               # Application security
BACKUP_ENCRYPTION="true"              # Encrypted backups
CONTAINER_NO_NEW_PRIVS="true"         # Container security
```

#### Sensitive Configuration

**Email Configuration**
- Use a real email address for Let's Encrypt notifications
- Consider using a dedicated SSL management email
- Ensure email account is secure and monitored

**Domain Configuration**
- Never use example domains in production
- Ensure you control the DNS for the domain
- Consider using a dedicated subdomain for the stack

**Resource Limits**
- Adjust based on your server specifications
- Monitor actual usage after installation
- Scale limits up for heavy workloads

### Configuration Validation

**Test Configuration**
```bash
# Validate configuration without installation
./jstack.sh --dry-run

# Check specific settings
source scripts/settings/config.sh
load_config
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo "Base Dir: $BASE_DIR"
```

**Common Validation Errors**

| Error | Cause | Solution |
|-------|-------|----------|
| "DOMAIN not set" | Missing domain configuration | Set DOMAIN in jstack.config |
| "EMAIL not set" | Missing email configuration | Set EMAIL in jstack.config |
| "DNS resolution failed" | Subdomain not configured | Configure DNS A records |
| "User does not exist" | Service user not created | Create jarvis user with proper permissions |

### Advanced Configuration Options

#### Custom Timezone Setup

```bash
# Set system and N8N timezone
N8N_TIMEZONE="America/New_York"

# The script automatically sets:
# - System timezone via timedatectl
# - Container timezone environment variables
# - N8N workflow timezone settings
```

#### Performance Tuning

```bash
# High-performance configuration (8GB+ RAM)
POSTGRES_MEMORY_LIMIT="6G"
POSTGRES_SHARED_BUFFERS="1.5GB"
POSTGRES_EFFECTIVE_CACHE_SIZE="4.5GB"
N8N_MEMORY_LIMIT="3G"
CHROME_MEMORY_LIMIT="6G"

# Low-resource configuration (4GB RAM)
POSTGRES_MEMORY_LIMIT="2G"
POSTGRES_SHARED_BUFFERS="512MB"
POSTGRES_EFFECTIVE_CACHE_SIZE="1.5GB"
N8N_MEMORY_LIMIT="1G"
CHROME_MEMORY_LIMIT="2G"
```

#### Network Customization

```bash
# Custom subdomain names
SUPABASE_SUBDOMAIN="api"              # api.your-domain.com
STUDIO_SUBDOMAIN="db"                 # db.your-domain.com
N8N_SUBDOMAIN="workflows"             # workflows.your-domain.com

# Custom network names
JARVIS_NETWORK="custom_network"
PUBLIC_TIER="web_tier"
PRIVATE_TIER="data_tier"
```

---

## Usage Examples & Commands

### Command Reference

The JarvisJR Stack provides a comprehensive CLI interface through the `jstack.sh` script. All operations are designed to be safe, logged, and reversible.

#### Core Installation Commands

```bash
# Standard installation (most common)
./jstack.sh

# Explicit installation command
./jstack.sh --install

# Test installation without making changes
./jstack.sh --dry-run

# Configure SSL certificates after installation
./jstack.sh --configure-ssl

# Show all available commands and options
./jstack.sh --help
```

#### Backup & Restore Operations

**Creating Backups**

```bash
# Create timestamped backup
./jstack.sh --backup
# Output: backup_domain_20250107_203045.tar.gz

# Create named backup (recommended for milestones)
./jstack.sh --backup working-version
# Output: backup_domain_working-version_20250107.tar.gz

# Create backup before major changes
./jstack.sh --backup pre-update
./jstack.sh --backup stable-config
./jstack.sh --backup before-testing
```

**Restoring from Backups**

```bash
# Interactive restore (shows menu of available backups)
./jstack.sh --restore

# Restore specific backup
./jstack.sh --restore backup_domain_20250107_203045.tar.gz

# List all available backups with details
./jstack.sh --list-backups
```

**Backup Management**

```bash
# Example backup workflow
./jstack.sh --backup working-version    # Create baseline
# ... make changes ...
./jstack.sh --backup experimental       # Save experiment
# ... test changes ...
./jstack.sh --restore working-version   # Rollback if needed
```

#### Site Management Commands

**Adding Custom Websites**

```bash
# Add a new website to the stack
./jstack.sh --add-site sites/my-app.com

# Add multiple sites
./jstack.sh --add-site sites/blog.example.com
./jstack.sh --add-site sites/api.example.com
./jstack.sh --add-site sites/dashboard.example.com
```

**Removing Websites**

```bash
# Remove a website from the stack
./jstack.sh --remove-site sites/my-app.com

# Remove with confirmation
./jstack.sh --remove-site sites/old-project.com
```

#### Maintenance Commands

```bash
# Complete system removal (with confirmation)
./jstack.sh --uninstall

# View all command options
./jstack.sh --help

# Check script version and status
./jstack.sh --version  # (if implemented)
```

### Common Workflows & Use Cases

#### Initial Setup Workflow

```bash
# 1. Prepare server and user
sudo adduser jarvis
sudo usermod -aG sudo jarvis
sudo loginctl enable-linger jarvis
su - jarvis

# 2. Download and configure
curl -fsSL "https://raw.githubusercontent.com/.../jstack.sh" -o jstack.sh
chmod +x jstack.sh
cp jstack.config.default jstack.config
nano jstack.config  # Edit DOMAIN and EMAIL

# 3. Test and install
./jstack.sh --dry-run     # Validate configuration
./jstack.sh               # Execute installation

# 4. Verify installation
docker ps --format 'table {{.Names}}	{{.Status}}'
curl -I https://n8n.your-domain.com
```

#### Development Workflow

```bash
# 1. Create baseline backup
./jstack.sh --backup stable-baseline

# 2. Make experimental changes
# ... modify configurations, add sites, etc. ...

# 3. Create experiment backup
./jstack.sh --backup experimental-v1

# 4. Test changes
./jstack.sh --dry-run  # Test configuration

# 5. Deploy or rollback
./jstack.sh           # Deploy changes
# OR
./jstack.sh --restore stable-baseline  # Rollback
```

#### Production Deployment Workflow

```bash
# 1. Pre-deployment backup
./jstack.sh --backup pre-prod-$(date +%Y%m%d)

# 2. Deploy to staging first (if available)
export JSTACK_CONFIG="jstack.config.staging"
./jstack.sh --dry-run

# 3. Production deployment
export JSTACK_CONFIG="jstack.config.prod"
./jstack.sh

# 4. Post-deployment verification
./scripts/health-check.sh  # (if implemented)
./jstack.sh --backup post-prod-$(date +%Y%m%d)
```

#### Disaster Recovery Workflow

```bash
# 1. Assess system state
docker ps --all
./jstack.sh --list-backups

# 2. Identify last known good backup
./jstack.sh --list-backups | head -5

# 3. Restore from backup
./jstack.sh --restore backup_domain_20250106_020000.tar.gz

# 4. Verify restoration
docker ps --format 'table {{.Names}}	{{.Status}}'
curl -I https://n8n.your-domain.com

# 5. Create post-recovery backup
./jstack.sh --backup post-recovery-$(date +%Y%m%d)
```

### Browser Automation Capabilities

The JarvisJR Stack includes comprehensive browser automation capabilities through Chrome/Puppeteer integration for N8N workflows.

#### Browser Automation Features

**Supported Operations**
- Web scraping and data extraction
- Automated form filling and submission
- Screenshot capture and PDF generation
- Multi-page workflow automation
- JavaScript execution and DOM manipulation

**Security & Performance**
- Headless Chrome with security hardening
- Resource limits to prevent memory leaks
- Sandboxed execution environment
- Configurable instance limits and timeouts

#### Browser Configuration Examples

```bash
# Enable browser automation (default)
ENABLE_BROWSER_AUTOMATION="true"

# High-performance browser setup
CHROME_MEMORY_LIMIT="6G"
CHROME_CPU_LIMIT="2.0" 
CHROME_MAX_INSTANCES="10"
CHROME_INSTANCE_TIMEOUT="600"

# Resource-constrained setup
CHROME_MEMORY_LIMIT="2G"
CHROME_CPU_LIMIT="1.0"
CHROME_MAX_INSTANCES="3"
CHROME_INSTANCE_TIMEOUT="300"
```

#### N8N Browser Automation Examples

**Web Scraping Workflow**
```javascript
// In N8N Chrome node
{
  "url": "https://example.com",
  "waitUntil": "networkidle2",
  "screenshot": true,
  "evaluate": "() => document.title"
}
```

**Automated Form Submission**
```javascript
// Multi-step automation
{
  "url": "https://form-site.com",
  "actions": [
    {"type": "type", "selector": "#email", "text": "user@example.com"},
    {"type": "type", "selector": "#password", "text": "password"},
    {"type": "click", "selector": "#submit"},
    {"type": "waitForNavigation"}
  ]
}
```

### SSL Management

#### Automatic SSL Certificate Management

The stack automatically handles SSL certificates through Let's Encrypt and an internal certificate authority.

**Certificate Lifecycle**
- Initial generation during installation
- Automatic renewal via systemd timers
- Internal service-to-service encryption
- Health monitoring and alerting

**Manual SSL Operations**

```bash
# Reconfigure SSL certificates
./jstack.sh --configure-ssl

# Check SSL certificate status
sudo -u jarvis /home/jarvis/scripts/ssl-status.sh

# View certificate details
openssl x509 -in /path/to/cert -text -noout

# Test SSL connectivity
curl -vI https://n8n.your-domain.com
```

#### SSL Troubleshooting

**Common SSL Issues**

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Certificate expired | Browser SSL warnings | Run `./jstack.sh --configure-ssl` |
| DNS validation failed | Let's Encrypt errors | Verify DNS A records |
| Internal SSL issues | Service connectivity problems | Check internal CA certificates |

**SSL Configuration Validation**

```bash
# Test external SSL (Let's Encrypt)
curl -I https://n8n.your-domain.com
curl -I https://supabase.your-domain.com
curl -I https://studio.your-domain.com

# Test internal SSL (Internal CA)
docker exec nginx openssl s_client -connect postgres:5432

# Check certificate renewal timers
systemctl --user list-timers ssl-renewal
```

### Performance Optimization

#### Resource Monitoring

```bash
# Container resource usage
docker stats

# System resource usage
htop
free -h
df -h

# Service-specific monitoring
docker logs postgres
docker logs n8n
docker logs nginx
```

#### Performance Tuning Commands

```bash
# Adjust PostgreSQL configuration
nano jstack.config
# Modify POSTGRES_* variables

# Restart services with new configuration
./jstack.sh --configure-ssl  # Restart all services

# Monitor performance impact
docker stats --format "table {{.Name}}	{{.CPUPerc}}	{{.MemUsage}}"
```

#### Optimization Workflows

**Database Performance Tuning**
```bash
# 1. Backup current state
./jstack.sh --backup before-db-tuning

# 2. Adjust PostgreSQL settings
nano jstack.config
# Increase POSTGRES_SHARED_BUFFERS for more RAM
# Adjust POSTGRES_WORK_MEM for complex queries

# 3. Apply changes
./jstack.sh --configure-ssl  # Restart containers

# 4. Monitor impact
docker exec postgres psql -U postgres -c "SELECT * FROM pg_stat_activity;"
```

**N8N Workflow Optimization**
```bash
# 1. Adjust N8N resource limits
ENABLE_DEBUG_LOGS="true"
N8N_MEMORY_LIMIT="3G"
N8N_EXECUTION_TIMEOUT="10800"  # 3 hours for complex workflows

# 2. Monitor workflow performance
docker logs n8n | grep -i error
docker logs n8n | grep -i timeout
```

---

## Service Management

### Docker Container Operations

The JarvisJR Stack runs all services as rootless Docker containers under the `jarvis` user for enhanced security and isolation.

#### Container Status & Health Checks

**View All Containers**
```bash
# Switch to service user
sudo su - jarvis

# List all containers with status
docker ps --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'

# Show only running containers
docker ps

# Show all containers (including stopped)
docker ps --all
```

**Detailed Container Information**
```bash
# Inspect specific container
docker inspect postgres
docker inspect n8n
docker inspect nginx

# Container resource usage
docker stats

# Real-time container logs
docker logs -f n8n
docker logs -f postgres --tail 50
```

**Health Status Monitoring**
```bash
# Check container health status
docker ps --filter health=healthy
docker ps --filter health=unhealthy

# Health check details
docker inspect --format='{{json .State.Health}}' postgres | jq
```

#### Service Lifecycle Management

**Starting Services**
```bash
# Start all services (handled by script)
sudo -u jarvis /home/jarvis/scripts/core/service_orchestration.sh start-all

# Start individual containers
docker start postgres
docker start supabase-api
docker start n8n
docker start nginx
```

**Stopping Services**
```bash
# Stop all services gracefully
sudo -u jarvis /home/jarvis/scripts/core/service_orchestration.sh stop-all

# Stop individual containers
docker stop n8n
docker stop supabase-api
docker stop postgres
docker stop nginx
```

**Restarting Services**
```bash
# Restart specific service
docker restart n8n
docker restart postgres

# Restart all services
sudo -u jarvis /home/jarvis/scripts/core/service_orchestration.sh restart-all
```

#### Container Logs & Debugging

**Log Management**
```bash
# View recent logs
docker logs postgres --tail 100
docker logs n8n --since 1h
docker logs nginx --since "2025-01-07T10:00:00"

# Follow logs in real-time
docker logs -f n8n
docker logs -f postgres

# Search logs for specific patterns
docker logs n8n 2>&1 | grep -i error
docker logs postgres 2>&1 | grep -i "connection"
```

**Log Rotation & Cleanup**
```bash
# Container logs are automatically rotated based on:
CONTAINER_LOG_MAX_SIZE="10m"      # 10MB per log file
CONTAINER_LOG_MAX_FILES="5"       # Keep 5 rotated files

# Manual log cleanup (if needed)
docker system prune --volumes
```

#### Network Management

**Docker Networks**
```bash
# List Docker networks
docker network ls

# Inspect network configuration
docker network inspect jarvis_network
docker network inspect public_tier
docker network inspect private_tier

# Test network connectivity
docker exec n8n ping postgres
docker exec nginx curl http://supabase-api:8000/health
```

**Service Discovery**
```bash
# Services communicate via container names:
# - postgres:5432 (database)
# - supabase-api:8000 (API)
# - n8n:5678 (workflows)

# Test internal connectivity
docker exec n8n curl -I http://supabase-api:8000
docker exec supabase-api curl -I http://postgres:5432
```

### System Services & Timers

#### Systemd Service Management

**SSL Certificate Renewal**
```bash
# Check SSL renewal timer status
systemctl --user status ssl-renewal.timer
systemctl --user list-timers ssl-renewal

# Manual SSL certificate renewal
systemctl --user start ssl-renewal.service

# View SSL renewal logs
journalctl --user -u ssl-renewal.service
```

**Backup Services**
```bash
# Check backup timer status
systemctl --user status backup.timer
systemctl --user list-timers backup

# Manual backup execution
systemctl --user start backup.service

# View backup logs
journalctl --user -u backup.service
```

**Service Configuration**
```bash
# List all user services
systemctl --user list-unit-files

# Service status overview
systemctl --user status
```

#### Security Services

**UFW Firewall Management**
```bash
# Check firewall status
sudo ufw status verbose

# View firewall logs
sudo tail -f /var/log/ufw.log

# Firewall rule management (rarely needed)
sudo ufw show added
```

**fail2ban Intrusion Prevention**
```bash
# Check fail2ban status
sudo systemctl status fail2ban

# View banned IPs
sudo fail2ban-client status
sudo fail2ban-client status sshd

# View fail2ban logs
sudo tail -f /var/log/fail2ban.log
```

**AppArmor Security Profiles**
```bash
# Check AppArmor status
sudo aa-status

# View AppArmor profiles
sudo apparmor_status

# AppArmor logs
sudo dmesg | grep -i apparmor
```

### Database Management

#### PostgreSQL Operations

**Database Access**
```bash
# Connect to PostgreSQL as superuser
docker exec -it postgres psql -U postgres

# Connect to specific database
docker exec -it postgres psql -U postgres -d supabase

# Run SQL commands directly
docker exec postgres psql -U postgres -c "SELECT version();"
```

**Database Monitoring**
```bash
# Database size and statistics
docker exec postgres psql -U postgres -c "
  SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation 
  FROM pg_stats 
  WHERE schemaname = 'public';"

# Active connections
docker exec postgres psql -U postgres -c "
  SELECT 
    state,
    count(*) 
  FROM pg_stat_activity 
  GROUP BY state;"

# Database performance metrics
docker exec postgres psql -U postgres -c "
  SELECT 
    datname,
    numbackends,
    xact_commit,
    xact_rollback,
    blks_read,
    blks_hit
  FROM pg_stat_database;"
```

**Database Backup & Maintenance**
```bash
# Manual database backup
docker exec postgres pg_dump -U postgres supabase > backup.sql

# Database vacuum and analyze
docker exec postgres psql -U postgres -c "VACUUM ANALYZE;"

# Check database integrity
docker exec postgres psql -U postgres -c "SELECT pg_database_size('supabase');"
```

#### Supabase Management

**Supabase API Health**
```bash
# Check Supabase API status
curl -I https://supabase.your-domain.com/health
curl https://supabase.your-domain.com/rest/v1/

# Test Supabase Studio access
curl -I https://studio.your-domain.com
```

**Supabase Configuration**
```bash
# View Supabase environment variables
docker exec supabase-api env | grep SUPABASE

# Check Supabase logs for errors
docker logs supabase-api 2>&1 | grep -i error
docker logs supabase-studio 2>&1 | grep -i error
```

### N8N Workflow Management

#### N8N Operations

**N8N Service Management**
```bash
# Check N8N status
curl -I https://n8n.your-domain.com

# View N8N logs
docker logs n8n --tail 100

# N8N container shell access
docker exec -it n8n /bin/bash

# Check N8N configuration
docker exec n8n env | grep N8N
```

**Workflow Monitoring**
```bash
# Monitor workflow executions
docker logs n8n | grep -i execution

# Check for workflow errors
docker logs n8n | grep -i error

# Performance monitoring
docker logs n8n | grep -i timeout
docker logs n8n | grep -i memory
```

**N8N Database Integration**
```bash
# Test N8N to PostgreSQL connectivity
docker exec n8n ping postgres

# Check N8N database connections
docker exec n8n netstat -an | grep 5432
```

### Monitoring & Alerting

#### Health Check Scripts

**System Status Overview**
```bash
# Comprehensive system status (when implemented)
sudo -u jarvis /home/jarvis/scripts/status.sh

# Service-specific status checks
curl -f https://n8n.your-domain.com || echo "N8N Down"
curl -f https://supabase.your-domain.com/health || echo "Supabase Down"
curl -f https://studio.your-domain.com || echo "Studio Down"
```

**Resource Monitoring**
```bash
# Container resource usage
docker stats --no-stream --format "table {{.Name}}	{{.CPUPerc}}	{{.MemUsage}}"

# System resource usage
free -h
df -h
uptime
```

**Network Connectivity**
```bash
# Test external connectivity
curl -I https://google.com

# Test internal Docker connectivity
docker exec n8n ping postgres
docker exec nginx nslookup supabase-api
```

#### Log Monitoring

**Centralized Log Viewing**
```bash
# View all service logs
docker logs postgres --tail 20
docker logs supabase-api --tail 20
docker logs n8n --tail 20
docker logs nginx --tail 20

# Search across all logs for errors
for container in postgres supabase-api n8n nginx; do
  echo "=== $container ==="
  docker logs $container 2>&1 | grep -i error | tail -5
done
```

**Log Analysis**
```bash
# Performance issues
docker logs n8n | grep -i "timeout\|memory\|performance"

# Security events
sudo grep -i "authentication\|unauthorized\|forbidden" /var/log/auth.log

# SSL/Certificate issues
docker logs nginx | grep -i "ssl\|certificate\|tls"
```

### Troubleshooting Common Issues

#### Container Issues

**Container Won't Start**
```bash
# Check container status and errors
docker ps --all
docker logs container_name

# Inspect container configuration
docker inspect container_name

# Check Docker daemon status
systemctl --user status docker
```

**Memory/Resource Issues**
```bash
# Check container resource limits
docker inspect container_name | grep -i memory
docker stats --no-stream

# Adjust resource limits in jstack.config
nano jstack.config
# Modify POSTGRES_MEMORY_LIMIT, N8N_MEMORY_LIMIT, etc.
```

**Network Connectivity Issues**
```bash
# Test Docker networking
docker network ls
docker network inspect jarvis_network

# Test internal connectivity
docker exec n8n ping postgres
docker exec nginx curl http://supabase-api:8000
```

#### Service-Specific Issues

**PostgreSQL Issues**
```bash
# Check PostgreSQL status
docker exec postgres pg_isready -U postgres

# Database connection issues
docker exec postgres psql -U postgres -c "SELECT 1;"

# Check PostgreSQL logs
docker logs postgres | grep -i error
```

**N8N Issues**
```bash
# N8N won't start
docker logs n8n | grep -i error

# Workflow execution issues
docker logs n8n | grep -i "execution\|timeout"

# Database connectivity from N8N
docker exec n8n ping postgres
```

**NGINX Issues**
```bash
# NGINX configuration test
docker exec nginx nginx -t

# SSL certificate issues
docker exec nginx openssl x509 -in /etc/ssl/certs/cert.pem -text -noout

# Proxy connectivity
docker exec nginx curl -I http://n8n:5678
```

---

## Advanced Operations

### Backup & Recovery System

The JarvisJR Stack includes a comprehensive backup and recovery system designed to protect all your data, configurations, and maintain business continuity.

#### Backup Architecture

**What Gets Backed Up**
- 📊 **Database Dumps**: Complete PostgreSQL database including N8N workflows
- 💾 **Volume Data**: All Docker volumes with service configurations
- 🔒 **SSL Certificates**: Both Let's Encrypt and internal CA certificates
- 🔑 **GPG Secrets**: Encrypted secrets and keyring data
- ⚙️ **System Configs**: Docker configurations, NGINX settings, scripts
- 🛡️ **Security Settings**: AppArmor profiles, fail2ban rules, UFW firewall
- ⚡ **System Services**: Systemd services and timers for SSL rotation

**Backup Storage Structure**
```
/home/jarvis/backups/
├── backup_domain_20250107_203045.tar.gz    # Timestamped backups
├── backup_domain_working-version_20250107.tar.gz  # Named backups
├── backup_domain_20250106_020000.tar.gz    # Automatic weekly backups
└── backup.log                              # Backup operation logs
```

#### Advanced Backup Operations

**Automated Backup Scheduling**
```bash
# Default schedule: Weekly backups every Sunday at 2 AM
BACKUP_SCHEDULE="0 2 * * 0"

# Custom schedules (edit in jstack.config)
BACKUP_SCHEDULE="0 2 * * *"     # Daily at 2 AM
BACKUP_SCHEDULE="0 2 */3 * *"   # Every 3 days at 2 AM
BACKUP_SCHEDULE="0 2 1 * *"     # Monthly on 1st at 2 AM
```

**Backup Encryption & Security**
```bash
# GPG encryption (enabled by default)
BACKUP_ENCRYPTION="true"
BACKUP_COMPRESSION_LEVEL="6"    # Balance of speed/size (1-9)

# Manual encrypted backup
./jstack.sh --backup secure-$(date +%Y%m%d)

# Backup verification
gpg --verify backup_domain_20250107_203045.tar.gz.sig
```

**Backup Retention Policies**
```bash
# Configure retention in jstack.config
DATABASE_BACKUP_RETENTION="1"      # Keep 1 database backup
VOLUME_BACKUP_RETENTION="1"        # Keep 1 volume backup
BACKUP_RETENTION_DAYS="1"          # Overall retention policy

# Custom retention for critical systems
DATABASE_BACKUP_RETENTION="7"      # Keep 7 database backups
VOLUME_BACKUP_RETENTION="3"        # Keep 3 volume backups
BACKUP_RETENTION_DAYS="30"         # Keep backups for 30 days
```

#### Disaster Recovery Procedures

**Complete System Recovery**
```bash
# Scenario: Complete server failure, new server setup

# 1. Prepare new server (same as initial installation)
adduser jarvis
usermod -aG sudo jarvis
loginctl enable-linger jarvis
su - jarvis

# 2. Download and configure JarvisJR Stack
curl -fsSL "https://raw.githubusercontent.com/.../jstack.sh" -o jstack.sh
chmod +x jstack.sh

# 3. Transfer backup files to new server
scp backup_domain_*.tar.gz jarvis@new-server:/home/jarvis/

# 4. Restore from backup
./jstack.sh --restore backup_domain_20250107_203045.tar.gz

# 5. Verify restoration
docker ps --format 'table {{.Names}}	{{.Status}}'
curl -I https://n8n.your-domain.com
```

**Partial Data Recovery**
```bash
# Scenario: Database corruption, services still running

# 1. Create emergency backup of current state
./jstack.sh --backup emergency-$(date +%Y%m%d-%H%M%S)

# 2. Stop affected services
docker stop supabase-api n8n

# 3. Restore database from known good backup
./jstack.sh --restore backup_domain_20250106_020000.tar.gz

# 4. Verify data integrity
docker exec postgres psql -U postgres -c "SELECT count(*) FROM information_schema.tables;"

# 5. Restart services
docker start supabase-api n8n
```

**Point-in-Time Recovery**
```bash
# List available backups by date
./jstack.sh --list-backups

# Restore to specific point in time
./jstack.sh --restore backup_domain_20250105_100000.tar.gz

# Verify recovered state matches expected data
docker exec postgres psql -U postgres -c "SELECT created_at FROM your_table ORDER BY created_at DESC LIMIT 5;"
```

### SSL Certificate Management

#### Certificate Architecture

**Dual Certificate System**
- **External SSL**: Let's Encrypt certificates for public-facing services
- **Internal SSL**: Self-signed CA for service-to-service communication
- **Automatic Renewal**: Systemd timers handle certificate lifecycle

**Certificate Locations**
```
/home/jarvis/jarvis-stack/ssl/
├── external/
│   ├── fullchain.pem       # Let's Encrypt certificate chain
│   ├── privkey.pem         # Let's Encrypt private key
│   └── renewal/            # Renewal configuration
└── internal/
    ├── ca.pem              # Internal CA certificate
    ├── ca-key.pem          # Internal CA private key
    ├── server.pem          # Internal server certificate
    └── server-key.pem      # Internal server private key
```

#### Advanced SSL Operations

**Manual Certificate Management**
```bash
# Reconfigure all SSL certificates
./jstack.sh --configure-ssl

# Check certificate status and expiration
sudo -u jarvis /home/jarvis/scripts/ssl-status.sh

# Test certificate renewal process
systemctl --user start ssl-renewal.service
journalctl --user -u ssl-renewal.service --follow
```

**Certificate Monitoring**
```bash
# Check certificate expiration dates
openssl x509 -in /home/jarvis/jarvis-stack/ssl/external/fullchain.pem -text -noout | grep "Not After"

# Verify certificate chain
openssl verify -CAfile /home/jarvis/jarvis-stack/ssl/internal/ca.pem /home/jarvis/jarvis-stack/ssl/internal/server.pem

# Test SSL connectivity
curl -vI https://n8n.your-domain.com 2>&1 | grep -E "(SSL|TLS|certificate)"
```

**Custom Certificate Integration**
```bash
# For organizations with existing PKI infrastructure

# 1. Replace internal CA certificates
cp your-ca.pem /home/jarvis/jarvis-stack/ssl/internal/ca.pem
cp your-ca-key.pem /home/jarvis/jarvis-stack/ssl/internal/ca-key.pem

# 2. Generate new server certificates
openssl req -new -key server-key.pem -out server.csr
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem -out server.pem

# 3. Restart services to use new certificates
./jstack.sh --configure-ssl
```

### Browser Automation Advanced Configuration

#### Puppeteer Optimization

**Performance Tuning**
```bash
# High-performance configuration for heavy automation
CHROME_MEMORY_LIMIT="8G"
CHROME_CPU_LIMIT="2.0"
CHROME_MAX_INSTANCES="15"
CHROME_INSTANCE_TIMEOUT="900"
CHROME_CACHE_SIZE="2G"

# Resource-constrained optimization
CHROME_MEMORY_LIMIT="1G"
CHROME_CPU_LIMIT="0.5"
CHROME_MAX_INSTANCES="2"
CHROME_INSTANCE_TIMEOUT="180"
CHROME_CACHE_SIZE="256M"
```

**Security Hardening**
```bash
# Browser security arguments (pre-configured)
CHROME_SECURITY_ARGS="
  --disable-dev-shm-usage
  --disable-gpu
  --headless=new
  --disable-extensions
  --disable-plugins
  --disable-background-timer-throttling
  --disable-renderer-backgrounding
  --disable-default-apps
  --disable-sync
  --disable-translate
  --hide-scrollbars
  --mute-audio
  --disable-background-networking
"

# Additional security options for sensitive environments
CHROME_EXTRA_SECURITY="
  --disable-features=VizDisplayCompositor
  --disable-ipc-flooding-protection
  --disable-renderer-backgrounding
  --disable-backgrounding-occluded-windows
  --disable-features=TranslateUI
"
```

**Browser Monitoring & Debugging**
```bash
# Monitor browser resource usage
docker stats | grep chrome

# Debug browser automation issues
docker logs n8n | grep -i "puppeteer\|chrome\|browser"

# Check browser instance management
docker exec n8n ps aux | grep chrome

# Browser cleanup (if instances stuck)
docker exec n8n pkill -f chrome
```

#### Custom Browser Profiles

**Profile Configuration**
```bash
# Custom browser profile for specific automation needs
PUPPETEER_USER_DATA_DIR="/home/jarvis/jarvis-stack/browser-profiles"

# Create profile directories
mkdir -p /home/jarvis/jarvis-stack/browser-profiles/automation
mkdir -p /home/jarvis/jarvis-stack/browser-profiles/testing
```

**Advanced Automation Examples**

**Multi-Tab Workflow**
```javascript
// N8N JavaScript node example
const browser = await this.getNodeParameter('browser');
const pages = [];

// Open multiple tabs
for (let i = 0; i < 5; i++) {
  const page = await browser.newPage();
  pages.push(page);
}

// Parallel processing
const results = await Promise.all(
  pages.map(async (page, index) => {
    await page.goto(`https://example.com/page${index}`);
    return await page.title();
  })
);

// Cleanup
for (const page of pages) {
  await page.close();
}

return results;
```

### Performance Optimization

#### System-Level Optimization

**Memory Management**
```bash
# Configure swap for large workloads
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Add to /etc/fstab for persistence
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Adjust swappiness for better performance
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
```

**CPU Optimization**
```bash
# Check CPU governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set performance mode for high-workload periods
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Return to powersave mode
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

**I/O Optimization**
```bash
# Check current I/O scheduler
cat /sys/block/sda/queue/scheduler

# Set deadline scheduler for better database performance
echo deadline | sudo tee /sys/block/sda/queue/scheduler

# Adjust dirty ratios for better write performance
echo 5 | sudo tee /proc/sys/vm/dirty_background_ratio
echo 10 | sudo tee /proc/sys/vm/dirty_ratio
```

#### Database Performance Tuning

**PostgreSQL Optimization**
```bash
# Advanced PostgreSQL configuration
POSTGRES_SHARED_BUFFERS="2GB"          # 25% of total RAM
POSTGRES_EFFECTIVE_CACHE_SIZE="6GB"    # 75% of total RAM
POSTGRES_WORK_MEM="64MB"                # Per connection work memory
POSTGRES_MAINTENANCE_WORK_MEM="512MB"  # Maintenance operations
POSTGRES_CHECKPOINT_COMPLETION_TARGET="0.9"
POSTGRES_WAL_BUFFERS="16MB"
POSTGRES_DEFAULT_STATISTICS_TARGET="100"
```

**Query Performance Monitoring**
```sql
-- Enable query logging for slow queries
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second
SELECT pg_reload_conf();

-- Monitor slow queries
SELECT 
  query,
  mean_time,
  calls,
  total_time
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- Database performance metrics
SELECT 
  schemaname,
  tablename,
  seq_scan,
  seq_tup_read,
  idx_scan,
  idx_tup_fetch
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC;
```

#### Container Optimization

**Docker Performance Tuning**
```bash
# Optimize Docker daemon configuration
mkdir -p /home/jarvis/.config/docker

cat > /home/jarvis/.config/docker/daemon.json << EOF
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
```

**Resource Limit Optimization**
```bash
# Balanced resource allocation for 8GB RAM server
POSTGRES_MEMORY_LIMIT="3G"
POSTGRES_CPU_LIMIT="2.0"
N8N_MEMORY_LIMIT="2G"
N8N_CPU_LIMIT="1.0"
CHROME_MEMORY_LIMIT="2G"
CHROME_CPU_LIMIT="1.0"
NGINX_MEMORY_LIMIT="512M"
NGINX_CPU_LIMIT="0.5"

# High-performance allocation for 16GB+ RAM server
POSTGRES_MEMORY_LIMIT="6G"
POSTGRES_CPU_LIMIT="4.0"
N8N_MEMORY_LIMIT="4G"
N8N_CPU_LIMIT="2.0"
CHROME_MEMORY_LIMIT="4G"
CHROME_CPU_LIMIT="2.0"
NGINX_MEMORY_LIMIT="1G"
NGINX_CPU_LIMIT="1.0"
```

### Security Hardening

#### Advanced Security Configuration

**AppArmor Profile Customization**
```bash
# View current AppArmor profiles
sudo aa-status

# Create custom profile for additional containers
sudo nano /etc/apparmor.d/docker-custom

# Reload AppArmor profiles
sudo systemctl reload apparmor
```

**fail2ban Advanced Configuration**
```bash
# Custom fail2ban jail for Docker services
sudo nano /etc/fail2ban/jail.d/docker-custom.conf

[docker-auth]
enabled = true
port = https,http
filter = docker-auth
logpath = /home/jarvis/logs/*.log
maxretry = 3
bantime = 3600
findtime = 600
```

**UFW Advanced Rules**
```bash
# Allow specific IP ranges for admin access
sudo ufw allow from 192.168.1.0/24 to any port 22

# Rate limiting for HTTP/HTTPS
sudo ufw limit 80/tcp
sudo ufw limit 443/tcp

# Block specific countries (example)
# Note: Requires geoip integration
sudo ufw deny from 192.0.2.0/24
```

#### Audit Logging

**System Audit Configuration**
```bash
# Enable audit logging
sudo systemctl enable auditd
sudo systemctl start auditd

# Configure audit rules for Docker
echo "-w /var/lib/docker -p rwxa -k docker" | sudo tee -a /etc/audit/rules.d/docker.rules
echo "-w /home/jarvis/jarvis-stack -p rwxa -k jarvis" | sudo tee -a /etc/audit/rules.d/jarvis.rules

# Reload audit rules
sudo augenrules --load
```

**Security Event Monitoring**
```bash
# Monitor authentication events
sudo ausearch -k authentication

# Monitor file access events
sudo ausearch -k jarvis

# Monitor Docker events
sudo ausearch -k docker

# Generate security reports
sudo aureport --auth
sudo aureport --file
```

---

## Maintenance & Updates

### Regular Maintenance Procedures

#### Weekly Maintenance Tasks

**System Health Check**
```bash
# Comprehensive weekly health check script
#!/bin/bash
echo "=== JarvisJR Stack Weekly Health Check ==="

# 1. Container status
echo "Container Status:"
docker ps --format 'table {{.Names}}	{{.Status}}	{{.RunningFor}}'

# 2. Resource usage
echo -e "
Resource Usage:"
docker stats --no-stream --format "table {{.Name}}	{{.CPUPerc}}	{{.MemUsage}}"

# 3. Disk usage
echo -e "
Disk Usage:"
df -h

# 4. SSL certificate status
echo -e "
SSL Certificate Expiration:"
openssl x509 -in /home/jarvis/jarvis-stack/ssl/external/fullchain.pem -text -noout | grep "Not After"

# 5. Service connectivity
echo -e "
Service Connectivity:"
curl -f -s https://n8n.your-domain.com > /dev/null && echo "N8N: OK" || echo "N8N: FAIL"
curl -f -s https://supabase.your-domain.com/health > /dev/null && echo "Supabase: OK" || echo "Supabase: FAIL"
curl -f -s https://studio.your-domain.com > /dev/null && echo "Studio: OK" || echo "Studio: FAIL"

# 6. Backup status
echo -e "
Recent Backups:"
ls -la /home/jarvis/backups/*.tar.gz | tail -3

echo -e "
=== Health Check Complete ==="
```

**Database Maintenance**
```bash
# Weekly database maintenance
docker exec postgres psql -U postgres -c "
  -- Vacuum and analyze all tables
  VACUUM ANALYZE;
  
  -- Update table statistics
  ANALYZE;
  
  -- Check database size
  SELECT pg_size_pretty(pg_database_size('postgres')) as database_size;
  
  -- Check for long-running queries
  SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
  FROM pg_stat_activity 
  WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
"
```

**Log Rotation & Cleanup**
```bash
# Clean up old logs (automated by configuration)
find /home/jarvis/logs -name "*.log" -mtime +14 -delete

# Clean up old Docker logs
docker system prune -f

# Clean up old container images
docker image prune -f

# Clean up old backup files (beyond retention policy)
find /home/jarvis/backups -name "backup_*.tar.gz" -mtime +7 -delete
```

#### Monthly Maintenance Tasks

**Security Updates**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker
sudo apt update && sudo apt install --only-upgrade docker-ce docker-ce-cli containerd.io

# Restart services if kernel updated
if [ -f /var/run/reboot-required ]; then
  echo "Reboot required after updates"
  # Plan reboot during maintenance window
fi
```

**Certificate Management**
```bash
# Verify SSL certificate renewal system
systemctl --user status ssl-renewal.timer
systemctl --user start ssl-renewal.service

# Test certificate renewal process
./jstack.sh --configure-ssl --dry-run

# Backup certificates
cp -r /home/jarvis/jarvis-stack/ssl /home/jarvis/backups/ssl-backup-$(date +%Y%m%d)
```

**Performance Review**
```bash
# Monthly performance analysis
echo "=== Monthly Performance Review ==="

# Resource usage trends
docker stats --no-stream --format "table {{.Name}}	{{.CPUPerc}}	{{.MemUsage}}" > performance-$(date +%Y%m).txt

# Database performance metrics
docker exec postgres psql -U postgres -c "
  SELECT 
    schemaname,
    tablename,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    seq_scan,
    idx_scan
  FROM pg_stat_user_tables
  ORDER BY n_tup_ins + n_tup_upd + n_tup_del DESC;
" > db-performance-$(date +%Y%m).txt

# Analyze performance trends
echo "Review performance files for optimization opportunities"
```

### Update Procedures

#### JarvisJR Stack Updates

**Preparation for Updates**
```bash
# 1. Create comprehensive backup before updates
./jstack.sh --backup pre-update-$(date +%Y%m%d)

# 2. Document current configuration
cp jstack.config jstack.config.backup-$(date +%Y%m%d)

# 3. Test current system health
./jstack.sh --dry-run

# 4. Note current version/commit
git log --oneline -n 5 > version-before-update.txt
```

**Update Process**
```bash
# 1. Download latest version
curl -fsSL -H "Cache-Control: no-cache" \
  "https://raw.githubusercontent.com/your-username/JarvisJR_Stack/main/jstack.sh?$(date +%s)" \
  -o jstack-new.sh

# 2. Compare versions
diff jstack.sh jstack-new.sh | head -20

# 3. Test new version with dry-run
chmod +x jstack-new.sh
./jstack-new.sh --dry-run

# 4. Apply update if tests pass
mv jstack.sh jstack-old.sh
mv jstack-new.sh jstack.sh

# 5. Run update
./jstack.sh --configure-ssl

# 6. Verify update success
docker ps --format 'table {{.Names}}	{{.Status}}'
curl -I https://n8n.your-domain.com
```

**Rollback Procedure**
```bash
# If update fails, rollback process:

# 1. Stop current services
docker stop $(docker ps -q)

# 2. Restore from backup
./jstack.sh --restore pre-update-$(date +%Y%m%d)

# 3. Restore old script version
mv jstack.sh jstack-failed.sh
mv jstack-old.sh jstack.sh

# 4. Restart services
./jstack.sh

# 5. Verify rollback success
docker ps --format 'table {{.Names}}	{{.Status}}'
```

#### Container Image Updates

**Manual Image Updates**
```bash
# Check for newer container images
docker images

# Update specific service
docker pull postgres:latest
docker pull n8n/n8n:latest

# Update with service restart
docker stop n8n
docker rm n8n
# Recreate container with new image (handled by stack script)
./jstack.sh --configure-ssl
```

**Automated Update Strategy**
```bash
# Configure update checking in jstack.config
UPDATE_ROLLBACK_ON_FAILURE="true"
PRE_UPDATE_BACKUP="true"
IMAGE_CLEANUP_RETENTION="5"

# Automated update script (create as cron job)
#!/bin/bash
echo "Checking for updates..."
./jstack.sh --backup auto-update-$(date +%Y%m%d)
./jstack.sh --update-images  # (if implemented)
```

### Monitoring & Alerting

#### System Monitoring Setup

**Resource Monitoring**
```bash
# Create monitoring script
cat > /home/jarvis/scripts/monitor.sh << 'EOF'
#!/bin/bash
THRESHOLD_CPU=80
THRESHOLD_MEM=85
THRESHOLD_DISK=90

# Check CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
if (( $(echo "$CPU_USAGE > $THRESHOLD_CPU" | bc -l) )); then
  echo "HIGH CPU: $CPU_USAGE%" | mail -s "JarvisJR Alert: High CPU" admin@your-domain.com
fi

# Check memory usage
MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100.0}')
if (( $(echo "$MEM_USAGE > $THRESHOLD_MEM" | bc -l) )); then
  echo "HIGH MEMORY: $MEM_USAGE%" | mail -s "JarvisJR Alert: High Memory" admin@your-domain.com
fi

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
if [ $DISK_USAGE -gt $THRESHOLD_DISK ]; then
  echo "HIGH DISK: $DISK_USAGE%" | mail -s "JarvisJR Alert: High Disk Usage" admin@your-domain.com
fi
EOF

chmod +x /home/jarvis/scripts/monitor.sh
```

**Service Health Monitoring**
```bash
# Create service health check
cat > /home/jarvis/scripts/health-check.sh << 'EOF'
#!/bin/bash
SERVICES=("https://n8n.your-domain.com" "https://supabase.your-domain.com/health" "https://studio.your-domain.com")
FAILED_SERVICES=""

for service in "${SERVICES[@]}"; do
  if ! curl -f -s "$service" > /dev/null; then
    FAILED_SERVICES="$FAILED_SERVICES $service"
  fi
done

if [ -n "$FAILED_SERVICES" ]; then
  echo "Failed services:$FAILED_SERVICES" | mail -s "JarvisJR Alert: Service Down" admin@your-domain.com
fi
EOF

chmod +x /home/jarvis/scripts/health-check.sh
```

**Cron Job Setup**
```bash
# Add monitoring cron jobs
crontab -e

# Add these lines:
# Resource monitoring every 15 minutes
*/15 * * * * /home/jarvis/scripts/monitor.sh

# Service health check every 5 minutes
*/5 * * * * /home/jarvis/scripts/health-check.sh

# Weekly comprehensive health report
0 9 * * 1 /home/jarvis/scripts/weekly-health-check.sh | mail -s "JarvisJR Weekly Health Report" admin@your-domain.com
```

#### Alerting Configuration

**Email Alerting Setup**
```bash
# Install and configure postfix for email alerts
sudo apt install postfix mailutils

# Configure postfix for relay (adjust for your email provider)
sudo postconf -e 'relayhost = [smtp.your-provider.com]:587'
sudo postconf -e 'smtp_use_tls = yes'
sudo postconf -e 'smtp_sasl_auth_enable = yes'

# Create SASL password file
echo '[smtp.your-provider.com]:587 username:password' | sudo tee /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd

# Restart postfix
sudo systemctl restart postfix
```

**Slack Integration (Optional)**
```bash
# Configure Slack webhook in jstack.config
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# Create Slack notification function
slack_notify() {
  local message="$1"
  if [ -n "$SLACK_WEBHOOK" ]; then
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"JarvisJR Alert: $message\"}" \
      "$SLACK_WEBHOOK"
  fi
}

# Use in monitoring scripts
if [ $CPU_USAGE -gt $THRESHOLD_CPU ]; then
  slack_notify "High CPU usage: $CPU_USAGE%"
fi
```

#### Performance Tuning

**Database Performance Monitoring**
```bash
# Create database performance monitoring
cat > /home/jarvis/scripts/db-monitor.sh << 'EOF'
#!/bin/bash
# Check for slow queries
SLOW_QUERIES=$(docker exec postgres psql -U postgres -t -c "
  SELECT count(*) FROM pg_stat_activity 
  WHERE state = 'active' 
  AND now() - query_start > interval '30 seconds'
")

if [ "$SLOW_QUERIES" -gt 5 ]; then
  echo "Warning: $SLOW_QUERIES slow running queries detected"
  docker exec postgres psql -U postgres -c "
    SELECT pid, now() - query_start as duration, query 
    FROM pg_stat_activity 
    WHERE state = 'active' 
    AND now() - query_start > interval '30 seconds'
  " | mail -s "JarvisJR: Slow Queries Detected" admin@your-domain.com
fi

# Check database size growth
DB_SIZE=$(docker exec postgres psql -U postgres -t -c "SELECT pg_database_size('postgres')")
echo "$(date): Database size: $DB_SIZE" >> /home/jarvis/logs/db-size.log
EOF

chmod +x /home/jarvis/scripts/db-monitor.sh
```

**Container Performance Optimization**
```bash
# Monitor container performance
docker stats --no-stream --format "table {{.Name}}	{{.CPUPerc}}	{{.MemUsage}}	{{.MemPerc}}" > /tmp/container-stats.txt

# Analyze performance bottlenecks
echo "=== Container Performance Analysis ==="
cat /tmp/container-stats.txt

# Recommendations based on usage patterns
echo "Performance recommendations:"
echo "- Adjust memory limits if usage consistently high"
echo "- Scale CPU limits for CPU-bound workloads"
echo "- Consider adding swap if memory pressure detected"
```

---

## Troubleshooting

### Common Problems & Solutions

#### Installation Issues

**Problem: "Service user 'jarvis' does not exist"**

*Symptoms:*
- Installation fails during user validation
- Error messages about missing user account
- Permission denied errors

*Diagnosis:*
```bash
# Check if user exists
id jarvis

# Check user permissions
groups jarvis

# Check systemd linger status
loginctl show-user jarvis
```

*Solution:*
```bash
# Create service user with proper permissions
sudo adduser jarvis
sudo usermod -aG sudo jarvis
sudo loginctl enable-linger jarvis

# Verify user setup
sudo su - jarvis
whoami
groups
```

*Prevention:*
- Always create service user before running installation
- Ensure `enable-linger` is executed for Docker rootless support
- Verify user can execute `sudo` commands

---

**Problem: "DNS resolution failed for subdomains"**

*Symptoms:*
- SSL certificate generation fails
- Let's Encrypt validation errors
- Cannot access services via subdomain URLs

*Diagnosis:*
```bash
# Test DNS resolution
nslookup supabase.your-domain.com
nslookup studio.your-domain.com
nslookup n8n.your-domain.com

# Check DNS propagation
dig supabase.your-domain.com +trace

# Test from multiple locations
# Use online tools: whatsmydns.net, dnschecker.org
```

*Solution:*
```bash
# 1. Verify DNS A records are correctly configured
# Each subdomain should point to server IP

# 2. Wait for DNS propagation (5-60 minutes)
# 3. Check with DNS provider for configuration issues
# 4. Retry installation after DNS is working

# Test DNS before proceeding
for subdomain in supabase studio n8n; do
  echo "Testing $subdomain.your-domain.com"
  nslookup $subdomain.your-domain.com
done
```

*Prevention:*
- Configure DNS records before installation
- Wait for full DNS propagation
- Test DNS resolution from multiple locations
- Use lower TTL values (300-600 seconds) during setup

---

**Problem: "Docker rootless installation fails"**

*Symptoms:*
- "Failed to connect to bus" errors
- Docker commands fail with permission errors
- Container startup failures

*Diagnosis:*
```bash
# Check Docker daemon status
systemctl --user status docker

# Check XDG_RUNTIME_DIR
echo $XDG_RUNTIME_DIR

# Check for systemd integration
systemctl --user list-units | grep docker
```

*Solution:*
```bash
# 1. Ensure loginctl enable-linger was run
sudo loginctl enable-linger jarvis

# 2. Set proper environment variables
echo 'export XDG_RUNTIME_DIR=/home/jarvis/.docker/run' >> ~/.bashrc
echo 'export DOCKER_HOST=unix:///home/jarvis/.docker/run/docker.sock' >> ~/.bashrc
source ~/.bashrc

# 3. Restart Docker rootless
systemctl --user restart docker

# 4. Verify Docker is working
docker ps
```

*Prevention:*
- Always run `loginctl enable-linger` for service user
- Source bashrc after Docker installation
- Verify Docker works before proceeding with stack installation

---

#### Service Connectivity Issues

**Problem: "Container won't start or keeps restarting"**

*Symptoms:*
- Container status shows "Restarting" or "Exited"
- Services not accessible via URLs
- Health checks fail

*Diagnosis:*
```bash
# Check container status
docker ps --all

# View container logs
docker logs postgres
docker logs n8n
docker logs nginx

# Check resource usage
docker stats --no-stream

# Inspect container configuration
docker inspect container_name
```

*Solution:*

*For Memory Issues:*
```bash
# Check system memory
free -h

# Adjust memory limits in jstack.config
POSTGRES_MEMORY_LIMIT="2G"  # Reduce if system has limited RAM
N8N_MEMORY_LIMIT="1G"

# Restart services
./jstack.sh --configure-ssl
```

*For Port Conflicts:*
```bash
# Check port usage
netstat -tulpn | grep :443
netstat -tulpn | grep :80

# Kill conflicting processes
sudo fuser -k 80/tcp
sudo fuser -k 443/tcp

# Restart stack
./jstack.sh
```

*For Configuration Issues:*
```bash
# Validate configuration
./jstack.sh --dry-run

# Check Docker network
docker network inspect jarvis_network

# Recreate containers
docker stop $(docker ps -q)
./jstack.sh
```

---

**Problem: "SSL certificate issues"**

*Symptoms:*
- Browser shows SSL warnings
- "Certificate not valid" errors
- Unable to access HTTPS services

*Diagnosis:*
```bash
# Check certificate files
ls -la /home/jarvis/jarvis-stack/ssl/external/

# Test certificate validity
openssl x509 -in /home/jarvis/jarvis-stack/ssl/external/fullchain.pem -text -noout | grep "Not After"

# Test SSL connectivity
curl -vI https://n8n.your-domain.com

# Check Let's Encrypt logs
docker logs nginx | grep -i ssl
```

*Solution:*
```bash
# 1. Reconfigure SSL certificates
./jstack.sh --configure-ssl

# 2. If DNS issues, wait and retry
sleep 300  # Wait 5 minutes for DNS propagation
./jstack.sh --configure-ssl

# 3. Manual certificate generation (if needed)
docker exec nginx certbot --nginx -d n8n.your-domain.com -d supabase.your-domain.com -d studio.your-domain.com

# 4. Verify certificate installation
curl -I https://n8n.your-domain.com
```

---

**Problem: "Database connection failures"**

*Symptoms:*
- N8N cannot connect to PostgreSQL
- Supabase API errors
- Database timeout errors

*Diagnosis:*
```bash
# Test database connectivity
docker exec postgres pg_isready -U postgres

# Check database logs
docker logs postgres | tail -50

# Test internal network connectivity
docker exec n8n ping postgres
docker exec supabase-api ping postgres

# Check database configuration
docker exec postgres psql -U postgres -c "SHOW all;"
```

*Solution:*
```bash
# 1. Restart PostgreSQL
docker restart postgres

# 2. Check database configuration
docker exec postgres psql -U postgres -c "SELECT version();"

# 3. Verify network connectivity
docker network inspect jarvis_network

# 4. Check resource limits
docker stats postgres

# 5. If database corruption suspected
./jstack.sh --restore backup_domain_YYYYMMDD_HHMMSS.tar.gz
```

---

#### Performance Issues

**Problem: "High memory usage and system slowdown"**

*Symptoms:*
- System becomes unresponsive
- High swap usage
- Container OOM (Out of Memory) kills

*Diagnosis:*
```bash
# Check system memory
free -h

# Check container memory usage
docker stats --no-stream

# Check swap usage
swapon --show

# Check for OOM kills
dmesg | grep -i "killed process"

# Check system load
uptime
htop
```

*Solution:*

*Immediate Relief:*
```bash
# Free system memory
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Restart high-memory containers
docker restart chrome  # If browser automation enabled
docker restart n8n
```

*Long-term Fix:*
```bash
# Adjust memory limits in jstack.config
POSTGRES_MEMORY_LIMIT="2G"      # Reduce from 4G
N8N_MEMORY_LIMIT="1G"           # Reduce from 2G
CHROME_MEMORY_LIMIT="2G"        # Reduce from 4G

# Add swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Apply new configuration
./jstack.sh --configure-ssl
```

---

**Problem: "Slow database performance"**

*Symptoms:*
- Long query execution times
- N8N workflow timeouts
- Unresponsive database operations

*Diagnosis:*
```bash
# Check for slow queries
docker exec postgres psql -U postgres -c "
  SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
  FROM pg_stat_activity 
  WHERE (now() - pg_stat_activity.query_start) > interval '10 seconds';
"

# Check database size
docker exec postgres psql -U postgres -c "
  SELECT pg_size_pretty(pg_database_size('postgres'));
"

# Check table statistics
docker exec postgres psql -U postgres -c "
  SELECT schemaname, tablename, seq_scan, seq_tup_read, idx_scan 
  FROM pg_stat_user_tables 
  ORDER BY seq_tup_read DESC;
"
```

*Solution:*
```bash
# 1. Vacuum and analyze database
docker exec postgres psql -U postgres -c "VACUUM ANALYZE;"

# 2. Update database statistics
docker exec postgres psql -U postgres -c "ANALYZE;"

# 3. Optimize PostgreSQL configuration
# Edit jstack.config:
POSTGRES_SHARED_BUFFERS="1GB"           # Increase for more RAM
POSTGRES_EFFECTIVE_CACHE_SIZE="3GB"     # Set to 75% of total RAM
POSTGRES_WORK_MEM="64MB"                # Increase for complex queries

# 4. Restart PostgreSQL with new settings
docker restart postgres

# 5. Monitor improvement
docker exec postgres psql -U postgres -c "SELECT * FROM pg_stat_activity;"
```

---

#### Browser Automation Issues

**Problem: "Chrome/Puppeteer failures in N8N"**

*Symptoms:*
- Browser automation workflows fail
- "Chrome not found" errors
- Browser timeout errors

*Diagnosis:*
```bash
# Check Chrome installation
docker exec n8n which google-chrome

# Check browser process
docker exec n8n ps aux | grep chrome

# Check Chrome capabilities
docker exec n8n google-chrome --version

# Check N8N browser automation logs
docker logs n8n | grep -i "puppeteer\|chrome\|browser"
```

*Solution:*
```bash
# 1. Verify browser automation is enabled
grep ENABLE_BROWSER_AUTOMATION jstack.config

# 2. Check Chrome memory limits
docker stats | grep n8n

# 3. Restart N8N container
docker restart n8n

# 4. Test browser automation manually
docker exec n8n google-chrome --headless --disable-gpu --dump-dom https://google.com

# 5. Adjust Chrome configuration if needed
# Edit jstack.config:
CHROME_MEMORY_LIMIT="4G"
CHROME_MAX_INSTANCES="3"
CHROME_INSTANCE_TIMEOUT="300"
```

### Error Message Explanations

#### Common Error Patterns

**Error: "Failed to connect to bus: No medium found"**

*Meaning:* Docker rootless cannot connect to systemd user session

*Root Cause:* Missing systemd user session or incorrect environment

*Fix:*
```bash
sudo loginctl enable-linger jarvis
echo 'export XDG_RUNTIME_DIR=/home/jarvis/.docker/run' >> ~/.bashrc
source ~/.bashrc
```

---

**Error: "Certificate verification failed"**

*Meaning:* SSL certificate cannot be validated or has expired

*Root Cause:* DNS issues, expired certificates, or incorrect configuration

*Fix:*
```bash
# Check DNS resolution first
nslookup your-domain.com

# Reconfigure SSL
./jstack.sh --configure-ssl

# Manual certificate check
openssl x509 -in cert.pem -text -noout | grep "Not After"
```

---

**Error: "Database connection refused"**

*Meaning:* PostgreSQL is not accepting connections

*Root Cause:* Database not running, network issues, or resource constraints

*Fix:*
```bash
# Check database status
docker ps | grep postgres

# Restart database
docker restart postgres

# Check logs
docker logs postgres
```

---

**Error: "Memory allocation failed"**

*Meaning:* Container cannot allocate requested memory

*Root Cause:* Insufficient system memory or memory limits too high

*Fix:*
```bash
# Check system memory
free -h

# Reduce memory limits
nano jstack.config  # Adjust MEMORY_LIMIT values

# Add swap space
sudo fallocate -l 2G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Debug Procedures

#### Systematic Debugging Approach

**Step 1: Identify the Problem Scope**
```bash
# Check overall system health
./jstack.sh --dry-run

# Check all container status
docker ps --format 'table {{.Names}}	{{.Status}}	{{.RunningFor}}'

# Check service accessibility
curl -I https://n8n.your-domain.com
curl -I https://supabase.your-domain.com
curl -I https://studio.your-domain.com
```

**Step 2: Gather Diagnostic Information**
```bash
# System resources
free -h
df -h
uptime

# Container resources
docker stats --no-stream

# Recent logs from all services
for container in postgres supabase-api n8n nginx; do
  echo "=== $container logs ==="
  docker logs $container --tail 20
done
```

**Step 3: Isolate the Issue**
```bash
# Test individual components
docker exec postgres pg_isready -U postgres     # Database
docker exec n8n curl http://localhost:5678      # N8N
docker exec nginx nginx -t                      # NGINX config

# Test network connectivity
docker exec n8n ping postgres
docker exec nginx ping supabase-api
```

**Step 4: Apply Targeted Fixes**
```bash
# Based on findings, apply specific solutions:

# For configuration issues:
./jstack.sh --dry-run
nano jstack.config

# For service issues:
docker restart service_name

# For resource issues:
# Adjust limits and restart

# For network issues:
docker network prune
./jstack.sh --configure-ssl
```

**Step 5: Verify Resolution**
```bash
# Confirm all services are healthy
docker ps --format 'table {{.Names}}	{{.Status}}'

# Test functionality
curl -f https://n8n.your-domain.com
curl -f https://supabase.your-domain.com/health
curl -f https://studio.your-domain.com

# Create success backup
./jstack.sh --backup fixed-$(date +%Y%m%d)
```

#### Getting Help & Support

**Before Seeking Help**

1. **Gather System Information**
```bash
# Create diagnostic report
echo "=== JarvisJR Diagnostic Report ===" > diagnostic-report.txt
echo "Date: $(date)" >> diagnostic-report.txt
echo "System: $(uname -a)" >> diagnostic-report.txt
echo "Docker Version: $(docker --version)" >> diagnostic-report.txt
echo "" >> diagnostic-report.txt

echo "=== Container Status ===" >> diagnostic-report.txt
docker ps --format 'table {{.Names}}	{{.Status}}	{{.RunningFor}}' >> diagnostic-report.txt
echo "" >> diagnostic-report.txt

echo "=== Resource Usage ===" >> diagnostic-report.txt
free -h >> diagnostic-report.txt
df -h >> diagnostic-report.txt
docker stats --no-stream >> diagnostic-report.txt
echo "" >> diagnostic-report.txt

echo "=== Recent Errors ===" >> diagnostic-report.txt
for container in postgres supabase-api n8n nginx; do
  echo "--- $container ---" >> diagnostic-report.txt
  docker logs $container --tail 10 2>&1 | grep -i error >> diagnostic-report.txt
done
```

2. **Try Basic Troubleshooting**
   - Run `./jstack.sh --dry-run` to validate configuration
   - Check recent changes to system or configuration
   - Review logs for error patterns
   - Test with known working backup if available

3. **Document the Issue**
   - Exact error messages
   - Steps that led to the problem
   - What was tried to fix it
   - System configuration and environment

**Support Resources**

- **AI Productivity Hub Community**: [https://www.skool.com/ai-productivity-hub/about](https://www.skool.com/ai-productivity-hub/about)
- **GitHub Issues**: Create detailed issue with diagnostic information
- **Documentation**: Review all sections of this guide
- **Community Forums**: Search for similar issues and solutions

**Emergency Recovery**

If the system is completely non-functional:

```bash
# 1. Attempt restoration from recent backup
./jstack.sh --list-backups
./jstack.sh --restore backup_domain_YYYYMMDD_HHMMSS.tar.gz

# 2. If restoration fails, fresh installation:
./jstack.sh --uninstall
# Reconfigure DNS and settings
./jstack.sh

# 3. Document the incident for future prevention
```

---

## Developer Information

### Architecture Documentation

#### System Architecture Overview

The JarvisJR Stack follows a modular, security-first architecture designed for enterprise-grade AI productivity infrastructure:

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Layer                           │
│                  (Let's Encrypt SSL)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              NGINX Reverse Proxy                            │
│          (SSL Termination & Routing)                        │
│     ┌─────────────┬─────────────┬─────────────┐            │
│     │   n8n.*     │  supabase.* │   studio.*  │            │
│     │ port 5678   │  port 8000  │  port 3000  │            │
└─────┴─────────────┴─────────────┴─────────────┴────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Docker Network Layer                         │
│              (jarvis_network)                               │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Public Tier   │ │   Private Tier  │ │   Data Tier     ││
│  │  - NGINX        │ │  - N8N          │ │  - PostgreSQL   ││
│  │  - Supabase API │ │  - Internal CA  │ │  - Volumes      ││
│  │  - Studio       │ │  - Monitoring   │ │  - Backups      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Security Layer                               │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐  │
│  │     UFW     │  fail2ban   │  AppArmor   │   Audit     │  │
│  │  Firewall   │   IDS/IPS   │  Profiles   │  Logging    │  │
│  └─────────────┴─────────────┴─────────────┴─────────────┘  │
└─────────────────────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│               Operating System Layer                        │
│                  (Debian 12)                               │
│    Docker Rootless + Systemd + Service User (jarvis)       │
└─────────────────────────────────────────────────────────────┘
```

#### Modular Script Architecture

**Philosophy**: Single Responsibility Principle
- Main orchestrator (`jstack.sh`) handles only CLI routing
- Business logic resides in specialized modules
- Shared utilities prevent code duplication
- Configuration centralized with override patterns

**Directory Structure**:
```
JarvisJR_Stack/
├── jstack.sh                    # Main CLI orchestrator
├── jstack.config.default        # Default configuration
├── jstack.config               # User customizations (created)
├── scripts/
│   ├── core/                   # Core functionality modules
│   │   ├── setup.sh           # System hardening & prerequisites  
│   │   ├── containers.sh      # Docker container orchestration
│   │   ├── ssl.sh            # Certificate management
│   │   ├── backup.sh         # Backup operations
│   │   └── service_orchestration.sh  # Service coordination
│   ├── lib/                   # Shared libraries
│   │   ├── common.sh         # Utilities, logging, progress
│   │   └── validation.sh     # Input validation functions
│   ├── settings/              # Configuration management
│   │   └── config.sh         # Config loading & validation
│   └── utils/                 # Utility scripts
│       └── cleanup.sh        # System cleanup & uninstall
└── docs/                      # Development documentation
    ├── bash_script_guidelines.md
    ├── testing_standards.md
    └── deployment_process.md
```

#### Data Flow Architecture

**Configuration Flow**:
```
jstack.config.default → config.sh → load_config() → export_config() → Environment Variables → All Scripts
```

**Service Orchestration Flow**:
```
jstack.sh → setup.sh → containers.sh → ssl.sh → service_orchestration.sh → Health Checks
```

**Network Communication Flow**:
```
Internet → NGINX :443 → Docker Network → Service Containers → PostgreSQL :5432
```

**Backup Flow**:
```
Manual/Cron Trigger → backup.sh → Database Dump + Volume Backup → GPG Encryption → Timestamped Archive
```

### API Documentation

#### Container Service APIs

**Supabase API Endpoints** (`https://supabase.your-domain.com`)
```bash
# Health check
GET /health
Response: {"status": "ok", "timestamp": "2025-01-07T12:00:00Z"}

# Database REST API
GET /rest/v1/table_name
POST /rest/v1/table_name
PATCH /rest/v1/table_name?id=eq.1
DELETE /rest/v1/table_name?id=eq.1

# Authentication
POST /auth/v1/signup
POST /auth/v1/token
POST /auth/v1/logout

# Real-time subscriptions
WebSocket: wss://supabase.your-domain.com/realtime/v1/websocket
```

**N8N Workflow API** (`https://n8n.your-domain.com`)
```bash
# Workflow management
GET /api/v1/workflows
POST /api/v1/workflows
GET /api/v1/workflows/{id}
PUT /api/v1/workflows/{id}
DELETE /api/v1/workflows/{id}

# Execution management
POST /api/v1/workflows/{id}/execute
GET /api/v1/executions
GET /api/v1/executions/{id}

# Webhook endpoints
POST /webhook/{workflow-id}
GET /webhook-test/{workflow-id}

# Health and status
GET /healthz
GET /api/v1/active-workflows
```

**Supabase Studio** (`https://studio.your-domain.com`)
```bash
# Database administration interface
GET /                           # Main dashboard
GET /project/{project-id}/editor # SQL Editor
GET /project/{project-id}/auth   # Authentication management
GET /project/{project-id}/storage # File storage management
```

#### Internal Docker APIs

**Container Health Checks**
```bash
# PostgreSQL health
docker exec postgres pg_isready -U postgres

# N8N health  
docker exec n8n curl -f http://localhost:5678/healthz

# NGINX configuration test
docker exec nginx nginx -t

# Supabase API health
docker exec supabase-api curl -f http://localhost:8000/health
```

**Service Discovery**
```bash
# Containers communicate via DNS names:
postgres:5432           # PostgreSQL database
supabase-api:8000      # Supabase REST API
n8n:5678               # N8N workflow engine
nginx:80,443           # NGINX reverse proxy

# Example internal API calls:
curl http://supabase-api:8000/health
curl http://n8n:5678/api/v1/workflows
```

#### External Integration APIs

**Let's Encrypt ACME API**
```bash
# Certificate issuance (automated)
POST https://acme-v02.api.letsencrypt.org/directory

# Certificate renewal (systemd timer)
systemctl --user status ssl-renewal.timer
```

**DNS Validation APIs**
```bash
# DNS challenge validation
TXT _acme-challenge.your-domain.com

# Health verification endpoints
GET https://n8n.your-domain.com/.well-known/acme-challenge/{token}
```

### Contributing Guidelines

#### Development Setup

**Prerequisites**
- Debian 12 development environment
- Docker installed (rootless preferred)
- Git for version control
- Text editor with bash syntax highlighting

**Setup Development Environment**
```bash
# Clone repository
git clone https://github.com/your-org/JarvisJR_Stack.git
cd JarvisJR_Stack

# Create development configuration
cp jstack.config.default jstack.config.dev
nano jstack.config.dev
# Set DEPLOYMENT_ENVIRONMENT="development"
# Set ENABLE_DEBUG_LOGS="true"

# Test development setup
export JSTACK_CONFIG="jstack.config.dev"
./jstack.sh --dry-run
```

**Development Workflow**
```bash
# 1. Create feature branch
git checkout -b feature/new-functionality

# 2. Develop with testing
./jstack.sh --dry-run  # Test configuration changes
bash -n script.sh     # Validate bash syntax

# 3. Test in isolated environment
export JSTACK_CONFIG="jstack.config.test"
./jstack.sh

# 4. Document changes
# Update relevant .md files
# Add comments to complex functions

# 5. Submit pull request
git add .
git commit -m "Add new functionality with tests"
git push origin feature/new-functionality
```

#### Code Standards

**Bash Script Standards**
```bash
#!/bin/bash
set -e  # Exit on any error

# Standard header pattern for all scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "${SCRIPT_DIR}")"))"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/settings/config.sh"

# Load configuration if not in dry-run mode
if [[ "${DRY_RUN:-false}" != "true" ]]; then
    load_config
    export_config
fi

# Function naming: verb_noun format
validate_prerequisites() {
    log_info "Validating system prerequisites"
    # Implementation
}

# Error handling with proper logging
install_component() {
    log_info "Installing component: $1"
    
    if ! command_that_might_fail; then
        log_error "Component installation failed: $1"
        return 1
    fi
    
    log_success "Component installed successfully: $1"
}
```

**Documentation Standards**
```bash
# Function documentation format
#
# Purpose: Brief description of function purpose
# Arguments:
#   $1 - Description of first argument
#   $2 - Description of second argument  
# Returns:
#   0 - Success
#   1 - Failure with specific reason
# Example:
#   install_docker "rootless" "jarvis"
#
install_docker() {
    local mode="$1"
    local user="$2"
    
    # Implementation with clear logging
    log_info "Installing Docker in $mode mode for user $user"
}
```

**Error Handling Patterns**
```bash
# Safe command execution
safe_execute() {
    local cmd="$1"
    local description="$2"
    
    log_info "Executing: $description"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY RUN] Would execute: $cmd"
        return 0
    fi
    
    if eval "$cmd"; then
        log_success "$description completed"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# Resource validation
validate_system_resources() {
    local min_ram_gb=4
    local available_ram_gb
    
    available_ram_gb=$(free -g | awk 'NR==2{print $2}')
    
    if [[ $available_ram_gb -lt $min_ram_gb ]]; then
        log_error "Insufficient RAM: ${available_ram_gb}GB available, ${min_ram_gb}GB required"
        return 1
    fi
    
    log_success "System resources validated"
}
```

#### Testing Guidelines

**Manual Testing Checklist**
```bash
# 1. Syntax validation
bash -n jstack.sh
bash -n scripts/core/*.sh
bash -n scripts/lib/*.sh

# 2. Dry-run testing  
./jstack.sh --dry-run                    # Full dry run
export JSTACK_CONFIG="jstack.config.minimal"
./jstack.sh --dry-run                    # Minimal config test

# 3. Installation testing
# Test on clean Debian 12 system
./jstack.sh                             # Full installation
docker ps --format 'table {{.Names}}	{{.Status}}'  # Verify containers

# 4. Backup/restore testing
./jstack.sh --backup test-backup
./jstack.sh --restore test-backup
# Verify data integrity

# 5. Uninstall testing
./jstack.sh --uninstall
# Verify complete cleanup
```

**Integration Testing**
```bash
# Test service integration
curl -f https://n8n.your-domain.com
curl -f https://supabase.your-domain.com/health
curl -f https://studio.your-domain.com

# Test internal connectivity
docker exec n8n ping postgres
docker exec nginx curl http://supabase-api:8000

# Test SSL certificates
openssl s_client -connect n8n.your-domain.com:443 -servername n8n.your-domain.com
```

**Performance Testing**
```bash
# Resource usage monitoring during installation
./jstack.sh &
INSTALL_PID=$!

while kill -0 $INSTALL_PID 2>/dev/null; do
    docker stats --no-stream --format "table {{.Name}}	{{.CPUPerc}}	{{.MemUsage}}"
    free -h
    sleep 30
done
```

#### Code Review Checklist

**Security Review**
- [ ] No hardcoded credentials or sensitive data
- [ ] Input validation for all user-provided data
- [ ] Proper file permissions and ownership
- [ ] Safe handling of temporary files
- [ ] Secure default configurations

**Functionality Review**
- [ ] Error handling covers edge cases
- [ ] Logging is comprehensive and informative
- [ ] Dry-run mode works correctly
- [ ] Resource cleanup on failure
- [ ] Backward compatibility maintained

**Code Quality Review**
- [ ] Functions have single responsibility
- [ ] Code is well-documented with comments
- [ ] Variable names are descriptive
- [ ] Constants are properly defined
- [ ] Shell quoting is correct

**Testing Review**
- [ ] Bash syntax validation passes
- [ ] Dry-run testing completed
- [ ] Integration testing performed
- [ ] Performance impact assessed
- [ ] Uninstall/cleanup verified

#### Release Process

**Version Management**
```bash
# Semantic versioning: MAJOR.MINOR.PATCH
# MAJOR: Breaking changes
# MINOR: New features, backward compatible
# PATCH: Bug fixes, backward compatible

# Tag releases
git tag -a v1.2.3 -m "Release version 1.2.3: Add browser automation"
git push origin v1.2.3
```

**Release Checklist**
- [ ] All tests pass on clean Debian 12 system
- [ ] Documentation updated with new features
- [ ] Breaking changes documented in changelog
- [ ] Backup/restore compatibility verified
- [ ] Performance regression testing completed
- [ ] Security review completed

**Deployment Process**
```bash
# 1. Create release branch
git checkout -b release/v1.2.3

# 2. Update version references
# Update documentation, config defaults, etc.

# 3. Final testing
./run_all_tests.sh  # When implemented

# 4. Merge to main
git checkout main
git merge release/v1.2.3

# 5. Tag and push
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin main --tags
```

This comprehensive documentation provides everything needed to understand, install, configure, operate, and develop the JarvisJR Stack. The modular architecture ensures maintainability while the security-first design provides enterprise-grade protection for your AI Second Brain infrastructure.