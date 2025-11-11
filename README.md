# 🧩 Unique Notify — CloudLinux CPU Alert (Telegram Admin Plugin)

**Unique Notify** হলো cPanel/WHM-এর জন্য তৈরি একটি lightweight CloudLinux CPU মনিটরিং প্লাগিন।  
এটি প্রতিটি cPanel ইউজারের CPU ব্যবহার নিরীক্ষণ করে এবং অ্যাডমিনকে টেলিগ্রামে স্বয়ংক্রিয়ভাবে অ্যালার্ট পাঠায়।

**📚 বাংলা গাইড / Bengali Guide:** [QUICKSTART_BN.md](QUICKSTART_BN.md) - সম্পূর্ণ বাংলায় ইনস্টলেশন ও ব্যবহার গাইড

---

## 📖 Features

- 🔹 CloudLinux LVE ভিত্তিক CPU usage মনিটরিং  
- 🔹 Admin-only Telegram নোটিফিকেশন  
- 🔹 Configurable CPU threshold, cooldown, quiet hours  
- 🔹 WHM Admin Panel UI থেকে সেটিংস পরিবর্তন  
- 🔹 Auto-running systemd daemon  
- 🔹 One-command install / uninstall

---

## ⚙️ Requirements

| Component | Requirement |
|------------|--------------|
| OS | CentOS / AlmaLinux / CloudLinux |
| Control Panel | cPanel/WHM |
| CloudLinux | ✅ Required |
| Python | v3.6+ |
| PHP | v7.4+ |
| Internet | Required (Telegram API) |
| Privilege | root access |

---

## 🚀 Installation

### 🧠 Method 1: One-line Install (Recommended)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/install.sh)
```

**Note:** If the above command returns a 404 error, try using `main` instead of `master`:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/install.sh)
```

### 🧠 Method 2: Manual Install (Alternative)
```bash
git clone https://github.com/noyonmiahdev/Unique-Notify.git
cd Unique-Notify
bash install.sh
```

### 🔍 Installation Troubleshooting

**If you see error: `/dev/fd/63: line 1: 404:: command not found`**

This means the GitHub raw URL returned "404: Not Found". To fix:

1. **Try the alternative branch**: Use `main` instead of `master` (or vice versa)
2. **Use manual installation**: Clone the repo and run `bash install.sh`
3. **Check GitHub**: Ensure the repository exists and files are accessible

**Why this happens:**
- The repository may use `master` or `main` as default branch
- Files may not be pushed to the branch yet
- The `curl -s` flag hides errors; using `curl -fsSL` is better (fails on error, shows location redirects)

---

## ⚡ Configuration (WHM)

WHM → **Plugins → Unique Notify**

Fill the fields:

| Setting           | Description                                           |
| ----------------- | ----------------------------------------------------- |
| **Bot Token**     | From [@BotFather](https://t.me/BotFather)             |
| **Chat ID**       | From `https://api.telegram.org/bot<TOKEN>/getUpdates` |
| **CPU Threshold** | e.g. 90%                                              |
| **Cooldown**      | e.g. 30 minutes                                       |
| **Quiet Hours**   | e.g. `00:00-06:59`                                    |

💾 Click **Save Configuration** to apply the settings.

### 🧪 Testing Your Configuration (টেস্ট করার পদ্ধতি)

After entering your Telegram credentials, you can test the connection:

1. **📤 Test Telegram Button**: Click this button to send a test message to your Telegram chat
2. If successful, you'll receive a message: "✅ Unique Notify Test Message"
3. This verifies your Bot Token and Chat ID are working correctly

**বাংলায় (In Bengali):**
1. আপনার Telegram Bot Token এবং Chat ID লিখুন
2. **📤 Test Telegram** বাটনে ক্লিক করুন
3. আপনার Telegram চ্যাটে টেস্ট মেসেজ পাবেন
4. সফল হলে "✅ Unique Notify Test Message" দেখাবে

**Note:** You can test without saving first to verify your credentials before saving the configuration.

---

## 📡 Telegram Alert Example

```
⚠️ High CPU Alert
Host: server01.example.com
User: johndoe
CPU: 95.8% ≥ 90%
Time: 2025-11-10 15:42:23
```

---

## 📁 File Structure

```
/usr/local/bin/uniquenotifyd.py               # Daemon service
/var/cpanel/uniquenotify/config.json          # Config file
/usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify/index.php  # WHM UI
/var/cpanel/apps/uniquenotify.conf            # WHM AppConfig
/etc/systemd/system/uniquenotify.service      # Systemd service
```

---

## 🧩 How It Works

| Layer                | Description                                                                                                           |
| -------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **uniquenotifyd.py** | Python daemon that fetches CloudLinux LVE CPU usage and triggers Telegram messages if any user exceeds the threshold. |
| **index.php**        | WHM plugin form to configure Telegram credentials and thresholds.                                                     |
| **config.json**      | Stores configuration and preferences.                                                                                 |
| **systemd service**  | Runs continuously and restarts automatically if stopped.                                                              |

---

## 🔄 Update (আপডেট)

### 🔁 Method 1: One-line Update (Recommended)

To update Unique Notify to the latest version, run this single command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/update.sh)
```

**Note:** If the above command returns a 404 error, try using `master` instead of `main`:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/update.sh)
```

### 🔁 Method 2: Manual Update (Alternative)

```bash
git clone https://github.com/noyonmiahdev/Unique-Notify.git
cd Unique-Notify
bash update.sh
```

**What the update script does:**
- ✅ Backs up your current configuration
- ✅ Downloads the latest version of the daemon and WHM UI
- ✅ Updates the WHM plugin registration (fixes plugin visibility issues)
- ✅ Restarts the service with your existing configuration
- ✅ Preserves all your settings (Bot Token, Chat ID, thresholds, etc.)

**Note:** Your configuration is never lost during updates. A backup is always created at `/var/cpanel/uniquenotify/config.json.backup`

**If the plugin is not visible in WHM → Plugins section:**
Run the update script to fix the plugin registration. This will update the AppConfig file to use the correct cPanel/WHM standards.

---

## 🔄 Uninstallation

### 🧹 Method 1: One-line Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/uninstall.sh)
```

**Note:** If the above command returns a 404 error, try using `main` instead of `master`:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/uninstall.sh)
```

### 🧹 Method 2: Manual Uninstall (Alternative)

```bash
git clone https://github.com/noyonmiahdev/Unique-Notify.git
cd Unique-Notify
bash uninstall.sh
```

---

### 🧾 Manual Uninstall (Alternative)

```bash
systemctl disable --now uniquenotify.service
rm -f /etc/systemd/system/uniquenotify.service
rm -rf /var/cpanel/uniquenotify
rm -rf /usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify
rm -f /usr/local/bin/uniquenotifyd.py
/usr/local/cpanel/bin/unregister_appconfig /var/cpanel/apps/uniquenotify.conf
rm -f /var/cpanel/apps/uniquenotify.conf
systemctl daemon-reload
```

---

## 🧰 Developer Guide

### 🧪 Local Development

```bash
git clone https://github.com/noyonmiahdev/Unique-Notify.git
cd Unique-Notify
```

Modify core files:

* `uniquenotifyd.py` — monitoring logic
* `index.php` — WHM UI
* `install.sh` / `uninstall.sh` — installer scripts

Then commit:

```bash
git add .
git commit -m "Improved Telegram alert handler"
git push origin main
```

---

### 🧠 Test & Debug

```bash
systemctl status uniquenotify.service
journalctl -u uniquenotify.service -f
python3 /usr/local/bin/uniquenotifyd.py
```

---

## 🧾 Config File Example

`/var/cpanel/uniquenotify/config.json`

```json
{
  "threshold_cpu": 90,
  "cooldown_minutes": 30,
  "quiet_hours": "00:00-06:59",
  "telegram": {
    "enabled": true,
    "bot_token": "YOUR_TELEGRAM_BOT_TOKEN",
    "chat_id": "YOUR_CHAT_ID"
  },
  "use_cloudlinux": true,
  "interval_seconds": 120,
  "max_alerts_per_hour": 10
}
```

---

## 🔧 Installer Script

The `install.sh` script automatically:

1. Creates required directories
2. Installs Python dependency (`requests`)
3. Registers the WHM appconfig
4. Enables the `uniquenotify.service`

Usage:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/install.sh)
# Or if master doesn't work, try: main instead of master
```

---

## 🧩 Uninstaller Script

The `uninstall.sh` script automatically:

1. Stops & disables the service
2. Removes plugin files
3. Unregisters from WHM

Usage:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/uninstall.sh)
# Or if master doesn't work, try: main instead of master
```

---

## 🔐 Security

* Config file permissions: `chmod 600 /var/cpanel/uniquenotify/config.json`
* Daemon runs as `root` with safe read-only commands (`lveinfo`)
* No user-side code execution

---

## 🧠 Future Expansion

| Feature             | Description                               |
| ------------------- | ----------------------------------------- |
| RAM Alerts          | Memory-based notification                 |
| I/O Tracking        | Detect heavy I/O or Disk usage            |
| Multi-admin Support | Multiple Telegram recipients              |
| WHMCS Integration   | Sync notifications with WHMCS admin panel |
| Email Alerts        | Optional email fallback                   |

---

## 📄 License

MIT License © 2025 IT StarLab

---

## 📬 Support & Contribution

**GitHub:** [https://github.com/noyonmiahdev/Unique-Notify](https://github.com/noyonmiahdev/Unique-Notify)
**Issues:** [https://github.com/noyonmiahdev/Unique-Notify/issues](https://github.com/noyonmiahdev/Unique-Notify/issues)
**Maintainer:** noyonmiahdev


