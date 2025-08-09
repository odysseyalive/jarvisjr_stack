# Git Workflow Guidelines

## Branch Management

### Branch Naming Convention
- `feature/description` - New features or enhancements
- `fix/issue-description` - Bug fixes and corrections
- `refactor/component-name` - Code restructuring without functionality changes
- `docs/section-name` - Documentation updates
- `chore/task-description` - Maintenance tasks, dependency updates

### Main Branch Protection
- `main` branch should always be in a working state
- All changes must go through pull requests
- Direct commits to `main` are prohibited
- Require at least basic testing before merging

## Commit Standards

### Commit Message Format
```
type(scope): brief description

Detailed explanation if needed
- What was changed
- Why it was changed
- Any breaking changes or considerations
```

### Commit Types
- `feat`: New feature or functionality
- `fix`: Bug fix or correction
- `refactor`: Code restructuring without functional changes
- `docs`: Documentation changes
- `chore`: Maintenance, dependencies, build process
- `test`: Adding or updating tests
- `style`: Code formatting, whitespace, etc.

### Examples
```
feat(scripts): add user authentication module

refactor(core): split deployment script into smaller modules
- Moved database operations to scripts/core/database.sh
- Extracted backup logic to scripts/utils/backup.sh
- Updated main orchestration in jstack.sh

fix(utils): resolve path resolution in cleanup script

docs(readme): update installation instructions
```

## File Management

### Adding New Files
- Follow established directory structure (`scripts/core/`, `scripts/utils/`, etc.)
- Include appropriate placeholder files (`.gitkeep`) for empty directories
- Update `.gitignore` for any new file types that shouldn't be tracked

### Removing Files
- Clean up any references in other scripts
- Update documentation if the file was part of public interface
- Consider deprecation warnings before complete removal

### Renaming/Moving Files
- Update all references in sourcing scripts
- Maintain backward compatibility where possible
- Document changes in commit message

## Pull Request Process

### Before Creating PR
1. Ensure all tests pass locally
2. Review changes against project guidelines
3. Update documentation if functionality changed
4. Clean up commit history if needed

### PR Description Template
```markdown
## Description
Brief summary of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactoring
- [ ] Documentation update
- [ ] Chore/maintenance

## Testing
- [ ] Tested locally
- [ ] All existing functionality still works
- [ ] New functionality tested

## Documentation
- [ ] Code comments updated
- [ ] Documentation files updated if needed
- [ ] README updated if public interface changed
```

## Release Management

### Tagging Strategy
- Use semantic versioning: `v1.2.3`
- Tag stable releases on `main` branch
- Include release notes with each tag

### Release Notes Format
```markdown
## v1.2.3 - YYYY-MM-DD

### Added
- New features and functionality

### Changed
- Modifications to existing features

### Fixed
- Bug fixes and corrections

### Removed
- Deprecated or removed functionality
```

## Emergency Procedures

### Hotfixes
1. Create `hotfix/critical-issue` branch from latest `main`
2. Make minimal necessary changes
3. Test thoroughly in isolated environment
4. Fast-track review process
5. Deploy immediately after merge
6. Follow up with post-mortem if needed

### Rollback Process
1. Identify last known good commit/tag
2. Create rollback branch: `rollback/to-v1.2.2`
3. Revert problematic changes
4. Test rollback thoroughly
5. Deploy through normal process
6. Document incident and resolution