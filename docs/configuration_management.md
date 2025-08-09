# Configuration Management

## Configuration System Overview

### Two-File Configuration Pattern
- **`jstack.default`**: Default values and documentation (version controlled)
- **`jstack.config`**: User-specific settings (not version controlled, required)

### Configuration Loading Order
1. Load `jstack.default` (establishes baseline)
2. Load `jstack.config` (overrides defaults with user values)
3. Validate required settings
4. Proceed with script execution

## Configuration File Structure

### jstack.default (Template)
```bash
#!/bin/bash
# Default configuration for jstack
# Copy this file to jstack.config and customize

# Application Settings
APP_NAME="jstack"
APP_VERSION="1.0.0"
APP_ENVIRONMENT="development"

# Directories and Paths
BACKUP_DIR="/tmp/jstack_backups"
LOG_DIR="/var/log/jstack"
DATA_DIR="/opt/jstack/data"
TEMP_DIR="/tmp/jstack"

# Database Configuration (if applicable)
DB_TYPE="sqlite"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="jstack_db"
DB_USER=""              # Set in jstack.config
DB_PASSWORD=""          # Set in jstack.config

# External Services
API_ENDPOINT="https://api.example.com"
API_TIMEOUT="30"
API_RETRY_COUNT="3"

# Logging Configuration
LOG_LEVEL="info"        # debug, info, warn, error
LOG_ROTATION="daily"
LOG_MAX_SIZE="100M"
LOG_RETENTION_DAYS="30"

# Security Settings
ENCRYPTION_ENABLED="false"
SSL_VERIFY="true"
MAX_FILE_SIZE="100M"

# Performance Settings
MAX_PARALLEL_JOBS="4"
TIMEOUT_SECONDS="300"
MEMORY_LIMIT="1G"

# Feature Flags
ENABLE_MONITORING="true"
ENABLE_NOTIFICATIONS="false"
ENABLE_AUTO_BACKUP="true"

# Notification Settings (if enabled)
SLACK_WEBHOOK=""        # Set in jstack.config if needed
EMAIL_SMTP_SERVER=""    # Set in jstack.config if needed
EMAIL_FROM=""           # Set in jstack.config if needed

# Custom User Settings (override in jstack.config)
# USER_SPECIFIC_SETTING=""
```

### jstack.config (User-Created)
```bash
#!/bin/bash
# User configuration for jstack
# This file is not version controlled

# Required Settings
DB_USER="myuser"
DB_PASSWORD="secure_password"

# Environment-Specific Overrides
APP_ENVIRONMENT="production"
LOG_LEVEL="warn"
BACKUP_DIR="/home/user/jstack_backups"

# User Preferences
MAX_PARALLEL_JOBS="2"
ENABLE_NOTIFICATIONS="true"
SLACK_WEBHOOK="https://hooks.slack.com/services/..."

# Custom Settings
USER_EMAIL="user@example.com"
PREFERRED_EDITOR="vim"
```

## Configuration Validation

### Required Settings Check
```bash
validate_configuration() {
    local errors=0
    
    # Check required variables
    local required_vars=(
        "DB_USER"
        "DB_PASSWORD"
        "BACKUP_DIR"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "Error: Required configuration variable '$var' is not set"
            ((errors++))
        fi
    done
    
    # Validate directory paths
    if [[ ! -d "$(dirname "$BACKUP_DIR")" ]]; then
        echo "Error: Backup directory parent does not exist: $(dirname "$BACKUP_DIR")"
        ((errors++))
    fi
    
    # Validate numeric values
    if ! [[ "$MAX_PARALLEL_JOBS" =~ ^[0-9]+$ ]]; then
        echo "Error: MAX_PARALLEL_JOBS must be a positive integer"
        ((errors++))
    fi
    
    # Validate enum values
    case "$LOG_LEVEL" in
        debug|info|warn|error) ;;
        *) echo "Error: LOG_LEVEL must be one of: debug, info, warn, error"
           ((errors++)) ;;
    esac
    
    if [[ $errors -gt 0 ]]; then
        echo "Configuration validation failed with $errors error(s)"
        return 1
    fi
    
    return 0
}
```

### Configuration Security
```bash
secure_configuration() {
    # Set restrictive permissions on config file
    chmod 600 "$user_config"
    
    # Verify no sensitive data in defaults
    if grep -q "password\|secret\|key" "$default_config"; then
        echo "Warning: Sensitive data found in default configuration"
    fi
    
    # Check for world-readable config
    if [[ "$(stat -c %a "$user_config")" != "600" ]]; then
        echo "Warning: Configuration file permissions too open"
        echo "Run: chmod 600 jstack.config"
    fi
}
```

## Configuration Management Functions

### Loading Configuration
```bash
load_configuration() {
    local default_config="${SCRIPT_DIR}/jstack.default"
    local user_config="${SCRIPT_DIR}/jstack.config"
    
    # Verify default configuration exists
    if [[ ! -f "$default_config" ]]; then
        echo "Error: Default configuration not found: $default_config"
        exit 1
    fi
    
    # Verify user configuration exists
    if [[ ! -f "$user_config" ]]; then
        echo "Error: User configuration not found: $user_config"
        echo ""
        echo "To create your configuration file:"
        echo "  cp jstack.default jstack.config"
        echo "  edit jstack.config with your settings"
        echo ""
        exit 1
    fi
    
    # Load configurations in order
    source "$default_config"
    source "$user_config"
    
    # Validate and secure
    validate_configuration || exit 1
    secure_configuration
    
    # Log configuration loaded (without sensitive data)
    log_info "Configuration loaded successfully"
    log_debug "Environment: $APP_ENVIRONMENT"
    log_debug "Log level: $LOG_LEVEL"
}
```

### Configuration Helpers
```bash
# Get configuration value with fallback
get_config() {
    local key="$1"
    local default="$2"
    local value="${!key}"
    
    echo "${value:-$default}"
}

# Check if feature is enabled
is_feature_enabled() {
    local feature="$1"
    local value="${!feature}"
    
    [[ "$value" == "true" ]] || [[ "$value" == "1" ]] || [[ "$value" == "yes" ]]
}

# Expand path variables
expand_path() {
    local path="$1"
    
    # Expand ~ to home directory
    path="${path/#~/$HOME}"
    
    # Expand environment variables
    eval echo "$path"
}

# Usage examples
EXPANDED_BACKUP_DIR=$(expand_path "$BACKUP_DIR")
if is_feature_enabled "ENABLE_MONITORING"; then
    setup_monitoring
fi
```

## Git Integration

### .gitignore Configuration
```gitignore
# User configuration (contains sensitive data)
jstack.config

# Log files
*.log
logs/

# Temporary files
tmp/
temp/
.tmp

# Backup files
*.bak
backups/

# Environment-specific files
.env
.env.local
.env.production
```

### Git Hooks for Configuration
```bash
#!/bin/bash
# .git/hooks/pre-commit
# Prevent accidental commit of sensitive files

if git diff --cached --name-only | grep -q "jstack.config"; then
    echo "Error: Attempting to commit jstack.config"
    echo "This file contains sensitive data and should not be committed"
    exit 1
fi

if git diff --cached --name-only | grep -qE "\.(env|config)$"; then
    echo "Warning: Configuration file detected in commit"
    echo "Please verify it doesn't contain sensitive data"
fi
```

## Setup and Installation

### Initial Setup Script
```bash
#!/bin/bash
# setup.sh - Initialize jstack configuration

setup_configuration() {
    local default_config="jstack.default"
    local user_config="jstack.config"
    
    echo "Setting up jstack configuration..."
    
    # Check if user config already exists
    if [[ -f "$user_config" ]]; then
        echo "Configuration file already exists: $user_config"
        read -p "Do you want to recreate it? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled"
            return 1
        fi
    fi
    
    # Copy default to user config
    if [[ ! -f "$default_config" ]]; then
        echo "Error: Default configuration not found: $default_config"
        return 1
    fi
    
    cp "$default_config" "$user_config"
    chmod 600 "$user_config"
    
    echo "Configuration file created: $user_config"
    echo "Please edit this file with your specific settings:"
    echo "  - Database credentials"
    echo "  - Directory paths"
    echo "  - API endpoints"
    echo "  - Notification settings"
    echo ""
    echo "Required settings to configure:"
    grep -E "^[A-Z_]+=.*(Set in jstack.config|required)" "$default_config" || true
}

# Run setup
setup_configuration
```

### Configuration Templates

#### Development Template
```bash
# jstack.config.development
APP_ENVIRONMENT="development"
LOG_LEVEL="debug"
DB_HOST="localhost"
DB_NAME="jstack_dev"
ENABLE_MONITORING="false"
```

#### Production Template
```bash
# jstack.config.production
APP_ENVIRONMENT="production"
LOG_LEVEL="error"
DB_HOST="prod-db.example.com"
DB_NAME="jstack_prod"
ENABLE_MONITORING="true"
SSL_VERIFY="true"
```

## Best Practices

### Security Guidelines
- Never commit `jstack.config` to version control
- Use restrictive file permissions (600) for config files
- Avoid hardcoding sensitive data in scripts
- Regularly audit configuration for exposed secrets
- Use environment variables for highly sensitive data

### Maintenance Guidelines
- Keep `jstack.default` updated with new options
- Document all configuration variables
- Provide example values in defaults
- Version your configuration schema
- Test configuration validation regularly

### Documentation Standards
- Comment all configuration variables
- Provide usage examples
- Document configuration dependencies
- Maintain migration guides for config changes
- Include security considerations for each setting