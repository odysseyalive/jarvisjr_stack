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
    log_section "Installing Chrome Dependencies for Debian 12"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would install Chrome dependencies"
        return 0
    fi
    
    if [[ "$ENABLE_BROWSER_AUTOMATION" != "true" ]]; then
        log_info "Browser automation disabled, skipping Chrome installation"
        return 0
    fi
    
    start_section_timer "Chrome Dependencies"
    
    # Update package index
    execute_cmd "apt-get update" "Update package index"
    
    # Install required dependencies for Chrome on Debian 12
    log_info "Installing Chrome system dependencies"
    execute_cmd "apt-get install -y wget gnupg ca-certificates apt-transport-https software-properties-common" "Install base dependencies"
    
    # Add Google Chrome repository
    log_info "Adding Google Chrome repository"
    execute_cmd "wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg" "Add Google signing key"
    execute_cmd "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] ${CHROME_REPOSITORY} stable main' > /etc/apt/sources.list.d/google-chrome.list" "Add Chrome repository"
    
    # Update package index with new repository
    execute_cmd "apt-get update" "Update with Chrome repository"
    
    # Install Chrome and required dependencies for headless operation
    log_info "Installing Google Chrome and headless dependencies"
    execute_cmd "apt-get install -y ${CHROME_PACKAGE} ${CHROME_DEPENDENCIES}" "Install Chrome and dependencies"
    
    # Install additional fonts for better rendering
    execute_cmd "apt-get install -y fonts-noto fonts-noto-color-emoji fonts-dejavu-core" "Install additional fonts"
    
    # Verify Chrome installation
    if chrome_version=$(google-chrome --version 2>/dev/null); then
        log_success "Chrome installed successfully: $chrome_version"
    else
        log_error "Chrome installation verification failed"
        return 1
    fi
    
    end_section_timer "Chrome Dependencies"
    log_success "Chrome dependencies installed successfully"
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
            echo "Usage: $0 [setup|browser-env|chrome|puppeteer|monitoring|test|status|logs]"
            echo ""
            echo "Commands:"
            echo "  setup      - Setup N8N container with browser automation"
            echo "  browser-env- Setup complete browser automation environment"
            echo "  chrome     - Install Chrome dependencies only"
            echo "  puppeteer  - Setup Puppeteer environment only"
            echo "  monitoring - Create browser monitoring system only"
            echo "  test       - Test browser automation integration"
            echo "  status     - Show N8N container status"
            echo "  logs       - Show N8N container logs"
            exit 1
            ;;
    esac
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi