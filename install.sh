#!/bin/bash
# Unique Notify - Installation Script
# CloudLinux CPU Monitoring with Telegram Alerts for cPanel/WHM
# 
# Usage Method 1 (One-line install):
#   bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/install.sh)
#   Or try: main instead of master if you get a 404 error
#
# Usage Method 2 (Manual install):
#   git clone https://github.com/noyonmiahdev/Unique-Notify.git
#   cd Unique-Notify && bash install.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
# Try master branch first, fall back to main if needed
REPO_URL="https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master"
DAEMON_FILE="/usr/local/bin/uniquenotifyd.py"
CONFIG_DIR="/var/cpanel/uniquenotify"
CONFIG_FILE="$CONFIG_DIR/config.json"
STATE_FILE="$CONFIG_DIR/state.json"
WHM_CGI_DIR="/usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify"
APPCONFIG_FILE="/var/cpanel/apps/uniquenotify.conf"
SERVICE_FILE="/etc/systemd/system/uniquenotify.service"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Unique Notify - Installer                 ║${NC}"
echo -e "${BLUE}║   CloudLinux CPU Alert System for cPanel/WHM   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ Error: This script must be run as root${NC}"
   exit 1
fi

echo -e "${GREEN}✓ Running as root${NC}"

# Check if cPanel is installed
if [ ! -d "/usr/local/cpanel" ]; then
    echo -e "${RED}✗ Error: cPanel/WHM not found. This plugin requires cPanel/WHM.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ cPanel/WHM detected${NC}"

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Error: Python 3 is required but not found${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}' | cut -d. -f1,2)
echo -e "${GREEN}✓ Python $PYTHON_VERSION detected${NC}"

# Check for CloudLinux (optional but recommended)
if command -v lveinfo &> /dev/null; then
    echo -e "${GREEN}✓ CloudLinux LVE detected${NC}"
else
    echo -e "${YELLOW}⚠ Warning: CloudLinux LVE not detected. CPU monitoring may be limited.${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}[1/7] Creating directories...${NC}"

# Create necessary directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$WHM_CGI_DIR"
chmod 700 "$CONFIG_DIR"

echo -e "${GREEN}✓ Directories created${NC}"

echo ""
echo -e "${BLUE}[2/7] Installing Python dependencies...${NC}"

# Install requests library
python3 -m pip install --upgrade pip > /dev/null 2>&1
python3 -m pip install requests > /dev/null 2>&1

echo -e "${GREEN}✓ Python dependencies installed${NC}"

echo ""
echo -e "${BLUE}[3/7] Downloading and installing daemon...${NC}"

# Download or copy daemon file
if [ -f "uniquenotifyd.py" ]; then
    # Running from local repository
    cp uniquenotifyd.py "$DAEMON_FILE"
else
    # Download from GitHub
    curl -fsSL "$REPO_URL/uniquenotifyd.py" -o "$DAEMON_FILE"
fi

chmod +x "$DAEMON_FILE"

echo -e "${GREEN}✓ Daemon installed at $DAEMON_FILE${NC}"

echo ""
echo -e "${BLUE}[4/7] Installing WHM plugin UI...${NC}"

# Download or copy WHM UI file
if [ -f "index.php" ]; then
    # Running from local repository
    cp index.php "$WHM_CGI_DIR/index.php"
else
    # Download from GitHub
    curl -fsSL "$REPO_URL/index.php" -o "$WHM_CGI_DIR/index.php"
fi

chmod 755 "$WHM_CGI_DIR/index.php"

echo -e "${GREEN}✓ WHM plugin UI installed${NC}"

echo ""
echo -e "${BLUE}[5/7] Creating default configuration...${NC}"

# Create default config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "threshold_cpu": 90,
  "cooldown_minutes": 30,
  "quiet_hours": "",
  "telegram": {
    "enabled": true,
    "bot_token": "",
    "chat_id": ""
  },
  "use_cloudlinux": true,
  "interval_seconds": 120,
  "max_alerts_per_hour": 10
}
EOF
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✓ Default configuration created${NC}"
else
    echo -e "${YELLOW}⚠ Configuration file already exists, keeping existing settings${NC}"
fi

echo ""
echo -e "${BLUE}[6/7] Registering WHM plugin...${NC}"

# Create WHM AppConfig
cat > "$APPCONFIG_FILE" << 'EOF'
---
name: "Unique Notify"
version: "1.0.0"
description: "CloudLinux CPU Monitoring with Telegram Alerts"
url: "/cgi/uniquenotify/index.php"
icon: "https://img.icons8.com/color/48/000000/telegram-app--v1.png"
group: "plugins"
feature_showcase: 0
EOF

# Register with cPanel
/usr/local/cpanel/bin/register_appconfig "$APPCONFIG_FILE" > /dev/null 2>&1 || true

echo -e "${GREEN}✓ WHM plugin registered${NC}"

echo ""
echo -e "${BLUE}[7/7] Setting up systemd service...${NC}"

# Create systemd service file
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Unique Notify - CloudLinux CPU Monitoring Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $DAEMON_FILE
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start service
systemctl daemon-reload
systemctl enable uniquenotify.service > /dev/null 2>&1
systemctl start uniquenotify.service

# Check if service started successfully
if systemctl is-active --quiet uniquenotify.service; then
    echo -e "${GREEN}✓ Service started successfully${NC}"
else
    echo -e "${YELLOW}⚠ Service may not have started. Check with: systemctl status uniquenotify.service${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation Completed Successfully!   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Go to ${YELLOW}WHM → Plugins → Unique Notify${NC}"
echo -e "  2. Configure your Telegram Bot Token and Chat ID"
echo -e "  3. Set your CPU threshold and preferences"
echo -e "  4. Click 'Test Telegram' to verify the connection"
echo -e "  5. Save the configuration"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  • Check service status: ${YELLOW}systemctl status uniquenotify.service${NC}"
echo -e "  • View logs: ${YELLOW}journalctl -u uniquenotify.service -f${NC}"
echo -e "  • Restart service: ${YELLOW}systemctl restart uniquenotify.service${NC}"
echo -e "  • Edit config: ${YELLOW}nano $CONFIG_FILE${NC}"
echo ""
echo -e "${BLUE}Support:${NC}"
echo -e "  • GitHub: ${YELLOW}https://github.com/noyonmiahdev/Unique-Notify${NC}"
echo -e "  • Documentation: Check README.md for detailed information"
echo ""
echo -e "${GREEN}Thank you for using Unique Notify!${NC}"
echo ""
