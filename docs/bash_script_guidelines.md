# Bash Script Management Guidelines

## Overview
This document defines the principles and structure for managing bash scripts in this project. These guidelines ensure maintainability, modularity, and consistency across all script development.

## Project Structure

### Directory Layout
```
project-root/
├── jstack.sh              # Main orchestration script (entry point)
├── jstack.default         # Default configuration (version controlled)
├── jstack.config          # User configuration (not in git - required)
└── scripts/               # All modular scripts live here
    ├── core/              # Core functionality modules
    ├── utils/             # Utility functions and helpers
    ├── lib/               # Shared libraries and common functions
    └── settings/          # Configuration and environment setup
```

### Configuration System
- **jstack.default**: Contains all default values, shipped with project
- **jstack.config**: User-created configuration file (required for operation)
- **Configuration precedence**: jstack.config overrides jstack.default
- **Git management**: jstack.default is tracked, jstack.config is ignored

### File Naming Conventions
- **Main script**: `jstack.sh` (project entry point)
- **Module scripts**: Descriptive names with `.sh` extension
- **Library files**: `lib_*.sh` or functional names like `common.sh`
- **Utility scripts**: Action-based names like `validate.sh`, `cleanup.sh`
- **Settings files**: `defaults.sh`, `env.sh`, `paths.sh`

## Core Principles

### 1. Modularization Requirements
- **Single Responsibility**: Each script should handle one specific task or domain
- **Token Limit Compliance**: Individual scripts must stay under 25,000 tokens (~15KB)
- **Reusability**: Functions should be extractable and reusable across modules
- **Independence**: Each module should work independently when possible

### 2. Script Organization
- **Main Script Role**: `jstack.sh` serves only as orchestrator and entry point
- **No Business Logic in Main**: All functionality goes in `/scripts/` subdirectories
- **Proper Sourcing**: Use relative paths from script location for sourcing
- **Error Propagation**: Errors should bubble up to main script for handling

### 3. Code Structure Standards
```bash
#!/bin/bash
# Script header with purpose and usage
# Author, date, version info

# Set script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Source dependencies
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Main function pattern
main() {
    # Implementation here
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Implementation Guidelines

### When to Create New Modules
- **Size Threshold**: When a script approaches 12KB
- **Functional Separation**: When distinct features can be isolated
- **Reusability**: When code is used in multiple places
- **Complexity**: When functions become difficult to understand

### Refactoring Process
1. **Identify** discrete functional units
2. **Extract** functions into appropriate `/scripts/` subdirectories
3. **Create** clean interfaces between modules
4. **Update** main script to orchestrate new modules
5. **Test** all integration points
6. **Document** changes and new module purposes

### Directory Usage Guidelines

#### `/scripts/core/`
- Primary business logic modules
- Feature-specific implementations
- Main workflow components

#### `/scripts/utils/`
- Helper functions
- Data validation and formatting
- File and directory operations
- Input/output utilities

#### `/scripts/lib/`
- Shared libraries and common functions
- Constants and global variables
- Error handling frameworks
- Logging utilities

#### `/scripts/settings/`
- Configuration management
- Environment variable handling
- Default value definitions
- Path and URL configurations

## Development Workflow

### Adding New Functionality
1. Determine appropriate subdirectory based on function type
2. Create modular script following naming conventions
3. Implement with proper error handling and documentation
4. Update main script to integrate new module
5. Test integration and individual module functionality

### Modifying Existing Scripts
1. Check current script size against token limits
2. If approaching limits, plan modularization strategy
3. Extract logical components following single responsibility principle
4. Maintain backward compatibility in main script interface
5. Update documentation to reflect changes

## Best Practices

### Error Handling
- Use consistent exit codes across all modules
- Implement proper error propagation to main script
- Provide meaningful error messages with context
- Log errors appropriately for debugging

### Documentation
- Include purpose and usage comments in script headers
- Document function parameters and return values
- Maintain README files for complex modules
- Update main script help/usage information

### Testing
- Each module should be testable independently
- Main script should validate module availability
- Include basic smoke tests for critical functionality
- Test integration points between modules

## Migration Strategy

### For Existing Large Scripts
1. **Audit**: Identify current script size and complexity
2. **Map**: Outline logical functional boundaries
3. **Prioritize**: Start with most independent components
4. **Extract**: Move functions to appropriate subdirectories
5. **Integrate**: Update main script orchestration
6. **Validate**: Ensure functionality remains intact

### Maintenance Considerations
- Regular size monitoring of all scripts
- Periodic review of module dependencies
- Cleanup of unused or deprecated modules
- Documentation updates with structural changes

---

**Note for Claude Code**: When working with bash scripts in this project, always refer to these guidelines for structural decisions, file placement, and modularization strategies. Maintain this structure and follow these principles for all script-related tasks.