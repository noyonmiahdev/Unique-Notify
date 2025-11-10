# NotifyGuard - Quick Start Guide

Get NotifyGuard up and running in 5 minutes!

## 🚀 Installation (1 minute)

**Method 1: One-line install**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/install.sh)
```

**If you get a "404: Not Found" error, try:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/install.sh)
```

**Method 2: Manual install (alternative)**
```bash
git clone https://github.com/noyonmiahdev/Unique-Notify.git
cd Unique-Notify
bash install.sh
```

Wait for installation to complete. You should see:
```
✓ Installation Completed Successfully!
```

## 📱 Setup Telegram Bot (2 minutes)

### 1. Create Bot
- Open Telegram and search for **@BotFather**
- Send: `/newbot`
- Name your bot: `MyServer Alert Bot`
- Username: `myserver_alert_bot`
- **Save the Bot Token** (looks like: `123456789:ABCdefGHI...`)

### 2. Get Chat ID
- Start a chat with your new bot
- Send any message to it
- Open browser: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
- Find `"chat":{"id":` and **copy the number** (e.g., `12345678` or `-1001234567890`)

## ⚙️ Configure (2 minutes)

### 1. Open WHM Plugin
- Login to WHM
- Go to: **WHM → Plugins → Unique Notify**

### 2. Enter Settings
- **Bot Token**: Paste your bot token
- **Chat ID**: Paste your chat ID
- **CPU Threshold**: `90` (alert when CPU > 90%)
- **Cooldown**: `30` (wait 30 min between alerts)

### 3. Test & Save
- Click **"Test Telegram"** button
- Check your Telegram for test message ✅
- Click **"Save Configuration"**
- Click **"Restart Service"**

## ✅ Done!

You're all set! NotifyGuard is now monitoring your server.

## 📊 What Happens Next?

When any user exceeds **90% CPU**, you'll receive:

```
⚠️ High CPU Alert
Host: server01.example.com
User: johndoe
CPU: 96.4% ≥ 90%
Time: 2025-11-10 15:42:23
```

## 🔧 Common Adjustments

### Make Alerts More Sensitive
Lower threshold to `80%` or `85%`

### Reduce Alert Spam
- Increase cooldown to `60` minutes
- Set quiet hours: `00:00-06:59`
- Lower max alerts per hour to `5`

### Change Check Frequency
- Default: checks every `120` seconds
- More frequent: `60` seconds
- Less frequent: `300` seconds

## 📋 Quick Commands

```bash
# Check if running
systemctl status uniquenotify.service

# View live logs
journalctl -u uniquenotify.service -f

# Restart service
systemctl restart uniquenotify.service

# Edit config manually
nano /var/cpanel/uniquenotify/config.json
systemctl restart uniquenotify.service
```

## ❓ Troubleshooting

### No alerts received?
1. Check service: `systemctl status uniquenotify.service`
2. View logs: `journalctl -u uniquenotify.service -n 50`
3. Test Telegram again from WHM interface
4. Verify CPU is actually high: `lveinfo --period=1m`

### Test message failed?
- Double-check Bot Token (no spaces)
- Verify Chat ID (include minus sign if present)
- Ensure internet access works: `ping -c 3 api.telegram.org`

### Service won't start?
```bash
# Check for errors
python3 /usr/local/bin/uniquenotifyd.py

# Check Python version (needs 3.6+)
python3 --version

# Reinstall
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/uninstall.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/install.sh)
# Or use: main instead of master if you get a 404 error
```

## 📚 Need More Help?

- **Full Documentation**: See [INSTALLATION.md](INSTALLATION.md)
- **Issues**: [GitHub Issues](https://github.com/noyonmiahdev/Unique-Notify/issues)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)

---

**Enjoy NotifyGuard! 🎉**
