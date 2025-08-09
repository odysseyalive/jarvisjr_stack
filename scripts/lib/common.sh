#!/bin/bash
# Common utilities and functions for JarvisJR Stack
# Provides logging, progress tracking, validation, and shared utilities

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "${SCRIPT_DIR}")")"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════════
# 📝 LOGGING SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

# Initialize logging system
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
    if [[ -d "$LOG_DIR" ]]; then
        find "$LOG_DIR" -name "setup_*.log" -type f | sort | head -n -10 | xargs -r rm
    fi
}

# Logging functions
log_info() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${BLUE}[INFO]${NC} $1" | tee -a "${SETUP_LOG_FILE:-/dev/null}"
}

log_success() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREEN}[SUCCESS]${NC} $1" | tee -a "${SETUP_LOG_FILE:-/dev/null}"
}

log_warning() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${YELLOW}[WARNING]${NC} $1" | tee -a "${SETUP_LOG_FILE:-/dev/null}"
}

log_error() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${RED}[ERROR]${NC} $1" | tee -a "${SETUP_LOG_FILE:-/dev/null}"
}

log_section() {
    echo -e "\n${PURPLE}═══════════════════════════════════════${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════${NC}\n"
}

# Exit handlers
log_failure_exit() {
    local line_no="${1:-unknown}"
    local exit_code="${2:-1}"
    local command="${3:-unknown}"
    
    log_error "Script failed at line $line_no with exit code $exit_code"
    log_error "Failed command: $command"
    log_error "Check the full log at: ${SETUP_LOG_FILE:-unavailable}"
    echo -e "\n${RED}Setup failed. Check logs for details.${NC}"
    exit "$exit_code"
}

log_interrupted_exit() {
    log_warning "Script interrupted by user"
    log_info "Partial installation may exist - run with --uninstall to clean up"
    echo -e "\n${YELLOW}Setup interrupted. Use --uninstall to clean up if needed.${NC}"
    exit 130
}

log_success_exit() {
    local duration=$(($(date +%s) - SCRIPT_START_EPOCH))
    log_success "Setup completed successfully in ${duration}s"
    echo -e "\n${GREEN}🎉 JarvisJR Stack setup completed successfully!${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 PROGRESS TRACKING
# ═══════════════════════════════════════════════════════════════════════════════

# Progress variables
PROGRESS_PID=""
CHECKPOINT_FILE=""
TIMING_DATA=""

# Show progress dots
show_progress_dots() {
    local message="$1"
    local delay="${2:-1}"
    
    echo -n "$message"
    while true; do
        echo -n "."
        sleep "$delay"
    done
}

# Start progress indicator
start_progress() {
    local message="$1"
    show_progress_dots "$message" 0.5 &
    PROGRESS_PID=$!
}

# Stop progress indicator
stop_progress() {
    if [[ -n "$PROGRESS_PID" ]]; then
        kill "$PROGRESS_PID" 2>/dev/null
        wait "$PROGRESS_PID" 2>/dev/null
        PROGRESS_PID=""
        echo " ✓"
    fi
}

# Progress bar
show_progress_bar() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ⏱️ TIMING SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

# Initialize timing system
init_timing_system() {
    TIMING_DATA=""
}

# Start section timer
start_section_timer() {
    local section_name="$1"
    echo "$section_name:$(date +%s)" >> /tmp/section_timings_$$
}

# End section timer
end_section_timer() {
    local section_name="$1"
    local start_time=$(grep "^$section_name:" /tmp/section_timings_$$ | cut -d: -f2)
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "$section_name completed in ${duration}s"
    
    # Remove from temp file
    grep -v "^$section_name:" /tmp/section_timings_$$ > /tmp/section_timings_$$.tmp || true
    mv /tmp/section_timings_$$.tmp /tmp/section_timings_$$ 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Safe command execution
safe_execute() {
    local description="$1"
    shift
    local command=("$@")
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would execute: $description"
        log_info "[DRY-RUN] Command: ${command[*]}"
        return 0
    fi
    
    log_info "$description"
    if "${command[@]}"; then
        log_success "$description completed"
        return 0
    else
        local exit_code=$?
        log_error "$description failed with exit code $exit_code"
        return $exit_code
    fi
}

# Execute command with detailed output
execute_cmd() {
    local cmd="$1"
    local description="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would execute: $description"
        log_info "[DRY-RUN] Command: $cmd"
        return 0
    fi
    
    log_info "$description"
    if eval "$cmd" >> "${SETUP_LOG_FILE:-/dev/null}" 2>&1; then
        log_success "$description - completed"
        return 0
    else
        local exit_code=$?
        log_error "$description - failed (exit code: $exit_code)"
        return $exit_code
    fi
}

# Docker command wrapper
docker_cmd() {
    local cmd="$1"
    local description="${2:-Docker command}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would execute docker command: $description"
        log_info "[DRY-RUN] Command: $cmd"
        return 0
    fi
    
    if sudo -u "$SERVICE_USER" bash -c "cd $BASE_DIR && $cmd" >> "${SETUP_LOG_FILE:-/dev/null}" 2>&1; then
        return 0
    else
        local exit_code=$?
        log_error "Docker command failed: $description (exit code: $exit_code)"
        return $exit_code
    fi
}

# Wait for service health
wait_for_service_health() {
    local service_name="$1"
    local timeout="${2:-120}"
    local interval="${3:-5}"
    local elapsed=0
    
    log_info "Waiting for $service_name to become healthy (timeout: ${timeout}s)"
    
    while [ $elapsed -lt $timeout ]; do
        if docker_cmd "docker ps --filter name=$service_name --filter health=healthy --format '{{.Names}}'" | grep -q "$service_name"; then
            log_success "$service_name is healthy"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
        echo -n "."
    done
    
    log_error "$service_name failed to become healthy within ${timeout}s"
    return 1
}

# Password generation
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

generate_secret() {
    openssl rand -base64 64 | tr -d "=+/" | cut -c1-50
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 SECURITY UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# File operations with safety checks
validate_temp_file() {
    local file="$1"
    
    # Check if file exists and is writable
    if [[ ! -f "$file" ]]; then
        log_error "Temporary file does not exist: $file"
        return 1
    fi
    
    # Check if file is in a safe location
    if [[ ! "$file" =~ ^/tmp/ ]] && [[ ! "$file" =~ ^"$BASE_DIR"/ ]]; then
        log_error "Unsafe file location: $file"
        return 1
    fi
    
    return 0
}

# Safe move operation
safe_mv() {
    local src="$1"
    local dst="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would move $src to $dst"
        return 0
    fi
    
    if validate_temp_file "$src" && mv "$src" "$dst"; then
        log_info "Successfully moved $src to $dst"
        return 0
    else
        log_error "Failed to move $src to $dst"
        return 1
    fi
}

# Safe chmod operation
safe_chmod() {
    local permissions="$1"
    local file="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would set permissions $permissions on $file"
        return 0
    fi
    
    if chmod "$permissions" "$file"; then
        log_info "Set permissions $permissions on $file"
        return 0
    else
        log_error "Failed to set permissions $permissions on $file"
        return 1
    fi
}

# Safe chown operation
safe_chown() {
    local ownership="$1"
    local file="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would set ownership $ownership on $file"
        return 0
    fi
    
    if chown "$ownership" "$file"; then
        log_info "Set ownership $ownership on $file"
        return 0
    else
        log_error "Failed to set ownership $ownership on $file"
        return 1
    fi
}

# Main function for testing
main() {
    setup_logging
    log_info "Common library loaded successfully"
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi