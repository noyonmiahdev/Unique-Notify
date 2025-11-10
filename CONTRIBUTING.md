# Contributing to NotifyGuard / Unique Notify

Thank you for your interest in contributing to NotifyGuard! This document provides guidelines for contributing to the project.

## Development Setup

### Prerequisites

- CentOS/AlmaLinux/CloudLinux server
- cPanel/WHM installed
- Python 3.6+
- Git
- Text editor or IDE

### Clone Repository

```bash
git clone https://github.com/noyonmiahdev/Unique-Notify.git
cd Unique-Notify
```

## Project Structure

```
Unique-Notify/
├── uniquenotifyd.py          # Main daemon script
├── index.php                 # WHM admin UI
├── install.sh                # Installation script
├── uninstall.sh              # Uninstallation script
├── config.json.example       # Example configuration
├── uniquenotify.service      # Systemd service template
├── uniquenotify.conf         # WHM AppConfig template
├── README.md                 # Main documentation
├── INSTALLATION.md           # Detailed installation guide
├── CONTRIBUTING.md           # This file
└── LICENSE                   # MIT License
```

## Making Changes

### 1. Python Daemon (uniquenotifyd.py)

The daemon monitors CloudLinux CPU usage and sends Telegram alerts.

**Key components:**
- `NotifyGuard` class - Main daemon logic
- `load_config()` - Configuration management
- `get_cloudlinux_cpu_usage()` - LVE data parsing
- `send_telegram_alert()` - Telegram API integration
- `should_send_alert()` - Alert throttling logic

**Testing changes:**
```bash
# Run daemon manually
python3 uniquenotifyd.py

# Check for syntax errors
python3 -m py_compile uniquenotifyd.py

# Install and test as service
sudo cp uniquenotifyd.py /usr/local/bin/
sudo systemctl restart uniquenotify.service
sudo journalctl -u uniquenotify.service -f
```

### 2. WHM UI (index.php)

The PHP interface for configuration management.

**Key components:**
- Configuration form
- Telegram connection testing
- Service restart functionality
- Status display

**Testing changes:**
```bash
# Check syntax
php -l index.php

# Deploy to WHM
sudo cp index.php /usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify/

# Access at: https://your-server:2087/cgi/uniquenotify/index.php
```

### 3. Installation Scripts

**install.sh:**
- Creates directories
- Installs dependencies
- Deploys files
- Registers with WHM
- Starts service

**uninstall.sh:**
- Stops service
- Removes files
- Unregisters from WHM
- Optional config backup

**Testing:**
```bash
# Test install script
bash install.sh

# Test uninstall script
bash uninstall.sh
```

## Code Style Guidelines

### Python

- Follow PEP 8 style guide
- Use 4 spaces for indentation
- Maximum line length: 100 characters
- Use docstrings for functions and classes
- Add type hints where appropriate
- Handle exceptions gracefully
- Use logging for debugging

Example:
```python
def get_cpu_usage(self) -> list:
    """
    Get CPU usage from CloudLinux LVE
    
    Returns:
        list: List of dicts with username and cpu usage
    """
    try:
        # Implementation
        pass
    except Exception as e:
        logger.error(f"Error: {e}")
        return []
```

### PHP

- Use consistent indentation (4 spaces)
- Follow WordPress PHP coding standards
- Sanitize all user inputs
- Use prepared statements for database queries
- Escape output with `htmlspecialchars()`
- Add comments for complex logic

Example:
```php
function saveConfig($post) {
    // Sanitize inputs
    $threshold = (int)($post['threshold_cpu'] ?? 90);
    
    // Validate
    if ($threshold < 1 || $threshold > 100) {
        return ['success' => false, 'message' => 'Invalid threshold'];
    }
    
    // Process
    // ...
}
```

### Bash

- Use `set -e` for error handling
- Quote variables: `"$VARIABLE"`
- Use functions for reusable code
- Add comments for clarity
- Check command existence before use

Example:
```bash
#!/bin/bash
set -e

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: Must run as root"
        exit 1
    fi
}
```

## Testing

### Unit Testing

Currently, the project doesn't have automated tests. Contributions to add testing would be welcome!

### Manual Testing Checklist

- [ ] Python daemon starts without errors
- [ ] Configuration loads correctly
- [ ] CloudLinux LVE data is parsed properly
- [ ] Telegram alerts are sent successfully
- [ ] Cooldown logic works as expected
- [ ] Quiet hours are respected
- [ ] Rate limiting functions correctly
- [ ] WHM UI displays properly
- [ ] Configuration saves successfully
- [ ] Test Telegram button works
- [ ] Service restarts properly
- [ ] Install script completes without errors
- [ ] Uninstall script removes all files
- [ ] Service auto-starts on boot

### Test Environment

It's recommended to test in a development environment before submitting changes:

1. Set up a test cPanel/WHM server
2. Install CloudLinux (or use mock data for testing)
3. Install NotifyGuard
4. Make your changes
5. Test thoroughly
6. Document any issues found

## Submitting Changes

### Pull Request Process

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clear, concise code
   - Add comments where necessary
   - Follow code style guidelines

4. **Test your changes**
   - Run manual tests
   - Verify no regressions

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Go to GitHub repository
   - Click "New Pull Request"
   - Select your branch
   - Fill in description
   - Submit

### Commit Message Guidelines

- Use present tense ("Add feature" not "Added feature")
- First line: brief summary (50 chars or less)
- Optionally add detailed description after blank line
- Reference issues: "Fixes #123" or "Relates to #456"

Examples:
```
Add RAM usage monitoring feature

Implement memory monitoring alongside CPU alerts.
Adds new configuration options for RAM thresholds.
Includes Telegram notification formatting for RAM alerts.

Fixes #15
```

## Feature Requests

Have an idea for a new feature? Great!

1. Check existing issues to avoid duplicates
2. Create a new issue with:
   - Clear feature description
   - Use case explanation
   - Benefits to users
   - Potential implementation approach

### Suggested Features for Contribution

- [ ] RAM/Memory usage monitoring
- [ ] Disk I/O alerts
- [ ] MySQL query monitoring
- [ ] Email notification option
- [ ] Multi-admin support (multiple Telegram chats)
- [ ] WHMCS integration
- [ ] Slack/Discord integration
- [ ] Historical data visualization
- [ ] Alert summary reports
- [ ] User whitelist/blacklist
- [ ] Custom alert templates
- [ ] API for external integrations
- [ ] Web dashboard
- [ ] Mobile app
- [ ] Alert acknowledgment system

## Bug Reports

Found a bug? Please report it!

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
- OS: [e.g., AlmaLinux 8]
- cPanel/WHM version: [e.g., 110.0]
- CloudLinux version: [e.g., 8.5]
- Python version: [e.g., 3.8]

**Logs**
```
Include relevant log excerpts
```

**Additional context**
Any other information about the problem.
```

## Security Issues

**DO NOT** report security vulnerabilities in public issues!

Instead, please email security concerns to:
- Email: security@yourdomain.com (or create private security advisory on GitHub)

Include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Documentation

Improvements to documentation are always welcome!

- Fix typos
- Clarify instructions
- Add examples
- Improve formatting
- Translate to other languages

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing others' private information
- Other unprofessional conduct

## Questions?

- Open an issue for general questions
- Join discussions in existing issues
- Check README.md and INSTALLATION.md first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Acknowledgments

Thank you to all contributors who help make NotifyGuard better!

---

**Happy Contributing! 🎉**
