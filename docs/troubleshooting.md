# Troubleshooting Guide

## General Troubleshooting Approach

### Systematic Problem-Solving
1. **Reproduce the Issue**: Consistently recreate the problem
2. **Gather Information**: Collect logs, error messages, and context
3. **Isolate the Problem**: Narrow down to specific component or interaction
4. **Form Hypothesis**: Develop theories about root cause
5. **Test Solutions**: Try fixes systematically, one at a time
6. **Document Resolution**: Record solution for future reference

### Information Gathering Checklist
- [ ] **Error Messages**: Exact error text and codes
- [ ] **Environment Details**: OS, shell version, dependencies
- [ ] **Recent Changes**: What changed before problem started
- [ ] **Reproduction Steps**: Minimal steps to recreate issue
- [ ] **Logs**: Relevant log entries with timestamps
- [ ] **System State**: Resource usage, running processes

## Common Bash Script Issues

### Script Execution Problems

#### Issue: Permission Denied
```bash
# Error message
bash: ./script.sh: Permission denied

# Diagnosis
ls -la script.sh
# -rw-r--r-- 1 user user 1234 Jan 15 10:00 script.sh

# Solution
chmod +x script.sh

# Prevention
# Always set executable permission when creating scripts
chmod +x new_script.sh
```

#### Issue: Command Not Found
```bash
# Error message
./scripts/core/deploy.sh: line 15: some_command: command not found

# Diagnosis
which some_command
# Check if command exists in PATH

# Solutions
# 1. Install missing dependency
sudo apt-get install required-package

# 2. Use full path
/usr/local/bin/some_command instead of some_command

# 3. Check PATH variable
echo $PATH
export PATH=$PATH:/new/directory
```

#### Issue: Script Exits Unexpectedly
```bash
# Common cause: set -e with commands that return non-zero
set -e
grep "pattern" file.txt  # Exits script if pattern not found

# Solutions
# 1. Handle expected failures
if grep -q "pattern" file.txt; then
    echo "Pattern found"
else
    echo "Pattern not found"
fi

# 2. Temporarily disable exit on error
set +e
grep "pattern" file.txt
result=$?
set -e
if [[ $result -eq 0 ]]; then
    echo "Pattern found"
fi
```

### Variable and Path Issues

#### Issue: Variable Not Expanding
```bash
# Problem
echo "Result: $result"
# Output: Result:

# Diagnosis
# Variable might not be set or in wrong scope

# Solutions
# 1. Check if variable is set
if [[ -z "$result" ]]; then
    echo "Variable 'result' is not set"
fi

# 2. Verify scope (use 'local' in functions)
function test_function() {
    local result="value"  # Only accessible within function
    echo "$result"
}

# 3. Export for child processes
export GLOBAL_VAR="value"
```

#### Issue: Path Resolution Problems
```bash
# Problem
source ../lib/common.sh
# Error: No such file or directory

# Solution: Use absolute paths based on script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Alternative: Check if file exists before sourcing
if [[ -f "${PROJECT_ROOT}/scripts/lib/common.sh" ]]; then
    source "${PROJECT_ROOT}/scripts/lib/common.sh"
else
    echo "Error: Cannot find common.sh library" >&2
    exit 1
fi
```

### File and Directory Issues

#### Issue: File Not Found Errors
```bash
# Problem
cp important_file.txt backup/
# Error: No such file or directory

# Diagnosis and solutions
# 1. Check if source file exists
if [[ ! -f "important_file.txt" ]]; then
    echo "Source file not found: important_file.txt"
    exit 1
fi

# 2. Check if destination directory exists
if [[ ! -d "backup" ]]; then
    mkdir -p backup
fi

# 3. Use full paths
cp "/full/path/to/important_file.txt" "/full/path/to/backup/"
```

#### Issue: Permission Problems
```bash
# Problem
mkdir /etc/myapp
# Error: Permission denied

# Solutions
# 1. Check current permissions
ls -ld /etc/
id  # Check current user/groups

# 2. Use appropriate permissions
sudo mkdir /etc/myapp
sudo chown myuser:mygroup /etc/myapp

# 3. Use user-accessible locations
mkdir -p "$HOME/.local/share/myapp"
```

## Debugging Techniques

### Enable Debug Mode
```bash
# Method 1: Command line
bash -x script.sh

# Method 2: In script
set -x  # Enable debug output
command_to_debug
set +x  # Disable debug output

# Method 3: Conditional debugging
if [[ "${DEBUG:-false}" == "true" ]]; then
    set -x
fi
```

### Add Logging and Tracing
```bash
# Simple logging function
log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "[DEBUG $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
    fi
}

log_info() {
    echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Usage
log_debug "Processing file: $filename"
log_info "Starting backup process"
log_error "Failed to connect to database"
```

### Variable State Inspection
```bash
# Debug variable contents
echo "DEBUG: variable_name='$variable_name'"
echo "DEBUG: array contents: ${array[@]}"
declare -p variable_name  # Show variable type and value

# Check environment
env | grep MYAPP  # Show all MYAPP-related variables
set | grep function_name  # Show function definitions
```

### Function Call Tracing
```bash
# Add entry/exit logging to functions
debug_function() {
    local func_name="$1"
    shift
    log_debug "ENTER: $func_name($*)"
    
    # Call original function
    "$func_name" "$@"
    local result=$?
    
    log_debug "EXIT: $func_name (exit code: $result)"
    return $result
}

# Wrap function calls for debugging
if [[ "${DEBUG:-false}" == "true" ]]; then
    debug_function process_data "$input_file"
else
    process_data "$input_file"
fi
```

## Performance Issues

### Slow Script Execution

#### Diagnosis
```bash
# Time the entire script
time ./script.sh

# Time specific sections
start_time=$(date +%s)
slow_operation
end_time=$(date +%s)
echo "Operation took $((end_time - start_time)) seconds"

# Profile with detailed timing
set -x
PS4='+ $(date "+%s.%N ($LINENO) ")'
slow_section_of_script
set +x
```

#### Common Performance Issues
```bash
# ❌ Inefficient: Command in loop
for file in *.txt; do
    lines=$(wc -l < "$file")  # Spawns process for each file
    echo "$file: $lines lines"
done

# ✅ Efficient: Batch processing
wc -l *.txt | while read lines file; do
    echo "$file: $lines lines"
done

# ❌ Inefficient: Repeated file access
for i in {1..1000}; do
    echo "Line $i" >> output.txt  # Opens file 1000 times
done

# ✅ Efficient: Single file access
{
    for i in {1..1000}; do
        echo "Line $i"
    done
} > output.txt
```

### Memory Issues

#### Diagnosis
```bash
# Monitor memory usage
ps aux | grep script_name
top -p PID

# Check for memory leaks in loops
while true; do
    # Monitor this loop for memory growth
    ps -o pid,vsz,rss -p $$
    do_some_work
    sleep 1
done
```

#### Solutions
```bash
# ❌ Memory-intensive: Loading large files into variables
large_content=$(cat huge_file.txt)  # Loads entire file into memory

# ✅ Memory-efficient: Process line by line
while IFS= read -r line; do
    process_line "$line"
done < huge_file.txt

# ❌ Array memory issues
declare -a huge_array
for i in {1..1000000}; do
    huge_array[i]="data"  # Uses lots of memory
done

# ✅ Process data as needed
for i in {1..1000000}; do
    process_item "data"  # No persistent storage
done
```

## Integration Issues

### Service Communication Problems

#### Issue: Cannot Connect to External Service
```bash
# Diagnosis
curl -v http://external-service.com/api
nslookup external-service.com
ping external-service.com
telnet external-service.com 80

# Check proxy settings
echo $http_proxy
echo $https_proxy
echo $no_proxy

# Solutions
# 1. Verify network connectivity
# 2. Check firewall rules
# 3. Validate SSL certificates
# 4. Confirm service endpoints
```

#### Issue: Database Connection Failures
```bash
# Diagnosis commands
# For PostgreSQL
pg_isready -h hostname -p port -U username

# For MySQL
mysqladmin ping -h hostname -u username -p

# For SQLite
sqlite3 database.db ".tables"

# Common solutions
# 1. Check connection parameters
# 2. Verify user permissions
# 3. Test network connectivity
# 4. Check service status
```

### File System Issues

#### Issue: Disk Space Problems
```bash
# Diagnosis
df -h  # Check disk space
du -sh directory/*  # Check directory sizes
lsof | grep deleted  # Find deleted files still open

# Solutions
# 1. Clean up temporary files
find /tmp -type f -atime +7 -delete

# 2. Rotate/compress logs
gzip large_log_file.log

# 3. Remove old backups
find /backups -type f -mtime +30 -delete
```

#### Issue: File Locking Problems
```bash
# Diagnosis
lsof filename  # See what processes have file open
fuser filename  # Find processes using file

# Solutions
# 1. Wait for process to complete
# 2. Kill processes if safe
kill -TERM PID

# 3. Use proper file locking
{
    flock -x 200
    # Critical section with exclusive lock
} 200>/var/lock/myapp.lock
```

## Environment-Specific Issues

### Development Environment

#### Issue: Missing Dependencies
```bash
# Diagnosis
command -v required_tool || echo "Tool not found"
which python3
python3 --version

# Solutions
# 1. Install system packages
sudo apt-get install package-name

# 2. Install Python packages
pip3 install package-name

# 3. Use virtual environments
python3 -m venv venv
source venv/bin/activate
pip install requirements.txt
```

### Production Environment

#### Issue: Environment Variables Not Set
```bash
# Diagnosis
env | grep MYAPP
echo $IMPORTANT_VAR

# Solutions
# 1. Check environment file
cat /etc/environment
source /etc/myapp/environment

# 2. Set in systemd service
# In service file:
Environment=MYAPP_CONFIG=/etc/myapp/config
EnvironmentFile=/etc/myapp/environment

# 3. Default values in script
MYAPP_CONFIG="${MYAPP_CONFIG:-/etc/myapp/default.conf}"
```

## Monitoring and Alerting Issues

### Log Analysis
```bash
# Common log analysis commands
# Search for errors
grep -i error /var/log/myapp.log

# Count occurrences
grep -c "connection failed" /var/log/myapp.log

# Time-based filtering
awk '$0 ~ /2025-01-15 14:/ {print}' /var/log/myapp.log

# Multiple files
zgrep "error" /var/log/myapp.log*

# Real-time monitoring
tail -f /var/log/myapp.log | grep --color error
```

### System Resource Monitoring
```bash
# CPU usage
top
htop
iostat -x 1

# Memory usage
free -h
vmstat 1

# Disk I/O
iotop
df -h
lsof | wc -l  # Open file count

# Network
netstat -tuln
ss -tuln
iftop
```

## Emergency Procedures

### System Recovery
```bash
# 1. Stop problematic processes
pkill -f script_name
systemctl stop myapp

# 2. Check system resources
df -h
free -h
ps aux --sort=-%cpu | head -10

# 3. Clean up if necessary
rm -rf /tmp/problematic_files
kill -9 stuck_process_pid

# 4. Restart services
systemctl start myapp
systemctl status myapp
```

### Data Recovery
```bash
# 1. Check recent backups
ls -la /backups/ | tail -10

# 2. Verify backup integrity
tar -tzf backup.tar.gz > /dev/null

# 3. Restore from backup
tar -xzf backup.tar.gz -C /restore/location

# 4. Validate restored data
diff -r original/ restored/
```

## Prevention Strategies

### Proactive Monitoring
```bash
# Health check script
#!/bin/bash
check_disk_space() {
    usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $usage -gt 90 ]]; then
        echo "WARNING: Disk usage at ${usage}%"
        return 1
    fi
}

check_memory() {
    available=$(free | awk 'NR==2{printf "%.0f", $7/$2*100}')
    if [[ $available -lt 10 ]]; then
        echo "WARNING: Memory usage critical"
        return 1
    fi
}

# Run checks
check_disk_space && check_memory
```

### Error Prevention
```bash
# Input validation
validate_input() {
    local input="$1"
    
    if [[ -z "$input" ]]; then
        log_error "Input cannot be empty"
        return 1
    fi
    
    if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Input contains invalid characters"
        return 1
    fi
    
    return 0
}

# Resource limits
ulimit -f 1000000  # Limit file size
ulimit -t 300      # Limit CPU time
ulimit -v 1000000  # Limit virtual memory
```

### Documentation and Runbooks
- Maintain up-to-date troubleshooting documentation
- Create runbooks for common scenarios
- Document all configuration changes
- Keep contact information for escalation
- Regular review and updates of procedures