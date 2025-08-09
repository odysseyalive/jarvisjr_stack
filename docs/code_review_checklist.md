# Code Review Checklist

## Review Philosophy

### Core Objectives
- **Functionality**: Code works as intended and meets requirements
- **Quality**: Code is clean, maintainable, and follows standards
- **Security**: No security vulnerabilities or sensitive data exposure
- **Performance**: Code is efficient and doesn't introduce bottlenecks
- **Documentation**: Changes are properly documented and explained

### Review Mindset
- **Constructive**: Focus on improving code quality, not criticizing
- **Educational**: Share knowledge and learn from each other
- **Collaborative**: Work together to find the best solution
- **Thorough**: Take time to understand the changes completely

## Pre-Review Requirements

### Author Checklist (Before Requesting Review)
- [ ] Code follows project style guidelines
- [ ] All tests pass locally
- [ ] Documentation updated where necessary
- [ ] Self-review completed
- [ ] Commit messages are clear and descriptive
- [ ] PR description explains what and why

### Reviewer Assignment
- **Primary Reviewer**: Must be familiar with the codebase area
- **Secondary Reviewer**: Optional for complex or critical changes
- **Domain Expert**: Required for security, performance, or architecture changes

## Bash Script Specific Checks

### Script Structure and Organization
- [ ] **File Location**: Script placed in correct directory (`scripts/core/`, `scripts/utils/`, etc.)
- [ ] **Size Limit**: Script stays under token limit (~15KB)
- [ ] **Modularization**: Large scripts broken into appropriate modules
- [ ] **Main Script**: Only orchestration logic in `jstack.sh`

### Script Header and Documentation
```bash
# ✅ Good example
#!/bin/bash
# Purpose: Backup user data and configurations
# Usage: backup.sh [--type=full|incremental] [--target=/path/to/backup]
# Author: Team Name
# Last Modified: 2025-01-15

# ❌ Bad example
#!/bin/bash
# does backup stuff
```

### Error Handling
- [ ] **Set Options**: Uses `set -euo pipefail` for strict error handling
- [ ] **Exit Codes**: Appropriate exit codes for different failure scenarios
- [ ] **Error Messages**: Clear, actionable error messages
- [ ] **Cleanup**: Proper cleanup in error conditions

```bash
# ✅ Good error handling
cleanup() {
    rm -rf "$temp_dir"
    log_info "Cleanup completed"
}
trap cleanup EXIT

if ! validate_input "$1"; then
    log_error "Invalid input: $1"
    echo "Usage: $0 <valid_input>" >&2
    exit 1
fi

# ❌ Poor error handling
rm important_file  # No validation or error checking
```

### Variable and Function Naming
- [ ] **Descriptive Names**: Variables and functions have clear, descriptive names
- [ ] **Consistent Style**: snake_case for variables, functions
- [ ] **Constants**: UPPER_CASE for constants and environment variables
- [ ] **Local Variables**: Proper use of `local` in functions

```bash
# ✅ Good naming
local backup_directory="/path/to/backups"
readonly MAX_RETRY_ATTEMPTS=3

process_user_data() {
    local user_id="$1"
    # ...
}

# ❌ Poor naming
d="/tmp"  # Unclear abbreviation
temp_stuff()  # Vague function name
x="$1"  # Non-descriptive parameter
```

### Script Safety and Security
- [ ] **Input Validation**: All inputs validated before use
- [ ] **Path Safety**: Proper quoting and path handling
- [ ] **Privilege Escalation**: Minimal privilege requirements
- [ ] **Sensitive Data**: No hardcoded secrets or credentials

```bash
# ✅ Safe practices
if [[ ! -f "$config_file" ]]; then
    log_error "Config file not found: $config_file"
    exit 1
fi

# Process file safely
while IFS= read -r line; do
    process_line "$line"
done < "$safe_file_path"

# ❌ Unsafe practices
rm -rf $user_input/*  # Unquoted variable expansion
eval $command  # Dangerous eval usage
```

### Code Quality Standards

#### Function Design
- [ ] **Single Responsibility**: Each function has one clear purpose
- [ ] **Size Limit**: Functions are reasonably sized (< 50 lines typically)
- [ ] **Parameters**: Clear parameter handling and validation
- [ ] **Return Values**: Consistent return value conventions

```bash
# ✅ Well-designed function
validate_email() {
    local email="$1"
    
    if [[ -z "$email" ]]; then
        log_error "Email cannot be empty"
        return 1
    fi
    
    if [[ ! "$email" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        log_error "Invalid email format: $email"
        return 1
    fi
    
    return 0
}
```

#### Code Organization
- [ ] **Logical Flow**: Code flows logically from setup to execution to cleanup
- [ ] **DRY Principle**: No unnecessary code duplication
- [ ] **Separation of Concerns**: Different responsibilities in different functions/files
- [ ] **Configuration**: Configuration separated from logic

#### Performance Considerations
- [ ] **Efficiency**: No obvious performance bottlenecks
- [ ] **Resource Usage**: Appropriate memory and CPU usage
- [ ] **External Calls**: Minimal unnecessary external command calls
- [ ] **Parallel Processing**: Use of background jobs where appropriate

```bash
# ✅ Efficient approach
# Process files in parallel
for file in *.txt; do
    process_file "$file" &
done
wait  # Wait for all background jobs

# ❌ Inefficient approach
# Process files sequentially when parallel is possible
for file in *.txt; do
    process_file "$file"
done
```

## General Code Review Criteria

### Functionality Review
- [ ] **Requirements Met**: Code solves the intended problem
- [ ] **Edge Cases**: Handles edge cases and error conditions
- [ ] **Integration**: Works correctly with existing system
- [ ] **Backwards Compatibility**: Doesn't break existing functionality

### Code Quality Review
- [ ] **Readability**: Code is easy to read and understand
- [ ] **Maintainability**: Code can be easily modified and extended
- [ ] **Consistency**: Follows established project patterns
- [ ] **Simplicity**: Uses the simplest approach that works

### Testing Review
- [ ] **Test Coverage**: Adequate tests for new functionality
- [ ] **Test Quality**: Tests are meaningful and well-written
- [ ] **Test Independence**: Tests don't depend on each other
- [ ] **Integration Tests**: Complex interactions are tested

### Documentation Review
- [ ] **Code Comments**: Complex logic is explained
- [ ] **Function Documentation**: Functions have clear documentation
- [ ] **Usage Examples**: Non-obvious usage is demonstrated
- [ ] **README Updates**: Public interface changes documented

## Security Review Checklist

### Input Validation
- [ ] **User Input**: All user input is validated and sanitized
- [ ] **File Paths**: Path traversal vulnerabilities prevented
- [ ] **Command Injection**: No possibility of command injection
- [ ] **SQL Injection**: Database queries are parameterized (if applicable)

### Access Control
- [ ] **Permissions**: Appropriate file and directory permissions
- [ ] **Privilege Separation**: Runs with minimal required privileges
- [ ] **Authentication**: Proper authentication mechanisms
- [ ] **Authorization**: Proper authorization checks

### Data Handling
- [ ] **Sensitive Data**: No sensitive data in logs or output
- [ ] **Encryption**: Sensitive data encrypted in transit and at rest
- [ ] **Data Exposure**: No unnecessary data exposure
- [ ] **Cleanup**: Temporary files and sensitive data properly cleaned up

## Performance Review Checklist

### Resource Usage
- [ ] **Memory Efficiency**: No memory leaks or excessive usage
- [ ] **CPU Efficiency**: Reasonable CPU usage patterns
- [ ] **I/O Efficiency**: Minimal unnecessary disk/network I/O
- [ ] **Caching**: Appropriate use of caching mechanisms

### Scalability
- [ ] **Load Handling**: Can handle expected load
- [ ] **Growth Patterns**: Scales appropriately with data growth
- [ ] **Bottlenecks**: No obvious performance bottlenecks
- [ ] **Monitoring**: Adequate performance monitoring

## Common Issues to Watch For

### Bash-Specific Anti-patterns
```bash
# ❌ Common mistakes
for i in `ls *.txt`; do  # Use shell glob instead
    echo $i              # Missing quotes
done

cd $some_dir || exit     # Should validate directory exists
rm -rf $HOME/$folder     # Dangerous path construction

# ✅ Better approaches
for file in *.txt; do
    echo "$file"
done

if [[ -d "$some_dir" ]]; then
    cd "$some_dir" || exit 1
else
    log_error "Directory not found: $some_dir"
    exit 1
fi
```

### General Code Issues
- **Magic Numbers**: Use named constants instead of magic numbers
- **Long Functions**: Break down functions that are too long
- **Deep Nesting**: Reduce nesting levels for better readability
- **Copy-Paste Code**: Extract common functionality into functions

## Review Process

### Review Workflow
1. **Initial Review**: Quick overview of changes and approach
2. **Detailed Review**: Line-by-line examination
3. **Testing Review**: Verify tests are adequate and passing
4. **Documentation Review**: Check documentation completeness
5. **Final Approval**: Approve or request changes

### Feedback Guidelines
- **Be Specific**: Point to exact lines and explain issues clearly
- **Suggest Solutions**: Don't just identify problems, suggest fixes
- **Explain Reasoning**: Help the author understand why changes are needed
- **Acknowledge Good Work**: Recognize well-written code

### Review Comments Examples
```markdown
# ✅ Good feedback
Line 45: Consider using `readonly` for this constant since it's never modified.
This would make the intent clearer and prevent accidental changes.

# ✅ Constructive suggestion
Lines 67-80: This function is doing multiple things. Consider splitting it into:
- `validate_input()` for input validation
- `process_data()` for the main logic
This would improve testability and readability.

# ❌ Poor feedback
This is wrong.
Bad code.
Why did you do it this way?
```

### Response to Feedback
- **Address All Comments**: Respond to every review comment
- **Ask for Clarification**: If feedback isn't clear, ask questions
- **Explain Decisions**: Justify design choices when necessary
- **Be Open to Learning**: View feedback as learning opportunity

## Approval Criteria

### Must Have (Blocking Issues)
- Functionality works correctly
- No security vulnerabilities
- Tests pass and provide adequate coverage
- No performance regressions
- Follows project standards

### Should Have (Strong Recommendations)
- Clear, readable code
- Proper error handling
- Good documentation
- Efficient implementation
- Follows best practices

### Nice to Have (Suggestions)
- Code optimizations
- Additional test cases
- Enhanced documentation
- Future-proofing considerations
- Style improvements

## Post-Review Actions

### After Approval
- [ ] Merge using appropriate strategy (squash, merge, rebase)
- [ ] Delete feature branch
- [ ] Update project documentation if needed
- [ ] Monitor deployment for any issues
- [ ] Close related issues/tickets

### Continuous Improvement
- Regularly review and update this checklist
- Gather feedback on review process
- Share common issues found in reviews
- Update coding standards based on review findings