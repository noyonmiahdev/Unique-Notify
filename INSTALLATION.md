# NotifyGuard / Unique Notify - Installation Guide

## Overview

NotifyGuard is a lightweight cPanel/WHM plugin that monitors CloudLinux LVE CPU usage and sends real-time Telegram alerts when users exceed configured thresholds.

## System Requirements

| Component | Requirement |
|-----------|-------------|
| **Operating System** | CentOS 7/8, AlmaLinux 8/9, CloudLinux |
| **Control Panel** | cPanel/WHM (v80+) |
| **CloudLinux** | Required for LVE monitoring |
| **Python** | Version 3.6 or higher |
| **PHP** | Version 7.4 or higher |
| **Network** | Internet access for Telegram API |
| **Privileges** | Root access required |

## Quick Installation

### One-Line Install

Run the following command as root:

```bash
bash <(curl -s https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/install.sh)
```

This will:
- Create necessary directories
- Install Python dependencies
- Deploy daemon and WHM UI
- Register with WHM
- Start the monitoring service

## Post-Installation Configuration

### Step 1: Create Telegram Bot

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` command
3. Follow the prompts to name your bot
4. Copy the **Bot Token** provided (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Step 2: Get Chat ID

1. Start a chat with your new bot
2. Send any message to the bot
3. Visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
4. Look for `"chat":{"id":` in the response
5. Copy the Chat ID (e.g., `-1001234567890`)

### Step 3: Configure in WHM

1. Log into WHM
2. Navigate to **Plugins → Unique Notify**
3. Enter your Bot Token and Chat ID
4. Configure CPU threshold (default: 90%)
5. Set cooldown period (default: 30 minutes)
6. Optionally configure quiet hours (e.g., `00:00-06:59`)
7. Click **Test Telegram** to verify connection
8. Click **Save Configuration**
9. Click **Restart Service** to apply changes

## Configuration Options

| Setting | Description | Default | Example |
|---------|-------------|---------|---------|
| **CPU Threshold** | Alert when CPU exceeds this percentage | 90% | 85, 90, 95 |
| **Cooldown Minutes** | Minimum time between alerts for same user | 30 | 15, 30, 60 |
| **Check Interval** | Seconds between CPU checks | 120 | 60, 120, 300 |
| **Max Alerts/Hour** | Maximum total alerts per hour | 10 | 5, 10, 20 |
| **Quiet Hours** | No alerts during these hours | (empty) | 00:00-06:59 |
| **Use CloudLinux** | Enable CloudLinux LVE monitoring | true | true/false |

## File Locations

```
/usr/local/bin/uniquenotifyd.py               # Daemon script
/var/cpanel/uniquenotify/config.json          # Configuration
/var/cpanel/uniquenotify/state.json           # Runtime state
/var/cpanel/uniquenotify/daemon.log           # Log file
/usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify/index.php  # WHM UI
/var/cpanel/apps/uniquenotify.conf            # WHM registration
/etc/systemd/system/uniquenotify.service      # Systemd service
```

## Service Management

### Check Service Status
```bash
systemctl status uniquenotify.service
```

### Start/Stop/Restart Service
```bash
systemctl start uniquenotify.service
systemctl stop uniquenotify.service
systemctl restart uniquenotify.service
```

### View Logs
```bash
# Real-time logs
journalctl -u uniquenotify.service -f

# Last 100 lines
journalctl -u uniquenotify.service -n 100

# Daemon log file
tail -f /var/cpanel/uniquenotify/daemon.log
```

### Enable/Disable Auto-Start
```bash
systemctl enable uniquenotify.service
systemctl disable uniquenotify.service
```

## Testing

### Test Configuration Manually
```bash
python3 /usr/local/bin/uniquenotifyd.py
```
Press `Ctrl+C` to stop.

### Test CloudLinux Integration
```bash
lveinfo --period=1m --display-username --show=cpu
```

### Send Test Alert
Use the "Test Telegram" button in the WHM interface, or manually test:
```bash
curl -X POST https://api.telegram.org/bot<TOKEN>/sendMessage \
  -H "Content-Type: application/json" \
  -d '{"chat_id":"<CHAT_ID>","text":"Test from NotifyGuard"}'
```

## Troubleshooting

### Service Won't Start
```bash
# Check service status
systemctl status uniquenotify.service

# Check logs for errors
journalctl -u uniquenotify.service -n 50

# Verify Python script
python3 /usr/local/bin/uniquenotifyd.py
```

### No Alerts Received

1. **Check Configuration**
   ```bash
   cat /var/cpanel/uniquenotify/config.json
   ```
   Verify Bot Token and Chat ID are correct

2. **Test Telegram Connection**
   - Use the "Test Telegram" button in WHM
   - Check if test message arrives

3. **Check CPU Usage**
   ```bash
   lveinfo --period=1m --display-username --show=cpu
   ```
   Verify users are actually exceeding threshold

4. **Check Quiet Hours**
   - Ensure current time is not within quiet hours
   - Check if cooldown period is preventing alerts

5. **View Logs**
   ```bash
   tail -f /var/cpanel/uniquenotify/daemon.log
   journalctl -u uniquenotify.service -f
   ```

### CloudLinux Not Detected

```bash
# Check if lveinfo is available
which lveinfo

# Check if CloudLinux is installed
cat /etc/redhat-release

# Install CloudLinux if needed (requires CloudLinux license)
```

### Telegram API Errors

- **401 Unauthorized**: Bot Token is incorrect
- **400 Bad Request**: Chat ID is incorrect or bot hasn't been started
- **Network Error**: Check firewall and internet connectivity

## Security Notes

1. **File Permissions**
   - Config file: `chmod 600` (only root can read)
   - Daemon runs as root with minimal privileges
   - No user-accessible endpoints

2. **Best Practices**
   - Keep Bot Token secret
   - Don't share Chat ID publicly
   - Regularly review alert logs
   - Monitor for false positives

3. **Firewall**
   - Ensure outbound HTTPS (443) is allowed
   - Telegram API: `api.telegram.org`

## Uninstallation

### One-Line Uninstall
```bash
bash <(curl -s https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/uninstall.sh)
```

The uninstaller will:
- Offer to backup your configuration
- Stop and remove the service
- Delete all plugin files
- Unregister from WHM

### Manual Uninstall
```bash
# Stop and disable service
systemctl stop uniquenotify.service
systemctl disable uniquenotify.service

# Remove files
rm -f /etc/systemd/system/uniquenotify.service
rm -rf /var/cpanel/uniquenotify
rm -rf /usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify
rm -f /usr/local/bin/uniquenotifyd.py

# Unregister from WHM
/usr/local/cpanel/bin/unregister_appconfig /var/cpanel/apps/uniquenotify.conf
rm -f /var/cpanel/apps/uniquenotify.conf

# Reload systemd
systemctl daemon-reload
```

## Upgrading

To upgrade to the latest version:

```bash
# Run installer again (it will preserve config)
bash <(curl -s https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/install.sh)

# Restart service
systemctl restart uniquenotify.service
```

## Support

- **GitHub**: [https://github.com/noyonmiahdev/Unique-Notify](https://github.com/noyonmiahdev/Unique-Notify)
- **Issues**: [https://github.com/noyonmiahdev/Unique-Notify/issues](https://github.com/noyonmiahdev/Unique-Notify/issues)
- **Documentation**: See README.md

## License

MIT License © 2025 IT StarLab
