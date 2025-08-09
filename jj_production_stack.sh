#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# PRODUCTION-READY CONTAINERIZED SUPABASE + N8N + NGINX STACK
# Enhanced with AppArmor, Advanced Backup, and Rolling Updates
# Optimized for Debian 12 Production Environments (No Monitoring Stack)
# Resource Allocations Updated January 2025 Based on Latest Service Requirements
# ═══════════════════════════════════════════════════════════════════════════════

set -e # Exit on any error

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 USER CONFIGURATION SECTION - REQUIRED: MODIFY THESE VALUES BEFORE RUNNING
# ═══════════════════════════════════════════════════════════════════════════════
#
# IMPORTANT: This script will NOT run with default values. You must configure
# at minimum the DOMAIN variable below with your actual domain name.
#
# Usage: bash jstack.sh --help
#

# DOMAIN CONFIGURATION - REQUIRED: CHANGE THESE VALUES
DOMAIN="example.com"             # ⚠️  REQUIRED: Change to your actual domain
EMAIL="admin@${DOMAIN}"          # Email for Let's Encrypt and notifications
COUNTRY_CODE="US"                # Country code for SSL certificates
STATE_NAME="California"          # State for SSL certificates
CITY_NAME="San Francisco"        # City for SSL certificates
ORGANIZATION="Your Organization" # Organization name for certificates

# SUBDOMAIN CONFIGURATION - Customize service subdomains
# These create the URLs where your services will be accessible:
# - Supabase API: https://SUPABASE_SUBDOMAIN.DOMAIN
# - Supabase Studio: https://STUDIO_SUBDOMAIN.DOMAIN
# - N8N Workflows: https://N8N_SUBDOMAIN.DOMAIN
SUPABASE_SUBDOMAIN="supabase" # Subdomain for Supabase API (e.g., supabase.yourdomain.com)
STUDIO_SUBDOMAIN="studio"     # Subdomain for Supabase Studio (e.g., studio.yourdomain.com)
N8N_SUBDOMAIN="n8n"           # Subdomain for N8N workflows (e.g., n8n.yourdomain.com)

# ENVIRONMENT CONFIGURATION
# Set deployment environment: development, staging, or production
DEPLOYMENT_ENVIRONMENT="${DEPLOYMENT_ENVIRONMENT:-production}" # Can be overridden with env var
ENABLE_INTERNAL_SSL="${ENABLE_INTERNAL_SSL:-true}"             # Enable internal SSL in production
ENABLE_DEVELOPMENT_MODE="${ENABLE_DEVELOPMENT_MODE:-false}"    # Enable development-friendly settings

# SERVICE USER CONFIGURATION
SERVICE_USER="jarvis"     # User that will run all services
SERVICE_GROUP="jarvis"    # Group for the service user
SERVICE_SHELL="/bin/bash" # Shell for service user

# DIRECTORY CONFIGURATION
BASE_DIR="/home/${SERVICE_USER}/jarvis-stack" # Base directory for all services
BACKUP_RETENTION_DAYS="1"                     # How many days to keep backups (1 backup)
LOG_RETENTION_DAYS="14"                       # How many days to keep logs
CONFIG_BACKUP_RETENTION="1"                   # Config backup retention (days)

# NETWORK CONFIGURATION
JARVIS_NETWORK="jarvis_network" # Main JarvisJR stack network - all application services
PUBLIC_TIER="public_tier"       # Internet-facing services (NGINX)
PRIVATE_TIER="private_tier"     # Internal services (Database, management)

# SERVICE PORTS (Internal Docker networking)
SUPABASE_API_PORT="8000"
SUPABASE_STUDIO_PORT="3000"
N8N_PORT="5678"
NEXTJS_PORT="3001"
POSTGRES_PORT="5432"

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 OPTIMIZED CONTAINER RESOURCE LIMITS - Updated January 2025
# Based on Latest Service Requirements and Production Testing
# ═══════════════════════════════════════════════════════════════════════════════

# PostgreSQL/Supabase Database - HIGHEST PRIORITY
# Research shows base Supabase usage ~500MB, scales linearly with memory
# Database performance is memory-dependent for query caching and buffers
POSTGRES_MEMORY_LIMIT="4G"            # Increased from 2G - Critical for performance
POSTGRES_CPU_LIMIT="2.0"              # Increased from 1.0 - Database queries are CPU-intensive
POSTGRES_SHARED_BUFFERS="1GB"         # Increased from 256MB - 25% of allocated memory
POSTGRES_EFFECTIVE_CACHE_SIZE="3GB"   # 75% of allocated memory for query planning
POSTGRES_WORK_MEM="32MB"              # Increased for better sort/hash operations
POSTGRES_MAINTENANCE_WORK_MEM="256MB" # For index creation and maintenance
POSTGRES_MAX_CONNECTIONS="200"        # Increased from 100 - Better for concurrent users

# N8N Workflow Automation - Memory scales with workflow complexity
# Research shows ~100MB idle, but complex workflows and Code nodes need much more
N8N_MEMORY_LIMIT="2G"          # Increased from 1G - Modern N8N workflows are memory-hungry
N8N_CPU_LIMIT="1.0"            # N8N is not CPU-intensive, focus resources on memory
N8N_EXECUTION_TIMEOUT="7200"   # Increased from 3600 - Allow longer-running workflows
N8N_MAX_EXECUTION_HISTORY="50" # Reduced from 100 - Save memory on execution history

# NGINX Reverse Proxy - Extremely efficient
# Research shows 1-10MB typical usage, can handle 10K+ connections efficiently
NGINX_MEMORY_LIMIT="256M"       # Reduced from 512M - NGINX is incredibly memory-efficient
NGINX_CPU_LIMIT="0.5"           # NGINX handles massive loads with minimal CPU
NGINX_WORKER_PROCESSES="auto"   # Auto-detect CPU cores
NGINX_WORKER_CONNECTIONS="2048" # Increased from 1024 - Handle more concurrent connections

# Monitoring stack removed to reduce resource usage and complexity

# ═══════════════════════════════════════════════════════════════════════════════
# 📈 RESOURCE ALLOCATION GUIDELINES BY SERVER SIZE
# ═══════════════════════════════════════════════════════════════════════════════
#
# 4 CPU / 8GB RAM Server (Minimal Production):
#   Total Container Memory Usage: ~5.6GB (70% utilization)
#   Reduce: POSTGRES_MEMORY_LIMIT="2G", N8N_MEMORY_LIMIT="1.5G",
# Monitoring removed - resource allocations simplified
#
# 4 CPU / 16GB RAM Server (Recommended - Current Settings):
#   Total Container Memory Usage: ~9.1GB (57% utilization - optimal)
#   Use settings above - excellent performance with safety margin
#
# 8 CPU / 32GB RAM Server (High Performance):
#   Increase: POSTGRES_MEMORY_LIMIT="8G", N8N_MEMORY_LIMIT="4G",
# Monitoring removed - enterprise monitoring not included
#
# ═══════════════════════════════════════════════════════════════════════════════

# CONTAINER SECURITY CONFIGURATION
APPARMOR_ENABLED="true"          # Enable AppArmor profiles for containers
CONTAINER_USER_NAMESPACES="true" # Enable user namespaces
CONTAINER_NO_NEW_PRIVS="true"    # Disable privilege escalation
CONTAINER_READ_ONLY_ROOT="false" # Read-only root filesystem (careful!)
FAIL2BAN_ENABLED="true"          # Enable fail2ban intrusion prevention
UFW_ENABLED="true"               # Enable UFW firewall

# BACKUP CONFIGURATION
BACKUP_SCHEDULE="0 2 * * 0"   # Weekly on Sunday at 2 AM
BACKUP_S3_BUCKET=""           # S3 bucket for offsite backups (optional)
BACKUP_ENCRYPTION="true"      # Encrypt backups
BACKUP_COMPRESSION_LEVEL="6"  # Compression level (1-9)
DATABASE_BACKUP_RETENTION="1" # Database backup retention (days)
VOLUME_BACKUP_RETENTION="1"   # Volume backup retention (days)

# ALERTING CONFIGURATION
ENABLE_ALERTING="true"         # Enable email/slack alerts
ALERT_EMAIL="alerts@${DOMAIN}" # Email for alerts
SLACK_WEBHOOK=""               # Slack webhook URL (optional)

UPDATE_ROLLBACK_ON_FAILURE="true" # Auto-rollback on failed updates
PRE_UPDATE_BACKUP="true"          # Create backup before updates
IMAGE_CLEANUP_RETENTION="5"       # Keep last 5 image versions

# N8N CONFIGURATION
N8N_DEFAULT_USER="admin"           # Default N8N username
N8N_TIMEZONE="America/Los_Angeles" # N8N timezone
N8N_WEBHOOK_TUNNEL_URL=""          # Webhook tunnel URL (optional)

# SUPABASE CONFIGURATION
SUPABASE_DB_NAME="postgres"                # Default database name
SUPABASE_AUTH_SITE_URL="https://${DOMAIN}" # Auth redirect URL

# NGINX CONFIGURATION - Optimized for performance
NGINX_CLIENT_MAX_BODY_SIZE="100M"  # Max upload size
NGINX_RATE_LIMIT_API="10r/s"       # API rate limit
NGINX_RATE_LIMIT_GENERAL="30r/s"   # General rate limit
NGINX_RATE_LIMIT_WEBHOOKS="100r/s" # Webhook rate limit
NGINX_KEEPALIVE_TIMEOUT="65"       # Keep-alive timeout
NGINX_GZIP_COMPRESSION="6"         # Gzip compression level

# LOGGING CONFIGURATION
CONTAINER_LOG_MAX_SIZE="10m" # Max log file size per container
CONTAINER_LOG_MAX_FILES="5"  # Max log files per container
AUDIT_LOGGING="true"         # Enable audit logging

# DEVELOPMENT/TESTING FLAGS
ENABLE_DEBUG_LOGS="false" # Enable debug logging
DRY_RUN="false"           # Show what would be done without executing

# ═══════════════════════════════════════════════════════════════════════════════
# ⚠️ PERFORMANCE OPTIMIZATION NOTES
# ═══════════════════════════════════════════════════════════════════════════════
#
# Key Changes Made Based on 2024/2025 Research:
# 1. PostgreSQL memory doubled (2G→4G) - Most critical for performance
# 2. N8N memory doubled (1G→2G) - Modern workflows need more memory
# 3. NGINX memory halved (512M→256M) - Research shows it's extremely efficient
# 4. Added PostgreSQL tuning parameters - Critical for database performance
# 5. Increased connection limits and timeouts for better user experience
# 6. Optimized retention periods for better storage usage
#
# Always monitor actual usage and adjust based on your specific workload!
#
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# 🛠️ SYSTEM CONFIGURATION REVIEW
# ═══════════════════════════════════════════════════════════════════════════════
#
# Ensure system binaries are accessible - many admin tools are in /usr/sbin, /sbin
# which may not be in regular user's PATH. This prevents "command not found" errors
# for tools like ufw, iptables, systemctl, etc.
#

# Add system binary directories to PATH if not already present
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/bin:$PATH"

# Remove duplicate entries from PATH (clean up)
export PATH=$(echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')

# Verify critical system commands are now accessible
# Note: This early verification helps catch PATH issues before they cause failures
SYSTEM_COMMANDS_CHECK=("systemctl" "ufw" "iptables" "mount" "chmod" "chown")
MISSING_COMMANDS=()

for cmd in "${SYSTEM_COMMANDS_CHECK[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    MISSING_COMMANDS+=("$cmd")
  fi
done

# Warn about missing commands but don't exit (let prerequisite check handle it)
if [ ${#MISSING_COMMANDS[@]} -gt 0 ]; then
  echo "⚠️  Warning: Some system commands not found in PATH: ${MISSING_COMMANDS[*]}"
  echo "   This may indicate missing packages or PATH configuration issues."
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 📝 ENHANCED LOGGING SETUP
# ═══════════════════════════════════════════════════════════════════════════════

# Create log directory and setup comprehensive logging
setup_logging() {
  # Create timestamp for this run
  SCRIPT_START_TIME=$(date '+%Y%m%d_%H%M%S')
  export SCRIPT_START_EPOCH=$(date +%s)

  # Try to create log directory, fallback to /tmp if BASE_DIR doesn't exist yet
  if [ -d "$(dirname "$BASE_DIR")" ]; then
    LOG_DIR="$BASE_DIR/logs"
    mkdir -p "$LOG_DIR" 2>/dev/null || {
      LOG_DIR="/tmp/setup-logs"
      mkdir -p "$LOG_DIR"
    }
  else
    LOG_DIR="/tmp/setup-logs"
    mkdir -p "$LOG_DIR"
  fi

  # Create timestamped log file
  export SETUP_LOG_FILE="$LOG_DIR/setup_${SCRIPT_START_TIME}.log"

  # Clean up old log files (keep last 10)
  find "$LOG_DIR" -name "setup_*.log" -type f | sort | head -n -10 | xargs rm -f 2>/dev/null || true

  # Add session start marker
  cat >>"$SETUP_LOG_FILE" <<EOF
================================================================================
SETUP SESSION START: $(date)
DOMAIN: $DOMAIN
SERVICE_USER: $SERVICE_USER  
BASE_DIR: $BASE_DIR
PID: $$
================================================================================

EOF

  # Set up comprehensive logging - redirect all output to both console and log file
  exec > >(tee -a "$SETUP_LOG_FILE")
  exec 2>&1

  echo "📝 Logging enabled: $SETUP_LOG_FILE"
}

# Call logging setup immediately
setup_logging

# Set up comprehensive error trapping for logging failures and interrupts
trap 'log_failure_exit $?' ERR
trap 'log_interrupted_exit' INT TERM

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR CODES AND HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Enhanced logging functions with timestamps (now works with exec redirection)
log_info() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${RED}[ERROR]${NC} $1"
}

log_section() {
  echo -e "\n${PURPLE}═══════════════════════════════════════${NC}"
  echo -e "${PURPLE} $1${NC}"
  echo -e "${PURPLE}═══════════════════════════════════════${NC}\n"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 SYSTEM TIMEZONE CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

setup_system_timezone() {
  log_section "Configuring System Timezone"

  # Validate timezone format
  if [ -z "$N8N_TIMEZONE" ]; then
    log_info "Using America/Los_Angeles timezone (default)"
    local target_timezone="America/Los_Angeles"
  else
    local target_timezone="$N8N_TIMEZONE"
    log_info "Setting system timezone to: $target_timezone"
  fi

  # Check if timezone is valid
  if [ ! -f "/usr/share/zoneinfo/$target_timezone" ]; then
    log_error "Invalid timezone: $target_timezone"
    log_info "Available timezones: timedatectl list-timezones"
    log_warning "Falling back to UTC"
    target_timezone="UTC"
  fi

  # Get current timezone
  local current_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Unknown")

  if [ "$current_timezone" = "$target_timezone" ]; then
    log_success "System timezone already set to: $target_timezone"
  else
    log_info "Changing system timezone from '$current_timezone' to '$target_timezone'"

    # Set system timezone
    execute_cmd "sudo timedatectl set-timezone $target_timezone" "Set system timezone"

    # Verify the change
    local new_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null)
    if [ "$new_timezone" = "$target_timezone" ]; then
      log_success "System timezone successfully changed to: $target_timezone"
    else
      log_error "Failed to set system timezone to: $target_timezone"
      return 1
    fi
  fi

  # Show current time information
  log_info "Current system time: $(date)"
  log_info "Current UTC time: $(date -u)"

  # Configure NTP synchronization for accurate time
  if command -v timedatectl >/dev/null 2>&1; then
    execute_cmd "sudo timedatectl set-ntp true" "Enable NTP synchronization"
    log_info "NTP synchronization enabled for accurate timekeeping"
  fi

  # Update timezone for current session
  export TZ="$target_timezone"

  # Ensure timezone is set in service user's environment
  if [ "$SERVICE_USER" != "root" ] && id "$SERVICE_USER" >/dev/null 2>&1; then
    execute_cmd "sudo -u $SERVICE_USER bash -c 'echo \"export TZ=$target_timezone\" >> ~/.bashrc'" "Set timezone for service user"
  fi

  log_success "System timezone configuration completed"
}

# Function to add error session end marker for failures
log_failure_exit() {
  local exit_code=$1
  local runtime=$(($(date +%s) - ${SCRIPT_START_EPOCH:-$(date +%s)}))
  cat >>"$SETUP_LOG_FILE" <<EOF

================================================================================
SETUP SESSION END: $(date)
STATUS: FAILED (Exit Code: $exit_code)
RUNTIME: ${runtime} seconds
================================================================================
EOF
  echo ""
  echo -e "${RED}❌ Setup failed! Check the complete log: ${WHITE}$SETUP_LOG_FILE${NC}"
  exit $exit_code
}

# Function to handle graceful interruption (Ctrl+C, SIGTERM)
log_interrupted_exit() {
  echo ""
  log_warning "Setup interrupted by user or system signal"
  local runtime=$(($(date +%s) - ${SCRIPT_START_EPOCH:-$(date +%s)}))
  cat >>"$SETUP_LOG_FILE" <<EOF

================================================================================
SETUP SESSION END: $(date)
STATUS: INTERRUPTED (Manual stop or system signal)
RUNTIME: ${runtime} seconds
================================================================================
EOF
  echo ""
  echo -e "${YELLOW}⚠️  Setup interrupted! Progress saved to: ${WHITE}$SETUP_LOG_FILE${NC}"
  echo -e "${CYAN}💡 To resume setup, run the script again${NC}"
  exit 130
}

# Function to mark successful completion
log_success_exit() {
  local runtime=$(($(date +%s) - ${SCRIPT_START_EPOCH:-$(date +%s)}))
  cat >>"$SETUP_LOG_FILE" <<EOF

================================================================================
SETUP SESSION END: $(date)
STATUS: SUCCESS (All operations completed successfully)
RUNTIME: ${runtime} seconds
================================================================================
EOF
  echo ""
  echo -e "${GREEN}✅ Setup completed successfully! Full log saved to: ${WHITE}$SETUP_LOG_FILE${NC}"
}

# Progress monitoring functions
PROGRESS_PID=""

# Show animated progress dots for long operations
show_progress_dots() {
  local message="${1:-Processing}"
  local delay=0.5
  while true; do
    printf "\r%s   " "$message"
    sleep $delay
    printf "\r%s.  " "$message"
    sleep $delay
    printf "\r%s.. " "$message"
    sleep $delay
    printf "\r%s..." "$message"
    sleep $delay
  done
}

# Start progress indicator for long operations
start_progress() {
  local message="${1:-Processing}"
  show_progress_dots "$message" &
  PROGRESS_PID=$!
  echo -n "$message"
}

# Stop progress indicator
stop_progress() {
  if [ -n "$PROGRESS_PID" ]; then
    kill $PROGRESS_PID 2>/dev/null
    wait $PROGRESS_PID 2>/dev/null || true
    PROGRESS_PID=""
    printf "\r%s" "$(printf '%*s' 80 '')"
    printf "\r"
  fi
}

# Enhanced progress tracking with checkpoints
CHECKPOINT_FILE=""
TOTAL_STEPS=12
CURRENT_STEP=0

# Initialize checkpoint system
init_checkpoints() {
  CHECKPOINT_FILE="$SETUP_LOG_FILE.checkpoint"
  if [ -f "$CHECKPOINT_FILE" ]; then
    CURRENT_STEP=$(tail -n 1 "$CHECKPOINT_FILE" 2>/dev/null | cut -d':' -f2 | tr -d ' ' || echo "0")
    log_info "Resuming from step $CURRENT_STEP of $TOTAL_STEPS"
  else
    CURRENT_STEP=0
    log_info "Starting fresh installation (estimated 15-20 minutes)"
  fi

  # Show initial progress
  show_progress_bar $CURRENT_STEP $TOTAL_STEPS
}

# Save checkpoint for resume capability
save_checkpoint() {
  local step_name="$1"
  local step_number="$2"
  CURRENT_STEP=$step_number

  echo "CHECKPOINT:$step_number:$step_name:$(date +%s)" >>"$CHECKPOINT_FILE"
  show_progress_bar $CURRENT_STEP $TOTAL_STEPS
  log_info "Checkpoint saved: $step_name (step $step_number/$TOTAL_STEPS)"
}

# Check if we should skip a step (resume capability)
should_skip_step() {
  local step_number="$1"
  # Handle non-numeric step identifiers by always running them
  if ! [[ "$step_number" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    return 1 # Don't skip non-numeric steps
  fi
  # Use awk for floating point comparison
  awk -v step="$step_number" -v current="$CURRENT_STEP" 'BEGIN { exit !(step <= current) }'
}

# Display progress bar
show_progress_bar() {
  local current=$1
  local total=$2
  local width=50

  # Handle floating point numbers by converting to integers for display
  local current_int=$(echo "$current" | cut -d. -f1)
  local percentage=$(awk -v c="$current" -v t="$total" 'BEGIN { printf "%.0f", c * 100 / t }')
  local filled=$(awk -v c="$current" -v t="$total" -v w="$width" 'BEGIN { printf "%.0f", c * w / t }')
  local empty=$((width - filled))

  printf "\r${CYAN}Progress: [%s%s] %d%% (%.1f/%d)${NC}" \
    "$(printf '%*s' $filled '' | tr ' ' '█')" \
    "$(printf '%*s' $empty '' | tr ' ' '░')" \
    $percentage $current $total
  echo
}

# Performance timing functions - using simple approach for maximum compatibility
SECTION_TIMERS_FILE=""

# Initialize timing system
init_timing_system() {
  SECTION_TIMERS_FILE="$SETUP_LOG_FILE.timers"
  >"$SECTION_TIMERS_FILE" # Clear the file
}

# Start timing a section
start_section_timer() {
  local section_name="$1"
  local start_time=$(date +%s)
  local safe_name=$(echo "$section_name" | tr ' -' '_' | tr -cd '[:alnum:]_')

  # Validate inputs to prevent errors
  if [ -z "$section_name" ]; then
    log_warning "start_section_timer called without section name"
    return 1
  fi

  if [ -z "$SECTION_TIMERS_FILE" ]; then
    init_timing_system
  fi

  # Store timing data in file format: safe_name:start_time:section_name
  echo "${safe_name}:${start_time}:${section_name}" >>"$SECTION_TIMERS_FILE"
  log_info "Starting: $section_name"
}

# End timing a section and log duration
end_section_timer() {
  local section_name="$1"
  local end_time=$(date +%s)
  local safe_name=$(echo "$section_name" | tr ' -' '_' | tr -cd '[:alnum:]_')

  # Validate inputs
  if [ -z "$section_name" ] || [ -z "$SECTION_TIMERS_FILE" ] || [ ! -f "$SECTION_TIMERS_FILE" ]; then
    log_success "Completed: $section_name"
    return 0
  fi

  # Find the start time for this section
  local start_time
  start_time=$(grep "^${safe_name}:" "$SECTION_TIMERS_FILE" | tail -1 | cut -d':' -f2)

  if [ -n "$start_time" ] && [ "$start_time" -gt 0 ] 2>/dev/null; then
    local duration=$((end_time - start_time))
    local min=$((duration / 60))
    local sec=$((duration % 60))

    if [ $min -gt 0 ]; then
      log_success "Completed: $section_name (${min}m ${sec}s)"
    else
      log_success "Completed: $section_name (${sec}s)"
    fi

    # Store for final performance report
    echo "$section_name:$duration" >>"$SETUP_LOG_FILE.perf" 2>/dev/null || true
  else
    log_success "Completed: $section_name"
  fi
}

# Comprehensive error prevention and validation
validate_environment() {
  local errors=0

  # Check bash version (need 4.0+ for some features)
  if [ "${BASH_VERSION%%.*}" -lt 4 ] 2>/dev/null; then
    log_warning "Bash version ${BASH_VERSION} detected. Some features may not work optimally."
  fi

  # Validate critical variables
  local required_vars=("DOMAIN" "SERVICE_USER" "BASE_DIR")
  for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
      log_error "Critical variable $var is not set"
      ((errors++))
    fi
  done

  # Test basic array functionality
  if ! (declare -a test_array=("test") 2>/dev/null); then
    log_error "Array functionality not available"
    ((errors++))
  fi

  # Test arithmetic operations
  if ! ((1 + 1 == 2)) 2>/dev/null; then
    log_error "Arithmetic operations not working"
    ((errors++))
  fi

  return $errors
}

# Safe wrapper for any potentially problematic operations
safe_execute() {
  local description="$1"
  shift
  local cmd=("$@")

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY RUN] Would execute: $description"
    return 0
  fi

  log_info "Safely executing: $description"

  # Execute with error handling
  if "${cmd[@]}" 2>/dev/null; then
    log_success "Completed safely: $description"
    return 0
  else
    local exit_code=$?
    log_error "Safe execution failed: $description (exit code: $exit_code)"
    return $exit_code
  fi
}

# Show performance summary
show_performance_summary() {
  if [ -f "$SETUP_LOG_FILE.perf" ]; then
    echo
    log_section "Performance Summary"

    local total_time=0
    while IFS=':' read -r section duration; do
      local min=$((duration / 60))
      local sec=$((duration % 60))

      if [ $min -gt 0 ]; then
        printf "  %-30s %2dm %2ds\n" "$section:" "$min" "$sec"
      else
        printf "  %-30s     %2ds\n" "$section:" "$sec"
      fi

      total_time=$((total_time + duration))
    done <"$SETUP_LOG_FILE.perf"

    local total_min=$((total_time / 60))
    local total_sec=$((total_time % 60))
    echo
    printf "  ${GREEN}%-30s %2dm %2ds${NC}\n" "Total Time:" "$total_min" "$total_sec"
    echo

    # Cleanup performance file
    rm -f "$SETUP_LOG_FILE.perf"
  fi
}

# Parallel DNS validation function
validate_dns_parallel() {
  local domain="$1"
  local server_ipv4="$2"
  local server_ipv6="$3"
  local result_file="$4"

  local resolved_ipv4 resolved_ipv6
  local ipv4_match=false ipv6_match=false
  local status="SUCCESS"
  local message=""

  # Check IPv4 A records
  if [ -n "$server_ipv4" ]; then
    resolved_ipv4=$(nslookup "$domain" 2>/dev/null | awk '/^Address: / { print $2 }' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
    if [ -n "$resolved_ipv4" ]; then
      if [ "$resolved_ipv4" = "$server_ipv4" ]; then
        ipv4_match=true
        message="${message}IPv4 DNS correctly configured: $domain → $resolved_ipv4; "
      else
        message="${message}IPv4 DNS mismatch: $domain resolves to $resolved_ipv4, but server IPv4 is $server_ipv4; "
      fi
    fi
  fi

  # Check IPv6 AAAA records
  if [ -n "$server_ipv6" ]; then
    resolved_ipv6=$(nslookup "$domain" 2>/dev/null | awk '/^Address: / { print $2 }' | grep -E '^[0-9a-fA-F:]+$' | head -1)
    if [ -n "$resolved_ipv6" ]; then
      if [ "$resolved_ipv6" = "$server_ipv6" ]; then
        ipv6_match=true
        message="${message}IPv6 DNS correctly configured: $domain → $resolved_ipv6; "
      else
        message="${message}IPv6 DNS mismatch: $domain resolves to $resolved_ipv6, but server IPv6 is $server_ipv6; "
      fi
    fi
  fi

  # Determine overall status
  if [ -z "$resolved_ipv4" ] && [ -z "$resolved_ipv6" ]; then
    status="FAILED"
    message="${message}DNS lookup failed: $domain (no A or AAAA records found)"
  elif [ "$ipv4_match" = false ] && [ "$ipv6_match" = false ]; then
    status="FAILED"
    message="${message}DNS configuration error: $domain doesn't resolve to any server IP"
  fi

  # Write result to temp file
  echo "$domain:$status:$message" >>"$result_file"
}

# Configure SSL certificates only (for incomplete installations)
configure_ssl_only() {
  log_section "Configuring SSL Certificates"

  # Verify prerequisites
  if [ ! -f "$BASE_DIR/docker-compose.yml" ]; then
    log_error "Main installation not found. Please run full installation first."
    exit 1
  fi

  if ! id "$SERVICE_USER" &>/dev/null; then
    log_error "Service user '$SERVICE_USER' not found. Please run full installation first."
    exit 1
  fi

  log_info "Configuring SSL certificates for existing installation..."

  # Set up logging for SSL configuration
  setup_logging

  # Configure SSL certificates
  setup_ssl_certificates
  setup_internal_ssl_infrastructure
  setup_internal_ssl_rotation

  log_success "SSL configuration completed successfully!"
  echo ""
  echo -e "${BLUE}🔐 SSL Configuration Complete:${NC}"
  echo -e "- ${GREEN}✓${NC} Let's Encrypt certificates configured"
  echo -e "- ${GREEN}✓${NC} Internal SSL infrastructure ready"
  echo -e "- ${GREEN}✓${NC} Certificate auto-renewal enabled"
  echo ""
  echo -e "${BLUE}Next Steps:${NC}"
  echo -e "1. ${YELLOW}Restart services:${NC} sudo -u $SERVICE_USER $BASE_DIR/scripts/restart-all.sh"
  echo -e "2. ${YELLOW}Verify SSL:${NC} sudo -u $SERVICE_USER $BASE_DIR/scripts/ssl-status.sh"
  echo -e "3. ${YELLOW}Test certificates:${NC} openssl s_client -connect ${DOMAIN}:443"
}

# Enhanced execution function with logging and progress
execute_cmd() {
  local cmd="$1"
  local description="${2:-$cmd}"
  local show_progress="${3:-false}"
  local progress_message="${4:-Processing}"

  if [ "$DRY_RUN" = "true" ]; then
    echo -e "${CYAN}[DRY RUN]${NC} Would execute: $description"
    return 0
  fi

  log_info "Executing: $description"

  # Show progress for long operations
  if [ "$show_progress" = "true" ]; then
    start_progress "$progress_message"
  fi

  if [ "$ENABLE_DEBUG_LOGS" = "true" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] Executing: $cmd"
  fi

  local start_time=$(date +%s)
  if eval "$cmd"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ "$show_progress" = "true" ]; then
      stop_progress
    fi

    if [ $duration -gt 5 ]; then
      log_success "Completed: $description (${duration}s)"
    else
      log_success "Completed: $description"
    fi
    return 0
  else
    local exit_code=$?
    if [ "$show_progress" = "true" ]; then
      stop_progress
    fi
    log_error "Failed: $description (exit code: $exit_code)"
    return $exit_code
  fi
}

# Parallel file operations helper
parallel_file_ops() {
  local operations=("$@")
  local pids=()

  # Execute all operations in parallel
  for op in "${operations[@]}"; do
    eval "$op" &
    pids+=($!)
  done

  # Wait for all to complete
  local failed=0
  for pid in "${pids[@]}"; do
    if ! wait $pid; then
      ((failed++))
    fi
  done

  return $failed
}

# Enhanced file operation validation functions
validate_temp_file() {
  local temp_file="$1"
  local description="${2:-file operation}"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would execute: $description"
    return 0
  fi

  if [[ ! -f "$temp_file" ]]; then
    log_error "ERROR: Temporary file not found: $temp_file"
    log_error "This indicates a script generation issue for: $description"
    return 1
  fi

  return 0
}

# Enhanced mv operation with validation
safe_mv() {
  local source="$1"
  local destination="$2"
  local description="${3:-move operation}"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would execute: $description"
    return 0
  fi

  if [[ ! -f "$source" ]] && [[ ! -d "$source" ]]; then
    log_error "ERROR: Source not found for move: $source"
    log_error "Cannot complete: $description"
    return 1
  fi

  execute_cmd "sudo mv '$source' '$destination'" "$description"
}

# Enhanced chmod operation with validation
safe_chmod() {
  local permissions="$1"
  local target="$2"
  local description="${3:-chmod operation}"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would execute: $description"
    return 0
  fi

  if [[ ! -f "$target" ]] && [[ ! -d "$target" ]]; then
    log_warning "Target not found for chmod: $target"
    log_info "Skipping: $description"
    return 0
  fi

  execute_cmd "sudo chmod $permissions '$target'" "$description"
}

# Enhanced chown operation with validation
safe_chown() {
  local ownership="$1"
  local target="$2"
  local description="${3:-chown operation}"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would execute: $description"
    return 0
  fi

  if [[ ! -f "$target" ]] && [[ ! -d "$target" ]]; then
    log_warning "Target not found for chown: $target"
    log_info "Skipping: $description"
    return 0
  fi

  execute_cmd "sudo chown $ownership '$target'" "$description"
}

# Container management functions
docker_cmd() {
  local cmd="$1"
  # Use Docker rootless paths that match the installation
  local docker_env="export XDG_RUNTIME_DIR=/home/$SERVICE_USER/.docker/run && export DOCKER_HOST=unix:///home/$SERVICE_USER/.docker/run/docker.sock && export PATH=/home/$SERVICE_USER/bin:\$PATH"

  execute_cmd "sudo -u $SERVICE_USER bash -c '$docker_env && $cmd'" "$cmd"
}

# Wait for service to be healthy
wait_for_service_health() {
  local service_name="$1"
  local timeout="${2:-300}"
  local interval="${3:-10}"
  local elapsed=0

  log_info "Waiting for $service_name to become healthy (timeout: ${timeout}s)..."

  while [ $elapsed -lt $timeout ]; do
    if docker_cmd "docker ps --filter name=$service_name --filter health=healthy --format '{{.Names}}'" | grep -q "$service_name"; then
      log_success "$service_name is healthy"
      return 0
    fi

    sleep $interval
    elapsed=$((elapsed + interval))
    echo -n "."
  done

  log_error "$service_name failed to become healthy within ${timeout} seconds"
  return 1
}

# Generate secure passwords and secrets
generate_password() {
  local length=${1:-32}
  openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-${length}
}

generate_secret() {
  local length=${1:-64}
  openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-${length}
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 VALIDATION AND PREREQUISITES
# ═══════════════════════════════════════════════════════════════════════════════

# Optimized DNS validation function with parallel processing
validate_dns_configuration() {
  start_section_timer "DNS Validation"
  log_info "Validating DNS configuration for required subdomains..."

  # Get server's public IPv4 and IPv6 addresses
  local server_ipv4 server_ipv6
  start_progress "Detecting server IP addresses"

  # Parallel IP detection
  {
    server_ipv4=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null || curl -4 -s --max-time 5 icanhazip.com 2>/dev/null || echo "")
  } &
  local ipv4_pid=$!

  {
    server_ipv6=$(curl -6 -s --max-time 5 ifconfig.me 2>/dev/null || curl -6 -s --max-time 5 icanhazip.com 2>/dev/null || echo "")
  } &
  local ipv6_pid=$!

  # Wait for both IP detections to complete
  wait $ipv4_pid
  wait $ipv6_pid

  stop_progress

  if [ -z "$server_ipv4" ] && [ -z "$server_ipv6" ]; then
    log_warning "Could not determine server's public IP addresses. Skipping DNS validation."
    log_warning "Please ensure DNS records point to your server's IP address(es)."
    end_section_timer "DNS Validation"
    return 0
  fi

  if [ -n "$server_ipv4" ]; then
    log_info "Server public IPv4: $server_ipv4"
  fi
  if [ -n "$server_ipv6" ]; then
    log_info "Server public IPv6: $server_ipv6"
  fi

  # Required subdomains to check (root domain is optional)
  local required_subdomains=(
    "${SUPABASE_SUBDOMAIN}.${DOMAIN}"
    "${STUDIO_SUBDOMAIN}.${DOMAIN}"
    "${N8N_SUBDOMAIN}.${DOMAIN}"
  )

  # Create temporary file for parallel results
  local dns_results_file=$(mktemp)
  local dns_pids=()

  log_info "Checking DNS for ${#required_subdomains[@]} domains in parallel..."
  start_progress "Validating DNS records"

  # Launch parallel DNS checks
  for domain in "${required_subdomains[@]}"; do
    validate_dns_parallel "$domain" "$server_ipv4" "$server_ipv6" "$dns_results_file" &
    dns_pids+=($!)
  done

  # Wait for all parallel DNS checks to complete
  for pid in "${dns_pids[@]}"; do
    wait $pid
  done

  stop_progress

  # Process results
  local dns_errors=0
  local failed_domains=()

  while IFS=':' read -r domain status message; do
    if [ "$status" = "SUCCESS" ]; then
      # Parse success messages and log them
      echo "$message" | tr ';' '\n' | while read -r msg; do
        [ -n "$msg" ] && log_success "$msg"
      done
    else
      log_warning "$message"
      failed_domains+=("$domain")
      ((dns_errors++))
    fi
  done <"$dns_results_file"

  # Cleanup temp file
  rm -f "$dns_results_file"

  if [ $dns_errors -gt 0 ]; then
    echo ""
    log_error "❌ DNS Configuration Issues Found"
    echo ""
    echo -e "${RED}The following domains are not properly configured:${NC}"
    for domain in "${failed_domains[@]}"; do
      echo -e "  ${YELLOW}• $domain${NC}"
    done
    echo ""
    echo -e "${BLUE}📋 Required DNS Records:${NC}"
    echo ""
    for domain in "${required_subdomains[@]}"; do
      if [ -n "$server_ipv4" ]; then
        echo -e "  ${CYAN}$domain${NC}        A     ${WHITE}$server_ipv4${NC}    (IPv4)"
      fi
      if [ -n "$server_ipv6" ]; then
        echo -e "  ${CYAN}$domain${NC}        AAAA  ${WHITE}$server_ipv6${NC}    (IPv6)"
      fi
    done
    echo ""
    echo -e "${BLUE}📖 DNS Setup Instructions:${NC}"
    echo -e "1. Go to your domain registrar or DNS provider"
    if [ -n "$server_ipv4" ]; then
      echo -e "2. Add A records for each subdomain pointing to $server_ipv4"
    fi
    if [ -n "$server_ipv6" ]; then
      echo -e "$([ -n "$server_ipv4" ] && echo "3" || echo "2"). Add AAAA records for each subdomain pointing to $server_ipv6"
    fi
    echo -e "$([ -n "$server_ipv4" ] && [ -n "$server_ipv6" ] && echo "4" || echo "3"). Wait 5-10 minutes for DNS propagation"
    echo -e "$([ -n "$server_ipv4" ] && [ -n "$server_ipv6" ] && echo "5" || echo "4"). Verify with: ${CYAN}nslookup supabase.$DOMAIN${NC}"
    echo ""
    echo -e "${GREEN}Note: Root domain ($DOMAIN) is optional - only subdomains are required${NC}"
    echo -e "${YELLOW}For detailed DNS setup instructions, see the README.md file.${NC}"
    echo ""

    if [ "$DRY_RUN" = "true" ]; then
      log_warning "DRY RUN MODE: DNS validation failed, but continuing for testing purposes"
      return 0
    fi

    echo -e "${RED}Installation cannot continue without proper DNS configuration.${NC}"
    echo -e "${YELLOW}Fix the DNS records above and run the script again.${NC}"
    exit 1
  fi

  log_success "All required subdomain DNS records are properly configured!"

  # Optional check for root domain (won't fail installation)
  log_info "Checking optional root domain configuration..."
  local root_ipv4 root_ipv6
  local root_matches=false

  if [ -n "$server_ipv4" ]; then
    root_ipv4=$(nslookup "$DOMAIN" 2>/dev/null | awk '/^Address: / { print $2 }' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
    if [ -n "$root_ipv4" ]; then
      if [ "$root_ipv4" = "$server_ipv4" ]; then
        log_success "Root domain ($DOMAIN) IPv4 points to this server → $root_ipv4"
        root_matches=true
      else
        log_info "Root domain ($DOMAIN) IPv4 points elsewhere → $root_ipv4 (this is optional)"
      fi
    fi
  fi

  if [ -n "$server_ipv6" ]; then
    root_ipv6=$(nslookup "$DOMAIN" 2>/dev/null | awk '/^Address: / { print $2 }' | grep -E '^[0-9a-fA-F:]+$' | head -1)
    if [ -n "$root_ipv6" ]; then
      if [ "$root_ipv6" = "$server_ipv6" ]; then
        log_success "Root domain ($DOMAIN) IPv6 points to this server → $root_ipv6"
        root_matches=true
      else
        log_info "Root domain ($DOMAIN) IPv6 points elsewhere → $root_ipv6 (this is optional)"
      fi
    fi
  fi

  if [ -z "$root_ipv4" ] && [ -z "$root_ipv6" ]; then
    log_info "Root domain ($DOMAIN) not configured (this is optional)"
  fi
}

# User and group validation function
validate_user_configuration() {
  log_info "Validating service user configuration..."

  # Check if SERVICE_USER exists
  if ! id "$SERVICE_USER" &>/dev/null; then
    log_error "Service user '$SERVICE_USER' does not exist"
    echo ""
    echo -e "${BLUE}📋 To create the service user, run:${NC}"
    echo -e "  ${CYAN}sudo adduser $SERVICE_USER${NC}"
    echo -e "  ${CYAN}sudo usermod -aG sudo $SERVICE_USER${NC}"
    echo ""
    echo -e "${YELLOW}Then switch to the service user and run this script again:${NC}"
    echo -e "  ${CYAN}sudo su - $SERVICE_USER${NC}"
    echo ""
    exit 1
  fi

  # Check if SERVICE_GROUP exists
  if ! getent group "$SERVICE_GROUP" &>/dev/null; then
    log_error "Service group '$SERVICE_GROUP' does not exist"
    echo ""
    echo -e "${BLUE}📋 To create the service group, run:${NC}"
    echo -e "  ${CYAN}sudo groupadd $SERVICE_GROUP${NC}"
    echo -e "  ${CYAN}sudo usermod -aG $SERVICE_GROUP $SERVICE_USER${NC}"
    echo ""
    exit 1
  fi

  # Check if SERVICE_USER is in SERVICE_GROUP
  if ! id -nG "$SERVICE_USER" | grep -qw "$SERVICE_GROUP"; then
    log_warning "Service user '$SERVICE_USER' is not in group '$SERVICE_GROUP'"
    echo ""
    echo -e "${BLUE}📋 To add user to group, run:${NC}"
    echo -e "  ${CYAN}sudo usermod -aG $SERVICE_GROUP $SERVICE_USER${NC}"
    echo ""
  fi

  # Check if current user matches SERVICE_USER
  local current_user
  current_user=$(whoami)

  if [ "$current_user" != "$SERVICE_USER" ]; then
    log_error "Script must be run as service user '$SERVICE_USER', but current user is '$current_user'"
    echo ""
    echo -e "${BLUE}📋 Security Best Practice:${NC}"
    echo -e "This script should run as the dedicated service user to ensure:"
    echo -e "  • Proper file ownership and permissions"
    echo -e "  • Rootless Docker configuration"
    echo -e "  • Service isolation and security"
    echo ""
    echo -e "${YELLOW}Switch to the service user and run again:${NC}"
    echo -e "  ${CYAN}sudo su - $SERVICE_USER${NC}"
    echo -e "  ${CYAN}cd $(pwd)${NC}"
    echo -e "  ${CYAN}./$(basename $0) $*${NC}"
    echo ""

    if [ "$DRY_RUN" = "true" ]; then
      log_warning "DRY RUN MODE: User validation failed, but continuing for testing purposes"
      return 0
    fi

    exit 1
  fi

  # Check if user has sudo privileges
  if ! sudo -n true 2>/dev/null; then
    log_warning "Current user '$current_user' may not have sudo privileges"
    echo ""
    echo -e "${BLUE}📋 To grant sudo privileges, run as root:${NC}"
    echo -e "  ${CYAN}usermod -aG sudo $SERVICE_USER${NC}"
    echo ""
    echo -e "${YELLOW}Note: Some installation steps require sudo access${NC}"
  fi

  # Get user and group IDs for later use
  SERVICE_UID=$(id -u "$SERVICE_USER")
  SERVICE_GID=$(id -g "$SERVICE_GROUP")

  log_success "Service user configuration validated:"
  log_success "  User: $SERVICE_USER (UID: $SERVICE_UID)"
  log_success "  Group: $SERVICE_GROUP (GID: $SERVICE_GID)"
  log_success "  Current user: $current_user ✓"
}

check_prerequisites() {
  log_section "Checking Prerequisites"

  # Check domain configuration
  if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "example.com" ]; then
    log_error "Domain must be configured in the script header (currently: $DOMAIN)"
    log_error "Please edit the DOMAIN variable at the top of this script"
    exit 1
  fi

  # Validate domain format
  if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    log_error "Invalid domain format: $DOMAIN"
    exit 1
  fi

  log_success "Domain validated: $DOMAIN"

  # Check OS version
  if ! grep -q "Debian.*12" /etc/os-release; then
    log_warning "This script is designed for Debian 12. Current OS:"
    cat /etc/os-release | head -2
    echo "Continue? (y/N)"
    read -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi

  # Check available disk space (minimum 10GB)
  available_space=$(df / | awk 'NR==2 {print $4}')
  required_space=$((10 * 1024 * 1024)) # 10GB in KB

  if [ "$available_space" -lt "$required_space" ]; then
    log_error "Insufficient disk space. Required: 10GB, Available: $((available_space / 1024 / 1024))GB"
    exit 1
  fi

  # Check memory (minimum 4GB)
  total_memory=$(free -m | awk 'NR==2{print $2}')
  if [ "$total_memory" -lt 4096 ]; then
    log_warning "Less than 4GB RAM detected. Some services may be unstable."
  fi

  # Check required commands (including nslookup for DNS validation)
  local required_commands=("curl" "openssl" "systemctl" "ufw" "gpg" "nslookup")

  # Skip Docker check if service user doesn't exist (will be installed during setup)
  if id "$SERVICE_USER" >/dev/null 2>&1; then
    required_commands+=("docker")
  else
    log_info "Service user '$SERVICE_USER' not found - Docker will be installed during setup"
  fi

  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_error "Required command not found: $cmd"
      if [ "$cmd" = "nslookup" ]; then
        log_error "Install with: sudo apt-get install dnsutils"
      fi
      exit 1
    fi
  done
  log_success "All required commands are available"

  # User and group validation - Check service user configuration
  log_info "Validating service user configuration..."
  validate_user_configuration

  # DNS validation - Check if domains resolve to current server
  log_info "Validating DNS configuration..."
  validate_dns_configuration

  log_success "Prerequisites check completed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔐 ENHANCED HOST OS HARDENING WITH APPARMOR
# ═══════════════════════════════════════════════════════════════════════════════

harden_host_os() {

  log_section "Hardening Host OS with AppArmor"

  # Update system packages
  log_info "Updating system packages..."
  execute_cmd "sudo apt-get update && sudo apt-get upgrade -y" "System package update"

  # Install security packages and useful CLI tools
  log_info "Installing security packages and CLI tools..."
  local security_packages=(
    # Security and system packages
    "fail2ban" "ufw" "unattended-upgrades" "apt-listchanges"
    "needrestart" "apparmor" "apparmor-utils" "apparmor-profiles"
    "auditd" "htop" "iotop" "netstat-nat" "tcpdump"
    "rsyslog" "logrotate" "etckeeper" "uidmap"
    # Useful CLI tools for file search and fuzzy finding
    "ripgrep" "fd-find" "fzf" # fd-find provides 'fdfind' command on Debian/Ubuntu
  )

  execute_cmd "sudo apt-get install -y ${security_packages[*]}" "Security packages and CLI tools installation"

  # Configure automatic security updates
  log_info "Configuring automatic security updates..."
  cat >/tmp/50unattended-upgrades <<EOF
// Enhanced unattended upgrades configuration
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Mail "${EMAIL}";
Unattended-Upgrade::MailOnlyOnError "true";
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
EOF
  safe_mv "/tmp/50unattended-upgrades" "/etc/apt/apt.conf.d/50unattended-upgrades" "Unattended upgrades config"
  execute_cmd "sudo systemctl enable unattended-upgrades" "Enable automatic updates"

  # Configure UFW firewall with enhanced rules
  if [ "$UFW_ENABLED" = "true" ]; then
    log_info "Configuring enhanced UFW firewall..."
    execute_cmd "sudo ufw --force reset" "Reset UFW"
    execute_cmd "sudo ufw default deny incoming" "Set default deny incoming"
    execute_cmd "sudo ufw default allow outgoing" "Set default allow outgoing"

    # Detect currently open ports from multiple sources
    log_info "Detecting currently open ports from iptables and active services..."

    # Get ports from iptables ACCEPT rules (with fallback)
    IPTABLES_PORTS=$(sudo iptables -L INPUT -n 2>/dev/null | grep ACCEPT | grep -E 'dpt:[0-9]+' | sed -E 's/.*dpt:([0-9]+).*/\1/' 2>/dev/null || true)

    # Get ports from currently listening services (with multiple methods)
    LISTENING_PORTS=$(sudo netstat -tuln 2>/dev/null | grep LISTEN | awk '{print $4}' | sed 's/.*://' | grep -E '^[0-9]+$' | sort -nu 2>/dev/null || true)

    # Fallback: try ss command if netstat failed
    if [ -z "$LISTENING_PORTS" ]; then
      LISTENING_PORTS=$(sudo ss -tuln 2>/dev/null | grep LISTEN | awk '{print $5}' | sed 's/.*://' | grep -E '^[0-9]+$' | sort -nu 2>/dev/null || true)
    fi

    # Combine and deduplicate ports
    CURRENT_PORTS=$(echo "$IPTABLES_PORTS $LISTENING_PORTS" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -nu | tr '\n' ' ' | sed 's/[[:space:]]*$//')

    # Essential services (always include these)
    execute_cmd "sudo ufw allow 22/tcp comment 'SSH'" "Allow SSH"
    execute_cmd "sudo ufw allow 80/tcp comment 'HTTP'" "Allow HTTP"
    execute_cmd "sudo ufw allow 443/tcp comment 'HTTPS'" "Allow HTTPS"

    # Add currently open ports (with safety limits)
    if [ -n "$CURRENT_PORTS" ]; then
      PORT_COUNT=$(echo $CURRENT_PORTS | wc -w)
      log_info "Found $PORT_COUNT open ports: $CURRENT_PORTS"

      # Safety check: don't add more than 20 ports to prevent misconfiguration
      if [ $PORT_COUNT -gt 20 ]; then
        log_warning "Too many ports detected ($PORT_COUNT). Only adding first 20 for safety."
        CURRENT_PORTS=$(echo $CURRENT_PORTS | cut -d' ' -f1-20)
      fi
      for port in $CURRENT_PORTS; do
        # Skip ports we already added
        if [[ "$port" != "22" && "$port" != "80" && "$port" != "443" ]]; then
          # Determine if it's likely TCP or UDP based on common usage
          if [[ "$port" =~ ^(25|53|110|143|993|995|465|587|993|995|8080|8443|3000|5432|3306|6379)$ ]]; then
            execute_cmd "sudo ufw allow $port/tcp comment 'Existing service port $port'" "Allow existing TCP port $port" || true
          else
            # Default to TCP for unknown ports, but also try to detect protocol from netstat
            PROTOCOL=$(sudo netstat -tuln 2>/dev/null | grep ":$port " | head -1 | awk '{print $1}' | tr '[:upper:]' '[:lower:]' || echo "tcp")
            if [ -n "$PROTOCOL" ]; then
              execute_cmd "sudo ufw allow $port/$PROTOCOL comment 'Existing $PROTOCOL port $port'" "Allow existing $PROTOCOL port $port" || true
            else
              execute_cmd "sudo ufw allow $port comment 'Existing port $port'" "Allow existing port $port" || true
            fi
          fi
        fi
      done
    else
      log_info "No additional open ports detected"
    fi

    # Log final UFW status
    log_info "UFW firewall rules configured. Current status:"
    sudo ufw status numbered | head -20 | while IFS= read -r line; do
      log_info "UFW: $line"
    done

    # Rate limiting for SSH
    execute_cmd "sudo ufw limit ssh" "Rate limit SSH"

    # Enable UFW
    execute_cmd "sudo ufw --force enable" "Enable UFW"
    log_success "UFW firewall configured with rate limiting"
  fi

  # Configure enhanced fail2ban
  if [ "$FAIL2BAN_ENABLED" = "true" ]; then
    log_info "Configuring enhanced fail2ban..."
    cat >/tmp/jail.local <<EOF
[DEFAULT]
# Enhanced fail2ban configuration
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ::1
banaction = ufw
action = %(action_mwl)s
destemail = ${EMAIL}

# SSH protection
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

# NGINX protection
[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
bantime = 600

[nginx-botsearch]
enabled = true
filter = nginx-botsearch
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 86400

# Docker container protection
[docker-auth]
enabled = true
filter = docker-auth
port = http,https
logpath = /var/log/docker.log
maxretry = 5
bantime = 1800
EOF

    safe_mv "/tmp/jail.local" "/etc/fail2ban/jail.local" "Install fail2ban config"

    # Create custom filter for Docker
    cat >/tmp/docker-auth.conf <<EOF
[Definition]
failregex = ^<HOST>.*"(GET|POST).*" (401|403|404) .*$
ignoreregex =
EOF
    safe_mv "/tmp/docker-auth.conf" "/etc/fail2ban/filter.d/docker-auth.conf" "Install Docker filter"

    execute_cmd "sudo systemctl enable fail2ban" "Enable fail2ban"
    execute_cmd "sudo systemctl restart fail2ban" "Start fail2ban"
    log_success "Enhanced fail2ban configured"
  fi

  # Setup AppArmor (Debian native security)
  if [ "$APPARMOR_ENABLED" = "true" ]; then
    log_info "Setting up AppArmor for container security..."

    # Enable AppArmor
    execute_cmd "sudo systemctl enable apparmor" "Enable AppArmor"
    execute_cmd "sudo systemctl start apparmor" "Start AppArmor"

    # Create AppArmor profile for Docker containers
    cat >/tmp/docker-default <<EOF
#include <tunables/global>

profile docker-default flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  
  # Allow networking
  network,
  capability,
  file,
  umount,
  
  # Deny dangerous operations
  deny @{PROC}/* w,
  deny @{PROC}/{[^1-9],[^1-9][^0-9],[^1-9s][^0-9y][^0-9s],[^1-9][^0-9][^0-9][^0-9]*}/** w,
  deny @{PROC}/sys/[^k]** w,
  deny @{PROC}/sys/kernel/{?,??,[^s][^h][^m]**} w,
  deny @{PROC}/sysrq-trigger rwklx,
  deny @{PROC}/mem rwklx,
  deny @{PROC}/kmem rwklx,
  deny @{PROC}/kcore rwklx,
  deny mount,
  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,
  deny /sys/fs/c[^g]*/** wklx,
  deny /sys/fs/cg[^r]*/** wklx,
  deny /sys/firmware/** rwklx,
  deny /sys/kernel/security/** rwklx,
  
  # Allow container-specific paths
  /var/lib/docker/** rw,
  /tmp/** rw,
  /var/tmp/** rw,
}
EOF

    safe_mv "/tmp/docker-default" "/etc/apparmor.d/docker-default" "Install Docker AppArmor profile"
    execute_cmd "sudo apparmor_parser -r /etc/apparmor.d/docker-default" "Load Docker AppArmor profile"
    log_success "AppArmor configured for container security"
  fi

  # Configure kernel security parameters
  log_info "Configuring secure kernel parameters..."
  cat >/tmp/99-security.conf <<EOF
# Network security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Memory protection
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.core_uses_pid = 1
kernel.ctrl-alt-del = 0

# File system security
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
EOF

  safe_mv "/tmp/99-security.conf" "/etc/sysctl.d/99-security.conf" "Install kernel security config"
  execute_cmd "sudo sysctl -p /etc/sysctl.d/99-security.conf" "Apply kernel security settings"

  # Setup audit logging
  if [ "$AUDIT_LOGGING" = "true" ]; then
    log_info "Configuring audit logging..."
    execute_cmd "sudo systemctl enable auditd" "Enable auditd"

    # Basic audit rules
    cat >/tmp/audit.rules <<EOF
# Enhanced audit rules for container security
-D
-b 8192
-f 1

# Monitor authentication
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k identity

# Monitor system configuration
-w /etc/hosts -p wa -k network
-w /etc/hostname -p wa -k network
-w /etc/resolv.conf -p wa -k network

# Monitor Docker
-w /var/lib/docker -p wa -k docker
-w /etc/docker -p wa -k docker
-w /usr/bin/docker -p x -k docker

# Monitor critical binaries
-w /bin/su -p x -k privileged
-w /usr/bin/sudo -p x -k privileged
-w /bin/mount -p x -k privileged
-w /bin/umount -p x -k privileged

# Immutable rules (must be last)
-e 2
EOF

    safe_mv "/tmp/audit.rules" "/etc/audit/rules.d/audit.rules" "Install audit rules"
    execute_cmd "sudo systemctl restart auditd" "Restart auditd"
    log_success "Audit logging configured"
  fi

  # Setup configuration tracking with etckeeper
  log_info "Setting up configuration tracking..."
  execute_cmd "sudo sh -c 'cd /etc && etckeeper init'" "Initialize etckeeper"
  execute_cmd "sudo sh -c 'cd /etc && etckeeper commit \"Initial configuration before container stack setup\"'" "Initial etckeeper commit"

  # Configure log rotation
  cat >/tmp/docker-logs <<EOF
/var/log/docker.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF
  safe_mv "/tmp/docker-logs" "/etc/logrotate.d/docker-logs" "Configure Docker log rotation"

  log_success "Host OS hardening completed with AppArmor integration"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🐳 ENHANCED CONTAINER SETUP
# ═══════════════════════════════════════════════════════════════════════════════

setup_container_environment() {
  log_section "Setting up Enhanced Container Environment"

  # Create service user if it doesn't exist
  if ! id "$SERVICE_USER" &>/dev/null; then
    log_info "Creating service user: $SERVICE_USER"
    execute_cmd "sudo useradd -r -m -s $SERVICE_SHELL -c 'Container Services User' $SERVICE_USER" "Create service user"
    execute_cmd "sudo usermod -aG docker $SERVICE_USER" "Add user to docker group"
    log_success "Service user created"
  else
    log_info "Service user already exists"
  fi

  # Get user IDs
  SERVICE_UID=$(id -u $SERVICE_USER)
  SERVICE_GID=$(id -g $SERVICE_USER)

  # Create comprehensive directory structure
  log_info "Creating directory structure..."
  local directories=(
    "$BASE_DIR/services/supabase/config/init"
    "$BASE_DIR/services/supabase/volumes/db/data"
    "$BASE_DIR/services/supabase/volumes/storage"
    "$BASE_DIR/services/supabase/volumes/functions"
    "$BASE_DIR/services/nginx/conf"
    "$BASE_DIR/services/nginx/ssl"
    "$BASE_DIR/services/nginx/logs"
    "$BASE_DIR/services/n8n/data"
    "$BASE_DIR/services/nextjs/app"
    "$BASE_DIR/services/certbot/conf"
    "$BASE_DIR/services/certbot/www"
    "$BASE_DIR/services/certbot/logs"
    # Monitoring directories removed
    "$BASE_DIR/scripts"
    "$BASE_DIR/backups/database"
    "$BASE_DIR/backups/volumes"
    "$BASE_DIR/backups/configs"
    "$BASE_DIR/logs"
    "$BASE_DIR/secrets"
    "$BASE_DIR/tmp"
  )

  for dir in "${directories[@]}"; do
    execute_cmd "sudo -u $SERVICE_USER mkdir -p $dir" "Create directory: $dir"
  done

  # Set proper permissions
  safe_chmod "700" "$BASE_DIR/secrets" "Secure secrets directory"
  safe_chmod "755" "$BASE_DIR/logs" "Set logs permissions"
  safe_chmod "755" "$BASE_DIR/backups" "Set backups permissions"

  # Setup rootless Docker if not already installed
  if ! sudo -u $SERVICE_USER test -f "/home/$SERVICE_USER/bin/docker"; then
    log_info "Installing rootless Docker for $SERVICE_USER..."

    # Install required rootless extras package first
    execute_cmd "sudo apt-get update" "Update package lists"
    execute_cmd "sudo apt-get install -y docker-ce-rootless-extras" "Install Docker rootless extras"

    execute_cmd "sudo -u $SERVICE_USER bash -c 'curl -fsSL https://get.docker.com/rootless | sh'" "Install rootless Docker"

    # Configure environment
    execute_cmd "sudo -u $SERVICE_USER bash -c 'echo \"export PATH=$BASE_DIR/bin:\\\$PATH\" >> $BASE_DIR/.bashrc'" "Add Docker to PATH"
    execute_cmd "sudo -u $SERVICE_USER bash -c 'echo \"export DOCKER_HOST=unix:///run/user/$SERVICE_UID/docker.sock\" >> $BASE_DIR/.bashrc'" "Set Docker host"

    log_success "Rootless Docker installed"
  else
    log_info "Rootless Docker already installed"
  fi

  # Configure Docker daemon for production
  log_info "Configuring Docker daemon for production..."

  # Create Docker daemon configuration directory
  execute_cmd "sudo -u $SERVICE_USER mkdir -p $BASE_DIR/.config/docker" "Create Docker config directory"

  cat >/tmp/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "${CONTAINER_LOG_MAX_SIZE}",
    "max-file": "${CONTAINER_LOG_MAX_FILES}",
    "compress": "true"
  },
  "storage-driver": "overlay2",
  "userland-proxy": false,
  "experimental": false,
  "live-restore": true,
  "no-new-privileges": ${CONTAINER_NO_NEW_PRIVS},
  "userns-remap": "$([ "$CONTAINER_USER_NAMESPACES" = "true" ] && echo "default" || echo "")",
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "path": "runc"
    }
  },
  "features": {
    "buildkit": true
  },
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "10GB"
    }
  }
}
EOF

  safe_mv "/tmp/daemon.json" "$BASE_DIR/.config/docker/daemon.json" "Install Docker daemon config"

  # Enable and start Docker for service user
  execute_cmd "sudo loginctl enable-linger $SERVICE_USER" "Enable lingering for service user"

  # Fix Docker rootless systemd issues for Debian systems
  log_info "Configuring Docker rootless environment..."

  # Set up environment variables for Docker rootless
  local docker_runtime_dir="/home/$SERVICE_USER/.docker/run"
  local docker_host="unix://$docker_runtime_dir/docker.sock"

  # Add Docker environment to user's bashrc
  execute_cmd "sudo -u $SERVICE_USER bash -c 'echo \"export XDG_RUNTIME_DIR=$docker_runtime_dir\" >> ~/.bashrc'" "Set XDG_RUNTIME_DIR"
  execute_cmd "sudo -u $SERVICE_USER bash -c 'echo \"export DOCKER_HOST=$docker_host\" >> ~/.bashrc'" "Set DOCKER_HOST"
  execute_cmd "sudo -u $SERVICE_USER bash -c 'echo \"export PATH=\\\$HOME/bin:\\\$PATH\" >> ~/.bashrc'" "Update PATH"

  # Enable and start Docker with proper environment - use Docker's own systemd setup
  log_info "Starting Docker rootless service..."
  execute_cmd "sudo -u $SERVICE_USER bash -c 'source ~/.bashrc && systemctl --user enable docker'" "Enable Docker service" || {
    log_warning "Systemctl enable failed, Docker rootless may not have systemd integration"
    log_info "Docker will be started manually when needed"
  }

  # Start Docker daemon if systemctl is available, otherwise it will auto-start on first use
  execute_cmd "sudo -u $SERVICE_USER bash -c 'source ~/.bashrc && systemctl --user start docker'" "Start Docker service" || {
    log_info "Docker will auto-start on first use"
  }

  # Wait for Docker to be ready
  log_info "Waiting for Docker to be ready..."
  local retries=30
  while [ $retries -gt 0 ]; do
    if docker_cmd "docker info" >/dev/null 2>&1; then
      break
    fi
    sleep 2
    ((retries--))
  done

  if [ $retries -eq 0 ]; then
    log_error "Docker failed to start properly"
    exit 1
  fi

  log_success "Docker is running and configured for production"

  # Create Docker networks with enhanced configuration in parallel
  start_section_timer "Docker Networks"
  log_info "Creating segmented Docker networks in parallel..."

  # Batch network creation for better performance
  local network_pids=()

  # Create networks in parallel
  {
    docker_cmd "docker network create $JARVIS_NETWORK --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 || true"
  } &
  network_pids+=($!)

  {
    docker_cmd "docker network create $PUBLIC_TIER --driver bridge --subnet=172.21.0.0/16 --gateway=172.21.0.1 || true"
  } &
  network_pids+=($!)

  {
    docker_cmd "docker network create $PRIVATE_TIER --driver bridge --subnet=172.22.0.0/16 --gateway=172.22.0.1 || true"
  } &
  network_pids+=($!)

  # Wait for all network creations to complete
  for pid in "${network_pids[@]}"; do
    wait $pid
  done

  end_section_timer "Docker Networks"

  end_section_timer "Container Environment Setup"
  log_success "Container environment setup completed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔐 ENHANCED SECRETS MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

setup_secrets_management() {
  log_section "Setting up Enhanced Secrets Management"

  local secrets_file="$BASE_DIR/secrets/secrets.env"
  local docker_env="export DOCKER_HOST=unix:///run/user/$SERVICE_UID/docker.sock && export PATH=$BASE_DIR/bin:\$PATH"

  # Generate all secrets with appropriate complexity
  log_info "Generating cryptographically secure secrets..."

  # Generate secrets securely and encrypt directly without temporary files
  log_info "Creating encrypted secrets file directly (no temporary storage)..."

  # Generate a random passphrase for encryption
  local encryption_passphrase
  encryption_passphrase=$(generate_secret 32)

  # Check if running in headless environment
  local gpg_method="gpg"
  if [[ ! -t 0 ]] || [[ -z "$DISPLAY" ]] || [[ "$CI" == "true" ]] || [[ "$DEBIAN_FRONTEND" == "noninteractive" ]]; then
    log_info "Detected headless environment, using automated encryption..."
    gpg_method="openssl"
  fi

  if [[ "$gpg_method" == "openssl" ]]; then
    # Use OpenSSL for headless environments
    # Check if DRY RUN mode
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY RUN] Would execute: OpenSSL encryption of secrets to $BASE_DIR/secrets/secrets.env.enc"
      log_info "[DRY RUN] Would execute: Store encryption passphrase securely"
    else
      (
        echo "# Container Stack Secrets - Generated $(date)"
        echo "# WARNING: These are sensitive credentials - keep secure!"
        echo ""
        echo "# Database credentials"
        echo "DB_PASSWORD=$(generate_password 32)"
        echo "POSTGRES_PASSWORD=\$DB_PASSWORD"
        echo ""
        echo "# Supabase secrets"
        echo "JWT_SECRET=$(generate_secret 64)"
        echo "ANON_KEY=$(generate_secret 32)"
        echo "SERVICE_ROLE_KEY=$(generate_secret 32)"
        echo "SUPABASE_SERVICE_KEY=$(generate_secret 32)"
        echo ""
        echo "# N8N secrets"
        echo "N8N_ENCRYPTION_KEY=$(generate_secret 32)"
        echo "N8N_PASSWORD=$(generate_password 16)"
        echo ""
        echo "# Monitoring secrets"
        echo ""
        echo "# Additional secrets"
        echo "WEBHOOK_SECRET=$(generate_secret 32)"
        echo "API_SECRET=$(generate_secret 32)"
        echo "SESSION_SECRET=$(generate_secret 32)"
        echo ""
        echo ""
        echo "# Backup encryption key"
        echo "BACKUP_ENCRYPTION_KEY=$(generate_secret 32)"
      ) | sudo -u $SERVICE_USER openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -pass pass:"$encryption_passphrase" -out $BASE_DIR/secrets/secrets.env.enc

      # Store the passphrase securely
      echo "$encryption_passphrase" | sudo -u $SERVICE_USER tee $BASE_DIR/secrets/.passphrase >/dev/null
    fi
    safe_chmod "600" "$BASE_DIR/secrets/.passphrase" "Secure passphrase file"

    log_info "Secrets encrypted with OpenSSL (headless-compatible)"

  else
    # Use GPG with proper environment variables and batch mode
    export GPG_TTY=$(tty)
    export PINENTRY_USER_DATA="USE_CURSES=1"

    # Check if DRY RUN mode
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY RUN] Would execute: GPG encryption of secrets to $BASE_DIR/secrets/secrets.env.gpg"
    else
      (
        echo "# Container Stack Secrets - Generated $(date)"
        echo "# WARNING: These are sensitive credentials - keep secure!"
        echo ""
        echo "# Database credentials"
        echo "DB_PASSWORD=$(generate_password 32)"
        echo "POSTGRES_PASSWORD=\$DB_PASSWORD"
        echo ""
        echo "# Supabase secrets"
        echo "JWT_SECRET=$(generate_secret 64)"
        echo "ANON_KEY=$(generate_secret 32)"
        echo "SERVICE_ROLE_KEY=$(generate_secret 32)"
        echo "SUPABASE_SERVICE_KEY=$(generate_secret 32)"
        echo ""
        echo "# N8N secrets"
        echo "N8N_ENCRYPTION_KEY=$(generate_secret 32)"
        echo "N8N_PASSWORD=$(generate_password 16)"
        echo ""
        echo "# Monitoring secrets"
        echo ""
        echo "# Additional secrets"
        echo "WEBHOOK_SECRET=$(generate_secret 32)"
        echo "API_SECRET=$(generate_secret 32)"
        echo "SESSION_SECRET=$(generate_secret 32)"
        echo ""
        echo ""
        echo "# Backup encryption key"
        echo "BACKUP_ENCRYPTION_KEY=$(generate_secret 32)"
      ) | sudo -u $SERVICE_USER env GPG_TTY="$GPG_TTY" PINENTRY_USER_DATA="$PINENTRY_USER_DATA" \
        gpg --batch --yes --passphrase "$encryption_passphrase" --symmetric --cipher-algo AES256 --output $BASE_DIR/secrets/secrets.env.gpg
    fi

    log_info "Secrets encrypted with GPG (interactive mode)"
  fi

  # Secrets encrypted directly without temporary storage
  log_info "Secrets encrypted directly - no temporary file exposure"

  # Create unencrypted version for Docker (protected by file permissions)
  if [[ "$gpg_method" == "openssl" ]]; then
    execute_cmd "sudo -u $SERVICE_USER openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 -pass file:$BASE_DIR/secrets/.passphrase -in $BASE_DIR/secrets/secrets.env.enc -out $secrets_file" "Decrypt secrets with OpenSSL"
  else
    execute_cmd "sudo -u $SERVICE_USER env GPG_TTY=\"$GPG_TTY\" gpg --quiet --batch --yes --passphrase \"$encryption_passphrase\" --decrypt $BASE_DIR/secrets/secrets.env.gpg > $secrets_file" "Decrypt secrets with GPG"
  fi
  safe_chmod "600" "$secrets_file" "Secure secrets file permissions"

  log_success "Secrets generated and encrypted"

  # Create Docker secrets from file
  log_info "Creating Docker secrets..."

  # Check DRY RUN mode and file existence before proceeding
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would execute: Create Docker secrets from $secrets_file"
    if [[ -f "$secrets_file" ]]; then
      local secret_count=$(grep -v '^#' "$secrets_file" | grep -c '=' 2>/dev/null || echo "0")
      log_info "[DRY RUN] Would create $secret_count Docker secrets"
    fi
    log_success "Secrets management completed (DRY RUN mode)"
    return 0
  fi

  # Verify secrets file exists before attempting to read it
  if [[ ! -f "$secrets_file" ]]; then
    log_error "ERROR: Secrets file not found: $secrets_file"
    log_error "This may indicate an issue with secrets generation or decryption"
    log_error "Run without --dry-run to generate actual secrets"
    return 1
  fi

  # Read secrets and create Docker secrets
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ $key =~ ^#.*$ ]] && continue
    [[ -z $key ]] && continue

    # Clean up the key and value
    key=$(echo "$key" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
    value=$(echo "$value" | sed 's/\$[A-Z_]*//')

    # Skip if value is a variable reference
    [[ $value =~ ^\$.*$ ]] && continue

    # Create Docker secret
    echo "$value" | docker_cmd "docker secret create ${key} - 2>/dev/null || true"

  done <"$secrets_file"

  # Create systemd service for secrets management
  cat >/tmp/container-secrets.service <<EOF
[Unit]
Description=Container Secrets Management
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$BASE_DIR
ExecStart=/bin/bash -c 'echo "Secrets service started"'
ExecStop=/bin/bash -c 'echo "Secrets service stopped"'

[Install]
WantedBy=multi-user.target
EOF

  safe_mv "/tmp/container-secrets.service" "/etc/systemd/system/container-secrets.service" "Install secrets service"
  execute_cmd "sudo systemctl daemon-reload" "Reload systemd"
  execute_cmd "sudo systemctl enable container-secrets.service" "Enable secrets service"

  log_success "Enhanced secrets management setup completed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🗄️ SUPABASE CONTAINERS SETUP
# ═══════════════════════════════════════════════════════════════════════════════

setup_supabase_containers() {
  log_section "Setting up Supabase Self-Hosted Stack"

  # Generate secure secrets
  local jwt_secret=$(openssl rand -base64 64 | tr -d '\n')
  local anon_key=$(openssl rand -base64 64 | tr -d '\n')
  local service_role_key=$(openssl rand -base64 64 | tr -d '\n')
  local postgres_password=$(openssl rand -base64 32 | tr -d '\n')

  # Create Supabase environment file
  log_info "Creating Supabase configuration..."
  cat >/tmp/supabase.env <<EOF
# Database
POSTGRES_HOST=postgres
POSTGRES_DB=supabase
POSTGRES_USER=supabase
POSTGRES_PASSWORD=$postgres_password
POSTGRES_PORT=5432

# API Settings
API_EXTERNAL_URL=https://${SUPABASE_SUBDOMAIN}.${DOMAIN}
SUPABASE_PUBLIC_URL=https://${SUPABASE_SUBDOMAIN}.${DOMAIN}

# JWT Settings
JWT_SECRET=$jwt_secret
SUPABASE_JWT_SECRET=$jwt_secret
JWT_EXPIRY=3600

# API Keys
SUPABASE_ANON_KEY=$anon_key
SUPABASE_SERVICE_ROLE_KEY=$service_role_key

# Studio Settings
STUDIO_DEFAULT_ORGANIZATION="$DOMAIN Organization"
STUDIO_DEFAULT_PROJECT="$DOMAIN Production"

# Auth Settings  
SITE_URL=https://${DOMAIN}
ADDITIONAL_REDIRECT_URLS=https://${SUPABASE_SUBDOMAIN}.${DOMAIN},https://${STUDIO_SUBDOMAIN}.${DOMAIN}
DISABLE_SIGNUP=false
ENABLE_EMAIL_CONFIRMATIONS=true
ENABLE_EMAIL_AUTOCONFIRM=false

# Email Settings (using Supabase's default email service)
SMTP_ADMIN_EMAIL=$EMAIL
SMTP_HOST=smtp.supabase.co
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
ENABLE_EMAIL_SIGNUP=true

# Storage
FILE_SIZE_LIMIT=52428800
STORAGE_BACKEND=file
FILE_STORAGE_BACKEND_PATH=/var/lib/storage

# GoTrue
GOTRUE_EXTERNAL_EMAIL_ENABLED=true
GOTRUE_MAILER_AUTOCONFIRM=false
GOTRUE_SMTP_MAX_FREQUENCY=1s

# Security
PGRST_DB_SCHEMAS=public,storage,graphql_public
PGRST_JWT_SECRET=$jwt_secret
EOF

  safe_mv "/tmp/supabase.env" "$BASE_DIR/services/supabase/.env" "Install Supabase environment"
  safe_chmod "600" "$BASE_DIR/services/supabase/.env" "Secure Supabase environment"

  # Create Docker Compose for Supabase (environment-aware)
  log_info "Creating Supabase Docker Compose configuration..."

  # Determine PostgreSQL configuration based on environment
  local postgres_volumes="      - postgres_data:/var/lib/postgresql/data
      - ./volumes/db/init:/docker-entrypoint-initdb.d:ro"
  local postgres_command="postgres -c config_file=/etc/postgresql/postgresql.conf"

  if [ "$DEPLOYMENT_ENVIRONMENT" != "development" ] && [ "$ENABLE_DEVELOPMENT_MODE" != "true" ] && [ "$ENABLE_INTERNAL_SSL" = "true" ]; then
    log_info "Production mode: Configuring PostgreSQL with internal SSL"
    postgres_volumes="$postgres_volumes
      - ../certs/services/supabase-postgres.pem:/var/lib/postgresql/server.crt:ro
      - ../certs/services/supabase-postgres-key.pem:/var/lib/postgresql/server.key:ro
      - ../certs/ca/internal-ca.pem:/var/lib/postgresql/ca.crt:ro"
    postgres_command="postgres -c ssl=on -c ssl_cert_file=/var/lib/postgresql/server.crt -c ssl_key_file=/var/lib/postgresql/server.key -c ssl_ca_file=/var/lib/postgresql/ca.crt -c ssl_ciphers='ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256' -c ssl_prefer_server_ciphers=on"
  else
    log_info "Development mode: PostgreSQL without internal SSL"
  fi

  cat >/tmp/docker-compose-supabase.yml <<EOF
version: '3.8'
name: supabase

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: supabase-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: \${POSTGRES_DB}
      POSTGRES_USER: \${POSTGRES_USER}  
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=C"
    volumes:
$postgres_volumes
    networks:
      - supabase-internal
    ports:
      - "127.0.0.1:5432:5432"
    command: $postgres_command
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER} -d \${POSTGRES_DB}"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Supabase Auth (GoTrue)
  auth:
    image: supabase/gotrue:v2.143.0
    container_name: supabase-auth
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      API_EXTERNAL_URL: \${API_EXTERNAL_URL}
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@postgres:\${POSTGRES_PORT}/\${POSTGRES_DB}
      GOTRUE_SITE_URL: \${SITE_URL}
      GOTRUE_URI_ALLOW_LIST: \${ADDITIONAL_REDIRECT_URLS}
      GOTRUE_DISABLE_SIGNUP: \${DISABLE_SIGNUP}
      GOTRUE_JWT_SECRET: \${JWT_SECRET}
      GOTRUE_JWT_EXP: \${JWT_EXPIRY}
      GOTRUE_JWT_DEFAULT_GROUP_NAME: authenticated
      GOTRUE_EXTERNAL_EMAIL_ENABLED: \${GOTRUE_EXTERNAL_EMAIL_ENABLED}
      GOTRUE_MAILER_AUTOCONFIRM: \${GOTRUE_MAILER_AUTOCONFIRM}
      GOTRUE_SMTP_HOST: \${SMTP_HOST}
      GOTRUE_SMTP_PORT: \${SMTP_PORT}
      GOTRUE_SMTP_USER: \${SMTP_USER}
      GOTRUE_SMTP_PASS: \${SMTP_PASS}
      GOTRUE_SMTP_ADMIN_EMAIL: \${SMTP_ADMIN_EMAIL}
      GOTRUE_MAILER_URLPATHS_INVITE: \${API_EXTERNAL_URL}/auth/v1/verify
      GOTRUE_MAILER_URLPATHS_CONFIRMATION: \${API_EXTERNAL_URL}/auth/v1/verify
      GOTRUE_MAILER_URLPATHS_RECOVERY: \${API_EXTERNAL_URL}/auth/v1/verify
      GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE: \${API_EXTERNAL_URL}/auth/v1/verify
    networks:
      - supabase-internal
      - supabase-public
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9999/health"]
      timeout: 5s
      interval: 5s
      retries: 3

  # Supabase REST API (PostgREST)
  rest:
    image: postgrest/postgrest:v12.0.1
    container_name: supabase-rest
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
EOF

  # Add environment-specific configuration for PostgREST
  if [ "$DEPLOYMENT_ENVIRONMENT" != "development" ] && [ "$ENABLE_DEVELOPMENT_MODE" != "true" ] && [ "$ENABLE_INTERNAL_SSL" = "true" ]; then
    log_info "Production mode: Configuring PostgREST with SSL database connection"
    cat >>/tmp/docker-compose-supabase.yml <<EOF
    environment:
      PGRST_DB_URI: postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@postgres:\${POSTGRES_PORT}/\${POSTGRES_DB}?sslmode=require&sslcert=/certs/postgres-client.pem&sslkey=/certs/postgres-client-key.pem&sslrootcert=/certs/internal-ca.pem
      PGRST_DB_SCHEMAS: \${PGRST_DB_SCHEMAS}
      PGRST_DB_ANON_ROLE: anon
      PGRST_JWT_SECRET: \${PGRST_JWT_SECRET}
      PGRST_DB_USE_LEGACY_GUCS: false
      PGRST_APP_SETTINGS_JWT_SECRET: \${JWT_SECRET}
      PGRST_APP_SETTINGS_JWT_EXP: \${JWT_EXPIRY}
    volumes:
      - ../certs/clients:/certs:ro
      - ../certs/ca:/certs:ro
EOF
  else
    log_info "Development mode: PostgREST with standard database connection"
    cat >>/tmp/docker-compose-supabase.yml <<EOF
    environment:
      PGRST_DB_URI: postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@postgres:\${POSTGRES_PORT}/\${POSTGRES_DB}
      PGRST_DB_SCHEMAS: \${PGRST_DB_SCHEMAS}
      PGRST_DB_ANON_ROLE: anon
      PGRST_JWT_SECRET: \${PGRST_JWT_SECRET}
      PGRST_DB_USE_LEGACY_GUCS: false
      PGRST_APP_SETTINGS_JWT_SECRET: \${JWT_SECRET}
      PGRST_APP_SETTINGS_JWT_EXP: \${JWT_EXPIRY}
EOF
  fi

  # Continue with PostgREST configuration
  cat >>/tmp/docker-compose-supabase.yml <<EOF
    networks:
      - supabase-internal  
      - supabase-public
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
      timeout: 5s
      interval: 5s
      retries: 3

  # Supabase Realtime
  realtime:
    image: supabase/realtime:v2.25.35
    container_name: supabase-realtime
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      PORT: 4000
      DB_HOST: postgres
      DB_PORT: \${POSTGRES_PORT}
      DB_USER: \${POSTGRES_USER}
      DB_PASSWORD: \${POSTGRES_PASSWORD}
      DB_NAME: \${POSTGRES_DB}
      DB_AFTER_CONNECT_QUERY: 'SET search_path TO _realtime'
      DB_ENC_KEY: supabaserealtime
      API_JWT_SECRET: \${JWT_SECRET}
      FLY_ALLOC_ID: fly123
      FLY_APP_NAME: realtime
      SECRET_KEY_BASE: \${JWT_SECRET}
      ERL_AFLAGS: -proto_dist inet_tcp
      ENABLE_TAILSCALE: false
      DNS_NODES: "''"
    networks:
      - supabase-internal
      - supabase-public  
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:4000/"]
      timeout: 5s
      interval: 5s
      retries: 3

  # Supabase Storage
  storage:
    image: supabase/storage-api:v0.43.11
    container_name: supabase-storage
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      rest:
        condition: service_healthy
    environment:
      ANON_KEY: \${SUPABASE_ANON_KEY}
      SERVICE_KEY: \${SUPABASE_SERVICE_ROLE_KEY}
      POSTGREST_URL: http://rest:3000
      PGRST_JWT_SECRET: \${JWT_SECRET}
      DATABASE_URL: postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@postgres:\${POSTGRES_PORT}/\${POSTGRES_DB}
      FILE_SIZE_LIMIT: \${FILE_SIZE_LIMIT}
      STORAGE_BACKEND: \${STORAGE_BACKEND}
      FILE_STORAGE_BACKEND_PATH: \${FILE_STORAGE_BACKEND_PATH}
      TENANT_ID: stub
      REGION: us-east-1
      GLOBAL_S3_BUCKET: stub
      ENABLE_IMAGE_TRANSFORMATION: true
      IMGPROXY_URL: http://imgproxy:5001
    volumes:
      - storage_data:/var/lib/storage
    networks:
      - supabase-internal
      - supabase-public
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5000/status"]
      timeout: 5s
      interval: 5s
      retries: 3

  # Image Proxy for Storage
  imgproxy:
    image: darthsim/imgproxy:v3.8.0
    container_name: supabase-imgproxy
    restart: unless-stopped
    environment:
      IMGPROXY_BIND: 0.0.0.0:5001
      IMGPROXY_LOCAL_FILESYSTEM_ROOT: /var/lib/storage
      IMGPROXY_USE_ETAG: true
      IMGPROXY_ENABLE_WEBP_DETECTION: true
    volumes:
      - storage_data:/var/lib/storage:ro
    networks:
      - supabase-internal
    healthcheck:
      test: ["CMD", "imgproxy", "health"]
      timeout: 5s
      interval: 5s
      retries: 3

  # Supabase Studio (Admin Dashboard)
  studio:
    image: supabase/studio:20240101-ce42139
    container_name: supabase-studio
    restart: unless-stopped
    depends_on:
      rest:
        condition: service_healthy
    environment:
      STUDIO_PG_META_URL: http://meta:8080
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      DEFAULT_ORGANIZATION_NAME: \${STUDIO_DEFAULT_ORGANIZATION}
      DEFAULT_PROJECT_NAME: \${STUDIO_DEFAULT_PROJECT}
      SUPABASE_URL: \${API_EXTERNAL_URL}
      SUPABASE_REST_URL: \${API_EXTERNAL_URL}/rest/v1/
      SUPABASE_ANON_KEY: \${SUPABASE_ANON_KEY}
      SUPABASE_SERVICE_KEY: \${SUPABASE_SERVICE_ROLE_KEY}
      LOGFLARE_API_KEY: \${SUPABASE_SERVICE_ROLE_KEY}
      LOGFLARE_URL: http://logflare:4000
      NEXT_PUBLIC_ENABLE_LOGS: true
    networks:
      - supabase-internal
      - supabase-public
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/api/health"]
      timeout: 5s
      interval: 5s
      retries: 3

  # Supabase Meta (Database Management)
  meta:
    image: supabase/postgres-meta:v0.68.0
    container_name: supabase-meta
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      PG_META_PORT: 8080
      PG_META_DB_HOST: postgres
      PG_META_DB_PORT: \${POSTGRES_PORT}
      PG_META_DB_NAME: \${POSTGRES_DB}
      PG_META_DB_USER: \${POSTGRES_USER}
      PG_META_DB_PASSWORD: \${POSTGRES_PASSWORD}
    networks:
      - supabase-internal
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      timeout: 5s
      interval: 5s
      retries: 3

  # Kong API Gateway (Proxy & Rate Limiting)
  kong:
    image: kong:3.4.2-alpine
    container_name: supabase-kong
    restart: unless-stopped
    depends_on:
      auth:
        condition: service_healthy
      rest:
        condition: service_healthy
      realtime:
        condition: service_healthy
      storage:
        condition: service_healthy
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /var/lib/kong/kong.yml
      KONG_DNS_ORDER: LAST,A,CNAME
      KONG_PLUGINS: request-size-limiting,cors,key-auth,acl,basic-auth
      KONG_NGINX_PROXY_PROXY_BUFFER_SIZE: 160k
      KONG_NGINX_PROXY_PROXY_BUFFERS: 64 160k
    volumes:
      - ./config/kong.yml:/var/lib/kong/kong.yml:ro
    networks:
      - supabase-public
    ports:
      - "127.0.0.1:8000:8000"
    healthcheck:
      test: ["CMD", "kong", "health"]
      timeout: 5s
      interval: 5s
      retries: 3

volumes:
  postgres_data:
    driver: local
  storage_data:
    driver: local

networks:
  supabase-internal:
    driver: bridge
    internal: true
  supabase-public:
    driver: bridge
EOF

  safe_mv "/tmp/docker-compose-supabase.yml" "$BASE_DIR/services/supabase/docker-compose.yml" "Install Supabase compose file"

  # Create Kong configuration
  log_info "Creating Kong gateway configuration..."
  cat >/tmp/kong.yml <<EOF
_format_version: "3.0"
_transform: true

services:
  - name: auth-v1-open
    url: http://auth:9999/verify
    routes:
      - name: auth-v1-open
        strip_path: true
        paths:
          - /auth/v1/verify
    plugins:
      - name: cors

  - name: auth-v1-open-callback
    url: http://auth:9999/callback
    routes:
      - name: auth-v1-open-callback
        strip_path: true
        paths:
          - /auth/v1/callback
    plugins:
      - name: cors

  - name: auth-v1
    _comment: GoTrue auth endpoints
    url: http://auth:9999/
    routes:
      - name: auth-v1-all
        strip_path: true
        paths:
          - /auth/v1/
    plugins:
      - name: cors

  - name: rest-v1
    _comment: PostgREST
    url: http://rest:3000/
    routes:
      - name: rest-v1-all
        strip_path: true
        paths:
          - /rest/v1/
    plugins:
      - name: cors

  - name: realtime-v1
    _comment: Realtime
    url: http://realtime:4000/socket/
    routes:
      - name: realtime-v1-all
        strip_path: true
        paths:
          - /realtime/v1/
    plugins:
      - name: cors

  - name: storage-v1
    _comment: Storage
    url: http://storage:5000/
    routes:
      - name: storage-v1-all
        strip_path: true
        paths:
          - /storage/v1/
    plugins:
      - name: cors

  - name: meta-v1
    _comment: pg-meta
    url: http://meta:8080/
    routes:
      - name: meta-v1-all
        strip_path: true
        paths:
          - /pg/
    plugins:
      - name: cors

consumers: []

plugins:
  - name: cors
    config:
      origins:
        - https://${DOMAIN}
        - https://${SUPABASE_SUBDOMAIN}.${DOMAIN}
        - https://${STUDIO_SUBDOMAIN}.${DOMAIN}
      methods:
        - GET
        - HEAD
        - PUT
        - PATCH  
        - POST
        - DELETE
        - OPTIONS
      headers:
        - Accept
        - Accept-Version
        - Content-Length
        - Content-MD5
        - Content-Type
        - Date
        - Authorization
        - X-Client-Info
        - apikey
        - x-requested-with
      credentials: true
      max_age: 3600
EOF

  safe_mv "/tmp/kong.yml" "$BASE_DIR/services/supabase/config/kong.yml" "Install Kong configuration"

  # Start Supabase services
  log_info "Starting Supabase containers..."
  docker_cmd "cd $BASE_DIR/services/supabase && docker-compose --env-file .env up -d"

  # Wait for services to be healthy
  log_info "Waiting for Supabase services to be ready..."
  sleep 30

  # Verify Supabase is running
  if docker_cmd "docker-compose -f $BASE_DIR/services/supabase/docker-compose.yml ps | grep -q 'Up'"; then
    log_success "Supabase stack deployed successfully"
    log_info "Supabase API: https://${SUPABASE_SUBDOMAIN}.${DOMAIN}"
    log_info "Supabase Studio: https://${STUDIO_SUBDOMAIN}.${DOMAIN}"
  else
    log_error "Supabase deployment failed"
    docker_cmd "cd $BASE_DIR/services/supabase && docker-compose logs"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 N8N WORKFLOW AUTOMATION SETUP
# ═══════════════════════════════════════════════════════════════════════════════

setup_n8n_container() {
  log_section "Setting up N8N Workflow Automation"

  # Generate N8N encryption key
  local n8n_encryption_key=$(openssl rand -hex 16)
  local n8n_db_password=$(openssl rand -base64 32 | tr -d '\n')

  # Create N8N environment file (environment-aware)
  log_info "Creating N8N configuration..."

  # Determine SSL configuration for N8N database
  local n8n_ssl_config=""
  if [ "$DEPLOYMENT_ENVIRONMENT" != "development" ] && [ "$ENABLE_DEVELOPMENT_MODE" != "true" ] && [ "$ENABLE_INTERNAL_SSL" = "true" ]; then
    log_info "Production mode: N8N with SSL database configuration"
    n8n_ssl_config="
# SSL Database Configuration
DB_POSTGRESDB_SSL=true
DB_POSTGRESDB_SSL_MODE=require
DB_POSTGRESDB_SSL_CERT=/certs/n8n-client.pem
DB_POSTGRESDB_SSL_KEY=/certs/n8n-client-key.pem
DB_POSTGRESDB_SSL_CA=/certs/internal-ca.pem"
  else
    log_info "Development mode: N8N without SSL database configuration"
  fi

  cat >/tmp/n8n.env <<EOF
# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=n8n-postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=$n8n_db_password$n8n_ssl_config

# N8N Configuration
N8N_HOST=${N8N_SUBDOMAIN}.${DOMAIN}
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://${N8N_SUBDOMAIN}.${DOMAIN}
N8N_EDITOR_BASE_URL=https://${N8N_SUBDOMAIN}.${DOMAIN}

# Security
N8N_ENCRYPTION_KEY=$n8n_encryption_key
N8N_USER_MANAGEMENT_DISABLED=false
N8N_USER_MANAGEMENT_JWT_SECRET=$n8n_encryption_key
N8N_SECURE_COOKIE=true

# Performance
EXECUTIONS_PROCESS=main
EXECUTIONS_MODE=regular
N8N_METRICS=true

# Logging
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console

# Files & Uploads
N8N_PAYLOAD_SIZE_MAX=16
N8N_PERSISTED_BINARY_DATA_TTL=1440



# Timezone
GENERIC_TIMEZONE=UTC

# Custom CA certificates
NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/custom-ca.crt
EOF

  safe_mv "/tmp/n8n.env" "$BASE_DIR/services/n8n/.env" "Install N8N environment"
  safe_chmod "600" "$BASE_DIR/services/n8n/.env" "Secure N8N environment"

  # Create N8N Docker Compose (environment-aware)
  log_info "Creating N8N Docker Compose configuration..."

  # Determine N8N PostgreSQL configuration based on environment
  local n8n_postgres_volumes="      - n8n_postgres_data:/var/lib/postgresql/data"
  local n8n_postgres_command=""
  local n8n_db_uri="postgresql://\${DB_POSTGRESDB_USER}:\${DB_POSTGRESDB_PASSWORD}@\${DB_POSTGRESDB_HOST}:\${DB_POSTGRESDB_PORT}/\${DB_POSTGRESDB_DATABASE}"

  if [ "$DEPLOYMENT_ENVIRONMENT" != "development" ] && [ "$ENABLE_DEVELOPMENT_MODE" != "true" ] && [ "$ENABLE_INTERNAL_SSL" = "true" ]; then
    log_info "Production mode: Configuring N8N with internal SSL"
    n8n_postgres_volumes="$n8n_postgres_volumes
      - ../certs/services/n8n-postgres.pem:/var/lib/postgresql/server.crt:ro
      - ../certs/services/n8n-postgres-key.pem:/var/lib/postgresql/server.key:ro
      - ../certs/ca/internal-ca.pem:/var/lib/postgresql/ca.crt:ro"
    n8n_postgres_command="    command: postgres -c ssl=on -c ssl_cert_file=/var/lib/postgresql/server.crt -c ssl_key_file=/var/lib/postgresql/server.key -c ssl_ca_file=/var/lib/postgresql/ca.crt"
    n8n_db_uri="postgresql://\${DB_POSTGRESDB_USER}:\${DB_POSTGRESDB_PASSWORD}@\${DB_POSTGRESDB_HOST}:\${DB_POSTGRESDB_PORT}/\${DB_POSTGRESDB_DATABASE}?sslmode=require&sslcert=/certs/n8n-client.pem&sslkey=/certs/n8n-client-key.pem&sslrootcert=/certs/internal-ca.pem"
  else
    log_info "Development mode: N8N without internal SSL"
  fi

  cat >/tmp/docker-compose-n8n.yml <<EOF
version: '3.8'
name: n8n

services:
  # PostgreSQL Database for N8N
  n8n-postgres:
    image: postgres:15-alpine
    container_name: n8n-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: \${DB_POSTGRESDB_DATABASE}
      POSTGRES_USER: \${DB_POSTGRESDB_USER}
      POSTGRES_PASSWORD: \${DB_POSTGRESDB_PASSWORD}
    volumes:
$n8n_postgres_volumes
    networks:
      - n8n-internal
$n8n_postgres_command
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_POSTGRESDB_USER} -d \${DB_POSTGRESDB_DATABASE}"]
      interval: 30s
      timeout: 10s
      retries: 3

  # N8N Application
  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n-app
    restart: unless-stopped
    depends_on:
      n8n-postgres:
        condition: service_healthy
    environment:
      # Database
      DB_TYPE: \${DB_TYPE}
      DB_POSTGRESDB_HOST: \${DB_POSTGRESDB_HOST}
      DB_POSTGRESDB_PORT: \${DB_POSTGRESDB_PORT}
      DB_POSTGRESDB_DATABASE: \${DB_POSTGRESDB_DATABASE}
      DB_POSTGRESDB_USER: \${DB_POSTGRESDB_USER}
      DB_POSTGRESDB_PASSWORD: \${DB_POSTGRESDB_PASSWORD}
      
      # N8N Settings
      N8N_HOST: \${N8N_HOST}
      N8N_PORT: \${N8N_PORT}
      N8N_PROTOCOL: \${N8N_PROTOCOL}
      WEBHOOK_URL: \${WEBHOOK_URL}
      N8N_EDITOR_BASE_URL: \${N8N_EDITOR_BASE_URL}
      
      # Security
      N8N_ENCRYPTION_KEY: \${N8N_ENCRYPTION_KEY}
      N8N_USER_MANAGEMENT_DISABLED: \${N8N_USER_MANAGEMENT_DISABLED}
      N8N_USER_MANAGEMENT_JWT_SECRET: \${N8N_USER_MANAGEMENT_JWT_SECRET}
      N8N_SECURE_COOKIE: \${N8N_SECURE_COOKIE}
      
      # Performance
      EXECUTIONS_PROCESS: \${EXECUTIONS_PROCESS}
      EXECUTIONS_MODE: \${EXECUTIONS_MODE}
      N8N_METRICS: \${N8N_METRICS}
      
      # Logging
      N8N_LOG_LEVEL: \${N8N_LOG_LEVEL}
      N8N_LOG_OUTPUT: \${N8N_LOG_OUTPUT}
      
      # Files
      N8N_PAYLOAD_SIZE_MAX: \${N8N_PAYLOAD_SIZE_MAX}
      N8N_PERSISTED_BINARY_DATA_TTL: \${N8N_PERSISTED_BINARY_DATA_TTL}
      
      
      # Timezone
      GENERIC_TIMEZONE: \${GENERIC_TIMEZONE}
      TZ: UTC
      
EOF

  # Add environment-specific configuration for N8N volumes
  if [ "$DEPLOYMENT_ENVIRONMENT" != "development" ] && [ "$ENABLE_DEVELOPMENT_MODE" != "true" ] && [ "$ENABLE_INTERNAL_SSL" = "true" ]; then
    log_info "Production mode: Adding SSL certificate volumes to N8N"
    cat >>/tmp/docker-compose-n8n.yml <<EOF
    volumes:
      - n8n_data:/home/node/.n8n
      - n8n_files:/files
      - ../certs/clients:/certs:ro
      - ../certs/ca:/certs:ro
EOF
  else
    log_info "Development mode: N8N without certificate volumes"
    cat >>/tmp/docker-compose-n8n.yml <<EOF
    volumes:
      - n8n_data:/home/node/.n8n
      - n8n_files:/files
EOF
  fi

  # Continue with N8N configuration
  cat >>/tmp/docker-compose-n8n.yml <<EOF
    networks:
      - n8n-internal
      - n8n-public
    ports:
      - "127.0.0.1:5678:5678"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      timeout: 5s
      interval: 30s
      retries: 3
    user: "1000:1000"

volumes:
  n8n_postgres_data:
    driver: local
  n8n_data:
    driver: local
  n8n_files:
    driver: local

networks:
  n8n-internal:
    driver: bridge
    internal: true
  n8n-public:
    driver: bridge
EOF

  safe_mv "/tmp/docker-compose-n8n.yml" "$BASE_DIR/services/n8n/docker-compose.yml" "Install N8N compose file"

  # Set up data directory permissions
  execute_cmd "sudo -u $SERVICE_USER mkdir -p $BASE_DIR/services/n8n/data/files" "Create N8N data directories"
  safe_chown "-R 1000:1000" "$BASE_DIR/services/n8n/data" "Set N8N data permissions"

  # Start N8N services
  log_info "Starting N8N containers..."
  docker_cmd "cd $BASE_DIR/services/n8n && docker-compose --env-file .env up -d"

  # Wait for N8N to be ready
  log_info "Waiting for N8N to be ready..."
  sleep 45

  # Verify N8N is running
  if docker_cmd "docker-compose -f $BASE_DIR/services/n8n/docker-compose.yml ps | grep -q 'Up'"; then
    log_success "N8N deployed successfully"
    log_info "N8N available at: https://${N8N_SUBDOMAIN}.${DOMAIN}"
    log_info "Complete setup by creating your first admin user through the web interface"
  else
    log_error "N8N deployment failed"
    docker_cmd "cd $BASE_DIR/services/n8n && docker-compose logs"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 NGINX REVERSE PROXY SETUP
# ═══════════════════════════════════════════════════════════════════════════════

setup_nginx_container() {
  log_section "Setting up NGINX Reverse Proxy"

  # Create main nginx configuration
  log_info "Creating NGINX configuration..."
  cat >/tmp/nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# Performance optimizations
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    # Basic settings
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Performance settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=login:10m rate=1r/s;
    
    # Logging format
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

  safe_mv "/tmp/nginx.conf" "$BASE_DIR/services/nginx/conf/nginx.conf" "Install main NGINX config"

  # Create Supabase API proxy configuration
  cat >/tmp/supabase.conf <<EOF
# Supabase API (supabase.domain.com)
server {
    listen 80;
    server_name ${SUPABASE_SUBDOMAIN}.${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${SUPABASE_SUBDOMAIN}.${DOMAIN};
    
    # SSL certificates (will be added by certbot)
    ssl_certificate /etc/letsencrypt/live/${SUPABASE_SUBDOMAIN}.${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${SUPABASE_SUBDOMAIN}.${DOMAIN}/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options SAMEORIGIN;
    
    # ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Supabase API proxy
    location / {
        # Rate limiting for API calls
        limit_req zone=api burst=50 nodelay;
        
        # Proxy settings
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 16k;
        proxy_buffers 8 16k;
    }
}
EOF

  safe_mv "/tmp/supabase.conf" "$BASE_DIR/services/nginx/conf/conf.d/supabase.conf" "Install Supabase proxy config"

  # Create Supabase Studio proxy configuration
  cat >/tmp/studio.conf <<EOF
# Supabase Studio (studio.domain.com)
server {
    listen 80;
    server_name ${STUDIO_SUBDOMAIN}.${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${STUDIO_SUBDOMAIN}.${DOMAIN};
    
    # SSL certificates (will be added by certbot)
    ssl_certificate /etc/letsencrypt/live/${STUDIO_SUBDOMAIN}.${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${STUDIO_SUBDOMAIN}.${DOMAIN}/privkey.pem;
    
    # Security headers for admin interface
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' https:; img-src 'self' data: https:; connect-src 'self' https: wss:";
    
    # ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Studio proxy with authentication rate limiting
    location / {
        limit_req zone=login burst=5 nodelay;
        
        # Proxy to Supabase Studio container
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support for live features
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Extended timeouts for admin operations
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
EOF

  safe_mv "/tmp/studio.conf" "$BASE_DIR/services/nginx/conf/conf.d/studio.conf" "Install Studio proxy config"

  # Create N8N proxy configuration
  cat >/tmp/n8n.conf <<EOF
# N8N Workflow Automation (n8n.domain.com)
server {
    listen 80;
    server_name ${N8N_SUBDOMAIN}.${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${N8N_SUBDOMAIN}.${DOMAIN};
    
    # SSL certificates (will be added by certbot)
    ssl_certificate /etc/letsencrypt/live/${N8N_SUBDOMAIN}.${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${N8N_SUBDOMAIN}.${DOMAIN}/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options SAMEORIGIN;
    
    # ACME challenge  
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # N8N application proxy
    location / {
        # Rate limiting for workflow execution
        limit_req zone=api burst=20 nodelay;
        
        # Proxy settings
        proxy_pass http://127.0.0.1:5678;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support for real-time features
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Extended timeouts for long-running workflows
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # Large payload support for file uploads
        client_max_body_size 50M;
    }
    
    # Webhook endpoint with higher rate limit
    location /webhook/ {
        limit_req zone=api burst=100 nodelay;
        
        proxy_pass http://127.0.0.1:5678;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # No timeout for webhooks
        proxy_read_timeout 0;
        proxy_send_timeout 0;
    }
}
EOF

  safe_mv "/tmp/n8n.conf" "$BASE_DIR/services/nginx/conf/conf.d/n8n.conf" "Install N8N proxy config"

  # Create main domain configuration
  cat >/tmp/main.conf <<EOF
# Main domain (${DOMAIN})
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};
    
    # SSL certificates (will be added by certbot)
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Default location - serve static site or redirect
    location / {
        root /var/www/html;
        index index.html index.htm;
        try_files \$uri \$uri/ =404;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

  safe_mv "/tmp/main.conf" "$BASE_DIR/services/nginx/conf/conf.d/main.conf" "Install main domain config"

  # Create NGINX Docker Compose
  log_info "Creating NGINX Docker Compose configuration..."
  cat >/tmp/docker-compose-nginx.yml <<EOF
version: '3.8'
name: nginx

services:
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      # NGINX configuration
      - ./conf/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./conf/conf.d:/etc/nginx/conf.d:ro
      
      # SSL certificates from certbot
      - ../certbot/conf:/etc/letsencrypt:ro
      - ../certbot/www:/var/www/certbot:ro
      
      # Static files
      - /var/www/html:/var/www/html:ro
      
      # Logs
      - ./logs:/var/log/nginx
      
    networks:
      - nginx-public
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      timeout: 5s
      interval: 30s
      retries: 3
    depends_on:
      - certbot

  # Certbot for SSL certificates (defined in next function)
  certbot:
    image: certbot/certbot
    container_name: nginx-certbot
    restart: "no"
    volumes:
      - ../certbot/conf:/etc/letsencrypt
      - ../certbot/www:/var/www/certbot
    command: certonly --webroot --webroot-path=/var/www/certbot --email $EMAIL --agree-tos --no-eff-email --keep-until-expiring -d ${DOMAIN} -d ${SUPABASE_SUBDOMAIN}.${DOMAIN} -d ${STUDIO_SUBDOMAIN}.${DOMAIN} -d ${N8N_SUBDOMAIN}.${DOMAIN}

networks:
  nginx-public:
    driver: bridge
EOF

  safe_mv "/tmp/docker-compose-nginx.yml" "$BASE_DIR/services/nginx/docker-compose.yml" "Install NGINX compose file"

  # Create simple index page
  log_info "Creating default index page..."
  cat >/tmp/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${DOMAIN} - Production Stack</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; }
        .container { max-width: 800px; margin: 0 auto; }
        .service-links { margin-top: 50px; }
        .service-links a { display: inline-block; margin: 10px; padding: 10px 20px; 
                          background: #007bff; color: white; text-decoration: none; border-radius: 5px; }
        .service-links a:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to ${DOMAIN}</h1>
        <p>Production containerized stack is running successfully!</p>
        
        <div class="service-links">
            <h3>Available Services:</h3>
            <a href="https://${SUPABASE_SUBDOMAIN}.${DOMAIN}" target="_blank">Supabase API</a>
            <a href="https://${STUDIO_SUBDOMAIN}.${DOMAIN}" target="_blank">Supabase Studio</a>
            <a href="https://${N8N_SUBDOMAIN}.${DOMAIN}" target="_blank">N8N Automation</a>
        </div>
        
        <p style="margin-top: 50px; color: #666;">
            <small>Deployed with enhanced security, monitoring, and backup systems.</small>
        </p>
    </div>
</body>
</html>
EOF

  execute_cmd "sudo mkdir -p /var/www/html" "Create web root"
  safe_mv "/tmp/index.html" "/var/www/html/index.html" "Install index page"

  log_success "NGINX reverse proxy configuration completed"
  log_info "NGINX will be started after SSL certificates are obtained"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔐 SSL CERTIFICATES SETUP
# ═══════════════════════════════════════════════════════════════════════════════

setup_ssl_certificates() {
  log_section "Setting up Let's Encrypt SSL Certificates"

  # Create Certbot Docker Compose
  log_info "Creating Certbot configuration..."
  cat >/tmp/docker-compose-certbot.yml <<EOF
version: '3.8'
name: certbot

services:
  certbot:
    image: certbot/certbot:latest
    container_name: letsencrypt-certbot
    restart: "no"
    volumes:
      - certbot_conf:/etc/letsencrypt
      - certbot_www:/var/www/certbot
      - certbot_logs:/var/log/letsencrypt
    networks:
      - certbot-network

volumes:
  certbot_conf:
    driver: local
  certbot_www:
    driver: local
  certbot_logs:
    driver: local

networks:
  certbot-network:
    driver: bridge
EOF

  safe_mv "/tmp/docker-compose-certbot.yml" "$BASE_DIR/services/certbot/docker-compose.yml" "Install Certbot compose file"

  # Create certificate request script
  log_info "Creating certificate request script..."
  cat >/tmp/request-certificates.sh <<EOF
#!/bin/bash

# Certificate request script
DOMAINS="${DOMAIN} ${SUPABASE_SUBDOMAIN}.${DOMAIN} ${STUDIO_SUBDOMAIN}.${DOMAIN} ${N8N_SUBDOMAIN}.${DOMAIN}"
EMAIL="$EMAIL"

echo "Requesting SSL certificates for: \$DOMAINS"

# Start temporary nginx for HTTP challenge
docker run --rm --name temp-nginx \\
  -p 80:80 \\
  -v \$(pwd)/../certbot/www:/var/www/certbot \\
  -d nginx:alpine \\
  /bin/sh -c "echo 'server { listen 80; location /.well-known/acme-challenge/ { root /var/www/certbot; } location / { return 404; } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"

# Wait for nginx to start
sleep 5

# Request certificates for each domain
for domain in \$DOMAINS; do
  echo "Requesting certificate for \$domain..."
  
  docker run --rm --name certbot \\
    -v \$(pwd)/../certbot/conf:/etc/letsencrypt \\
    -v \$(pwd)/../certbot/www:/var/www/certbot \\
    -v \$(pwd)/../certbot/logs:/var/log/letsencrypt \\
    certbot/certbot certonly \\
      --webroot \\
      --webroot-path=/var/www/certbot \\
      --email \$EMAIL \\
      --agree-tos \\
      --no-eff-email \\
      --keep-until-expiring \\
      --rsa-key-size 4096 \\
      --staple-ocsp \\
      -d \$domain
      
  if [ \$? -eq 0 ]; then
    echo "✅ Certificate obtained for \$domain"
  else
    echo "❌ Failed to obtain certificate for \$domain"
    
    # In production mode, fail fast on SSL certificate errors
    if [ "\${DEPLOYMENT_ENVIRONMENT:-production}" = "production" ] && [ "\${ENABLE_DEVELOPMENT_MODE:-false}" != "true" ]; then
      echo "🔴 CRITICAL: SSL certificate acquisition failed in production mode"
      echo "Production deployment cannot continue without valid SSL certificates"
      echo "Please check:"
      echo "  - Domain DNS configuration points to this server"
      echo "  - Port 80 is accessible from the internet"
      echo "  - No other web server is running on port 80"
      echo "  - Domain validation challenges can be completed"
      exit 1
    else
      echo "⚠️  WARNING: SSL certificate failed in development mode - continuing with HTTP only"
      echo "This is acceptable for development but NOT for production use"
    fi
  fi
done

# Stop temporary nginx
docker stop temp-nginx 2>/dev/null || true

echo "Certificate request completed"
EOF

  safe_mv "/tmp/request-certificates.sh" "$BASE_DIR/services/certbot/request-certificates.sh" "Install certificate request script"
  safe_chmod "+x" "$BASE_DIR/services/certbot/request-certificates.sh" "Make script executable"

  # Create renewal script
  log_info "Creating certificate renewal script..."
  cat >/tmp/renew-certificates.sh <<EOF
#!/bin/bash

echo "Renewing SSL certificates..."

# Renew certificates
docker run --rm --name certbot-renew \\
  -v \$(pwd)/../certbot/conf:/etc/letsencrypt \\
  -v \$(pwd)/../certbot/www:/var/www/certbot \\
  -v \$(pwd)/../certbot/logs:/var/log/letsencrypt \\
  certbot/certbot renew \\
    --webroot \\
    --webroot-path=/var/www/certbot \\
    --quiet

if [ \$? -eq 0 ]; then
  echo "✅ Certificate renewal completed"
  
  # Reload nginx to use new certificates
  if docker ps --format "table {{.Names}}" | grep -q "nginx-proxy"; then
    echo "Reloading NGINX to use renewed certificates..."
    docker exec nginx-proxy nginx -s reload
    echo "✅ NGINX reloaded"
  fi
else
  echo "❌ Certificate renewal failed"
  exit 1
fi
EOF

  safe_mv "/tmp/renew-certificates.sh" "$BASE_DIR/services/certbot/renew-certificates.sh" "Install renewal script"
  safe_chmod "+x" "$BASE_DIR/services/certbot/renew-certificates.sh" "Make renewal script executable"

  # Create systemd timer for auto-renewal
  log_info "Setting up automatic certificate renewal..."
  cat >/tmp/certbot-renewal.service <<EOF
[Unit]
Description=Certbot Renewal Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
User=$SERVICE_USER
WorkingDirectory=$BASE_DIR/services/certbot
ExecStart=$BASE_DIR/services/certbot/renew-certificates.sh
StandardOutput=journal
StandardError=journal
EOF

  cat >/tmp/certbot-renewal.timer <<EOF
[Unit]
Description=Run Certbot renewal twice daily
Requires=certbot-renewal.service

[Timer]
OnCalendar=*-*-* 00,12:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

  safe_mv "/tmp/certbot-renewal.service" "/etc/systemd/system/certbot-renewal.service" "Install renewal service"
  safe_mv "/tmp/certbot-renewal.timer" "/etc/systemd/system/certbot-renewal.timer" "Install renewal timer"
  execute_cmd "sudo systemctl daemon-reload" "Reload systemd"
  execute_cmd "sudo systemctl enable certbot-renewal.timer" "Enable renewal timer"
  execute_cmd "sudo systemctl start certbot-renewal.timer" "Start renewal timer"

  # Request initial certificates
  log_info "Requesting initial SSL certificates..."
  if docker_cmd "cd $BASE_DIR/services/certbot && ./request-certificates.sh"; then
    log_success "SSL certificates obtained successfully"

    # Start NGINX with SSL
    log_info "Starting NGINX with SSL configuration..."
    if docker_cmd "cd $BASE_DIR/services/nginx && docker-compose up -d"; then
      log_success "NGINX started with SSL certificates"
    else
      log_error "Failed to start NGINX with SSL"
      return 1
    fi
  else
    log_error "Failed to obtain SSL certificates"
    log_info "Starting NGINX in HTTP-only mode for troubleshooting..."

    # Create temporary HTTP-only configuration
    cat >/tmp/nginx-temp.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN} ${SUPABASE_SUBDOMAIN}.${DOMAIN} ${STUDIO_SUBDOMAIN}.${DOMAIN} ${N8N_SUBDOMAIN}.${DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 503 "SSL setup in progress";
    }
}
EOF

    safe_mv "/tmp/nginx-temp.conf" "$BASE_DIR/services/nginx/conf/conf.d/temp.conf" "Install temporary config"
    docker_cmd "cd $BASE_DIR/services/nginx && docker-compose up -d nginx" || true

    log_warning "NGINX started in HTTP-only mode. Please check domain DNS and firewall settings."
    return 1
  fi

  # Verify SSL setup
  log_info "Verifying SSL certificate installation..."
  sleep 10

  for subdomain in "${SUPABASE_SUBDOMAIN}" "${STUDIO_SUBDOMAIN}" "${N8N_SUBDOMAIN}"; do
    if command -v curl >/dev/null 2>&1; then
      if curl -s -I "https://${subdomain}.${DOMAIN}" | grep -q "200\|301\|302"; then
        log_success "SSL verified for ${subdomain}.${DOMAIN}"
      else
        log_warning "SSL verification failed for ${subdomain}.${DOMAIN}"
      fi
    fi
  done

  log_success "SSL certificate setup completed"
  log_info "Certificates will be automatically renewed twice daily"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔐 INTERNAL SSL CERTIFICATE MANAGEMENT (PRODUCTION ONLY)
# ═══════════════════════════════════════════════════════════════════════════════

setup_internal_ssl_infrastructure() {
  # Skip internal SSL in development mode
  if [ "$DEPLOYMENT_ENVIRONMENT" = "development" ] || [ "$ENABLE_DEVELOPMENT_MODE" = "true" ]; then
    log_info "Development mode: Skipping internal SSL certificate setup"
    return 0
  fi

  if [ "$ENABLE_INTERNAL_SSL" != "true" ]; then
    log_info "Internal SSL disabled - skipping certificate infrastructure setup"
    return 0
  fi

  log_section "Setting up Internal SSL Certificate Infrastructure"

  # Create certificate directories
  local cert_dir="$BASE_DIR/services/certs"
  execute_cmd "sudo -u $SERVICE_USER mkdir -p $cert_dir/ca $cert_dir/services $cert_dir/clients" "Create certificate directories"
  safe_chmod "700" "$cert_dir" "Secure certificate directory"

  # Check if internal CA already exists
  if [ -f "$cert_dir/ca/internal-ca.pem" ] && [ -f "$cert_dir/ca/internal-ca-key.pem" ]; then
    log_info "Internal Certificate Authority already exists"

    # Verify CA certificate is still valid (not expiring within 30 days)
    if openssl x509 -in "$cert_dir/ca/internal-ca.pem" -checkend 2592000 >/dev/null 2>&1; then
      log_success "Internal CA certificate is valid"
      return 0
    else
      log_warning "Internal CA certificate expires soon, regenerating..."
    fi
  fi

  # Generate Internal Certificate Authority
  log_info "Creating Internal Certificate Authority..."

  # Generate CA private key
  execute_cmd "sudo -u $SERVICE_USER openssl genrsa -out $cert_dir/ca/internal-ca-key.pem 4096" "Generate CA private key"

  # Create CA certificate
  cat >/tmp/ca-config.conf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
C = $COUNTRY_CODE
ST = $STATE_NAME
L = $CITY_NAME
O = $ORGANIZATION
OU = Internal Services Certificate Authority
CN = $DOMAIN Internal CA

[v3_ca]
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
nsComment = "Internal Certificate Authority for $DOMAIN"
EOF

  execute_cmd "sudo -u $SERVICE_USER openssl req -new -x509 -sha256 -days 3650 -key $cert_dir/ca/internal-ca-key.pem -out $cert_dir/ca/internal-ca.pem -config /tmp/ca-config.conf" "Create CA certificate"
  execute_cmd "rm -f /tmp/ca-config.conf" "Clean up CA config"

  # Set proper permissions on CA files
  safe_chmod "600" "$cert_dir/ca/internal-ca-key.pem" "Secure CA private key"
  safe_chmod "644" "$cert_dir/ca/internal-ca.pem" "Set CA certificate permissions"

  log_success "Internal Certificate Authority created successfully"

  # Create service certificates
  create_internal_service_certificates
}

create_internal_service_certificates() {
  local cert_dir="$BASE_DIR/services/certs"

  log_info "Generating internal service certificates..."

  # List of services that need certificates
  local services=(
    "supabase-postgres:postgres,supabase-postgres,localhost"
    "supabase-kong:kong,supabase-kong,localhost"
    "n8n-postgres:n8n-postgres,postgres,localhost"
    "postgrest:rest,postgrest,supabase-rest,localhost"
    "gotrue:auth,gotrue,supabase-auth,localhost"
    "realtime:realtime,supabase-realtime,localhost"
    "storage:storage,supabase-storage,localhost"
  )

  for service_entry in "${services[@]}"; do
    IFS=':' read -r service_name dns_names <<<"$service_entry"
    create_service_certificate "$service_name" "$dns_names" "$cert_dir"
  done

  # Create client certificates for service-to-service communication
  create_client_certificate "postgres-client" "postgres" "$cert_dir"
  create_client_certificate "n8n-client" "n8n" "$cert_dir"

  log_success "All internal service certificates generated"
}

create_service_certificate() {
  local service_name="$1"
  local dns_names="$2"
  local cert_dir="$3"

  log_info "Creating certificate for service: $service_name"

  # Generate private key
  execute_cmd "sudo -u $SERVICE_USER openssl genrsa -out $cert_dir/services/${service_name}-key.pem 4096" "Generate $service_name private key"

  # Create certificate configuration
  cat >/tmp/service-cert-config.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = $COUNTRY_CODE
ST = $STATE_NAME
L = $CITY_NAME
O = $ORGANIZATION
OU = Internal Services
CN = $service_name

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
nsComment = "Internal Service Certificate for $service_name"

[alt_names]
EOF

  # Add DNS names to certificate
  local dns_count=1
  IFS=',' read -ra DNS_ARRAY <<<"$dns_names"
  for dns in "${DNS_ARRAY[@]}"; do
    echo "DNS.${dns_count} = $dns" >>/tmp/service-cert-config.conf
    ((dns_count++))
  done
  echo "IP.1 = 127.0.0.1" >>/tmp/service-cert-config.conf

  # Generate certificate signing request
  execute_cmd "sudo -u $SERVICE_USER openssl req -new -key $cert_dir/services/${service_name}-key.pem -out /tmp/${service_name}.csr -config /tmp/service-cert-config.conf" "Generate $service_name CSR"

  # Sign certificate with internal CA
  execute_cmd "sudo -u $SERVICE_USER openssl x509 -req -sha256 -days 365 -in /tmp/${service_name}.csr -CA $cert_dir/ca/internal-ca.pem -CAkey $cert_dir/ca/internal-ca-key.pem -CAcreateserial -out $cert_dir/services/${service_name}.pem -extensions v3_req -extfile /tmp/service-cert-config.conf" "Sign $service_name certificate"

  # Set proper permissions
  safe_chmod "600" "$cert_dir/services/${service_name}-key.pem" "Secure $service_name private key"
  safe_chmod "644" "$cert_dir/services/${service_name}.pem" "Set $service_name certificate permissions"

  # Clean up temporary files
  execute_cmd "rm -f /tmp/${service_name}.csr /tmp/service-cert-config.conf" "Clean up temporary files"

  # Verify certificate
  if execute_cmd "sudo -u $SERVICE_USER openssl verify -CAfile $cert_dir/ca/internal-ca.pem $cert_dir/services/${service_name}.pem" "Verify $service_name certificate"; then
    log_success "Certificate created and verified for $service_name"
  else
    log_error "Certificate verification failed for $service_name"
    return 1
  fi
}

create_client_certificate() {
  local client_name="$1"
  local service_name="$2"
  local cert_dir="$3"

  log_info "Creating client certificate: $client_name"

  # Generate client private key
  execute_cmd "sudo -u $SERVICE_USER openssl genrsa -out $cert_dir/clients/${client_name}-key.pem 4096" "Generate $client_name private key"

  # Create client certificate configuration
  cat >/tmp/client-cert-config.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = $COUNTRY_CODE
ST = $STATE_NAME
L = $CITY_NAME
O = $ORGANIZATION
OU = Internal Service Clients
CN = $client_name

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
nsComment = "Internal Client Certificate for $client_name"
EOF

  # Generate client CSR and certificate
  execute_cmd "sudo -u $SERVICE_USER openssl req -new -key $cert_dir/clients/${client_name}-key.pem -out /tmp/${client_name}.csr -config /tmp/client-cert-config.conf" "Generate $client_name CSR"
  execute_cmd "sudo -u $SERVICE_USER openssl x509 -req -sha256 -days 365 -in /tmp/${client_name}.csr -CA $cert_dir/ca/internal-ca.pem -CAkey $cert_dir/ca/internal-ca-key.pem -CAcreateserial -out $cert_dir/clients/${client_name}.pem -extensions v3_req -extfile /tmp/client-cert-config.conf" "Sign $client_name certificate"

  # Set permissions
  safe_chmod "600" "$cert_dir/clients/${client_name}-key.pem" "Secure $client_name private key"
  safe_chmod "644" "$cert_dir/clients/${client_name}.pem" "Set $client_name certificate permissions"

  # Clean up
  execute_cmd "rm -f /tmp/${client_name}.csr /tmp/client-cert-config.conf" "Clean up temporary files"

  log_success "Client certificate created for $client_name"
}

setup_internal_ssl_rotation() {
  if [ "$DEPLOYMENT_ENVIRONMENT" = "development" ] || [ "$ENABLE_DEVELOPMENT_MODE" = "true" ]; then
    return 0
  fi

  if [ "$ENABLE_INTERNAL_SSL" != "true" ]; then
    return 0
  fi

  log_info "Setting up internal certificate rotation..."

  # Create certificate rotation script
  cat >/tmp/rotate-internal-certs.sh <<'EOF'
#!/bin/bash

CERT_DIR="$(dirname "$0")/../certs"
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../scripts/common-functions.sh"

log_info "Checking internal certificate expiration..."

# Check if any service certificates expire within 30 days
ROTATE_NEEDED=false
for cert_file in "$CERT_DIR/services"/*.pem; do
  if [ -f "$cert_file" ]; then
    if ! openssl x509 -in "$cert_file" -checkend 2592000 >/dev/null 2>&1; then
      log_warning "Certificate $(basename "$cert_file") expires within 30 days"
      ROTATE_NEEDED=true
    fi
  fi
done

if [ "$ROTATE_NEEDED" = "true" ]; then
  log_info "Rotating internal certificates..."
  
  # Call the certificate creation function
  cd "$SCRIPT_DIR/.." 
  ./jj_production_stack.sh --rotate-internal-certs
  
  # Restart services to pick up new certificates
  log_info "Restarting services to use new certificates..."
  cd services/supabase && docker-compose restart postgres kong
  cd ../n8n && docker-compose restart n8n-postgres
  
  log_success "Internal certificate rotation completed"
else
  log_info "Internal certificates are still valid"
fi
EOF

  safe_mv "/tmp/rotate-internal-certs.sh" "$BASE_DIR/scripts/rotate-internal-certs.sh" "Install certificate rotation script"
  safe_chmod "+x" "$BASE_DIR/scripts/rotate-internal-certs.sh" "Make rotation script executable"

  # Create systemd service for rotation
  cat >/tmp/internal-cert-rotation.service <<EOF
[Unit]
Description=Internal Certificate Rotation Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
User=$SERVICE_USER
WorkingDirectory=$BASE_DIR
ExecStart=$BASE_DIR/scripts/rotate-internal-certs.sh
StandardOutput=journal
StandardError=journal
EOF

  cat >/tmp/internal-cert-rotation.timer <<EOF
[Unit]
Description=Run internal certificate rotation monthly
Requires=internal-cert-rotation.service

[Timer]
OnCalendar=monthly
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

  safe_mv "/tmp/internal-cert-rotation.service" "/etc/systemd/system/internal-cert-rotation.service" "Install rotation service"
  safe_mv "/tmp/internal-cert-rotation.timer" "/etc/systemd/system/internal-cert-rotation.timer" "Install rotation timer"
  execute_cmd "sudo systemctl daemon-reload" "Reload systemd"
  execute_cmd "sudo systemctl enable internal-cert-rotation.timer" "Enable rotation timer"
  execute_cmd "sudo systemctl start internal-cert-rotation.timer" "Start rotation timer"

  log_success "Internal certificate rotation scheduled (monthly)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MONITORING STACK (DISABLED)
# ═══════════════════════════════════════════════════════════════════════════════

setup_monitoring_stack() {
  log_info "Monitoring stack disabled - skipping"
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 ENHANCED BACKUP SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

create_enhanced_backup_system() {
  log_section "Creating Enhanced Backup System"

  # Create comprehensive backup script
  cat >/tmp/enhanced-backup.sh <<EOF
#!/bin/bash
# Enhanced Backup System for Containerized Stack
# Supports database consistency, incremental backups, and encryption

set -e

# Configuration
BACKUP_BASE_DIR="$BASE_DIR/backups"
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${DOMAIN}_\${DATE}"
DOCKER_ENV="export PATH=$BASE_DIR/bin:\\\$PATH && export DOCKER_HOST=unix:///run/user/$SERVICE_UID/docker.sock"

# Logging function
log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') [\$1] \$2" | tee -a $BASE_DIR/logs/backup.log
}

log "INFO" "Starting enhanced backup: \$BACKUP_NAME"

# Create backup working directory
BACKUP_DIR="\$BACKUP_BASE_DIR/\$BACKUP_NAME"
mkdir -p "\$BACKUP_DIR"/{database,volumes,configs}

# 1. Database Backup with Consistency
log "INFO" "Creating consistent database backup..."
\$DOCKER_ENV && docker-compose -f $BASE_DIR/services/supabase/docker-compose.yml exec -T db \\
    bash -c "
        # Start backup label for consistency
        psql -U postgres -c \\\"SELECT pg_start_backup('enhanced-backup-\$DATE', true);\\\"
        
        # Create full database dump
        pg_dumpall -U postgres --clean --if-exists > /backup/full_database.sql
        
        # Create individual database dumps
        psql -U postgres -lqt | cut -d \\\\| -f 1 | grep -qw postgres && \\
            pg_dump -U postgres -d postgres --clean --if-exists > /backup/postgres_db.sql
        
        psql -U postgres -lqt | cut -d \\\\| -f 1 | grep -qw n8n && \\
            pg_dump -U postgres -d n8n --clean --if-exists > /backup/n8n_db.sql
        
        
        
        # End backup label
        psql -U postgres -c \\\"SELECT pg_stop_backup();\\\"
    " > "\$BACKUP_DIR/database/full_database.sql" 2>"\$BACKUP_DIR/database/backup.log"

# Copy individual database dumps
\$DOCKER_ENV && docker cp supabase-db:/backup/postgres_db.sql "\$BACKUP_DIR/database/" 2>/dev/null || true
\$DOCKER_ENV && docker cp supabase-db:/backup/n8n_db.sql "\$BACKUP_DIR/database/" 2>/dev/null || true  

log "SUCCESS" "Database backup completed"

# 2. Volume Data Backup
log "INFO" "Backing up volume data..."

# Supabase volumes
if [ -d "$BASE_DIR/services/supabase/volumes" ]; then
    tar -czf "\$BACKUP_DIR/volumes/supabase-volumes.tar.gz" \\
        -C "$BASE_DIR/services/supabase" volumes/ 2>/dev/null || true
fi

# N8N data
if [ -d "$BASE_DIR/services/n8n/data" ]; then
    tar -czf "\$BACKUP_DIR/volumes/n8n-data.tar.gz" \\
        -C "$BASE_DIR/services/n8n" data/ 2>/dev/null || true
fi

# SSL certificates (NGINX)
if [ -d "$BASE_DIR/services/nginx/ssl" ]; then
    tar -czf "\$BACKUP_DIR/volumes/ssl-certs.tar.gz" \\
        -C "$BASE_DIR/services/nginx" ssl/ 2>/dev/null || true
fi

# Internal SSL Certificate Authority (NEW - for newer functions)
if [ -d "$BASE_DIR/ssl" ]; then
    tar -czf "\$BACKUP_DIR/volumes/internal-ssl-ca.tar.gz" \\
        -C "$BASE_DIR" ssl/ 2>/dev/null || true
fi

# GPG encrypted secrets (NEW - for newer functions)
if [ -f "$BASE_DIR/secrets/secrets.env.gpg" ]; then
    cp "$BASE_DIR/secrets/secrets.env.gpg" "\$BACKUP_DIR/volumes/" 2>/dev/null || true
fi


log "SUCCESS" "Volume backup completed"

# 3. Configuration Backup
log "INFO" "Backing up configurations..."

# Docker Compose files
find "$BASE_DIR/services" -name "docker-compose.yml" -exec cp {} "\$BACKUP_DIR/configs/" \\; 2>/dev/null || true

# Service configurations
find "$BASE_DIR/services" -type d -name "config" -exec cp -r {} "\$BACKUP_DIR/configs/" \\; 2>/dev/null || true

# NGINX configuration
cp -r "$BASE_DIR/services/nginx/conf" "\$BACKUP_DIR/configs/nginx-conf" 2>/dev/null || true

# Scripts
cp -r "$BASE_DIR/scripts" "\$BACKUP_DIR/configs/" 2>/dev/null || true

# System configuration (etckeeper)
if [ -d "/etc/.git" ]; then
    sudo sh -c "cd /etc && git bundle create '\$BACKUP_DIR/configs/etc-config.bundle' --all" 2>/dev/null || true
fi

# Enhanced security configurations (NEW - for newer functions)
mkdir -p "\$BACKUP_DIR/configs/security"

# AppArmor profiles
if [ -f "/etc/apparmor.d/docker-default" ]; then
    sudo cp "/etc/apparmor.d/docker-default" "\$BACKUP_DIR/configs/security/" 2>/dev/null || true
fi

# Fail2ban configurations  
if [ -f "/etc/fail2ban/jail.local" ]; then
    sudo cp "/etc/fail2ban/jail.local" "\$BACKUP_DIR/configs/security/" 2>/dev/null || true
fi
if [ -f "/etc/fail2ban/filter.d/docker-auth.conf" ]; then
    sudo cp "/etc/fail2ban/filter.d/docker-auth.conf" "\$BACKUP_DIR/configs/security/" 2>/dev/null || true
fi

# Systemd services and timers (NEW - for newer functions)
mkdir -p "\$BACKUP_DIR/configs/systemd"
sudo cp "/etc/systemd/system/internal-cert-rotation"* "\$BACKUP_DIR/configs/systemd/" 2>/dev/null || true
sudo cp "/etc/systemd/system/certbot-renewal"* "\$BACKUP_DIR/configs/systemd/" 2>/dev/null || true
sudo cp "/etc/systemd/system/container-secrets.service" "\$BACKUP_DIR/configs/systemd/" 2>/dev/null || true

# UFW rules export
sudo ufw status numbered > "\$BACKUP_DIR/configs/security/ufw-rules.txt" 2>/dev/null || true

log "SUCCESS" "Configuration backup completed"

# 4. Create metadata file
cat > "\$BACKUP_DIR/backup-metadata.json" << METADATA_EOF
{
    "backup_name": "\$BACKUP_NAME",
    "domain": "${DOMAIN}",
    "timestamp": "\$(date -Iseconds)",
    "backup_type": "full",
    "encryption": $([ "$BACKUP_ENCRYPTION" = "true" ] && echo "true" || echo "false"),
    "services": {
        "supabase": "\$(docker ps --filter name=supabase --format '{{.Names}}:{{.Status}}' | tr '\\n' ',' | sed 's/,\$//')",
        "n8n": "\$(docker ps --filter name=n8n --format '{{.Names}}:{{.Status}}')",
        "nginx": "\$(docker ps --filter name=nginx --format '{{.Names}}:{{.Status}}')",
    },
    "sizes": {
        "database": "\$(du -sh \\"\$BACKUP_DIR/database\\" | cut -f1)",
        "volumes": "\$(du -sh \\"\$BACKUP_DIR/volumes\\" | cut -f1)",
        "configs": "\$(du -sh \\"\$BACKUP_DIR/configs\\" | cut -f1)"
    }
}
METADATA_EOF

# 5. Create compressed archive
log "INFO" "Creating compressed archive..."
cd "\$BACKUP_BASE_DIR"

if [ "$BACKUP_ENCRYPTION" = "true" ]; then
    tar -c "\$BACKUP_NAME" | gzip -${BACKUP_COMPRESSION_LEVEL} | gpg --symmetric --cipher-algo AES256 --compress-algo 2 --output "\${BACKUP_NAME}.tar.gz.gpg"
    FINAL_BACKUP="\${BACKUP_NAME}.tar.gz.gpg"
    log "SUCCESS" "Encrypted backup created: \$FINAL_BACKUP"
else
    tar -czf "\${BACKUP_NAME}.tar.gz" "\$BACKUP_NAME"
    FINAL_BACKUP="\${BACKUP_NAME}.tar.gz"
    log "SUCCESS" "Backup created: \$FINAL_BACKUP"
fi

# 6. Upload to S3 if configured
if [ -n "$BACKUP_S3_BUCKET" ] && command -v aws >/dev/null 2>&1; then
    log "INFO" "Uploading to S3 bucket: $BACKUP_S3_BUCKET"
    if aws s3 cp "\$FINAL_BACKUP" "s3://$BACKUP_S3_BUCKET/backups/"; then
        log "SUCCESS" "Backup uploaded to S3"
    else
        log "ERROR" "Failed to upload backup to S3"
    fi
fi

# 7. Cleanup old backups (keep only 1 most recent)
log "INFO" "Cleaning up old backups (keeping only 1 most recent)..."

# Remove all but the most recent backup archive
ls -t "\$BACKUP_BASE_DIR"/backup_${DOMAIN}_*.tar.gz* 2>/dev/null | tail -n +2 | xargs -r rm -f

# Remove all but the most recent database backups
if [ -d "\$BACKUP_BASE_DIR/database" ]; then
    ls -t "\$BACKUP_BASE_DIR/database"/*.sql 2>/dev/null | tail -n +2 | xargs -r rm -f
fi

# Remove old working directories
find "\$BACKUP_BASE_DIR" -name "backup_${DOMAIN}_*" -type d -mtime +0 -exec rm -rf {} + 2>/dev/null || true

# Cleanup temporary backup directory
rm -rf "\$BACKUP_DIR"

# Calculate final size
BACKUP_SIZE=\$(du -sh "\$FINAL_BACKUP" | cut -f1)
log "SUCCESS" "Backup completed: \$FINAL_BACKUP (Size: \$BACKUP_SIZE)"

# Send notification if email is configured
if command -v mail >/dev/null 2>&1; then
    echo "Backup completed successfully for ${DOMAIN}
    
Backup Details:
- Name: \$BACKUP_NAME
- Size: \$BACKUP_SIZE
- Location: \$FINAL_BACKUP
- Timestamp: \$(date)

Services backed up:
- Supabase (Database + Volumes)
- N8N (Workflows + Data)
- NGINX (Configuration + SSL)

$([ -n "$BACKUP_S3_BUCKET" ] && echo "✓ Uploaded to S3: $BACKUP_S3_BUCKET")
" | mail -s "[${DOMAIN}] Backup Completed Successfully" "${ALERT_EMAIL}" 2>/dev/null || true
fi
EOF

  safe_mv "/tmp/enhanced-backup.sh" "$BASE_DIR/scripts/enhanced-backup.sh" "Install enhanced backup script"
  safe_chmod "+x" "$BASE_DIR/scripts/enhanced-backup.sh" "Make backup script executable"

  # Create restore script
  cat >/tmp/enhanced-restore.sh <<EOF
#!/bin/bash
# Enhanced Restore System for Containerized Stack

set -e

RESTORE_FILE="\$1"
DOCKER_ENV="export PATH=$BASE_DIR/bin:\\\$PATH && export DOCKER_HOST=unix:///run/user/$SERVICE_UID/docker.sock"

if [ -z "\$RESTORE_FILE" ]; then
    echo "Usage: \$0 <backup-file>"
    echo "Available backups:"
    ls -la $BASE_DIR/backups/backup_${DOMAIN}_*.tar.gz* 2>/dev/null || echo "No backups found"
    exit 1
fi

# Function to log with timestamp
log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') [\$1] \$2" | tee -a $BASE_DIR/logs/restore.log
}

log "INFO" "Starting restore from: \$RESTORE_FILE"

# Confirm restore operation
echo "WARNING: This will restore from backup and may overwrite existing data!"
echo "Backup file: \$RESTORE_FILE"
echo "Continue? (yes/no)"
read -r confirm
if [ "\$confirm" != "yes" ]; then
    log "INFO" "Restore cancelled by user"
    exit 0
fi

# Create temporary restore directory
RESTORE_DIR="/tmp/restore_\$(date +%s)"
mkdir -p "\$RESTORE_DIR"

# Extract backup
log "INFO" "Extracting backup..."
cd "\$RESTORE_DIR"

if [[ "\$RESTORE_FILE" == *.gpg ]]; then
    gpg --decrypt "\$RESTORE_FILE" | tar -xzf -
else
    tar -xzf "\$RESTORE_FILE"
fi

BACKUP_NAME=\$(ls -d backup_*/ | head -n1 | sed 's|/||')
cd "\$BACKUP_NAME"

log "SUCCESS" "Backup extracted"

# Stop services
log "INFO" "Stopping services for restore..."
$BASE_DIR/scripts/stop-all.sh || true

sleep 10

# Restore database
if [ -d "database" ]; then
    log "INFO" "Restoring database..."
    
    # Start only database for restore
    \$DOCKER_ENV && docker-compose -f $BASE_DIR/services/supabase/docker-compose.yml up -d db
    
    # Wait for database to be ready
    sleep 30
    
    # Restore main database
    if [ -f "database/full_database.sql" ]; then
        \$DOCKER_ENV && docker-compose -f $BASE_DIR/services/supabase/docker-compose.yml exec -T db \\
            psql -U postgres < "database/full_database.sql"
    fi
    
    log "SUCCESS" "Database restored"
fi

# Restore volumes
if [ -d "volumes" ]; then
    log "INFO" "Restoring volume data..."
    
    # Stop services to ensure clean restore
    \$DOCKER_ENV && docker-compose -f $BASE_DIR/services/supabase/docker-compose.yml down || true
    \$DOCKER_ENV && docker-compose -f $BASE_DIR/services/n8n/docker-compose.yml down || true
    
    # Restore Supabase volumes
    if [ -f "volumes/supabase-volumes.tar.gz" ]; then
        tar -xzf "volumes/supabase-volumes.tar.gz" -C "$BASE_DIR/services/supabase/"
    fi
    
    # Restore N8N data
    if [ -f "volumes/n8n-data.tar.gz" ]; then
        tar -xzf "volumes/n8n-data.tar.gz" -C "$BASE_DIR/services/n8n/"
    fi
    
    # Restore SSL certificates
    if [ -f "volumes/ssl-certs.tar.gz" ]; then
        tar -xzf "volumes/ssl-certs.tar.gz" -C "$BASE_DIR/services/nginx/"
    fi
    
    # Restore Internal SSL Certificate Authority (NEW)
    if [ -f "volumes/internal-ssl-ca.tar.gz" ]; then
        tar -xzf "volumes/internal-ssl-ca.tar.gz" -C "$BASE_DIR/"
    fi
    
    # Restore GPG encrypted secrets (NEW)
    if [ -f "volumes/secrets.env.gpg" ]; then
        cp "volumes/secrets.env.gpg" "$BASE_DIR/secrets/" 2>/dev/null || true
    fi
    
    # Monitoring restore removed
    fi
    
    log "SUCCESS" "Volumes restored"
fi

# Restore configurations
if [ -d "configs" ]; then
    log "INFO" "Restoring configurations..."
    
    # Backup current configs
    cp -r "$BASE_DIR/services" "$BASE_DIR/services.backup.\$(date +%s)" 2>/dev/null || true
    
    # Restore Docker Compose files
    find "configs" -name "docker-compose.yml" -exec cp {} "$BASE_DIR/services/" \\; 2>/dev/null || true
    
    # Restore NGINX config
    if [ -d "configs/nginx-conf" ]; then
        cp -r "configs/nginx-conf/"* "$BASE_DIR/services/nginx/conf/" 2>/dev/null || true
    fi
    
    # Restore scripts
    if [ -d "configs/scripts" ]; then
        cp -r "configs/scripts/"* "$BASE_DIR/scripts/" 2>/dev/null || true
        chmod +x $BASE_DIR/scripts/*.sh
    fi
    
    # Restore enhanced security configurations (NEW)
    if [ -d "configs/security" ]; then
        # Restore AppArmor profiles
        if [ -f "configs/security/docker-default" ]; then
            sudo cp "configs/security/docker-default" "/etc/apparmor.d/" 2>/dev/null || true
            sudo apparmor_parser -r "/etc/apparmor.d/docker-default" 2>/dev/null || true
        fi
        
        # Restore fail2ban configurations
        if [ -f "configs/security/jail.local" ]; then
            sudo cp "configs/security/jail.local" "/etc/fail2ban/" 2>/dev/null || true
        fi
        if [ -f "configs/security/docker-auth.conf" ]; then
            sudo cp "configs/security/docker-auth.conf" "/etc/fail2ban/filter.d/" 2>/dev/null || true
            sudo systemctl restart fail2ban 2>/dev/null || true
        fi
    fi
    
    # Restore systemd services and timers (NEW)
    if [ -d "configs/systemd" ]; then
        sudo cp configs/systemd/* "/etc/systemd/system/" 2>/dev/null || true
        sudo systemctl daemon-reload
        
        # Enable and start restored services
        sudo systemctl enable internal-cert-rotation.timer 2>/dev/null || true
        sudo systemctl start internal-cert-rotation.timer 2>/dev/null || true
        sudo systemctl enable certbot-renewal.timer 2>/dev/null || true
        sudo systemctl start certbot-renewal.timer 2>/dev/null || true
    fi
    
    log "SUCCESS" "Configurations restored"
fi

# Fix permissions
log "INFO" "Fixing permissions..."
sudo chown -R $SERVICE_USER:$SERVICE_GROUP $BASE_DIR/services
sudo chmod -R 755 $BASE_DIR/services
sudo chmod 600 $BASE_DIR/secrets/secrets.env 2>/dev/null || true

# Start services
log "INFO" "Starting services after restore..."
$BASE_DIR/scripts/start-all.sh

# Cleanup
rm -rf "\$RESTORE_DIR"

log "SUCCESS" "Restore completed successfully"

# Verify services
log "INFO" "Verifying restored services..."
sleep 60

# Check service health
SERVICES_OK=true
if ! docker ps --filter health=healthy --filter name=supabase-db --format '{{.Names}}' | grep -q supabase-db; then
    log "ERROR" "Database health check failed"
    SERVICES_OK=false
fi

if ! docker ps --filter health=healthy --filter name=n8n --format '{{.Names}}' | grep -q n8n; then
    log "WARNING" "N8N health check failed"
fi

if [ "\$SERVICES_OK" = "true" ]; then
    log "SUCCESS" "All critical services are healthy after restore"
else
    log "ERROR" "Some services failed health checks after restore"
    exit 1
fi
EOF

  safe_mv "/tmp/enhanced-restore.sh" "$BASE_DIR/scripts/enhanced-restore.sh" "Install restore script"
  safe_chmod "+x" "$BASE_DIR/scripts/enhanced-restore.sh" "Make restore script executable"

  # Create backup verification script
  cat >/tmp/verify-backup.sh <<EOF
#!/bin/bash
# Backup Verification Script

BACKUP_FILE="\$1"

if [ -z "\$BACKUP_FILE" ]; then
    echo "Usage: \$0 <backup-file>"
    exit 1
fi

echo "Verifying backup: \$BACKUP_FILE"

# Check if file exists and is readable
if [ ! -f "\$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found"
    exit 1
fi

# Create temp directory for verification
VERIFY_DIR="/tmp/verify_\$(date +%s)"
mkdir -p "\$VERIFY_DIR"

echo "Extracting backup for verification..."
cd "\$VERIFY_DIR"

# Extract backup
if [[ "\$BACKUP_FILE" == *.gpg ]]; then
    if ! gpg --decrypt "\$BACKUP_FILE" | tar -tzf - >/dev/null 2>&1; then
        echo "ERROR: Failed to decrypt or extract backup"
        rm -rf "\$VERIFY_DIR"
        exit 1
    fi
    gpg --decrypt "\$BACKUP_FILE" | tar -xzf -
else
    if ! tar -tzf "\$BACKUP_FILE" >/dev/null 2>&1; then
        echo "ERROR: Failed to extract backup"
        rm -rf "\$VERIFY_DIR"
        exit 1
    fi
    tar -xzf "\$BACKUP_FILE"
fi

BACKUP_NAME=\$(ls -d backup_*/ | head -n1 | sed 's|/||')
cd "\$BACKUP_NAME"

echo "Backup contents:"
echo "=================="

# Verify metadata
if [ -f "backup-metadata.json" ]; then
    echo "✓ Metadata file present"
    cat backup-metadata.json | jq . 2>/dev/null || cat backup-metadata.json
else
    echo "✗ Metadata file missing"
fi

# Verify database backup
if [ -d "database" ]; then
    echo "✓ Database backup present"
    echo "  Files: \$(ls database/ | tr '\\n' ' ')"
    echo "  Size: \$(du -sh database | cut -f1)"
else
    echo "✗ Database backup missing"
fi

# Verify volumes
if [ -d "volumes" ]; then
    echo "✓ Volume backups present"
    echo "  Files: \$(ls volumes/ | tr '\\n' ' ')"
    echo "  Size: \$(du -sh volumes | cut -f1)"
else
    echo "✗ Volume backups missing"
fi

# Verify configs
if [ -d "configs" ]; then
    echo "✓ Configuration backups present"
    echo "  Files: \$(find configs -type f | wc -l) files"
    echo "  Size: \$(du -sh configs | cut -f1)"
else
    echo "✗ Configuration backups missing"
fi

# Cleanup
rm -rf "\$VERIFY_DIR"

echo "=================="
echo "Backup verification completed"
EOF

  safe_mv "/tmp/verify-backup.sh" "$BASE_DIR/scripts/verify-backup.sh" "Install backup verification script"
  safe_chmod "+x" "$BASE_DIR/scripts/verify-backup.sh" "Make verification script executable"

  # Set up backup cron job
  log_info "Setting up automated backup schedule..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would execute: Install backup crontab entry for $SERVICE_USER"
    log_info "[DRY RUN] Schedule: $BACKUP_SCHEDULE $BASE_DIR/scripts/enhanced-backup.sh"
  else
    (
      sudo -u $SERVICE_USER crontab -l 2>/dev/null
      echo "$BACKUP_SCHEDULE $BASE_DIR/scripts/enhanced-backup.sh >> $BASE_DIR/logs/backup.log 2>&1"
    ) | sudo -u $SERVICE_USER crontab -
  fi

  log_success "Enhanced backup system created"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 ROLLING UPDATE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

create_rolling_update_system() {
  log_section "Creating Rolling Update System"

  # Create rolling update script
  cat >/tmp/rolling-update.sh <<EOF
#!/bin/bash
# Rolling Update System for Containerized Services
# Supports health checks, rollback, and zero-downtime updates

set -e

SERVICE_DIR="\$1"
UPDATE_TYPE="\${2:-rolling}"  # rolling, blue-green, manual
DOCKER_ENV="export PATH=$BASE_DIR/bin:\\\$PATH && export DOCKER_HOST=unix:///run/user/$SERVICE_UID/docker.sock"

# Color codes
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

# Logging function
log() {
    echo -e "\$(date '+%Y-%m-%d %H:%M:%S') [\$1] \$2" | tee -a $BASE_DIR/logs/update.log
}

# Health check function
check_service_health() {
    local service="\$1"
    local timeout="\${2:-${UPDATE_HEALTH_CHECK_TIMEOUT}}"
    local retries=\$((timeout / 10))
    
    log "INFO" "Checking health of \$service (timeout: \${timeout}s)..."
    
    for i in \$(seq 1 \$retries); do
        if \$DOCKER_ENV && docker ps --filter name=\$service --filter health=healthy --format '{{.Names}}' | grep -q \$service; then
            log "SUCCESS" "\$service is healthy"
            return 0
        fi
        
        log "INFO" "Waiting for \$service to become healthy (attempt \$i/\$retries)..."
        sleep 10
    done
    
    log "ERROR" "\$service failed health check after \${timeout} seconds"
    return 1
}

# Rollback function
rollback_service() {
    local service_dir="\$1"
    local backup_tag="\$2"
    
    log "WARNING" "Rolling back \$service_dir to \$backup_tag..."
    
    cd "$BASE_DIR/services/\$service_dir"
    
    # Stop current services
    \$DOCKER_ENV && docker-compose down
    
    # Restore from backup tags
    \$DOCKER_ENV && docker-compose config --services | while read service; do
        if docker image inspect "\${service}:\${backup_tag}" >/dev/null 2>&1; then
            docker tag "\${service}:\${backup_tag}" "\${service}:latest"
            log "INFO" "Restored \$service to \$backup_tag"
        fi
    done
    
    # Start services
    \$DOCKER_ENV && docker-compose up -d
    
    log "SUCCESS" "Rollback completed for \$service_dir"
}

# Main update function
perform_rolling_update() {
    local service_dir="\$1"
    local backup_tag="pre-update-\$(date +%Y%m%d_%H%M%S)"
    
    if [ ! -d "$BASE_DIR/services/\$service_dir" ]; then
        log "ERROR" "Service directory not found: \$service_dir"
        exit 1
    fi
    
    cd "$BASE_DIR/services/\$service_dir"
    
    log "INFO" "Starting rolling update for \$service_dir"
    
    # Pre-update backup if enabled
    if [ "$PRE_UPDATE_BACKUP" = "true" ]; then
        log "INFO" "Creating pre-update backup..."
        $BASE_DIR/scripts/enhanced-backup.sh
    fi
    
    # Tag current images for potential rollback
    log "INFO" "Tagging current images for rollback..."
    \$DOCKER_ENV && docker-compose config --services | while read service; do
        current_image=\$(docker-compose images -q \$service 2>/dev/null || echo "")
        if [ -n "\$current_image" ]; then
            docker tag \$current_image "\${service}:\${backup_tag}"
            log "INFO" "Tagged \$service with \$backup_tag"
        fi
    done
    
    # Pull new images
    log "INFO" "Pulling new images..."
    if ! \$DOCKER_ENV && docker-compose pull; then
        log "ERROR" "Failed to pull new images"
        exit 1
    fi
    
    # Perform rolling update based on strategy
    case "\$UPDATE_TYPE" in
        "rolling")
            log "INFO" "Performing rolling update..."
            
            # Update services one by one
            \$DOCKER_ENV && docker-compose config --services | while read service; do
                log "INFO" "Updating service: \$service"
                
                # Update single service
                \$DOCKER_ENV && docker-compose up -d --no-deps \$service
                
                # Wait for health check
                if ! check_service_health \$service; then
                    if [ "$UPDATE_ROLLBACK_ON_FAILURE" = "true" ]; then
                        log "ERROR" "Health check failed for \$service, initiating rollback..."
                        rollback_service "\$service_dir" "\$backup_tag"
                        return 1
                    else
                        log "ERROR" "Health check failed for \$service, manual intervention required"
                        return 1
                    fi
                fi
                
                log "SUCCESS" "Service \$service updated successfully"
            done
            ;;
            
        "blue-green")
            log "INFO" "Performing blue-green update..."
            
            # Start new version alongside old
            \$DOCKER_ENV && docker-compose up -d --scale \$(docker-compose config --services | head -n1)=2
            
            # Wait for new instances to be healthy
            sleep 30
            
            # Check if new instances are healthy
            if check_service_health "\$(docker-compose config --services | head -n1)"; then
                # Scale down old instances
                \$DOCKER_ENV && docker-compose up -d --remove-orphans
                log "SUCCESS" "Blue-green update completed"
            else
                log "ERROR" "New instances failed health check, rolling back..."
                \$DOCKER_ENV && docker-compose down --remove-orphans
                rollback_service "\$service_dir" "\$backup_tag"
                return 1
            fi
            ;;
            
        "manual")
            log "INFO" "Manual update mode - stopping services for update..."
            \$DOCKER_ENV && docker-compose down
            \$DOCKER_ENV && docker-compose up -d --remove-orphans
            
            # Wait for services to start
            sleep 30
            
            # Check health
            \$DOCKER_ENV && docker-compose config --services | while read service; do
                if ! check_service_health \$service; then
                    log "ERROR" "Health check failed for \$service after manual update"
                    if [ "$UPDATE_ROLLBACK_ON_FAILURE" = "true" ]; then
                        rollback_service "\$service_dir" "\$backup_tag"
                        return 1
                    fi
                fi
            done
            ;;
            
        *)
            log "ERROR" "Unknown update strategy: \$UPDATE_TYPE"
            exit 1
            ;;
    esac
    
    # Cleanup old images (keep last ${IMAGE_CLEANUP_RETENTION} versions)
    log "INFO" "Cleaning up old images..."
    \$DOCKER_ENV && docker images --format "table {{.Repository}}:{{.Tag}}\\t{{.CreatedAt}}" | \\
        grep -E "(supabase|n8n|nginx)" | \\
        tail -n +\$((${IMAGE_CLEANUP_RETENTION} + 1)) | \\
        awk '{print \$1}' | \\
        xargs -r docker rmi 2>/dev/null || true
    
    log "SUCCESS" "Rolling update completed for \$service_dir"
    
    # Post-update verification
    log "INFO" "Running post-update verification..."
    
    # Verify all services are healthy
    ALL_HEALTHY=true
    \$DOCKER_ENV && docker-compose config --services | while read service; do
        if ! check_service_health \$service 30; then
            log "WARNING" "Service \$service is not healthy after update"
            ALL_HEALTHY=false
        fi
    done
    
    if [ "\$ALL_HEALTHY" = "true" ]; then
        log "SUCCESS" "All services are healthy after update"
        
        # Send notification
        if command -v mail >/dev/null 2>&1; then
            echo "Rolling update completed successfully for ${DOMAIN}
            
Update Details:
- Service: \$service_dir
- Strategy: \$UPDATE_TYPE
- Timestamp: \$(date)
- Backup Tag: \$backup_tag

All services are healthy and operational.
" | mail -s "[${DOMAIN}] Rolling Update Completed" "${ALERT_EMAIL}" 2>/dev/null || true
        fi
    else
        log "ERROR" "Some services are not healthy after update"
        exit 1
    fi
}

# Main execution
if [ -z "\$SERVICE_DIR" ]; then
    echo "Usage: \$0 <service-directory> [update-type]"
    echo ""
    echo "Available services:"
    ls -1 "$BASE_DIR/services" | grep -v nginx | head -10
    echo ""
    echo "Update types: rolling (default), blue-green, manual"
    exit 1
fi

perform_rolling_update "\$SERVICE_DIR"
EOF

  safe_mv "/tmp/rolling-update.sh" "$BASE_DIR/scripts/rolling-update.sh" "Install rolling update script"
  safe_chmod "+x" "$BASE_DIR/scripts/rolling-update.sh" "Make rolling update script executable"

  # Create update all services script
  cat >/tmp/update-all-services.sh <<EOF
#!/bin/bash
# Update All Services with Rolling Updates

set -e

echo "🔄 Starting rolling updates for all services..."

SERVICES=("supabase" "n8n")
FAILED_SERVICES=()

for service in "\${SERVICES[@]}"; do
    echo "Updating service: \$service"
    
    if $BASE_DIR/scripts/rolling-update.sh "\$service" rolling; then
        echo "✅ \$service updated successfully"
    else
        echo "❌ \$service update failed"
        FAILED_SERVICES+=("\$service")
    fi
    
    # Wait between service updates
    sleep 30
done

# Update NGINX last (reverse proxy)
echo "Updating NGINX (reverse proxy)..."
if $BASE_DIR/scripts/rolling-update.sh "nginx" manual; then
    echo "✅ NGINX updated successfully"
else
    echo "❌ NGINX update failed"
    FAILED_SERVICES+=("nginx")
fi

# Summary
echo ""
echo "Update Summary:"
echo "==============="

if [ \${#FAILED_SERVICES[@]} -eq 0 ]; then
    echo "✅ All services updated successfully!"
else
    echo "❌ Failed services: \${FAILED_SERVICES[*]}"
    echo "Please check logs and consider manual intervention."
    exit 1
fi
EOF

  safe_mv "/tmp/update-all-services.sh" "$BASE_DIR/scripts/update-all-services.sh" "Install update all script"
  safe_chmod "+x" "$BASE_DIR/scripts/update-all-services.sh" "Make update all script executable"

  log_success "Rolling update system created"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🧹 RESET/CLEANUP FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════

reset_installation() {
  log_section "UNINSTALL - Removing All Installed Components"

  echo -e "${RED}⚠️  WARNING: This will completely remove:${NC}"
  echo -e "${YELLOW}  - All Docker containers, images, secrets, and custom networks${NC}"
  echo -e "${YELLOW}  - All service data and volumes${NC}"
  echo -e "${YELLOW}  - Script-created directories: jarvis-stack, backups, logs, scripts${NC}"
  echo -e "${YELLOW}  - All configurations and backups${NC}"
  echo -e "${YELLOW}  - SSL certificates and internal certificate authority${NC}"
  echo -e "${YELLOW}  - GPG encrypted secrets and keyring${NC}"
  echo -e "${YELLOW}  - Systemd services, timers, and cron jobs${NC}"
  echo -e "${YELLOW}  - Security configurations (firewall rules, fail2ban, etc.)${NC}"
  echo -e "${GREEN}  ✅ User account '$SERVICE_USER' will be preserved${NC}"
  echo -e "${GREEN}  ✅ System packages (Docker, etc.) will be preserved${NC}"
  echo ""
  echo -e "${RED}This action CANNOT be undone!${NC}"
  echo -e "${YELLOW}Type 'UNINSTALL-ALL' to confirm:${NC}"

  read -r confirmation
  if [ "$confirmation" != "UNINSTALL-ALL" ]; then
    log_info "Uninstall cancelled by user"
    exit 0
  fi

  log_warning "Starting complete system uninstall..."

  # 1. Stop all Docker containers
  if id "$SERVICE_USER" &>/dev/null; then
    log_info "Stopping all Docker containers..."
    sudo -u $SERVICE_USER bash -c "
      export DOCKER_HOST=unix:///run/user/$(id -u $SERVICE_USER)/docker.sock
      export PATH=$BASE_DIR/bin:\$PATH
      
      # Stop all containers
      docker ps -q | xargs -r docker stop 2>/dev/null || true
      
      # Remove all containers
      docker ps -aq | xargs -r docker rm -f 2>/dev/null || true
      
      # Remove all images
      docker images -q | xargs -r docker rmi -f 2>/dev/null || true
      
      # Remove all volumes
      docker volume ls -q | xargs -r docker volume rm 2>/dev/null || true
      
      # Remove all networks (except default ones)
      docker network ls --format '{{.Name}}' | grep -v -E '^(bridge|host|none)$' | xargs -r docker network rm 2>/dev/null || true
    " || true

    # Stop Docker service for user
    sudo -u $SERVICE_USER systemctl --user stop docker 2>/dev/null || true
    sudo -u $SERVICE_USER systemctl --user disable docker 2>/dev/null || true
  fi

  # 2. Remove cron jobs and backup system components
  log_info "Removing cron jobs and backup system..."
  if id "$SERVICE_USER" &>/dev/null; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY RUN] Would execute: Remove crontab entries for $SERVICE_USER"
    else
      sudo -u $SERVICE_USER crontab -r 2>/dev/null || true
    fi
  fi

  # Remove system-wide backup cron jobs
  sudo rm -f /etc/cron.d/jarvis-backup* 2>/dev/null || true
  sudo rm -f /etc/cron.d/container-backup* 2>/dev/null || true
  sudo rm -f /etc/cron.daily/jarvis-* 2>/dev/null || true
  sudo rm -f /etc/cron.weekly/jarvis-* 2>/dev/null || true

  # Remove backup scripts and configurations
  sudo rm -rf /opt/jarvis-backup 2>/dev/null || true
  sudo rm -f /usr/local/bin/jarvis-backup* 2>/dev/null || true

  # 3. Remove systemd services and timers (including new SSL rotation services)
  log_info "Removing systemd services and timers..."

  # Original container secrets service
  sudo systemctl stop container-secrets.service 2>/dev/null || true
  sudo systemctl disable container-secrets.service 2>/dev/null || true
  sudo rm -f /etc/systemd/system/container-secrets.service 2>/dev/null || true

  # SSL certificate rotation services and timers (added for newer functions)
  sudo systemctl stop internal-cert-rotation.service 2>/dev/null || true
  sudo systemctl disable internal-cert-rotation.service 2>/dev/null || true
  sudo systemctl stop internal-cert-rotation.timer 2>/dev/null || true
  sudo systemctl disable internal-cert-rotation.timer 2>/dev/null || true
  sudo rm -f /etc/systemd/system/internal-cert-rotation.service 2>/dev/null || true
  sudo rm -f /etc/systemd/system/internal-cert-rotation.timer 2>/dev/null || true

  # Certbot renewal services and timers
  sudo systemctl stop certbot-renewal.service 2>/dev/null || true
  sudo systemctl disable certbot-renewal.service 2>/dev/null || true
  sudo systemctl stop certbot-renewal.timer 2>/dev/null || true
  sudo systemctl disable certbot-renewal.timer 2>/dev/null || true
  sudo rm -f /etc/systemd/system/certbot-renewal.service 2>/dev/null || true
  sudo rm -f /etc/systemd/system/certbot-renewal.timer 2>/dev/null || true

  # Additional backup-related services if any exist
  sudo systemctl stop jarvis-backup.service 2>/dev/null || true
  sudo systemctl disable jarvis-backup.service 2>/dev/null || true
  sudo systemctl stop jarvis-backup.timer 2>/dev/null || true
  sudo systemctl disable jarvis-backup.timer 2>/dev/null || true
  sudo rm -f /etc/systemd/system/jarvis-backup.service 2>/dev/null || true
  sudo rm -f /etc/systemd/system/jarvis-backup.timer 2>/dev/null || true

  sudo systemctl daemon-reload

  # 4. Remove AppArmor profiles
  log_info "Removing AppArmor profiles..."
  if [ -f /etc/apparmor.d/docker-default ]; then
    sudo apparmor_parser -R /etc/apparmor.d/docker-default 2>/dev/null || true
    sudo rm -f /etc/apparmor.d/docker-default
  fi

  # 5. Remove fail2ban configurations
  log_info "Removing fail2ban configurations..."
  sudo rm -f /etc/fail2ban/jail.local 2>/dev/null || true
  sudo rm -f /etc/fail2ban/filter.d/docker-auth.conf 2>/dev/null || true
  sudo systemctl restart fail2ban 2>/dev/null || true

  # 6. Reset UFW firewall rules (if it was enabled)
  if [ "$UFW_ENABLED" = "true" ]; then
    log_info "Resetting UFW firewall rules..."
    sudo ufw --force reset 2>/dev/null || true
    # Re-enable basic SSH access to not lock out user
    sudo ufw allow 22/tcp 2>/dev/null || true
    sudo ufw --force enable 2>/dev/null || true
  fi

  # 7. Remove kernel security parameters
  log_info "Removing kernel security parameters..."
  sudo rm -f /etc/sysctl.d/99-security.conf 2>/dev/null || true
  sudo sysctl --system 2>/dev/null || true

  # 8. Remove audit rules
  log_info "Removing audit rules..."
  sudo rm -f /etc/audit/rules.d/audit.rules 2>/dev/null || true
  sudo systemctl restart auditd 2>/dev/null || true

  # 9. Remove log rotation configs
  log_info "Removing log rotation configs..."
  sudo rm -f /etc/logrotate.d/docker-logs 2>/dev/null || true

  # 9.5. Remove SSL infrastructure and certificates (added for newer functions)
  log_info "Removing SSL infrastructure and certificates..."

  # Remove internal SSL certificate authority and certificates
  sudo rm -rf "$BASE_DIR/ssl" 2>/dev/null || true
  sudo rm -rf "$BASE_DIR/services/nginx/ssl" 2>/dev/null || true
  sudo rm -rf "$BASE_DIR/services/certbot" 2>/dev/null || true

  # Remove Let's Encrypt certificates if they exist
  sudo rm -rf /etc/letsencrypt/live/$DOMAIN* 2>/dev/null || true
  sudo rm -rf /etc/letsencrypt/archive/$DOMAIN* 2>/dev/null || true
  sudo rm -rf /etc/letsencrypt/renewal/$DOMAIN* 2>/dev/null || true

  # Remove any remaining SSL-related files
  sudo rm -f /etc/ssl/certs/jarvis-* 2>/dev/null || true
  sudo rm -f /etc/ssl/private/jarvis-* 2>/dev/null || true

  # 9.6. Remove GPG secrets and keyring cleanup (added for newer functions)
  log_info "Cleaning up GPG secrets and keyring..."
  if id "$SERVICE_USER" &>/dev/null; then
    # Remove GPG secrets file
    sudo rm -f "$BASE_DIR/secrets/secrets.env.gpg" 2>/dev/null || true

    # Clean up GPG keyring for service user
    sudo -u $SERVICE_USER bash -c "
      # Remove any JarvisJR Stack related keys
      gpg --batch --yes --delete-secret-keys 'JarvisJR Stack' 2>/dev/null || true
      gpg --batch --yes --delete-keys 'JarvisJR Stack' 2>/dev/null || true
      
      # Remove GPG directory if it exists
      rm -rf ~/.gnupg 2>/dev/null || true
    " 2>/dev/null || true
  fi

  # 9.7. Enhanced Docker cleanup (added for newer functions)
  log_info "Enhanced Docker secrets and networks cleanup..."
  if id "$SERVICE_USER" &>/dev/null; then
    sudo -u $SERVICE_USER bash -c "
      export DOCKER_HOST=unix:///run/user/$(id -u $SERVICE_USER)/docker.sock
      export PATH=$BASE_DIR/bin:\$PATH
      
      # Remove Docker secrets
      docker secret ls -q 2>/dev/null | xargs -r docker secret rm 2>/dev/null || true
      
      # Remove custom networks more thoroughly
      docker network ls --format '{{.Name}}' | grep -E '(jarvis|supabase|n8n|nginx)' | xargs -r docker network rm 2>/dev/null || true
      
      # Clean up any remaining custom networks
      docker network prune -f 2>/dev/null || true
      
      # Remove any orphaned containers
      docker container prune -f 2>/dev/null || true
      
      # Remove build cache
      docker builder prune -f 2>/dev/null || true
    " 2>/dev/null || true
  fi

  # 10. Clean up script-created directories from user home (preserve user account)
  log_info "Cleaning up script-created directories from $SERVICE_USER home..."
  if id "$SERVICE_USER" &>/dev/null; then
    SERVICE_USER_HOME=$(getent passwd "$SERVICE_USER" | cut -d: -f6)

    # SAFETY CHECK: Ensure BASE_DIR is NOT the user's home directory
    if [ "$BASE_DIR" = "$SERVICE_USER_HOME" ]; then
      log_error "SAFETY CHECK FAILED: BASE_DIR equals user home directory!"
      log_error "This would delete the entire user home. Aborting uninstall."
      exit 1
    fi

    # Save a list of what we're removing for the log
    if [ -d "$BASE_DIR" ]; then
      log_info "Removing script directory: $BASE_DIR"
      ls -la "$BASE_DIR" >>"$SETUP_LOG_FILE" 2>/dev/null || true
      sudo rm -rf "$BASE_DIR"
    fi

    # Clean up other script-created directories in user home (specific paths only)
    log_info "Removing script-created directories: backups, logs, scripts, bin"
    [ -d "$SERVICE_USER_HOME/backups" ] && sudo rm -rf "$SERVICE_USER_HOME/backups" 2>/dev/null || true
    [ -d "$SERVICE_USER_HOME/logs" ] && sudo rm -rf "$SERVICE_USER_HOME/logs" 2>/dev/null || true
    [ -d "$SERVICE_USER_HOME/scripts" ] && sudo rm -rf "$SERVICE_USER_HOME/scripts" 2>/dev/null || true
    [ -d "$SERVICE_USER_HOME/bin" ] && sudo rm -rf "$SERVICE_USER_HOME/bin" 2>/dev/null || true
    [ -f "$SERVICE_USER_HOME/.docker/config.json" ] && sudo rm -f "$SERVICE_USER_HOME/.docker/config.json" 2>/dev/null || true

    # Remove user crontab entries (preserve user account)
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY RUN] Would execute: Remove user crontab entries for $SERVICE_USER"
    else
      sudo -u $SERVICE_USER crontab -r 2>/dev/null || true
    fi

    # Disable user systemd lingering but keep user account
    sudo loginctl disable-linger $SERVICE_USER 2>/dev/null || true

    log_success "Script-created files cleaned up (user account preserved)"
  else
    log_info "Service user $SERVICE_USER not found - skipping user cleanup"
  fi

  # 11. Docker and system packages are preserved
  log_info "System packages (Docker, etc.) are preserved - only removing script-created content"

  # 12. Rollback etckeeper if it was initialized
  if [ -d "/etc/.git" ]; then
    echo -e "${YELLOW}Rollback /etc configuration changes with etckeeper? (y/N)${NC}"
    read -r rollback_etc
    if [[ $rollback_etc =~ ^[Yy]$ ]]; then
      log_info "Rolling back configuration changes..."
      sudo sh -c "cd /etc && git log --oneline -10"
      echo "Enter commit hash to rollback to (or press Enter to skip):"
      read -r commit_hash
      if [ -n "$commit_hash" ]; then
        sudo sh -c "cd /etc && git reset --hard $commit_hash" 2>/dev/null || true
        log_success "Configuration rolled back"
      fi
    fi
  fi

  # 13. Clean up temporary files
  log_info "Cleaning up temporary files..."
  rm -rf /tmp/setup-logs 2>/dev/null || true
  rm -rf /tmp/restore_* 2>/dev/null || true
  rm -rf /tmp/verify_* 2>/dev/null || true

  log_success "Reset completed!"
  echo ""
  echo -e "${GREEN}✅ System has been reset to pre-installation state${NC}"
  echo -e "${GREEN}✅ User account '$SERVICE_USER' has been preserved${NC}"
  echo ""
  echo -e "${YELLOW}Note: Some packages installed by the script remain:${NC}"
  echo -e "  - Security packages (fail2ban, ufw, apparmor, etc.)"
  echo -e "  - Monitoring tools (htop, iotop, etc.)"
  echo -e "  - GPG, OpenSSL, and other system tools"
  echo -e "  - User account: $SERVICE_USER (preserved for safety)"
  echo -e "  - These can be removed manually if desired"
  echo ""
  echo -e "${GREEN}✅ Enhanced uninstall completed - all script-created content cleaned up${NC}"
  echo ""
  echo -e "${BLUE}You can now run the installation script again if needed.${NC}"
  echo -e "${BLUE}The preserved user account '$SERVICE_USER' is ready for reuse.${NC}"

  # Final log entry
  cat >>"$SETUP_LOG_FILE" <<EOF

================================================================================
RESET SESSION END: $(date)
STATUS: COMPLETED
================================================================================
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN EXECUTION FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  # Create initial log directory
  mkdir -p "$BASE_DIR/logs" 2>/dev/null || mkdir -p "/tmp/setup-logs"

  log_section "Starting Enhanced Production Container Stack Setup"

  # Initialize all systems and validate environment
  init_timing_system

  # Validate environment before proceeding
  if ! validate_environment; then
    log_error "Environment validation failed. Aborting for safety."
    exit 1
  fi

  # Initialize progress tracking and checkpoints
  init_checkpoints

  echo -e "${BLUE}🏗️  Setting up production-ready containerized stack for: ${WHITE}${DOMAIN}${NC}"
  echo -e "${BLUE}📧 Email: ${WHITE}${EMAIL}${NC}"
  echo -e "${BLUE}👤 Service User: ${WHITE}${SERVICE_USER}${NC}"
  echo -e "${BLUE}📁 Base Directory: ${WHITE}${BASE_DIR}${NC}"
  echo -e "${BLUE}🔐 Security: ${WHITE}AppArmor, UFW, fail2ban, rootless Docker${NC}"
  echo -e "${BLUE}💾 Backup: ${WHITE}Enhanced with encryption and S3 support${NC}"
  echo -e "${BLUE}🔄 Updates: ${WHITE}Rolling updates with health checks${NC}"

  if [ "$DRY_RUN" = "true" ]; then
    echo -e "\n${CYAN}🧪 DRY RUN MODE - No changes will be made${NC}\n"
  fi

  # Confirm before proceeding (unless in dry run mode)
  if [ "$DRY_RUN" != "true" ]; then
    echo -e "\n${YELLOW}⚠️ This will install and configure a complete production-ready containerized stack.${NC}"
    echo -e "${YELLOW}   This includes system hardening, security configurations, and service deployment.${NC}"
    echo -e "${YELLOW}   Continue? (y/N)${NC}"
    read -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
      log_info "Setup cancelled by user"
      exit 0
    fi
  fi

  # Execute setup steps with checkpoint tracking and performance monitoring
  if ! should_skip_step 1; then
    start_section_timer "Prerequisites Check"
    check_prerequisites
    end_section_timer "Prerequisites Check"
    save_checkpoint "Prerequisites validated" 1
  fi

  # Configure system timezone to match N8N_TIMEZONE
  if ! should_skip_step 1.5; then
    start_section_timer "System Timezone"
    setup_system_timezone
    end_section_timer "System Timezone"
    save_checkpoint "System timezone configured" 1.5
  fi

  if ! should_skip_step 2; then
    start_section_timer "Host OS Hardening"
    harden_host_os
    end_section_timer "Host OS Hardening"
    save_checkpoint "Host OS hardening completed" 2
  fi

  if ! should_skip_step 3; then
    start_section_timer "Container Environment"
    setup_container_environment
    end_section_timer "Container Environment"
    save_checkpoint "Container environment ready" 3
  fi

  if ! should_skip_step 4; then
    start_section_timer "Secrets Management"
    setup_secrets_management
    end_section_timer "Secrets Management"
    save_checkpoint "Secrets management configured" 4
  fi

  if ! should_skip_step 5; then
    start_section_timer "Supabase Stack"
    setup_supabase_containers
    end_section_timer "Supabase Stack"
    save_checkpoint "Supabase stack deployed" 5
  fi

  if ! should_skip_step 6; then
    start_section_timer "N8N Automation"
    setup_n8n_container
    end_section_timer "N8N Automation"
    save_checkpoint "N8N workflow automation ready" 6
  fi

  if ! should_skip_step 7; then
    start_section_timer "NGINX Reverse Proxy"
    setup_nginx_container
    end_section_timer "NGINX Reverse Proxy"
    save_checkpoint "NGINX reverse proxy configured" 7
  fi

  if ! should_skip_step 8; then
    start_section_timer "SSL Certificates"
    setup_ssl_certificates
    end_section_timer "SSL Certificates"
    save_checkpoint "SSL certificates obtained" 8
  fi

  if ! should_skip_step 9; then
    start_section_timer "Internal SSL Infrastructure"
    setup_internal_ssl_infrastructure
    end_section_timer "Internal SSL Infrastructure"
    save_checkpoint "Internal SSL infrastructure ready" 9
  fi

  if ! should_skip_step 10; then
    start_section_timer "SSL Certificate Rotation"
    setup_internal_ssl_rotation
    end_section_timer "SSL Certificate Rotation"
    save_checkpoint "SSL certificate rotation configured" 10
  fi

  if ! should_skip_step 11; then
    start_section_timer "Enhanced Backup System"
    create_enhanced_backup_system
    end_section_timer "Enhanced Backup System"
    save_checkpoint "Enhanced backup system ready" 11
  fi

  if ! should_skip_step 12; then
    start_section_timer "Rolling Update System"
    create_rolling_update_system
    end_section_timer "Rolling Update System"
    save_checkpoint "Rolling update system configured" 12
  fi

  # Final summary
  log_section "Enhanced Production Setup Complete!"

  echo -e "${GREEN}✅ Production-ready containerized stack setup completed successfully!${NC}"
  echo ""
  echo -e "${BLUE}📋 Next Steps:${NC}"
  echo -e "1. ${YELLOW}Switch to service user:${NC} sudo su - $SERVICE_USER"
  echo -e "2. ${YELLOW}Start all services:${NC} $BASE_DIR/scripts/start-all.sh"
  echo -e "3. ${YELLOW}Setup SSL certificates:${NC} $BASE_DIR/scripts/setup-ssl.sh"
  echo -e "4. ${YELLOW}Check system status:${NC} $BASE_DIR/scripts/status.sh"
  echo -e "5. ${YELLOW}View secrets:${NC} gpg --decrypt $BASE_DIR/secrets/secrets.env.gpg"
  echo ""
  echo -e "${BLUE}🌐 Your Services:${NC}"
  echo -e "- ${WHITE}Main site:${NC} https://${DOMAIN}"
  echo -e "- ${WHITE}Supabase API:${NC} https://${SUPABASE_SUBDOMAIN}.${DOMAIN}"
  echo -e "- ${WHITE}Supabase Studio:${NC} https://${STUDIO_SUBDOMAIN}.${DOMAIN}"
  echo -e "- ${WHITE}N8N:${NC} https://${N8N_SUBDOMAIN}.${DOMAIN}"
  echo ""
  echo -e "${BLUE}🔧 Enhanced Management:${NC}"
  echo -e "- ${WHITE}Start all:${NC} $BASE_DIR/scripts/start-all.sh"
  echo -e "- ${WHITE}Rolling updates:${NC} $BASE_DIR/scripts/rolling-update.sh <service>"
  echo -e "- ${WHITE}Enhanced backup:${NC} $BASE_DIR/scripts/enhanced-backup.sh"
  echo -e "- ${WHITE}Restore:${NC} $BASE_DIR/scripts/enhanced-restore.sh <backup-file>"
  echo -e "- ${WHITE}Verify backup:${NC} $BASE_DIR/scripts/verify-backup.sh <backup-file>"
  echo -e "- ${WHITE}Status check:${NC} $BASE_DIR/scripts/status.sh"
  echo ""
  echo -e "${BLUE}🛡️ Security Features:${NC}"
  echo -e "- ${GREEN}✓${NC} AppArmor container profiles"
  echo -e "- ${GREEN}✓${NC} UFW firewall with rate limiting"
  echo -e "- ${GREEN}✓${NC} fail2ban intrusion prevention"
  echo -e "- ${GREEN}✓${NC} Encrypted secrets management"
  echo -e "- ${GREEN}✓${NC} Network segmentation"
  echo -e "- ${GREEN}✓${NC} Rootless containers"
  echo -e "- ${GREEN}✓${NC} Audit logging"
  echo ""
  echo -e "${BLUE}📊 Operational Features:${NC}"
  echo -e "- ${GREEN}✓${NC} Automated encrypted backups"
  echo -e "- ${GREEN}✓${NC} Rolling updates with health checks"
  echo -e "- ${GREEN}✓${NC} Automatic SSL certificate renewal"
  echo -e "- ${GREEN}✓${NC} Container resource limits"
  echo ""
  echo -e "${YELLOW}⚠️  Important Security Notes:${NC}"
  echo -e "- ${RED}Change all default passwords immediately${NC}"
  echo -e "- ${RED}Secure the encrypted secrets file${NC}"
  echo -e "- ${RED}Configure DNS records to point to this server${NC}"
  echo -e "- ${RED}Test backup and restore procedures${NC}"
  echo -e "- ${RED}Set up external backup storage (S3)${NC}"
  echo ""

  # Clean up checkpoint and timing files on successful completion
  rm -f "$CHECKPOINT_FILE" 2>/dev/null || true
  rm -f "$SECTION_TIMERS_FILE" 2>/dev/null || true

  # Show final progress
  show_progress_bar $TOTAL_STEPS $TOTAL_STEPS
  echo

  # Show performance summary
  show_performance_summary

  # Mark successful completion
  log_success_exit
  echo -e "${GREEN}🎉 Your enhanced, production-ready containerized stack is ready!${NC}"

  # Add session end marker to log
  cat >>"$SETUP_LOG_FILE" <<EOF

================================================================================
SETUP SESSION END: $(date)
TOTAL RUNTIME: $(($(date +%s) - $(date -d "$SCRIPT_START_TIME" +%s 2>/dev/null || echo 0)))s
STATUS: SUCCESS
================================================================================
EOF

  echo ""
  echo -e "${BLUE}📝 Complete setup log saved to: ${WHITE}$SETUP_LOG_FILE${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 COMMAND-LINE ARGUMENT PARSING
# ═══════════════════════════════════════════════════════════════════════════════

# Show usage information
show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Enhanced Production Container Stack Setup Script"
  echo ""
  echo "Options:"
  echo "  --install          Run the installation (default)"
  echo "  --uninstall        Uninstall/remove all installed components"
  echo "  --backup [NAME]    Create complete system backup (optional custom name)"
  echo "  --dry-run          Run in dry-run mode (no actual changes)"
  echo "  --ssl-only         Configure SSL certificates only"
  echo "  --add-site PATH    Add a site from specified path"
  echo "  --remove-site PATH Remove a site from specified path"
  echo "  --enable-debug     Enable debug logging"
  echo "  --help             Show this help message"
  echo ""
  echo "PROGRESS & RESUME FEATURES:"
  echo "  • Progress bar shows completion status (X/12 steps)"
  echo "  • Automatic checkpoint saving for resume capability"
  echo "  • Visual progress indicators for long operations"
  echo "  • Estimated completion time: 15-20 minutes"
  echo "  • Graceful interrupt handling (Ctrl+C)"
  echo ""
  echo "RESUME INFO:"
  echo "  If interrupted, run the same command again to resume from last checkpoint."
  echo "  Progress is automatically saved in checkpoint files."
  echo ""
  echo "  --restore [FILE]   Restore from backup (interactive selection if no file)"
  echo "  --list-backups     List all available backups with details"
  echo "  --add-site PATH    Add a new site to the stack from config"
  echo "  --remove-site PATH Remove a site from the stack"
  echo "  --dry-run          Show what would be done without executing"
  echo "  --configure-ssl    Configure SSL certificates after installation"
  echo "  --help             Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                 # Run normal installation"
  echo "  $0 --uninstall     # Remove everything and uninstall"
  echo "  $0 --backup        # Create timestamped backup"
  echo "  $0 --backup pre-upgrade  # Create named backup"
  echo "  $0 --restore       # Interactive restore selection"
  echo "  $0 --restore backup_20250107_203045.tar.gz  # Restore specific backup"
  echo "  $0 --list-backups  # Show all available backups"
  echo "  $0 --add-site sites/example.com    # Add a site from config"
  echo "  $0 --remove-site sites/example.com # Remove a site"
  echo "  $0 --dry-run       # Test run without making changes"
  echo "  $0 --configure-ssl # Configure SSL certificates"
  echo ""
  exit 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 SITE MANAGEMENT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Parse and validate site configuration
parse_site_config() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    log_error "Site configuration file not found: $config_file"
    exit 1
  fi

  # Validate JSON syntax
  if ! jq empty "$config_file" 2>/dev/null; then
    log_error "Invalid JSON in site configuration: $config_file"
    exit 1
  fi

  # Extract and validate required fields
  SITE_DOMAIN=$(jq -r '.domain // empty' "$config_file")
  SITE_TYPE=$(jq -r '.type // "generic"' "$config_file")

  if [[ -z "$SITE_DOMAIN" ]]; then
    log_error "Missing required 'domain' field in site configuration"
    exit 1
  fi

  log_info "Parsed site config: $SITE_DOMAIN ($SITE_TYPE)"
}

# Add a new site to the stack
add_site() {
  local site_path="$1"
  local config_file="$site_path/site.json"

  log_section "Adding Site to JarvisJR Stack"
  log_info "Site path: $site_path"

  # Validate site path and config
  if [[ ! -d "$site_path" ]]; then
    log_error "Site directory not found: $site_path"
    exit 1
  fi

  parse_site_config "$config_file"

  # Create site directory in stack
  local stack_site_dir="${BASE_DIR}/sites/${SITE_DOMAIN}"

  log_info "Creating stack site directory: $stack_site_dir"
  execute_cmd "mkdir -p '$stack_site_dir'"

  # In dry-run mode, create temp directory for testing
  if [[ "$DRY_RUN" == "true" ]]; then
    stack_site_dir="/tmp/jarvis-dry-run-$(date +%s)"
    mkdir -p "$stack_site_dir" # Actually create temp dir in dry-run
    log_info "Using temp directory for dry-run: $stack_site_dir"
  fi

  # Generate Docker Compose for the site
  generate_site_compose "$config_file" "$stack_site_dir"

  # Generate NGINX configuration
  generate_site_nginx_config "$config_file" "$stack_site_dir"

  # Start the site containers
  log_info "Starting site containers..."
  execute_cmd "cd '$stack_site_dir' && docker-compose up -d"

  # Request SSL certificate if enabled
  if [[ "$(jq -r '.ssl.enabled // false' "$config_file")" == "true" ]]; then
    log_info "Requesting SSL certificate for $SITE_DOMAIN"
    request_site_ssl_certificate "$SITE_DOMAIN"
  fi

  # Reload NGINX to pick up new configuration
  log_info "Reloading NGINX configuration..."
  execute_cmd "docker exec nginx nginx -s reload"

  log_success "Site $SITE_DOMAIN added successfully!"
  log_info "Site available at: https://$SITE_DOMAIN"
}

# Remove a site from the stack
remove_site() {
  local site_path="$1"
  local config_file="$site_path/site.json"

  log_section "Removing Site from JarvisJR Stack"
  log_info "Site path: $site_path"

  if [[ ! -f "$config_file" ]]; then
    log_error "Site configuration file not found: $config_file"
    exit 1
  fi

  parse_site_config "$config_file"

  local stack_site_dir="${BASE_DIR}/sites/${SITE_DOMAIN}"

  # Stop and remove containers
  if [[ -d "$stack_site_dir" ]]; then
    log_info "Stopping site containers..."
    execute_cmd "cd '$stack_site_dir' && docker-compose down -v"

    # Remove site directory
    log_info "Removing stack site directory: $stack_site_dir"
    execute_cmd "rm -rf '$stack_site_dir'"
  fi

  # Remove NGINX configuration
  local nginx_config="${BASE_DIR}/nginx/sites-enabled/${SITE_DOMAIN}.conf"
  if [[ -f "$nginx_config" ]]; then
    log_info "Removing NGINX configuration: $nginx_config"
    execute_cmd "rm -f '$nginx_config'"
  fi

  # Remove SSL certificates
  log_info "Removing SSL certificates for $SITE_DOMAIN"
  execute_cmd "docker exec nginx certbot delete --cert-name '$SITE_DOMAIN' --non-interactive || true"

  # Reload NGINX
  log_info "Reloading NGINX configuration..."
  execute_cmd "docker exec nginx nginx -s reload"

  log_success "Site $SITE_DOMAIN removed successfully!"
}

# Generate Docker Compose file for a site
generate_site_compose() {
  local config_file="$1"
  local site_dir="$2"
  local compose_file="$site_dir/docker-compose.yml"

  log_info "Generating Docker Compose configuration..."

  # Extract configuration values
  local domain=$(jq -r '.domain' "$config_file")
  local container_name=$(echo "$domain" | tr '.' '-')
  local build_context=$(jq -r '.container.build // "."' "$config_file")
  local port=$(jq -r '.container.port // 80' "$config_file")

  # Generate compose file
  cat >"$compose_file" <<EOF
version: '3.8'

services:
  $container_name:
    build:
      context: $build_context
    container_name: $container_name
    networks:
      - $JARVIS_NETWORK
    environment:
$(jq -r '.container.environment // {} | to_entries[] | "      - \(.key)=\(.value)"' "$config_file")
    volumes:
$(jq -r '.container.volumes[]? // [] | "      - \(.)"' "$config_file")
    restart: $(jq -r '.container.restart // "unless-stopped"' "$config_file")
    healthcheck:
      test: $(jq -r '(.container.healthcheck.test // ["CMD", "curl", "-f", "http://localhost/"]) | join(" ")' "$config_file")
      interval: $(jq -r '.container.healthcheck.interval // "30s"' "$config_file")
      timeout: $(jq -r '.container.healthcheck.timeout // "10s"' "$config_file")
      retries: $(jq -r '.container.healthcheck.retries // 3' "$config_file")

networks:
  $JARVIS_NETWORK:
    external: true
EOF

  log_success "Docker Compose file generated: $compose_file"
}

# Generate NGINX configuration for a site
generate_site_nginx_config() {
  local config_file="$1"
  local site_dir="$2"

  log_info "Generating NGINX configuration..."

  local domain=$(jq -r '.domain' "$config_file")
  local container_name=$(echo "$domain" | tr '.' '-')
  local port=$(jq -r '.container.port // 80' "$config_file")
  local nginx_config="${BASE_DIR}/nginx/sites-enabled/${domain}.conf"

  # Ensure nginx config directory exists
  execute_cmd "mkdir -p '${BASE_DIR}/nginx/sites-enabled'"

  # In dry-run mode, use temp location
  if [[ "$DRY_RUN" == "true" ]]; then
    nginx_config="/tmp/nginx-dry-run-${domain}.conf"
  fi

  # Generate NGINX config
  cat >"$nginx_config" <<EOF
server {
    listen 80;
    server_name $domain;
    
    location / {
        proxy_pass http://$container_name:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffering off;
    }
}
EOF

  log_success "NGINX configuration generated: $nginx_config"
}

# Request SSL certificate for a site
request_site_ssl_certificate() {
  local domain="$1"

  log_info "Requesting Let's Encrypt certificate for $domain"

  execute_cmd "docker exec nginx certbot --nginx -d '$domain' --non-interactive --agree-tos --email '$EMAIL' --redirect"

  if [[ $? -eq 0 ]]; then
    log_success "SSL certificate obtained for $domain"
  else
    log_warning "Failed to obtain SSL certificate for $domain"
  fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --uninstall)
    # Call uninstall function directly
    reset_installation
    exit 0
    ;;
  --reset)
    # Legacy support for --reset flag
    echo "Warning: --reset is deprecated, use --uninstall instead"
    reset_installation
    exit 0
    ;;
  --backup)
    # Manual backup trigger
    if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
      BACKUP_NAME_SUFFIX="_$2"
      shift 2
    else
      BACKUP_NAME_SUFFIX=""
      shift
    fi

    # Run the existing backup system manually
    echo "🔄 Triggering manual backup..."
    if id "$SERVICE_USER" &>/dev/null && [ -x "$BASE_DIR/scripts/enhanced-backup.sh" ]; then
      sudo -u $SERVICE_USER $BASE_DIR/scripts/enhanced-backup.sh
    else
      echo "❌ Backup system not found. Please run installation first."
      exit 1
    fi
    exit 0
    ;;
  --restore)
    # Manual restore trigger
    RESTORE_FILE="$2"
    if [[ -n "$RESTORE_FILE" && ! "$RESTORE_FILE" =~ ^-- ]]; then
      shift 2
    else
      # Interactive selection
      if [ -d "$BASE_DIR/backups" ]; then
        echo "📋 Available backups:"
        ls -la "$BASE_DIR/backups"/backup_*.tar.gz* 2>/dev/null | nl -w2 -s') '
        echo ""
        echo "Enter backup number (or full path):"
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
          RESTORE_FILE=$(ls -t "$BASE_DIR/backups"/backup_*.tar.gz* 2>/dev/null | sed -n "${choice}p")
        else
          RESTORE_FILE="$choice"
        fi
        shift
      else
        echo "❌ No backups directory found. Please run installation first."
        exit 1
      fi
    fi

    # Run the existing restore system
    echo "🔄 Starting restore from: $RESTORE_FILE"
    if id "$SERVICE_USER" &>/dev/null && [ -x "$BASE_DIR/scripts/enhanced-restore.sh" ]; then
      sudo -u $SERVICE_USER $BASE_DIR/scripts/enhanced-restore.sh "$RESTORE_FILE"
    else
      echo "❌ Restore system not found. Please run installation first."
      exit 1
    fi
    exit 0
    ;;
  --list-backups)
    # List available backups with details
    if [ -d "$BASE_DIR/backups" ]; then
      echo "📋 Available Backups for $DOMAIN:"
      echo "=================================="
      for backup in "$BASE_DIR/backups"/backup_*.tar.gz*; do
        if [ -f "$backup" ]; then
          size=$(du -sh "$backup" | cut -f1)
          date=$(date -r "$backup" '+%Y-%m-%d %H:%M:%S')
          echo "$(basename "$backup") | Size: $size | Date: $date"
        fi
      done
    else
      echo "❌ No backups directory found."
    fi
    exit 0
    ;;
  --dry-run)
    DRY_RUN="true"
    shift
    ;;
  --configure-ssl)
    configure_ssl_only
    exit 0
    ;;
  --add-site)
    if [[ -z "$2" ]]; then
      echo "Error: --add-site requires a path to site configuration"
      echo "Usage: $0 --add-site /path/to/site/directory"
      exit 1
    fi
    SITE_ACTION="add"
    SITE_PATH="$2"
    shift 2
    ;;
  --remove-site)
    if [[ -z "$2" ]]; then
      echo "Error: --remove-site requires a path to site configuration"
      echo "Usage: $0 --remove-site /path/to/site/directory"
      exit 1
    fi
    SITE_ACTION="remove"
    SITE_PATH="$2"
    shift 2
    ;;
  --install)
    # Default action
    shift
    ;;
  --help | -h)
    show_usage
    ;;
  *)
    echo "Unknown option: $1"
    echo "Use --help for usage information"
    exit 1
    ;;
  esac
done

# Handle site management actions
if [[ -n "$SITE_ACTION" ]]; then
  case $SITE_ACTION in
  "add")
    add_site "$SITE_PATH"
    exit 0
    ;;
  "remove")
    remove_site "$SITE_PATH"
    exit 0
    ;;
  esac
fi

# Run main function
main

