# Testing Standards

## Testing Philosophy

### Core Principles
- **Test Early**: Write tests alongside development, not after
- **Test Independence**: Each test should run independently
- **Test Clarity**: Tests should be self-documenting and easy to understand
- **Test Coverage**: Focus on critical paths and edge cases

### Testing Pyramid
1. **Unit Tests**: Individual functions and modules (70%)
2. **Integration Tests**: Module interactions (20%)
3. **End-to-End Tests**: Complete workflows (10%)

## Bash Script Testing

### Test File Structure
```
tests/
├── unit/
│   ├── test_core_functions.sh
│   ├── test_utils.sh
│   └── test_settings.sh
├── integration/
│   ├── test_script_interactions.sh
│   └── test_main_workflows.sh
├── e2e/
│   └── test_complete_scenarios.sh
├── fixtures/
│   ├── sample_data/
│   └── mock_configs/
└── helpers/
    ├── test_framework.sh
    └── assertions.sh
```

### Testing Framework

#### Basic Test Structure
```bash
#!/bin/bash
# Test file header
source "$(dirname "$0")/../helpers/test_framework.sh"
source "$(dirname "$0")/../../scripts/lib/common.sh"

setup() {
    # Setup test environment
    export TEST_MODE=true
    mkdir -p /tmp/test_workspace
}

teardown() {
    # Cleanup after tests
    rm -rf /tmp/test_workspace
}

test_function_returns_expected_value() {
    # Arrange
    local input="test_input"
    local expected="expected_output"
    
    # Act
    local result=$(target_function "$input")
    
    # Assert
    assert_equals "$expected" "$result" "Function should return expected value"
}

# Run tests
run_tests
```

#### Assertion Functions
```bash
# In helpers/assertions.sh
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    if [[ "$expected" != "$actual" ]]; then
        echo "FAIL: $message"
        echo "  Expected: '$expected'"
        echo "  Actual: '$actual'"
        return 1
    fi
    echo "PASS: $message"
}

assert_file_exists() {
    local file_path="$1"
    local message="${2:-File should exist}"
    
    if [[ ! -f "$file_path" ]]; then
        echo "FAIL: $message - File not found: $file_path"
        return 1
    fi
    echo "PASS: $message"
}

assert_command_succeeds() {
    local command="$1"
    local message="${2:-Command should succeed}"
    
    if ! eval "$command" &>/dev/null; then
        echo "FAIL: $message - Command failed: $command"
        return 1
    fi
    echo "PASS: $message"
}
```

## Test Categories

### Unit Tests
- **Target**: Individual functions within modules
- **Scope**: Single responsibility testing
- **Isolation**: Mock external dependencies
- **Speed**: Fast execution (< 1 second each)

#### Example Unit Test
```bash
test_validate_email_function() {
    # Valid email
    assert_command_succeeds "validate_email 'user@example.com'" \
        "Should accept valid email format"
    
    # Invalid email
    assert_command_fails "validate_email 'invalid-email'" \
        "Should reject invalid email format"
    
    # Empty input
    assert_command_fails "validate_email ''" \
        "Should reject empty email input"
}
```

### Integration Tests
- **Target**: Module interactions and dependencies
- **Scope**: Multiple components working together
- **Environment**: Controlled test environment
- **Data**: Realistic test data and scenarios

#### Example Integration Test
```bash
test_backup_and_restore_workflow() {
    # Setup test data
    echo "test data" > /tmp/test_file.txt
    
    # Test backup creation
    assert_command_succeeds "./scripts/core/backup.sh /tmp/test_file.txt" \
        "Backup should be created successfully"
    
    # Verify backup exists
    assert_file_exists "/tmp/backup/test_file.txt" \
        "Backup file should exist"
    
    # Test restore process
    rm /tmp/test_file.txt
    assert_command_succeeds "./scripts/core/restore.sh /tmp/backup/test_file.txt" \
        "Restore should work successfully"
    
    # Verify restored content
    local content=$(cat /tmp/test_file.txt)
    assert_equals "test data" "$content" \
        "Restored file should have original content"
}
```

### End-to-End Tests
- **Target**: Complete user workflows
- **Scope**: Full system behavior
- **Environment**: Production-like setup
- **Scenarios**: Real-world usage patterns

#### Example E2E Test
```bash
test_complete_deployment_workflow() {
    # Test complete jstack.sh workflow
    assert_command_succeeds "./jstack.sh deploy --env=test" \
        "Complete deployment should succeed"
    
    # Verify deployment artifacts
    assert_file_exists "/tmp/deployment/app.tar.gz" \
        "Deployment package should be created"
    
    # Test rollback capability
    assert_command_succeeds "./jstack.sh rollback --version=previous" \
        "Rollback should work after deployment"
}
```

## Test Data Management

### Test Fixtures
- Store sample data in `tests/fixtures/`
- Use realistic but anonymized data
- Version control test data with code
- Keep fixtures small and focused

### Mock Data Generation
```bash
# In helpers/test_data.sh
generate_test_config() {
    cat > /tmp/test.conf << EOF
DATABASE_URL=sqlite:///tmp/test.db
LOG_LEVEL=debug
BACKUP_DIR=/tmp/test_backups
EOF
}

generate_sample_users() {
    cat > /tmp/users.txt << EOF
alice@example.com
bob@example.com
charlie@example.com
EOF
}
```

## Test Execution

### Running Tests
```bash
# Run all tests
./run_tests.sh

# Run specific test category
./run_tests.sh unit
./run_tests.sh integration
./run_tests.sh e2e

# Run specific test file
./run_tests.sh tests/unit/test_utils.sh

# Run with verbose output
./run_tests.sh --verbose
```

### Continuous Integration
- All tests must pass before merging
- Run tests on multiple environments
- Generate test coverage reports
- Fail fast on critical test failures

### Test Runner Script
```bash
#!/bin/bash
# run_tests.sh
set -e

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tests"
VERBOSE=false

run_test_file() {
    local test_file="$1"
    echo "Running: $(basename "$test_file")"
    
    if [[ "$VERBOSE" == "true" ]]; then
        bash "$test_file"
    else
        bash "$test_file" | grep -E "(PASS|FAIL|ERROR)"
    fi
}

# Parse arguments and run appropriate tests
case "${1:-all}" in
    "unit")     find "$TEST_DIR/unit" -name "*.sh" -exec bash {} \; ;;
    "integration") find "$TEST_DIR/integration" -name "*.sh" -exec bash {} \; ;;
    "e2e")      find "$TEST_DIR/e2e" -name "*.sh" -exec bash {} \; ;;
    "all")      find "$TEST_DIR" -name "test_*.sh" -exec bash {} \; ;;
    *)          run_test_file "$1" ;;
esac
```

## Quality Gates

### Pre-commit Checks
- Syntax validation (`bash -n script.sh`)
- Code style checks (`shellcheck`)
- Basic smoke tests
- Documentation updates

### Test Coverage Requirements
- **Critical functions**: 100% coverage
- **Core modules**: 90% coverage
- **Utility functions**: 80% coverage
- **Integration points**: 95% coverage

### Performance Benchmarks
- Unit tests: < 1 second each
- Integration tests: < 10 seconds each
- E2E tests: < 60 seconds each
- Full test suite: < 5 minutes

## Best Practices

### Writing Good Tests
- Use descriptive test names that explain the scenario
- Follow Arrange-Act-Assert pattern
- Test one thing at a time
- Include both positive and negative test cases
- Test edge cases and error conditions

### Test Maintenance
- Review and update tests when functionality changes
- Remove obsolete tests for deprecated features
- Keep tests simple and focused
- Avoid testing implementation details

### Debugging Failed Tests
- Use verbose output to understand failures
- Isolate failing tests for debugging
- Check test environment setup
- Verify test data and assumptions
- Use debugging tools and logging