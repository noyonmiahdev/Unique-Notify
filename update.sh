#!/bin/bash
# Unique Notify - Update Script
# CloudLinux CPU Monitoring with Telegram Alerts for cPanel/WHM
# 
# Usage Method 1 (One-line update):
#   bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/update.sh)
#   Or try: master instead of main if you get a 404 error
#
# Usage Method 2 (Manual update):
#   git clone https://github.com/noyonmiahdev/Unique-Notify.git
#   cd Unique-Notify && bash update.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
# Try main branch first, fall back to master if needed
REPO_URL="https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main"
DAEMON_FILE="/usr/local/bin/uniquenotifyd.py"
CONFIG_DIR="/var/cpanel/uniquenotify"
CONFIG_FILE="$CONFIG_DIR/config.json"
CONFIG_BACKUP="$CONFIG_DIR/config.json.backup"
WHM_CGI_DIR="/usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify"
APPCONFIG_FILE="/var/cpanel/apps/uniquenotify.conf"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Unique Notify - Updater                 ║${NC}"
echo -e "${BLUE}║   CloudLinux CPU Alert System for cPanel/WHM   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ Error: This script must be run as root${NC}"
   exit 1
fi

echo -e "${GREEN}✓ Running as root${NC}"

# Check if Unique Notify is installed
if [ ! -f "$DAEMON_FILE" ]; then
    echo -e "${RED}✗ Error: Unique Notify is not installed. Please run install.sh first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Unique Notify installation detected${NC}"

# Backup current configuration
echo ""
echo -e "${BLUE}[1/5] Backing up configuration...${NC}"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_BACKUP"
    echo -e "${GREEN}✓ Configuration backed up${NC}"
else
    echo -e "${YELLOW}⚠ No configuration file found${NC}"
fi

# Stop the service
echo ""
echo -e "${BLUE}[2/5] Stopping service...${NC}"

if systemctl is-active --quiet uniquenotify.service; then
    systemctl stop uniquenotify.service
    echo -e "${GREEN}✓ Service stopped${NC}"
else
    echo -e "${YELLOW}⚠ Service was not running${NC}"
fi

# Update daemon file
echo ""
echo -e "${BLUE}[3/5] Updating daemon...${NC}"

if [ -f "uniquenotifyd.py" ]; then
    # Running from local repository
    cp uniquenotifyd.py "$DAEMON_FILE"
else
    # Download from GitHub
    if curl -fsSL "$REPO_URL/uniquenotifyd.py" -o "$DAEMON_FILE"; then
        echo -e "${GREEN}✓ Daemon updated${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to download from main branch, trying master...${NC}"
        REPO_URL="https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master"
        if curl -fsSL "$REPO_URL/uniquenotifyd.py" -o "$DAEMON_FILE"; then
            echo -e "${GREEN}✓ Daemon updated from master branch${NC}"
        else
            echo -e "${RED}✗ Failed to download daemon file${NC}"
            # Restore backup if exists
            if [ -f "$CONFIG_BACKUP" ]; then
                cp "$CONFIG_BACKUP" "$CONFIG_FILE"
            fi
            systemctl start uniquenotify.service
            exit 1
        fi
    fi
fi

chmod +x "$DAEMON_FILE"

# Update WHM UI
echo ""
echo -e "${BLUE}[4/5] Updating WHM plugin UI...${NC}"

if [ -f "index.php" ]; then
    # Running from local repository
    cp index.php "$WHM_CGI_DIR/index.php"
else
    # Download from GitHub
    if curl -fsSL "$REPO_URL/index.php" -o "$WHM_CGI_DIR/index.php"; then
        echo -e "${GREEN}✓ WHM UI updated${NC}"
    else
        echo -e "${RED}✗ Failed to download WHM UI file${NC}"
    fi
fi

chmod 755 "$WHM_CGI_DIR/index.php"

# Update AppConfig
if [ -f "uniquenotify.conf" ]; then
    cp uniquenotify.conf "$APPCONFIG_FILE"
    echo -e "${GREEN}✓ AppConfig updated${NC}"
elif curl -fsSL "$REPO_URL/uniquenotify.conf" -o "$APPCONFIG_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ AppConfig updated${NC}"
else
    echo -e "${YELLOW}⚠ Unable to update AppConfig from repository${NC}"
fi

# Re-register with cPanel
if /usr/local/cpanel/bin/register_appconfig "$APPCONFIG_FILE" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ WHM plugin registration refreshed${NC}"
else
    echo -e "${YELLOW}⚠ Unable to refresh WHM plugin registration. Review $APPCONFIG_FILE for syntax issues.${NC}"
fi

# Restore configuration
if [ -f "$CONFIG_BACKUP" ]; then
    cp "$CONFIG_BACKUP" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✓ Configuration restored${NC}"
fi

# Restart the service
echo ""
echo -e "${BLUE}[5/5] Restarting service...${NC}"

systemctl daemon-reload
systemctl start uniquenotify.service

# Check if service started successfully
if systemctl is-active --quiet uniquenotify.service; then
    echo -e "${GREEN}✓ Service restarted successfully${NC}"
else
    echo -e "${YELLOW}⚠ Service may not have started. Check with: systemctl status uniquenotify.service${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Update Completed Successfully!        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}What's Updated:${NC}"
echo -e "  • Daemon script: ${YELLOW}$DAEMON_FILE${NC}"
echo -e "  • WHM UI: ${YELLOW}$WHM_CGI_DIR/index.php${NC}"
echo -e "  • Configuration: ${YELLOW}Preserved (backup at $CONFIG_BACKUP)${NC}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  • Check service status: ${YELLOW}systemctl status uniquenotify.service${NC}"
echo -e "  • View logs: ${YELLOW}journalctl -u uniquenotify.service -f${NC}"
echo -e "  • Restart service: ${YELLOW}systemctl restart uniquenotify.service${NC}"
echo ""
echo -e "${BLUE}To access the plugin:${NC}"
echo -e "  • Go to ${YELLOW}WHM → Plugins → Unique Notify${NC}"
echo -e "  • Use the 'Test Telegram' button to verify your configuration"
echo ""
echo -e "${GREEN}Thank you for using Unique Notify!${NC}"
echo ""
