# Claude Code Instructions

## Project Documentation

Before making any changes to this project, review the documentation in the `docs/` directory. Use the filenames to determine which guidelines and principles apply to your current task.

## Documentation Architecture

### Index-Based System

- **Main docs files** (e.g., `docs/testing-standards.md`) serve as indexes
- **Subdirectory files** (e.g., `docs/testing-standards/unit-testing.md`) contain focused content
- **Load only relevant files** based on your current task context
- **Follow index guidance** to determine which specific files to reference

### File Size Monitoring

- **Check file sizes first**: Before working with any docs file, check if it exceeds 12k characters
- **Proactive optimization**: If a file is too large, suggest optimization before proceeding with the user's request
- **Explain the benefit**: Make clear that optimization will improve context efficiency for the current task
- **User choice**: Always wait for approval before optimizing
- **Workflow protection**: Prevent context issues by addressing size problems upfront

Example: "I see you want to update deployment-process.md, but it's currently 15k characters. Should I optimize it into focused subdirectories first? This will help me work with it more effectively and give you better results."

## Documentation Optimization

### When to Optimize

- **User requests explicitly**: "optimize docs/filename.md"
- **New large files created**: Files approaching or exceeding 12k characters
- **Never automatically**: Only when specifically requested

### Optimization Process

1. **Check if already optimized**: Look for existing `docs/filename/` subdirectory
2. **If already optimized**: Inform user and skip
3. **If not optimized**: Break down into logical, focused files
4. **Create index file**: Replace original with navigation/index content
5. **Create subdirectory**: `docs/filename/` with specific content files
6. **Verify file sizes**: Ensure all subdirectory files are 10k-12k characters max
7. **Use descriptive names**: File names should clearly indicate their purpose

### Optimization Rules

- **Only optimize files directly in** `/docs/` directory
- **Never optimize files in** `/docs/*/` subdirectories
- **Never optimize files with existing subdirectories**
- **Split by subject only**: Each file must cover one complete subject/topic
- **Logical navigation**: File names must clearly indicate their subject matter
- **No arbitrary splitting**: Never split based on size alone - always by logical subject boundaries
- **Complete subject coverage**: Each split file should contain everything about its specific subject
- **Cross-reference appropriately**: Related subjects should reference each other in index

## Key Documentation Files

- Review files that match your current work context
- File names indicate their scope and applicability
- Follow the principles and guidelines outlined in relevant docs
- Maintain consistency with established patterns

## Proactive Documentation Management

### Required Actions

When working on this project, you MUST:

1. **Update Existing Documentation**: If your changes affect existing processes, update the relevant docs immediately
2. **Create New Documentation**: If you identify gaps or new patterns, create appropriate documentation files
3. **Maintain Documentation Quality**: Ensure all docs remain current, accurate, and helpful
4. **Respect Size Limits**: Keep subdirectory files within 10k-12k character limits
5. **Work Iteratively**: Focus on one documentation improvement at a time

### Iterative Documentation Process

- **One improvement per iteration**: Focus on single, specific changes rather than comprehensive overhauls
- **Seek review between steps**: Wait for user approval before proceeding to next improvement
- **Suggest next steps**: After completing changes, identify the next potential improvement for user consideration
- **Respect user pacing**: Let users control when to continue optimization process
- **Clear completion**: Each iteration should have obvious start and end points
- **Context preservation**: Reference what was just completed when suggesting next steps

### Documentation Triggers

Automatically create or update documentation when you:

- **Add new scripts or modules** → Update `bash-script-guidelines.md` or relevant subdirectory files
- **Identify performance issues** → Create/update performance analysis docs
- **Encounter bugs or failures** → Add to `troubleshooting.md` or relevant subdirectory files
- **Implement new testing patterns** → Update `testing-standards.md` or subdirectory files
- **Change deployment processes** → Update `deployment-process.md` or subdirectory files
- **Establish new coding patterns** → Update `code-review-checklist.md` or subdirectory files
- **Modify git workflows** → Update `git-workflow.md` or subdirectory files
- **Change configuration patterns** → Update `configuration-management.md` or subdirectory files

### Documentation Creation Guidelines

Create new documentation files for:

- **Performance benchmarks** → `performance-benchmarks.md` (with subdirectory if large)
- **Security protocols** → `security-guidelines.md` (with subdirectory if large)
- **API documentation** → `api-reference.md` (with subdirectory if large)
- **Monitoring setup** → `monitoring-setup.md` (with subdirectory if large)
- **Backup procedures** → `backup-recovery.md` (with subdirectory if large)
- **Environment setup** → `environment-setup.md` (with subdirectory if large)
- **Common patterns** → `development-patterns.md` (with subdirectory if large)
- **Project architecture** → `architecture-overview.md` (with subdirectory if large)

### Documentation Standards

All documentation should:

- Follow consistent markdown formatting
- Provide practical examples
- Include troubleshooting sections where relevant
- Reference related documentation files
- **Respect the 10k-12k character limit for subdirectory files**

## General Workflow

1. Check `docs/` for relevant guidelines before starting
2. Load only the specific subdirectory files you need based on index guidance
3. Apply appropriate principles based on file naming and content
4. Follow established project structure and conventions
5. **Proactively update or create documentation as needed**
6. **Optimize large documentation files when requested**
7. Maintain documentation standards throughout development

## Priority

Documentation guidelines take precedence over general coding practices when conflicts arise. Keep documentation current, comprehensive, and properly sized - it's a core project responsibility, not an afterthought.
