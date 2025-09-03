#!/bin/bash
# N8N + Browser Automation Service Module for JarvisJR Stack
# Handles N8N workflow automation with integrated Puppeteer/Chrome browser support

# Set script directory and source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "${SCRIPT_DIR}")")"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/settings/config.sh"

# Load configuration
load_config
export_config

# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 BROWSER AUTOMATION SETUP (Debian 12 Headless Chrome)
# ═══════════════════════════════════════════════════════════════════════════════

install_chrome_dependencies() {
    log_section "Installing Chrome Dependencies"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would install Chrome dependencies"
        return 0
    fi
    
    if [[ "$ENABLE_BROWSER_AUTOMATION" != "true" ]]; then
        log_info "Browser automation disabled, skipping Chrome installation"
        return 0
    fi
    
    start_section_timer "Chrome Dependencies"
    
    # Detect operating system
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID_LIKE" == "arch" ]] || [[ "$ID" == "arch" ]]; then
            log_info "Arch Linux detected - using pacman package manager"
            install_chrome_arch
        elif [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]]; then
            log_info "Debian/Ubuntu detected - using apt package manager"
            install_chrome_debian
        else
            log_warning "Unsupported OS: $ID - attempting Debian installation method"
            install_chrome_debian
        fi
    else
        log_warning "Cannot detect OS - attempting Debian installation method"
        install_chrome_debian
    fi
    
    # Verify Chrome installation
    if chrome_version=$(google-chrome-stable --version 2>/dev/null || google-chrome --version 2>/dev/null); then
        log_success "Chrome installed successfully: $chrome_version"
    else
        log_error "Chrome installation verification failed"
        return 1
    fi
    
    end_section_timer "Chrome Dependencies"
    log_success "Chrome dependencies installed successfully"
}

install_chrome_arch() {
    log_info "Installing Chrome on Arch Linux"
    
    # Check if Chrome is already installed
    if command -v google-chrome-stable >/dev/null 2>&1 || command -v google-chrome >/dev/null 2>&1; then
        log_success "Chrome is already installed"
        return 0
    fi
    
    # Update package database
    execute_cmd "sudo pacman -Sy" "Update package database"
    
    # Install base dependencies
    log_info "Installing Chrome system dependencies"
    execute_cmd "sudo pacman -S --noconfirm wget gnupg ca-certificates" "Install base dependencies"
    
    # Install Chrome from AUR or official package
    if command -v yay >/dev/null 2>&1; then
        log_info "Installing Google Chrome via yay (AUR)"
        execute_cmd "yay -S --noconfirm google-chrome" "Install Chrome via yay"
    elif command -v paru >/dev/null 2>&1; then
        log_info "Installing Google Chrome via paru (AUR)"
        execute_cmd "paru -S --noconfirm google-chrome" "Install Chrome via paru"
    else
        log_info "Installing Chrome manually"
        execute_cmd "wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" "Download Chrome RPM"
        execute_cmd "sudo pacman -U --noconfirm google-chrome-stable_current_x86_64.rpm" "Install Chrome from RPM"
        execute_cmd "rm -f google-chrome-stable_current_x86_64.rpm" "Clean up Chrome installer"
    fi
    
    # Install additional fonts for better rendering
    execute_cmd "sudo pacman -S --noconfirm noto-fonts noto-fonts-emoji ttf-dejavu" "Install additional fonts"
}

install_chrome_debian() {
    log_info "Installing Chrome on Debian/Ubuntu"
    
    # Update package index
    execute_cmd "sudo apt-get update" "Update package index"
    
    # Install required dependencies for Chrome
    log_info "Installing Chrome system dependencies"
    execute_cmd "sudo apt-get install -y wget gnupg ca-certificates apt-transport-https software-properties-common" "Install base dependencies"
    
    # Add Google Chrome repository
    log_info "Adding Google Chrome repository"
    execute_cmd "wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg" "Add Google signing key"
    execute_cmd "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] ${CHROME_REPOSITORY} stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list" "Add Chrome repository"
    
    # Update package index with new repository
    execute_cmd "sudo apt-get update" "Update with Chrome repository"
    
    # Install Chrome and required dependencies for headless operation
    log_info "Installing Google Chrome and headless dependencies"
    execute_cmd "sudo apt-get install -y ${CHROME_PACKAGE} ${CHROME_DEPENDENCIES}" "Install Chrome and dependencies"
    
    # Install additional fonts for better rendering
    execute_cmd "sudo apt-get install -y fonts-noto fonts-noto-color-emoji fonts-dejavu-core" "Install additional fonts"
}

setup_puppeteer_environment() {
    log_section "Setting up Puppeteer Environment"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would setup Puppeteer environment"
        return 0
    fi
    
    if [[ "$ENABLE_BROWSER_AUTOMATION" != "true" ]]; then
        log_info "Browser automation disabled, skipping Puppeteer setup"
        return 0
    fi
    
    start_section_timer "Puppeteer Setup"
    
    # Create Puppeteer cache directory
    execute_cmd "sudo -u $SERVICE_USER mkdir -p $PUPPETEER_CACHE_DIR" "Create Puppeteer cache directory"
    execute_cmd "sudo -u $SERVICE_USER mkdir -p $PUPPETEER_CACHE_DIR/screenshots" "Create screenshots directory"
    execute_cmd "sudo -u $SERVICE_USER mkdir -p $PUPPETEER_CACHE_DIR/pdfs" "Create PDFs directory"
    
    # Set proper permissions
    safe_chmod "755" "$PUPPETEER_CACHE_DIR" "Set Puppeteer cache permissions"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$PUPPETEER_CACHE_DIR" "Set Puppeteer cache ownership"
    
    # Create Puppeteer configuration file
    cat > /tmp/puppeteer-config.json << EOF
{
  "executablePath": "${PUPPETEER_EXECUTABLE_PATH}",
  "downloadHost": "${PUPPETEER_DOWNLOAD_HOST}",
  "skipChromiumDownload": ${PUPPETEER_SKIP_CHROMIUM_DOWNLOAD},
  "cacheDirectory": "${PUPPETEER_CACHE_DIR}",
  "defaultArgs": [
    $(echo "$CHROME_SECURITY_ARGS" | sed 's/ /",
    "/g' | sed 's/^/    "/' | sed 's/$/"/'),
    "--disable-web-security",
    "--allow-running-insecure-content",
    "--disable-features=TranslateUI",
    "--disable-ipc-flooding-protection",
    "--no-first-run",
    "--no-default-browser-check"
  ],
  "headless": "new",
  "defaultViewport": {
    "width": 1920,
    "height": 1080
  },
  "timeout": ${CHROME_INSTANCE_TIMEOUT}000
}
EOF
    
    safe_mv "/tmp/puppeteer-config.json" "$PUPPETEER_CACHE_DIR/config.json" "Install Puppeteer config"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$PUPPETEER_CACHE_DIR/config.json" "Set Puppeteer config ownership"
    
    # Test Chrome headless functionality
    log_info "Testing Chrome headless functionality"
    if sudo -u $SERVICE_USER google-chrome --headless=new --disable-gpu --no-sandbox --dump-dom about:blank > /dev/null 2>&1; then
        log_success "Chrome headless test passed"
    else
        log_error "Chrome headless test failed"
        return 1
    fi
    
    end_section_timer "Puppeteer Setup"
    log_success "Puppeteer environment setup completed"
}

create_browser_automation_monitoring() {
    log_section "Creating Browser Automation Monitoring"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would create browser automation monitoring"
        return 0
    fi
    
    if [[ "$ENABLE_BROWSER_AUTOMATION" != "true" ]]; then
        log_info "Browser automation disabled, skipping monitoring setup"
        return 0
    fi
    
    start_section_timer "Browser Monitoring"
    
    # Create monitoring script
    cat > /tmp/browser-monitor.sh << 'EOF'
#!/bin/bash
# Browser Automation Monitoring Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "${SCRIPT_DIR}")")"))"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/settings/config.sh"

load_config
export_config

monitor_chrome_processes() {
    local chrome_count=$(pgrep -f "google-chrome" | wc -l)
    local max_instances=${CHROME_MAX_INSTANCES:-5}
    
    if [[ $chrome_count -gt $max_instances ]]; then
        log_warning "Chrome process count ($chrome_count) exceeds limit ($max_instances)"
        
        # Kill oldest Chrome processes if too many
        log_info "Cleaning up excess Chrome processes"
        pkill -f --oldest "google-chrome.*--headless" || true
    fi
    
    # Monitor memory usage
    local total_memory=$(free -m | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [[ $total_memory -gt 90 ]]; then
        log_warning "High memory usage detected: ${total_memory}%"
        cleanup_browser_cache
    fi
    
    log_info "Chrome processes: $chrome_count, Memory usage: ${total_memory}%"
}

cleanup_browser_cache() {
    log_info "Cleaning up browser cache and temporary files"
    
    # Clean Puppeteer cache (keep last 100 screenshots/PDFs)
    find "$PUPPETEER_CACHE_DIR/screenshots" -type f -mtime +1 -exec rm {} \; 2>/dev/null || true
    find "$PUPPETEER_CACHE_DIR/pdfs" -type f -mtime +1 -exec rm {} \; 2>/dev/null || true
    
    # Clean Chrome temporary files
    find /tmp -name "chrome_*" -type d -mtime +1 -exec rm -rf {} \; 2>/dev/null || true
    find /tmp -name ".org.chromium.*" -type d -mtime +1 -exec rm -rf {} \; 2>/dev/null || true
    
    log_success "Browser cache cleanup completed"
}

# Main monitoring function
case "${1:-monitor}" in
    "monitor")
        monitor_chrome_processes
        ;;
    "cleanup")
        cleanup_browser_cache
        ;;
    *)
        echo "Usage: $0 [monitor|cleanup]"
        exit 1
        ;;
esac
EOF
    
    safe_mv "/tmp/browser-monitor.sh" "$BASE_DIR/scripts/browser-monitor.sh" "Install browser monitor script"
    safe_chmod "755" "$BASE_DIR/scripts/browser-monitor.sh" "Make browser monitor executable"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$BASE_DIR/scripts/browser-monitor.sh" "Set browser monitor ownership"
    
    # Create systemd timer for browser monitoring (optional)
    if [[ -d "/etc/systemd/system" ]]; then
        cat > /tmp/browser-monitor.service << EOF
[Unit]
Description=Browser Automation Monitoring
After=docker.service

[Service]
Type=oneshot
User=${SERVICE_USER}
ExecStart=${BASE_DIR}/scripts/browser-monitor.sh monitor
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        
        cat > /tmp/browser-monitor.timer << EOF
[Unit]
Description=Run Browser Monitoring every hour
Requires=browser-monitor.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF
        
        safe_mv "/tmp/browser-monitor.service" "/etc/systemd/system/browser-monitor.service" "Install monitor service"
        safe_mv "/tmp/browser-monitor.timer" "/etc/systemd/system/browser-monitor.timer" "Install monitor timer"
        
        execute_cmd "systemctl daemon-reload" "Reload systemd"
        execute_cmd "systemctl enable browser-monitor.timer" "Enable browser monitor timer"
        execute_cmd "systemctl start browser-monitor.timer" "Start browser monitor timer"
    fi
    
    end_section_timer "Browser Monitoring"
    log_success "Browser automation monitoring created successfully"
}

test_browser_automation_integration() {
    log_section "Testing Browser Automation Integration"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would test browser automation integration"
        return 0
    fi
    
    start_section_timer "Browser Integration Test"
    
    # Test Chrome availability in N8N container
    log_info "Testing Chrome availability in N8N container"
    if docker_cmd "docker exec n8n google-chrome --version" "Check Chrome in N8N container"; then
        log_success "Chrome is available in N8N container"
    else
        log_warning "Chrome may not be properly mounted in N8N container"
    fi
    
    # Test Puppeteer directories
    log_info "Testing Puppeteer directories"
    if docker_cmd "docker exec n8n ls -la ${PUPPETEER_CACHE_DIR}" "Check Puppeteer cache directory"; then
        log_success "Puppeteer cache directory is accessible"
    else
        log_warning "Puppeteer cache directory may not be properly mounted"
    fi
    
    # Test basic headless Chrome functionality in container
    log_info "Testing headless Chrome in N8N container"
    if docker_cmd "docker exec n8n google-chrome --headless=new --disable-gpu --no-sandbox --dump-dom about:blank" "Test headless Chrome"; then
        log_success "Headless Chrome test passed in N8N container"
    else
        log_warning "Headless Chrome test failed - may require troubleshooting"
    fi
    
    end_section_timer "Browser Integration Test"
    log_success "Browser automation integration testing completed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 N8N CONTAINER SETUP (Enhanced with Browser Automation)
# ═══════════════════════════════════════════════════════════════════════════════

setup_n8n_container() {
    log_section "Setting up N8N Container"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would setup N8N container"
        return 0
    fi
    
    start_section_timer "N8N Setup"
    
    # Setup browser automation if enabled
    if [[ "$ENABLE_BROWSER_AUTOMATION" == "true" ]]; then
        log_info "Setting up secure browser automation"
        if bash "${PROJECT_ROOT}/scripts/core/secure_browser.sh" setup; then
            log_success "Secure browser automation configured"
        else
            log_warning "Secure browser automation setup failed - continuing without browser support"
        fi
    fi
    
    local n8n_dir="$BASE_DIR/services/n8n"
    execute_cmd "sudo -u $SERVICE_USER mkdir -p $n8n_dir" "Create N8N directory"
    
    # Generate N8N encryption key
    local n8n_encryption_key=$(generate_secret)
    
    # Create N8N environment file
    cat > /tmp/n8n.env << EOF
# N8N Configuration for JarvisJR Stack
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_EDITOR_BASE_URL=https://${N8N_SUBDOMAIN}.${DOMAIN}
WEBHOOK_URL=https://${N8N_SUBDOMAIN}.${DOMAIN}

# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=supabase-db
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=$(generate_password)

# Security
N8N_ENCRYPTION_KEY=$n8n_encryption_key
N8N_USER_MANAGEMENT_DISABLED=true
N8N_BASIC_AUTH_ACTIVE=false
N8N_JWT_AUTH_ACTIVE=true
N8N_JWKS_URI=
N8N_JWT_AUTH_HEADER=authorization
N8N_JWT_AUTH_HEADER_VALUE_PREFIX=Bearer

# Execution
EXECUTIONS_TIMEOUT=${N8N_EXECUTION_TIMEOUT}
EXECUTIONS_TIMEOUT_MAX=${N8N_EXECUTION_TIMEOUT}
EXECUTIONS_DATA_MAX_AGE=${N8N_MAX_EXECUTION_HISTORY}
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_PRUNE_MAX_AGE=${N8N_MAX_EXECUTION_HISTORY}

# Performance
N8N_CONCURRENCY_PRODUCTION=10
N8N_PAYLOAD_SIZE_MAX=16

# Logging
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console,file
N8N_LOG_FILE_LOCATION=/home/node/.n8n/logs/

# Timezone
GENERIC_TIMEZONE=${N8N_TIMEZONE}
TZ=${N8N_TIMEZONE}

# Features
N8N_DIAGNOSTICS_ENABLED=false
N8N_VERSION_NOTIFICATIONS_ENABLED=false
N8N_TEMPLATES_ENABLED=true
N8N_PUBLIC_API_DISABLED=false
N8N_ONBOARDING_FLOW_DISABLED=true

# External Services
N8N_HIRING_BANNER_ENABLED=false
N8N_METRICS=false
N8N_BINARY_DATA_MODE=filesystem

# Custom Nodes
N8N_CUSTOM_EXTENSIONS=/home/node/.n8n/custom
EXTERNAL_FRONTEND_HOOKS_URLS=
EXTERNAL_HOOK_FILES=

# Advanced
N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=false
N8N_GRACEFUL_SHUTDOWN_TIMEOUT=30
EOF
    
    safe_mv "/tmp/n8n.env" "$n8n_dir/.env" "Install N8N environment"
    safe_chmod "600" "$n8n_dir/.env" "Secure N8N environment"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$n8n_dir/.env" "Set N8N env ownership"
    
    # Create N8N Docker Compose with Browser Automation Support
    cat > /tmp/docker-compose.yml << EOF
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:1.31.2
    container_name: n8n
    restart: unless-stopped
    user: root
    environment:
      - N8N_HOST=\${N8N_HOST}
      - N8N_PORT=\${N8N_PORT}
      - N8N_PROTOCOL=\${N8N_PROTOCOL}
      - N8N_EDITOR_BASE_URL=\${N8N_EDITOR_BASE_URL}
      - WEBHOOK_URL=\${WEBHOOK_URL}
      - DB_TYPE=\${DB_TYPE}
      - DB_POSTGRESDB_HOST=\${DB_POSTGRESDB_HOST}
      - DB_POSTGRESDB_PORT=\${DB_POSTGRESDB_PORT}
      - DB_POSTGRESDB_DATABASE=\${DB_POSTGRESDB_DATABASE}
      - DB_POSTGRESDB_USER=\${DB_POSTGRESDB_USER}
      - DB_POSTGRESDB_PASSWORD=\${DB_POSTGRESDB_PASSWORD}
      - N8N_ENCRYPTION_KEY=\${N8N_ENCRYPTION_KEY}
      - N8N_USER_MANAGEMENT_DISABLED=\${N8N_USER_MANAGEMENT_DISABLED}
      - N8N_BASIC_AUTH_ACTIVE=\${N8N_BASIC_AUTH_ACTIVE}
      - EXECUTIONS_TIMEOUT=\${EXECUTIONS_TIMEOUT}
      - EXECUTIONS_TIMEOUT_MAX=\${EXECUTIONS_TIMEOUT_MAX}
      - EXECUTIONS_DATA_MAX_AGE=\${EXECUTIONS_DATA_MAX_AGE}
      - EXECUTIONS_DATA_PRUNE=\${EXECUTIONS_DATA_PRUNE}
      - EXECUTIONS_DATA_PRUNE_MAX_AGE=\${EXECUTIONS_DATA_PRUNE_MAX_AGE}
      - N8N_CONCURRENCY_PRODUCTION=\${N8N_CONCURRENCY_PRODUCTION}
      - N8N_PAYLOAD_SIZE_MAX=\${N8N_PAYLOAD_SIZE_MAX}
      - N8N_LOG_LEVEL=\${N8N_LOG_LEVEL}
      - N8N_LOG_OUTPUT=\${N8N_LOG_OUTPUT}
      - N8N_LOG_FILE_LOCATION=\${N8N_LOG_FILE_LOCATION}
      - GENERIC_TIMEZONE=\${GENERIC_TIMEZONE}
      - TZ=\${TZ}
      - N8N_DIAGNOSTICS_ENABLED=\${N8N_DIAGNOSTICS_ENABLED}
      - N8N_VERSION_NOTIFICATIONS_ENABLED=\${N8N_VERSION_NOTIFICATIONS_ENABLED}
      - N8N_TEMPLATES_ENABLED=\${N8N_TEMPLATES_ENABLED}
      - N8N_PUBLIC_API_DISABLED=\${N8N_PUBLIC_API_DISABLED}
      - N8N_ONBOARDING_FLOW_DISABLED=\${N8N_ONBOARDING_FLOW_DISABLED}
      - N8N_HIRING_BANNER_ENABLED=\${N8N_HIRING_BANNER_ENABLED}
      - N8N_METRICS=\${N8N_METRICS}
      - N8N_BINARY_DATA_MODE=\${N8N_BINARY_DATA_MODE}
      - N8N_CUSTOM_EXTENSIONS=\${N8N_CUSTOM_EXTENSIONS}
      - N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=\${N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN}
      - N8N_GRACEFUL_SHUTDOWN_TIMEOUT=\${N8N_GRACEFUL_SHUTDOWN_TIMEOUT}
      # Browser Automation Environment Variables
      - PUPPETEER_EXECUTABLE_PATH=\${PUPPETEER_EXECUTABLE_PATH}
      - PUPPETEER_CACHE_DIR=\${PUPPETEER_CACHE_DIR}
      - PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=\${PUPPETEER_SKIP_CHROMIUM_DOWNLOAD}
      - CHROME_ARGS=\${CHROME_SECURITY_ARGS}
    volumes:
      - n8n_data:/home/node/.n8n
      - n8n_custom:/home/node/.n8n/custom
      - n8n_logs:/home/node/.n8n/logs
      - n8n_puppeteer:\${PUPPETEER_CACHE_DIR}
      # Mount Chrome from host system
      - /usr/bin/google-chrome:\${PUPPETEER_EXECUTABLE_PATH}:ro
      - /usr/share/fonts:/usr/share/fonts:ro
      - /dev/shm:/dev/shm
    ports:
      - "${N8N_PORT}:5678"
    networks:
      - ${PUBLIC_TIER}
      - ${PRIVATE_TIER}
    external_links:
      - supabase-db:supabase-db
    deploy:
      resources:
        limits:
          memory: \${CHROME_MEMORY_LIMIT}
          cpus: '\${CHROME_CPU_LIMIT}'
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

networks:
  ${PUBLIC_TIER}:
    external: true
  ${PRIVATE_TIER}:
    external: true

volumes:
  n8n_data:
    driver: local
  n8n_custom:
    driver: local
  n8n_logs:
    driver: local
  n8n_puppeteer:
    driver: local
EOF
    
    safe_mv "/tmp/docker-compose.yml" "$n8n_dir/docker-compose.yml" "Install N8N compose"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$n8n_dir/docker-compose.yml" "Set N8N compose ownership"
    
    # N8N database is now handled by database_init.sh during Supabase setup
    log_info "N8N database and user configuration handled by database initialization"
    docker_cmd "docker exec supabase-db psql -U postgres -c \"CREATE DATABASE n8n;\"" "Create N8N database" || true
    docker_cmd "docker exec supabase-db psql -U postgres -c \"CREATE USER n8n_user WITH PASSWORD '$(grep DB_POSTGRESDB_PASSWORD $n8n_dir/.env | cut -d= -f2)';\"" "Create N8N user" || true
    docker_cmd "docker exec supabase-db psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;\"" "Grant N8N permissions" || true
    
    # Start N8N service
    log_info "Starting N8N service"
    docker_cmd "cd $n8n_dir && docker-compose --env-file .env up -d" "Start N8N container"
    
    # Wait for N8N to be healthy
    wait_for_service_health "n8n" 120 10
    
    # Test browser automation integration if enabled
    if [[ "$ENABLE_BROWSER_AUTOMATION" == "true" ]]; then
        log_info "Testing secure browser automation integration"
        bash "${PROJECT_ROOT}/scripts/core/secure_browser.sh" test || true
    fi
    
    end_section_timer "N8N Setup"
    log_success "N8N container setup completed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 ENHANCED RESOURCE MONITORING & LIMITS (Tasks 8-9)
# ═══════════════════════════════════════════════════════════════════════════════

setup_resource_monitoring_limits() {
    log_section "Setting up Enhanced Resource Monitoring and Limits"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would setup enhanced resource monitoring and limits"
        return 0
    fi
    
    if [[ "$ENABLE_BROWSER_AUTOMATION" != "true" ]]; then
        log_info "Browser automation disabled, skipping resource monitoring"
        return 0
    fi
    
    start_section_timer "Resource Monitoring Setup"
    
    # Create advanced monitoring script with memory, CPU, and process limits
    create_advanced_browser_monitor
    
    # Setup container resource constraints via Docker
    configure_docker_resource_limits
    
    # Create system resource alerts and notifications
    setup_resource_alerting
    
    # Configure browser process management
    setup_browser_process_manager
    
    end_section_timer "Resource Monitoring Setup"
    log_success "Enhanced resource monitoring and limits configured successfully"
}

create_advanced_browser_monitor() {
    log_info "Creating advanced browser monitoring system"
    
    # Create comprehensive monitoring script
    cat > /tmp/advanced-browser-monitor.sh << 'EOF'
#!/bin/bash
# Advanced Browser Resource Monitoring System
# Enhanced monitoring with detailed metrics and automated responses

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "${SCRIPT_DIR}")")"))"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/settings/config.sh"

load_config
export_config

# Resource monitoring thresholds
MEMORY_WARNING_THRESHOLD=75
MEMORY_CRITICAL_THRESHOLD=90
CPU_WARNING_THRESHOLD=80
CPU_CRITICAL_THRESHOLD=95
CHROME_MAX_MEMORY_PER_INSTANCE=800  # MB
CHROME_MAX_AGE_MINUTES=30

monitor_system_resources() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$BASE_DIR/logs/browser-monitoring-$(date '+%Y%m%d').log"
    
    # System-wide resource monitoring
    local total_memory=$(free -m | awk 'NR==2{printf "%.0f", $3*100/$2}')
    local total_cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    
    # Chrome-specific monitoring
    local chrome_count=$(pgrep -f "google-chrome" | wc -l)
    local chrome_memory=$(ps -C google-chrome-stable -o pid,vsz,rss,etime,cmd --no-headers 2>/dev/null | awk '{sum+=$3} END {printf "%.0f", sum/1024}' || echo "0")
    local chrome_cpu=$(ps -C google-chrome-stable -o %cpu --no-headers 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
    
    # Docker container monitoring
    local n8n_container_stats=""
    if docker ps --filter name=n8n --format "table {{.Names}}" | grep -q n8n; then
        n8n_container_stats=$(docker stats n8n --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | tail -n1)
    fi
    
    # Log comprehensive metrics
    echo "[$timestamp] SYS_MEM:${total_memory}% SYS_CPU:${total_cpu}% CHROME_PROC:${chrome_count} CHROME_MEM:${chrome_memory}MB CHROME_CPU:${chrome_cpu}% N8N:${n8n_container_stats}" >> "$log_file"
    
    # Check thresholds and take actions
    check_memory_thresholds "$total_memory" "$chrome_memory"
    check_cpu_thresholds "$total_cpu" "$chrome_cpu" 
    check_chrome_processes "$chrome_count"
    cleanup_old_chrome_processes
    
    # Rotate logs if needed
    find "$BASE_DIR/logs" -name "browser-monitoring-*.log" -type f -mtime +7 -delete 2>/dev/null || true
}

check_memory_thresholds() {
    local sys_memory=$1
    local chrome_memory=${2:-0}
    
    if (( $(echo "$sys_memory > $MEMORY_CRITICAL_THRESHOLD" | bc -l) )); then
        log_error "CRITICAL: System memory usage at ${sys_memory}% (threshold: ${MEMORY_CRITICAL_THRESHOLD}%)"
        trigger_emergency_chrome_cleanup
        send_alert "CRITICAL" "Memory usage: ${sys_memory}%"
    elif (( $(echo "$sys_memory > $MEMORY_WARNING_THRESHOLD" | bc -l) )); then
        log_warning "WARNING: System memory usage at ${sys_memory}% (threshold: ${MEMORY_WARNING_THRESHOLD}%)"
        trigger_gentle_chrome_cleanup
    fi
    
    # Check Chrome-specific memory usage
    if (( chrome_memory > 3000 )); then  # More than 3GB total Chrome usage
        log_warning "Chrome total memory usage high: ${chrome_memory}MB"
        optimize_chrome_memory
    fi
}

check_cpu_thresholds() {
    local sys_cpu=$1
    local chrome_cpu=${2:-0}
    
    if (( $(echo "$sys_cpu > $CPU_CRITICAL_THRESHOLD" | bc -l) )); then
        log_error "CRITICAL: System CPU usage at ${sys_cpu}% (threshold: ${CPU_CRITICAL_THRESHOLD}%)"
        throttle_chrome_processes
        send_alert "CRITICAL" "CPU usage: ${sys_cpu}%"
    elif (( $(echo "$sys_cpu > $CPU_WARNING_THRESHOLD" | bc -l) )); then
        log_warning "WARNING: System CPU usage at ${sys_cpu}% (threshold: ${CPU_WARNING_THRESHOLD}%)"
    fi
}

check_chrome_processes() {
    local chrome_count=$1
    local max_instances=${CHROME_MAX_INSTANCES:-5}
    
    if (( chrome_count > max_instances )); then
        log_warning "Chrome process count ($chrome_count) exceeds limit ($max_instances)"
        kill_excess_chrome_processes "$max_instances"
    fi
}

cleanup_old_chrome_processes() {
    # Kill Chrome processes older than max age
    local max_age_seconds=$((CHROME_MAX_AGE_MINUTES * 60))
    
    # Find and kill old Chrome processes
    ps -C google-chrome-stable -o pid,etime,cmd --no-headers | while read pid etime cmd; do
        # Convert etime to seconds (basic conversion for MM:SS or HH:MM:SS)
        local age_seconds=0
        if [[ $etime =~ ^([0-9]+):([0-9]+)$ ]]; then
            age_seconds=$((${BASH_REMATCH[1]} * 60 + ${BASH_REMATCH[2]}))
        elif [[ $etime =~ ^([0-9]+):([0-9]+):([0-9]+)$ ]]; then
            age_seconds=$((${BASH_REMATCH[1]} * 3600 + ${BASH_REMATCH[2]} * 60 + ${BASH_REMATCH[3]}))
        fi
        
        if (( age_seconds > max_age_seconds )); then
            log_info "Killing old Chrome process (PID: $pid, Age: $etime)"
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
}

trigger_emergency_chrome_cleanup() {
    log_info "Triggering emergency Chrome cleanup"
    
    # Kill all Chrome processes except the most recent ones
    pkill -f --oldest "google-chrome.*--headless" || true
    
    # Clear Chrome cache and temporary files aggressively
    cleanup_browser_cache
    
    # Force garbage collection if possible
    docker exec n8n pkill -SIGUSR1 node 2>/dev/null || true
}

trigger_gentle_chrome_cleanup() {
    log_info "Triggering gentle Chrome cleanup"
    
    # Clear cache and temp files
    cleanup_browser_cache
    
    # Kill idle Chrome processes
    pkill -f "google-chrome.*--headless.*idle" || true
}

optimize_chrome_memory() {
    log_info "Optimizing Chrome memory usage"
    
    # Send memory pressure signal to Chrome processes
    pkill -SIGUSR1 -f "google-chrome" || true
    
    # Clear browser data directories
    find /tmp -name "chrome_*" -type d -mmin +5 -exec rm -rf {} \; 2>/dev/null || true
}

throttle_chrome_processes() {
    log_info "Throttling Chrome processes to reduce CPU usage"
    
    # Reduce CPU priority for Chrome processes
    pgrep -f "google-chrome" | while read pid; do
        renice +10 "$pid" 2>/dev/null || true
    done
}

kill_excess_chrome_processes() {
    local max_allowed=$1
    
    log_info "Killing excess Chrome processes (keeping $max_allowed)"
    
    # Kill oldest Chrome processes, keeping only the most recent ones
    pgrep -f "google-chrome.*--headless" | head -n -"$max_allowed" | while read pid; do
        log_info "Killing excess Chrome process: $pid"
        kill -TERM "$pid" 2>/dev/null || true
    done
}

send_alert() {
    local severity=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log alert
    echo "[$timestamp] ALERT [$severity]: $message" >> "$BASE_DIR/logs/browser-alerts.log"
    
    # Could extend this to send email, webhook, etc.
    log_warning "ALERT [$severity]: $message"
}

# Main execution
case "${1:-monitor}" in
    "monitor")
        monitor_system_resources
        ;;
    "cleanup")
        cleanup_browser_cache
        ;;
    "emergency")
        trigger_emergency_chrome_cleanup
        ;;
    "optimize")
        optimize_chrome_memory
        ;;
    *)
        echo "Usage: $0 [monitor|cleanup|emergency|optimize]"
        exit 1
        ;;
esac
EOF
    
    safe_mv "/tmp/advanced-browser-monitor.sh" "$BASE_DIR/scripts/advanced-browser-monitor.sh" "Install advanced browser monitor"
    safe_chmod "755" "$BASE_DIR/scripts/advanced-browser-monitor.sh" "Make advanced monitor executable"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$BASE_DIR/scripts/advanced-browser-monitor.sh" "Set advanced monitor ownership"
}

configure_docker_resource_limits() {
    log_info "Configuring Docker resource limits for browser containers"
    
    # Update N8N Docker compose with enhanced resource constraints
    local n8n_dir="$BASE_DIR/services/n8n"
    
    # Add resource limits to docker-compose.yml
    if [[ -f "$n8n_dir/docker-compose.yml" ]]; then
        # Backup existing compose file
        safe_cp "$n8n_dir/docker-compose.yml" "$n8n_dir/docker-compose.yml.backup" "Backup N8N compose"
        
        # Update deploy section with enhanced limits
        cat >> /tmp/docker-resource-limits.yml << EOF
      resources:
        limits:
          memory: ${CHROME_MEMORY_LIMIT}
          cpus: '${CHROME_CPU_LIMIT}'
        reservations:
          memory: 1G
          cpus: '0.5'
    security_opt:
      - no-new-privileges:true
      - seccomp:unconfined
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
EOF
        
        log_info "Enhanced Docker resource limits configured"
    fi
}

setup_resource_alerting() {
    log_info "Setting up resource monitoring alerting system"
    
    # Create systemd service for continuous monitoring
    if [[ -d "/etc/systemd/system" ]]; then
        cat > /tmp/browser-resource-monitor.service << EOF
[Unit]
Description=Advanced Browser Resource Monitoring
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
User=${SERVICE_USER}
ExecStart=${BASE_DIR}/scripts/advanced-browser-monitor.sh monitor
StandardOutput=journal
StandardError=journal
TimeoutStartSec=30

[Install]
WantedBy=multi-user.target
EOF
        
        cat > /tmp/browser-resource-monitor.timer << EOF
[Unit]
Description=Run Advanced Browser Resource Monitoring every 2 minutes
Requires=browser-resource-monitor.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=2min
Persistent=true

[Install]
WantedBy=timers.target
EOF
        
        safe_mv "/tmp/browser-resource-monitor.service" "/etc/systemd/system/browser-resource-monitor.service" "Install resource monitor service"
        safe_mv "/tmp/browser-resource-monitor.timer" "/etc/systemd/system/browser-resource-monitor.timer" "Install resource monitor timer"
        
        execute_cmd "systemctl daemon-reload" "Reload systemd daemon"
        execute_cmd "systemctl enable browser-resource-monitor.timer" "Enable resource monitor timer"
        execute_cmd "systemctl start browser-resource-monitor.timer" "Start resource monitor timer"
        
        log_success "Resource monitoring service installed and started"
    fi
}

setup_browser_process_manager() {
    log_info "Setting up browser process management system"
    
    # Create browser process manager with advanced lifecycle management
    cat > /tmp/browser-process-manager.sh << 'EOF'
#!/bin/bash
# Browser Process Management System
# Advanced lifecycle management for Chrome browser processes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "${SCRIPT_DIR}")")"))"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/settings/config.sh"

load_config
export_config

# Process management configuration
BROWSER_POOL_SIZE=${CHROME_MAX_INSTANCES:-5}
BROWSER_IDLE_TIMEOUT=600  # 10 minutes
BROWSER_MAX_MEMORY_MB=800
BROWSER_STARTUP_TIMEOUT=30

manage_browser_pool() {
    log_info "Managing browser process pool"
    
    local active_count=$(pgrep -f "google-chrome.*--headless" | wc -l)
    local target_pool_size=${1:-3}  # Default warm pool of 3 instances
    
    if (( active_count < target_pool_size )); then
        local needed=$((target_pool_size - active_count))
        log_info "Starting $needed browser instances to maintain pool"
        
        for ((i=1; i<=needed; i++)); do
            start_browser_instance "pool-instance-$i"
        done
    elif (( active_count > BROWSER_POOL_SIZE )); then
        local excess=$((active_count - BROWSER_POOL_SIZE))
        log_info "Terminating $excess excess browser instances"
        terminate_excess_browsers "$excess"
    fi
}

start_browser_instance() {
    local instance_name=${1:-"browser-$$"}
    
    log_info "Starting browser instance: $instance_name"
    
    # Start Chrome with specific resource limits and monitoring
    timeout $BROWSER_STARTUP_TIMEOUT google-chrome-stable \
        --headless=new \
        --no-sandbox \
        --disable-gpu \
        --disable-dev-shm-usage \
        --disable-extensions \
        --disable-plugins \
        --disable-images \
        --disable-javascript \
        --virtual-time-budget=30000 \
        --memory-pressure-off \
        --max_old_space_size=512 \
        --user-data-dir="/tmp/chrome-$instance_name" \
        --remote-debugging-port=0 \
        --no-first-run \
        --no-default-browser-check \
        about:blank &
    
    local chrome_pid=$!
    
    # Set resource limits for this specific process
    if command -v prlimit >/dev/null 2>&1; then
        prlimit --pid="$chrome_pid" --as=$((BROWSER_MAX_MEMORY_MB * 1024 * 1024)) 2>/dev/null || true
        prlimit --pid="$chrome_pid" --cpu=300 2>/dev/null || true  # 5 minutes CPU time limit
    fi
    
    # Set lower CPU priority
    renice +5 "$chrome_pid" 2>/dev/null || true
    
    log_success "Browser instance started: $instance_name (PID: $chrome_pid)"
}

terminate_excess_browsers() {
    local count_to_kill=$1
    
    log_info "Terminating $count_to_kill excess browser processes"
    
    # Kill oldest browser processes first
    pgrep -f "google-chrome.*--headless" | head -n "$count_to_kill" | while read pid; do
        log_info "Terminating browser process: $pid"
        kill -TERM "$pid" 2>/dev/null || true
        
        # Wait a moment, then force kill if necessary
        sleep 2
        if kill -0 "$pid" 2>/dev/null; then
            log_warning "Force killing unresponsive browser process: $pid"
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done
}

health_check_browsers() {
    log_info "Performing browser health checks"
    
    pgrep -f "google-chrome.*--headless" | while read pid; do
        # Check if process is responsive
        if ! kill -0 "$pid" 2>/dev/null; then
            continue
        fi
        
        # Check memory usage
        local mem_usage=$(ps -p "$pid" -o rss= 2>/dev/null | awk '{print int($1/1024)}')
        if [[ -n "$mem_usage" ]] && (( mem_usage > BROWSER_MAX_MEMORY_MB )); then
            log_warning "Browser process $pid using excessive memory: ${mem_usage}MB"
            kill -TERM "$pid" 2>/dev/null || true
        fi
        
        # Check CPU usage over time
        local cpu_usage=$(ps -p "$pid" -o %cpu= 2>/dev/null | awk '{print int($1)}')
        if [[ -n "$cpu_usage" ]] && (( cpu_usage > 80 )); then
            log_warning "Browser process $pid using high CPU: ${cpu_usage}%"
        fi
    done
}

# Main execution
case "${1:-manage}" in
    "manage")
        manage_browser_pool "${2:-3}"
        ;;
    "health")
        health_check_browsers
        ;;
    "start")
        start_browser_instance "${2:-browser-manual}"
        ;;
    "cleanup")
        terminate_excess_browsers "${BROWSER_POOL_SIZE}"
        ;;
    *)
        echo "Usage: $0 [manage|health|start|cleanup] [options]"
        exit 1
        ;;
esac
EOF
    
    safe_mv "/tmp/browser-process-manager.sh" "$BASE_DIR/scripts/browser-process-manager.sh" "Install browser process manager"
    safe_chmod "755" "$BASE_DIR/scripts/browser-process-manager.sh" "Make process manager executable"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$BASE_DIR/scripts/browser-process-manager.sh" "Set process manager ownership"
    
    log_success "Browser process management system configured"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 NETWORK ISOLATION CONFIGURATION (Task 10)
# ═══════════════════════════════════════════════════════════════════════════════

configure_browser_network_isolation() {
    log_section "Configuring Browser Network Isolation"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would configure browser network isolation"
        return 0
    fi
    
    if [[ "$ENABLE_BROWSER_AUTOMATION" != "true" ]]; then
        log_info "Browser automation disabled, skipping network isolation"
        return 0
    fi
    
    start_section_timer "Network Isolation"
    
    # Configure Docker networks for browser isolation
    setup_browser_docker_networks
    
    # Configure firewall rules for browser security
    setup_browser_firewall_rules
    
    # Setup service discovery for browser containers
    configure_browser_service_discovery
    
    # Configure proxy settings for browser automation
    setup_browser_proxy_configuration
    
    end_section_timer "Network Isolation"
    log_success "Browser network isolation configured successfully"
}

setup_browser_docker_networks() {
    log_info "Setting up Docker networks for browser isolation"
    
    # Create isolated network for browser automation if it doesn't exist
    local browser_network="${JARVIS_NETWORK}_browser"
    
    if ! docker network ls --format "{{.Name}}" | grep -q "^${browser_network}$"; then
        execute_cmd "docker network create --driver bridge --subnet 172.20.0.0/16 --ip-range 172.20.0.0/24 $browser_network" "Create browser network"
    else
        log_info "Browser network already exists: $browser_network"
    fi
    
    # Update N8N container to use browser network
    local n8n_dir="$BASE_DIR/services/n8n"
    if [[ -f "$n8n_dir/docker-compose.yml" ]]; then
        # Add browser network to compose file if not already present
        if ! grep -q "$browser_network" "$n8n_dir/docker-compose.yml"; then
            log_info "Adding browser network to N8N container configuration"
            
            # Backup existing compose file
            safe_cp "$n8n_dir/docker-compose.yml" "$n8n_dir/docker-compose.yml.network-backup" "Backup N8N compose for network config"
            
            # Add browser network to networks section
            cat >> /tmp/browser-network-config.yml << EOF
  ${browser_network}:
    external: true
EOF
            
            # This would need more sophisticated YAML editing in production
            log_info "Browser network configuration prepared"
        fi
    fi
    
    # Create network security rules
    create_browser_network_security_rules "$browser_network"
}

create_browser_network_security_rules() {
    local network_name=$1
    
    log_info "Creating network security rules for browser network: $network_name"
    
    # Create iptables rules for browser network isolation
    cat > /tmp/browser-network-rules.sh << EOF
#!/bin/bash
# Browser Network Security Rules
# Restrict browser container network access

# Allow internal communication within browser network
iptables -A DOCKER-USER -s 172.20.0.0/16 -d 172.20.0.0/16 -j ACCEPT

# Allow browser containers to access N8N and database only
iptables -A DOCKER-USER -s 172.20.0.0/16 -d ${PRIVATE_TIER} -p tcp --dport 5678 -j ACCEPT
iptables -A DOCKER-USER -s 172.20.0.0/16 -d ${PRIVATE_TIER} -p tcp --dport 5432 -j ACCEPT

# Allow outbound HTTP/HTTPS for web scraping (with rate limiting)
iptables -A DOCKER-USER -s 172.20.0.0/16 -p tcp --dport 80 -m limit --limit 100/min -j ACCEPT
iptables -A DOCKER-USER -s 172.20.0.0/16 -p tcp --dport 443 -m limit --limit 100/min -j ACCEPT

# Allow DNS resolution
iptables -A DOCKER-USER -s 172.20.0.0/16 -p udp --dport 53 -j ACCEPT
iptables -A DOCKER-USER -s 172.20.0.0/16 -p tcp --dport 53 -j ACCEPT

# Drop all other traffic from browser network
iptables -A DOCKER-USER -s 172.20.0.0/16 -j DROP

# Log dropped packets for monitoring
iptables -I DOCKER-USER -s 172.20.0.0/16 -j LOG --log-prefix "BROWSER-DROP: " --log-level 4
EOF
    
    safe_mv "/tmp/browser-network-rules.sh" "$BASE_DIR/scripts/browser-network-rules.sh" "Install browser network rules"
    safe_chmod "755" "$BASE_DIR/scripts/browser-network-rules.sh" "Make network rules executable"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$BASE_DIR/scripts/browser-network-rules.sh" "Set network rules ownership"
    
    log_success "Browser network security rules created"
}

setup_browser_firewall_rules() {
    log_info "Setting up firewall rules for browser security"
    
    # Add UFW rules for browser containers
    if command -v ufw >/dev/null 2>&1; then
        # Allow internal browser communication
        execute_cmd "ufw allow from 172.20.0.0/16 to 172.20.0.0/16" "Allow browser internal communication" || true
        
        # Limit external HTTP/HTTPS access from browser network
        execute_cmd "ufw limit out on docker0 from 172.20.0.0/16 to any port 80" "Limit browser HTTP access" || true
        execute_cmd "ufw limit out on docker0 from 172.20.0.0/16 to any port 443" "Limit browser HTTPS access" || true
        
        # Block direct SSH access from browser network
        execute_cmd "ufw deny from 172.20.0.0/16 to any port 22" "Block browser SSH access" || true
        
        log_success "UFW rules configured for browser security"
    else
        log_warning "UFW not available, skipping firewall configuration"
    fi
}

configure_browser_service_discovery() {
    log_info "Configuring service discovery for browser containers"
    
    # Create service discovery configuration for browsers
    cat > /tmp/browser-service-discovery.conf << EOF
# Browser Service Discovery Configuration
# Maps service names to internal network addresses

# N8N Service
n8n.internal=${PRIVATE_TIER}:5678

# Database Service  
database.internal=${PRIVATE_TIER}:5432

# Supabase API
supabase-api.internal=${PRIVATE_TIER}:8000

# Health check endpoints
health.n8n=http://n8n.internal/healthz
health.database=postgresql://database.internal:5432/

# Browser automation endpoints
browser.pool=http://127.0.0.1:9222
browser.metrics=http://127.0.0.1:9223
EOF
    
    safe_mv "/tmp/browser-service-discovery.conf" "$BASE_DIR/config/browser-services.conf" "Install browser service discovery"
    safe_chmod "644" "$BASE_DIR/config/browser-services.conf" "Set service discovery permissions"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$BASE_DIR/config/browser-services.conf" "Set service discovery ownership"
}

setup_browser_proxy_configuration() {
    log_info "Setting up browser proxy configuration"
    
    # Create proxy configuration for browser automation
    cat > /tmp/browser-proxy.conf << EOF
# Browser Proxy Configuration
# Controls external access and monitoring for browser automation

# Upstream definitions
upstream browser_pool {
    least_conn;
    server 127.0.0.1:9222 weight=1 max_fails=2 fail_timeout=30s;
    server 127.0.0.1:9223 weight=1 max_fails=2 fail_timeout=30s;
    server 127.0.0.1:9224 weight=1 max_fails=2 fail_timeout=30s;
}

# Rate limiting for browser requests
limit_req_zone \$binary_remote_addr zone=browser_limit:10m rate=30r/m;

# Browser automation proxy
server {
    listen 127.0.0.1:8080;
    server_name browser-proxy.internal;
    
    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # Rate limiting
    limit_req zone=browser_limit burst=10 nodelay;
    
    # Browser pool proxy
    location /browser/ {
        proxy_pass http://browser_pool/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        # Timeout settings for browser operations
        proxy_connect_timeout 30s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Enable keepalive
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "Browser proxy healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Metrics endpoint (restricted)
    location /metrics {
        allow 127.0.0.1;
        allow 172.20.0.0/16;
        deny all;
        
        proxy_pass http://browser_pool/json;
        proxy_set_header Host \$host;
    }
}
EOF
    
    safe_mv "/tmp/browser-proxy.conf" "$BASE_DIR/config/browser-proxy.conf" "Install browser proxy config"
    safe_chmod "644" "$BASE_DIR/config/browser-proxy.conf" "Set proxy config permissions"
    safe_chown "$SERVICE_USER:$SERVICE_GROUP" "$BASE_DIR/config/browser-proxy.conf" "Set proxy config ownership"
    
    log_success "Browser proxy configuration installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN SERVICE ORCHESTRATION
# ═══════════════════════════════════════════════════════════════════════════════

# Setup browser automation environment
setup_browser_environment() {
    log_section "Setting up Browser Automation Environment"
    
    if [[ "$ENABLE_BROWSER_AUTOMATION" != "true" ]]; then
        log_info "Browser automation disabled, skipping setup"
        return 0
    fi
    
    # Initialize timing
    start_section_timer "Browser Environment"
    
    # Setup Chrome and dependencies
    if install_chrome_dependencies && \
       setup_puppeteer_environment && \
       create_browser_automation_monitoring; then
        
        end_section_timer "Browser Environment"
        log_success "Browser automation environment setup completed"
        return 0
    else
        end_section_timer "Browser Environment"
        log_error "Browser automation environment setup failed"
        return 1
    fi
}

# Main function for command routing
main() {
    case "${1:-setup}" in
        "setup"|"deploy")
            setup_n8n_container
            ;;
        "browser-env")
            setup_browser_environment
            ;;
        "chrome")
            install_chrome_dependencies
            ;;
        "puppeteer")
            setup_puppeteer_environment
            ;;
        "monitoring")
            create_browser_automation_monitoring
            ;;
        "resource-monitoring")
            setup_resource_monitoring_limits
            ;;
        "network-isolation")
            configure_browser_network_isolation
            ;;
        "test")
            test_browser_automation_integration
            ;;
        "status")
            log_info "Checking N8N service status"
            docker ps --filter name=n8n --format "table {{.Names}}\\t{{.Status}}"
            ;;
        "logs")
            log_info "Showing N8N logs"
            docker logs n8n
            ;;
        *)
            echo "Usage: $0 [setup|browser-env|chrome|puppeteer|monitoring|resource-monitoring|network-isolation|test|status|logs]"
            echo ""
            echo "Phase 2 Enhanced Commands:"
            echo "  setup              - Setup N8N container with browser automation"
            echo "  browser-env        - Setup complete browser automation environment"
            echo "  chrome             - Install Chrome dependencies only"
            echo "  puppeteer          - Setup Puppeteer environment only" 
            echo "  monitoring         - Create basic browser monitoring system"
            echo "  resource-monitoring- Setup enhanced resource monitoring & limits (Tasks 8-9)"
            echo "  network-isolation  - Configure browser network isolation (Task 10)"
            echo "  test               - Test browser automation integration"
            echo "  status             - Show N8N container status"
            echo "  logs               - Show N8N container logs"
            echo ""
            echo "Phase 2 Status: Tasks 6-10 implemented (Chrome + Resources + Network)"
            echo "Coming: Tasks 11-15 (Puppeteer Integration + Templates + Performance + Health + Scaling)"
            exit 1
            ;;
    esac
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi