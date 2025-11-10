# 🧩 Unique Notify — CloudLinux CPU Alert (Telegram Admin Plugin)

**Unique Notify** হলো cPanel/WHM-এর জন্য তৈরি একটি lightweight CloudLinux CPU মনিটরিং প্লাগিন।  
এটি প্রতিটি cPanel ইউজারের CPU ব্যবহার নিরীক্ষণ করে এবং অ্যাডমিনকে টেলিগ্রামে স্বয়ংক্রিয়ভাবে অ্যালার্ট পাঠায়।

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

### 🧠 One-line Install (from GitHub)
```bash
bash <(curl -s https://raw.githubusercontent.com/noyonmiahdev/unique-notify/main/install.sh)
````

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

💾 Click **Save** to apply the settings.

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

## 🔄 Uninstallation

### 🧹 One-line Uninstall

```bash
bash <(curl -s https://raw.githubusercontent.com/noyonmiahdev/unique-notify/main/uninstall.sh)
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
git clone https://github.com/noyonmiahdev/unique-notify.git
cd unique-notify
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
bash <(curl -s https://raw.githubusercontent.com/noyonmiahdev/unique-notify/main/install.sh)
```

---

## 🧩 Uninstaller Script

The `uninstall.sh` script automatically:

1. Stops & disables the service
2. Removes plugin files
3. Unregisters from WHM

Usage:

```bash
bash <(curl -s https://raw.githubusercontent.com/noyonmiahdev/unique-notify/main/uninstall.sh)
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

**GitHub:** [https://github.com/yourusername/unique-notify](https://github.com/yourusername/unique-notify)
**Email:** [support@yourdomain.com](mailto:support@yourdomain.com)
**Maintainer:** noyonmiahdev


