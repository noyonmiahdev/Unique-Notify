# Unique Notify - Technical Reference

## Architecture Overview

Unique Notify follows a modular architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                     WHM Admin Interface                      │
│                        (index.php)                           │
│  • Configuration Management                                  │
│  • Telegram Testing                                          │
│  • Service Control                                           │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Reads/Writes
                        ▼
┌─────────────────────────────────────────────────────────────┐
│               Configuration Storage                          │
│            /var/cpanel/uniquenotify/                        │
│  • config.json  - User preferences                          │
│  • state.json   - Runtime state                             │
│  • daemon.log   - Application logs                          │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Used by
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Python Monitoring Daemon                        │
│              (uniquenotifyd.py)                             │
│  • CloudLinux LVE Monitoring                                │
│  • Alert Logic Engine                                       │
│  • Telegram API Integration                                 │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Managed by
                        ▼
┌─────────────────────────────────────────────────────────────┐
│               Systemd Service Manager                        │
│           (uniquenotify.service)                            │
│  • Auto-start on boot                                       │
│  • Automatic restart on crash                               │
│  • Log management                                           │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Python Daemon (uniquenotifyd.py)

#### Class: UniqueNotify

**Initialization:**
```python
def __init__(self):
    self.config = self.load_config()
    self.state = self.load_state()
    self.hostname = socket.gethostname()
```

**Key Methods:**

##### load_config()
- **Purpose:** Load and validate configuration from JSON
- **Returns:** dict with configuration
- **Error Handling:** Returns defaults if file missing or invalid
- **Security:** Creates file with 0600 permissions

##### load_state() / save_state()
- **Purpose:** Persistent state management for cooldowns and tracking
- **State Structure:**
  ```python
  {
    "last_alerts": {
      "username": "2025-11-10T15:42:23.123456"
    },
    "alert_count_hour": 5,
    "alert_hour_start": "2025-11-10T15:00:00.000000"
  }
  ```

##### is_quiet_hours()
- **Purpose:** Check if current time is within configured quiet hours
- **Logic:** Handles both same-day and overnight ranges
- **Examples:**
  - `00:00-06:59`: Quiet from midnight to 7am
  - `22:00-06:00`: Quiet from 10pm to 6am (overnight)

##### should_send_alert(username)
- **Purpose:** Determine if alert should be sent based on multiple criteria
- **Checks:**
  1. Quiet hours (skip if in quiet period)
  2. Hourly rate limit (max alerts per hour)
  3. Per-user cooldown (minimum time between alerts)
- **Returns:** bool

##### get_cloudlinux_cpu_usage()
- **Purpose:** Query CloudLinux LVE for CPU usage data
- **Command:** `lveinfo --period=1m --display-username --show=cpu`
- **Parsing:** Extracts username and CPU percentage from output
- **Returns:** List of dicts: `[{'username': 'user1', 'cpu': 95.5}, ...]`
- **Error Handling:** Returns empty list on failure

##### send_telegram_alert(username, cpu_usage)
- **Purpose:** Send formatted alert to Telegram
- **API Endpoint:** `https://api.telegram.org/bot{token}/sendMessage`
- **Timeout:** 10 seconds
- **Error Handling:** Logs API errors, returns False on failure

##### check_and_alert()
- **Purpose:** Main monitoring iteration
- **Flow:**
  1. Get CPU usage data from CloudLinux
  2. Compare each user against threshold
  3. Check if alert should be sent
  4. Send alert if conditions met
  5. Update state with alert timestamp

##### run()
- **Purpose:** Main daemon loop
- **Behavior:** 
  - Infinite loop with configurable interval
  - Graceful shutdown on KeyboardInterrupt
  - Continues on exceptions (logs errors)

### 2. WHM Admin UI (index.php)

#### Security Features

```php
// Configuration file protection
chmod(CONFIG_FILE, 0600);  // Only root can read

// Input sanitization
$threshold = (int)($post['threshold_cpu'] ?? 90);
$botToken = trim($post['bot_token'] ?? '');

// Output escaping
echo htmlspecialchars($config['telegram']['bot_token']);
```

#### Key Functions

##### loadConfig()
- **Returns:** Configuration array with defaults merged
- **Default Values:**
  ```php
  [
    'threshold_cpu' => 90,
    'cooldown_minutes' => 30,
    'quiet_hours' => '',
    'telegram' => [
      'enabled' => true,
      'bot_token' => '',
      'chat_id' => ''
    ],
    'use_cloudlinux' => true,
    'interval_seconds' => 120,
    'max_alerts_per_hour' => 10
  ]
  ```

##### saveConfig($post)
- **Purpose:** Validate and save configuration
- **Validation:**
  - Integer fields cast to int
  - Strings trimmed
  - Booleans checked via isset()
- **Returns:** Success/error message

##### testTelegramConnection($post)
- **Purpose:** Verify Telegram credentials without saving
- **Method:** Sends test message via Telegram API
- **Validation:** Checks response for success

##### restartService()
- **Command:** `systemctl restart uniquenotify.service`
- **Returns:** Success/failure with output

##### getServiceStatus()
- **Command:** `systemctl is-active uniquenotify.service`
- **Returns:** Active status and text

### 3. Installation Script (install.sh)

#### Installation Steps

1. **Pre-flight Checks**
   - Root user verification
   - cPanel/WHM detection
   - Python 3 availability
   - CloudLinux LVE check (optional)

2. **Directory Creation**
   ```bash
   mkdir -p /var/cpanel/uniquenotify
   mkdir -p /usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify
   chmod 700 /var/cpanel/uniquenotify
   ```

3. **Python Dependencies**
   ```bash
   python3 -m pip install --upgrade pip
   python3 -m pip install requests
   ```

4. **File Deployment**
   - Daemon: `/usr/local/bin/uniquenotifyd.py` (chmod +x)
   - WHM UI: `/usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify/index.php`
   - Config: `/var/cpanel/uniquenotify/config.json` (chmod 600)

5. **WHM Registration**
   ```bash
   /usr/local/cpanel/bin/register_appconfig /var/cpanel/apps/uniquenotify.conf
   ```

6. **Service Setup**
   ```bash
   systemctl daemon-reload
   systemctl enable uniquenotify.service
   systemctl start uniquenotify.service
   ```

### 4. Configuration Schema

#### config.json Structure

```json
{
  "threshold_cpu": 90,           // Alert when CPU >= this value
  "cooldown_minutes": 30,        // Min minutes between alerts per user
  "quiet_hours": "00:00-06:59",  // No alerts during these hours (HH:MM-HH:MM)
  "telegram": {
    "enabled": true,             // Master enable/disable
    "bot_token": "...",          // Bot API token from @BotFather
    "chat_id": "..."             // Telegram chat/channel ID
  },
  "use_cloudlinux": true,        // Use CloudLinux LVE data
  "interval_seconds": 120,       // Seconds between CPU checks
  "max_alerts_per_hour": 10      // Global rate limit
}
```

#### state.json Structure

```json
{
  "last_alerts": {
    "user1": "2025-11-10T15:42:23.123456",
    "user2": "2025-11-10T16:15:10.987654"
  },
  "alert_count_hour": 5,
  "alert_hour_start": "2025-11-10T15:00:00.000000"
}
```

## API Integration

### Telegram Bot API

#### Send Message Endpoint

```
POST https://api.telegram.org/bot{token}/sendMessage
Content-Type: application/json

{
  "chat_id": "12345678",
  "text": "Alert message",
  "parse_mode": "HTML"
}
```

#### Response Format

```json
{
  "ok": true,
  "result": {
    "message_id": 123,
    "chat": {"id": 12345678},
    "date": 1699632143,
    "text": "Alert message"
  }
}
```

### CloudLinux LVE API

#### lveinfo Command

```bash
lveinfo --period=1m --display-username --show=cpu
```

#### Output Format

```
ID      EP      SPEED   CPU     NCPU    ...
0       0       100%    0%      0%      ...
1000    user1   100%    95.5%   4%      ...
1001    user2   100%    12.3%   1%      ...
```

#### Parsing Logic

```python
lines = output.strip().split('\n')
for line in lines[2:]:  # Skip header lines
    parts = line.split()
    username = parts[1]
    cpu_usage = float(parts[2].rstrip('%'))
```

## Performance Considerations

### Resource Usage

- **Memory:** ~20-30 MB (Python daemon)
- **CPU:** <1% (during monitoring intervals)
- **Disk I/O:** Minimal (config/state writes on changes only)
- **Network:** 1 API call per alert (~1KB)

### Scalability

- **Users Monitored:** Unlimited (depends on lveinfo performance)
- **Alerts Per Hour:** Configurable rate limit (default: 10)
- **Check Interval:** Configurable (default: 120 seconds)

### Optimization Tips

1. **Reduce Check Frequency:** Increase `interval_seconds` to 300 (5 min)
2. **Increase Cooldown:** Set `cooldown_minutes` to 60 for less noise
3. **Enable Quiet Hours:** Skip monitoring during low-traffic periods
4. **Rate Limiting:** Lower `max_alerts_per_hour` to prevent spam

## Logging and Debugging

### Log Locations

1. **Daemon Log:** `/var/cpanel/uniquenotify/daemon.log`
2. **Systemd Journal:** `journalctl -u uniquenotify.service`

### Log Levels

- **INFO:** Normal operations (alerts sent, checks completed)
- **WARNING:** Non-critical issues (rate limits hit, quiet hours)
- **ERROR:** Problems requiring attention (API failures, parsing errors)

### Debug Mode

Run daemon manually for verbose output:

```bash
python3 /usr/local/bin/uniquenotifyd.py
```

### Common Log Messages

```
INFO - Unique Notify daemon starting...
INFO - Hostname: server01.example.com
INFO - CPU Threshold: 90%
INFO - High CPU detected: johndoe = 96.4%
INFO - Telegram alert sent for johndoe (CPU: 96.4%)
INFO - Skipping alert for janedoe - cooldown period
WARNING - Max alerts per hour (10) reached
ERROR - lveinfo command not found
ERROR - Telegram API error: 401 - Unauthorized
```

## Security Model

### Threat Mitigation

| Threat | Mitigation |
|--------|-----------|
| **Token Exposure** | Config file chmod 600 (root only) |
| **Injection Attacks** | Input sanitization, no shell execution of user data |
| **DoS via Alerts** | Rate limiting, cooldown periods |
| **Unauthorized Access** | WHM authentication required |
| **Code Injection** | No eval(), exec(), or dynamic code execution |

### Best Practices

1. **Rotate Bot Token:** Periodically regenerate via @BotFather
2. **Monitor Logs:** Check for unauthorized access attempts
3. **Limit Chat Access:** Use private chat IDs, not public channels
4. **Regular Updates:** Keep dependencies updated
5. **Backup Config:** Before updates or changes

## Extension Points

### Adding New Alert Types

1. **Modify `check_and_alert()`:**
   ```python
   def check_and_alert(self):
       # Existing CPU check
       ...
       
       # Add new check
       users_ram = self.get_ram_usage()
       for user_data in users_ram:
           if user_data['ram'] >= self.config['threshold_ram']:
               self.send_ram_alert(user_data['username'], user_data['ram'])
   ```

2. **Add Configuration:**
   ```json
   {
     "threshold_ram": 80,
     "ram_enabled": true
   }
   ```

### Adding New Notification Channels

1. **Create New Method:**
   ```python
   def send_slack_alert(self, username, cpu_usage):
       # Slack webhook implementation
       pass
   ```

2. **Update Configuration:**
   ```json
   {
     "slack": {
       "enabled": true,
       "webhook_url": "..."
     }
   }
   ```

### Custom Alert Templates

```python
def get_alert_template(self):
    template = self.config.get('alert_template', 'default')
    
    templates = {
        'default': "⚠️ High CPU Alert\nHost: {host}\nUser: {user}\nCPU: {cpu}",
        'minimal': "CPU Alert: {user} @ {cpu}%",
        'detailed': "⚠️ Alert\nServer: {host}\nAccount: {user}\nCPU Usage: {cpu}% (threshold: {threshold}%)\nTime: {time}\nCooldown: {cooldown} minutes"
    }
    
    return templates.get(template, templates['default'])
```

## Testing

### Unit Tests

Run comprehensive tests:

```bash
python3 test_daemon.py
```

### Integration Tests

1. **Test CloudLinux Integration:**
   ```bash
   lveinfo --period=1m --display-username --show=cpu
   ```

2. **Test Telegram API:**
   ```bash
   curl -X POST https://api.telegram.org/bot{TOKEN}/sendMessage \
     -d "chat_id={CHAT_ID}" \
     -d "text=Test from Unique Notify"
   ```

3. **Test Service:**
   ```bash
   systemctl restart uniquenotify.service
   systemctl status uniquenotify.service
   journalctl -u uniquenotify.service -f
   ```

### Load Testing

Simulate high CPU users:

```bash
# Create test config with low threshold
echo '{"threshold_cpu": 1, ...}' > /var/cpanel/uniquenotify/config.json

# Monitor alerts
journalctl -u uniquenotify.service -f
```

## Troubleshooting

### Common Issues

1. **Service Won't Start**
   - Check Python path: `which python3`
   - Verify script permissions: `ls -l /usr/local/bin/uniquenotifyd.py`
   - Check logs: `journalctl -u uniquenotify.service -n 50`

2. **No Alerts Received**
   - Verify Telegram credentials
   - Check if CPU actually exceeds threshold
   - Verify not in quiet hours
   - Check cooldown hasn't blocked alerts

3. **Too Many Alerts**
   - Increase cooldown period
   - Lower max_alerts_per_hour
   - Set quiet hours
   - Increase threshold

## References

- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)
- [CloudLinux LVE Documentation](https://docs.cloudlinux.com/)
- [cPanel/WHM Plugin Development](https://documentation.cpanel.net/)
- [Python Logging Documentation](https://docs.python.org/3/library/logging.html)
- [Systemd Service Documentation](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

## Version History

- **v1.0.0** (2025-11-10)
  - Initial release
  - CloudLinux CPU monitoring
  - Telegram notifications
  - WHM admin interface
  - Systemd service integration
  - Comprehensive documentation

---

**Maintained by:** noyonmiahdev  
**License:** MIT  
**Repository:** https://github.com/noyonmiahdev/Unique-Notify
