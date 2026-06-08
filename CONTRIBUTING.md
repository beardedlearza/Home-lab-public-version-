# Contributing to Homelab Kubernetes Infrastructure

Thank you for your interest in contributing! This document outlines how to contribute to the project.

---

## Project Status

**⚠️ Work in Progress** — This project is actively being developed. We're still finalizing:
- Documentation completeness
- Feature stability
- Testing coverage
- API surface

Contributions that help in these areas are especially welcome.

---

## How to Contribute

### Reporting Issues

Found a bug or have a feature request?

1. **Check existing issues** — Search to avoid duplicates
2. **Create a detailed issue** with:
   - What you were trying to do
   - What happened instead
   - Steps to reproduce (if applicable)
   - Your environment (OS, Kubernetes version, etc.)
   - Error messages or logs

### Improving Documentation

Documentation improvements are highly valued:

- Fix typos and unclear wording
- Add examples or clarifications
- Document known limitations
- Improve troubleshooting sections

**How to contribute docs:**
1. Fork and clone
2. Edit the relevant `.md` file
3. Preview changes locally (GFM compatible)
4. Submit pull request with description

### Code Contributions

Interested in adding features or fixing bugs?

**Before starting:**
1. Check open issues and pull requests
2. Comment on the issue to let others know you're working on it
3. Discuss major changes before implementing

**Development workflow:**
```bash
# Clone and setup
git clone https://github.com/yourname/homelab-infra.git
cd homelab-infra

# Create feature branch
git checkout -b feature/descriptive-name

# Make changes
# Test thoroughly (ideally in non-production environment)

# Commit with clear messages
git commit -m "Brief description of change"

# Push and create pull request
git push origin feature/descriptive-name
```

**Code standards:**
- Ansible: Follow Ansible best practices and style guide
- Kubernetes YAML: Use proper indentation, comments for clarity
- Shell scripts: POSIX compatible, proper error handling
- Documentation: Clear, complete, no sensitive information

---

## Areas for Contribution

### High Priority

- [ ] Comprehensive testing on different hardware
- [ ] Expanded documentation (especially troubleshooting)
- [ ] Backup and disaster recovery procedures
- [ ] Security hardening guides
- [ ] Network policy implementations

### Medium Priority

- [ ] Alternative CNI options (Cilium, Calico)
- [ ] Monitoring stack (Prometheus, Grafana)
- [ ] Log aggregation (Loki, ELK)
- [ ] Additional services
- [ ] CI/CD pipeline improvements

### Nice to Have

- [ ] Multi-cluster federation
- [ ] GitOps (ArgoCD, Flux)
- [ ] Advanced networking
- [ ] Performance benchmarks
- [ ] Hardware compatibility matrix

---

## Pull Request Process

1. **Update relevant documentation** if your change adds/modifies features
2. **Test your changes** thoroughly
3. **Keep PRs focused** — one feature/fix per PR if possible
4. **Write clear commit messages**:
   ```
   Brief description (50 chars max)
   
   Longer explanation of what and why (if needed)
   ```
5. **Link related issues**: "Fixes #123" or "Related to #456"

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Infrastructure improvement
- [ ] Other (please describe)

## Testing
How have you tested these changes?

## Checklist
- [ ] I've tested this thoroughly
- [ ] I've updated documentation
- [ ] I've removed sensitive information
- [ ] Code follows project style
```

---

## Development Setup

### Local Testing

```bash
# Install development dependencies
pip install ansible pytest

# Run linters (when available)
ansible-lint ansible/

# Test Ansible syntax
ansible-playbook --syntax-check ansible/site.yml

# Test in non-production environment first
```

### Testing on Hardware

- Test on your own home lab equipment first
- Document any hardware-specific issues
- Note performance implications

---

## Sensitive Information Guidelines

**Never commit:**
- IP addresses (use examples like `192.168.X.X`)
- Passwords or tokens
- SSH keys
- API credentials
- Domain names (use `yourdomain.ts.net`)
- Specific hardware model numbers (ok to generalize)

**Always:**
- Use examples and templates
- Redact in error messages/logs
- Document what values should be customized

---

## Documentation Style

- Use clear, simple language
- Assume readers have basic Linux/K8s knowledge
- Include examples and expected output
- Mark work-in-progress sections with `⚠️ WIP`
- Keep formatting minimal (prefer prose over heavy markup)

### Example structure:
```markdown
## Feature Name

Brief description of what this does.

### How It Works

Technical explanation for those interested.

### Usage

```bash
# Command example
```

Expected output or result.

### Troubleshooting

Common issues and solutions.
```

---

## Code Review Process

All contributions go through code review. Reviewers may:
- Ask for clarifications
- Suggest improvements
- Request additional testing
- Point out style inconsistencies

**This is collaborative, not confrontational.** We're working together to keep the project high-quality.

---

## Licensing

By contributing, you agree that your contributions are licensed under the **MIT License**. You retain copyright to your work, but you're granting the project permission to use it.

---

## Community Standards

- Be respectful and inclusive
- Assume good intent
- Provide constructive feedback
- Accept feedback gracefully
- Help others learn

**Unacceptable behavior:**
- Harassment or discrimination
- Abusive language
- Dismissive attitudes toward others
- Gatekeeping or gatekeeping attitudes

---

## Questions?

- Open a discussion on GitHub
- Create an issue with `[Question]` prefix
- Check existing documentation and issues first

---

## Recognition

Contributors are recognized in:
- README.md contributors section
- Individual commit history
- GitHub contributor graph

Thank you for helping make this project better! 🎉

---

**Last updated:** June 2025
