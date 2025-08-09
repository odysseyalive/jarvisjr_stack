# Module Execution Pattern

All modules in this project are designed to work without executable permissions.

## Usage Pattern

Instead of:
```bash
./scripts/core/setup.sh run
```

Use:
```bash
bash scripts/core/setup.sh run
```

This ensures the modules work regardless of file permissions, making the system more robust and portable.

## Module Structure

Each module follows the pattern:
```bash
#!/bin/bash
# Module description

# Main function
main() {
    # Implementation
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

This pattern allows modules to be both sourced as libraries and executed directly with bash.