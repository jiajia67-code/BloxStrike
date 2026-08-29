# 🤝 Contributing to BloxStrike

Thank you for your interest in contributing to BloxStrike! This document provides guidelines and information for contributors.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

## 📜 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment
- No harassment or discrimination

## 🚀 How to Contribute

### 1. Fork the Repository
```bash
# Click the "Fork" button on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/BloxStrike.git
```

### 2. Create a Branch
```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or a bug fix branch
git checkout -b fix/your-bug-fix
```

### 3. Make Your Changes
- Follow the coding standards below
- Test your changes thoroughly
- Update documentation if needed

### 4. Commit Your Changes
```bash
# Stage your changes
git add .

# Commit with a clear message
git commit -m "feat: Add new feature description"
```

### 5. Push to Your Fork
```bash
git push origin feature/your-feature-name
```

### 6. Create a Pull Request
- Go to the original repository
- Click "New Pull Request"
- Select your branch
- Add a clear description

## 💻 Development Setup

### Prerequisites
- A Roblox executor (for testing)
- Git
- Text editor (VS Code recommended)

### Project Structure
```
BloxStrike/
├── BloxStrike.lua          # Main loader
├── modules/
│   ├── core.lua            # Core services
│   ├── ui.lua              # UI framework
│   ├── combat.lua          # Combat features
│   ├── esp.lua             # ESP system
│   └── ...                 # Other modules
└── docs/
    └── ...                 # Documentation
```

### Making Changes

1. **Module Files**: Edit files in `modules/` directory
2. **Main Loader**: Edit `BloxStrike.lua` for loader changes
3. **Testing**: Test in Roblox before submitting

## 📝 Pull Request Process

### Before Submitting
- [ ] Test your changes in-game
- [ ] Ensure no syntax errors
- [ ] Follow coding standards
- [ ] Update documentation if needed

### PR Title Format
Use conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance

### PR Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Other

## Testing
- [ ] Tested in BloxStrike game
- [ ] No syntax errors
- [ ] Features work as expected

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Changes tested locally
```

## 📐 Coding Standards

### Lua Style Guide

1. **Indentation**: Use 4 spaces
```lua
if condition then
    doSomething()
end
```

2. **Naming Conventions**:
- Variables: `camelCase`
- Functions: `camelCase`
- Constants: `UPPER_CASE`
- Tables: `PascalCase`

3. **Comments**:
```lua
-- Single line comment

--[[
    Multi-line comment
    For complex explanations
]]
```

4. **Error Handling**:
```lua
-- Always use pcall for risky operations
pcall(function()
    riskyOperation()
end)
```

5. **Module Structure**:
```lua
local Module = {}

function Module.feature()
    -- Implementation
end

return Module
```

### Git Commit Messages

- Use present tense: "Add feature" not "Added feature"
- Use imperative mood: "Move cursor" not "Moves cursor"
- Keep first line under 72 characters
- Reference issues when applicable

## 🐛 Reporting Bugs

### Bug Report Template
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- Executor: [e.g., Fluxus, Delta]
- Device: [e.g., PC, Mobile]
- Game: BloxStrike

**Additional context**
Any other context about the problem.
```

## 💡 Suggesting Features

### Feature Request Template
```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other solutions you've thought about.

**Additional context**
Any other context or screenshots.
```

## 🏷️ Labels

We use labels to categorize issues and PRs:

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Documentation improvements
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `question` - Further information is requested

## 📞 Questions?

If you have questions about contributing:

1. Check existing issues and discussions
2. Open a new issue with the `question` label
3. Be patient and respectful

## 🙏 Thank You!

Your contributions help make BloxStrike better for everyone. Thank you for taking the time to contribute!
