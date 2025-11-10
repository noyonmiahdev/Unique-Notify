#!/bin/bash
# NotifyGuard / Unique Notify - Uninstallation Script
# CloudLinux CPU Monitoring with Telegram Alerts for cPanel/WHM
# 
# Usage Method 1 (One-line uninstall):
#   bash <(curl -fsSL https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/master/uninstall.sh)
#   Or try: main instead of master if you get a 404 error
#
# Usage Method 2 (Manual uninstall):
#   git clone https://github.com/noyonmiahdev/Unique-Notify.git
#   cd Unique-Notify && bash uninstall.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DAEMON_FILE="/usr/local/bin/uniquenotifyd.py"
CONFIG_DIR="/var/cpanel/uniquenotify"
WHM_CGI_DIR="/usr/local/cpanel/whostmgr/docroot/cgi/uniquenotify"
APPCONFIG_FILE="/var/cpanel/apps/uniquenotify.conf"
SERVICE_FILE="/etc/systemd/system/uniquenotify.service"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  NotifyGuard / Unique Notify - Uninstaller     ║${NC}"
echo -e "${BLUE}║   CloudLinux CPU Alert System for cPanel/WHM   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ Error: This script must be run as root${NC}"
   exit 1
fi

echo -e "${GREEN}✓ Running as root${NC}"

# Confirm uninstallation
echo ""
echo -e "${YELLOW}⚠ WARNING: This will remove NotifyGuard and all its files.${NC}"
read -p "Are you sure you want to uninstall? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Uninstallation cancelled.${NC}"
    exit 0
fi

# Ask about configuration backup
echo ""
read -p "Do you want to backup the configuration file before removing? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$CONFIG_DIR/config.json" ]; then
        BACKUP_FILE="/root/uniquenotify_config_backup_$(date +%Y%m%d_%H%M%S).json"
        cp "$CONFIG_DIR/config.json" "$BACKUP_FILE"
        echo -e "${GREEN}✓ Configuration backed up to $BACKUP_FILE${NC}"
    fi
fi

echo ""
echo -e "${BLUE}[1/6] Stopping service...${NC}"

# Stop and disable service
if systemctl is-active --quiet uniquenotify.service; then
    systemctl stop uniquenotify.service
    echo -e "${GREEN}✓ Service stopped${NC}"
else
    echo -e "${YELLOW}⚠ Service was not running${NC}"
fi

if systemctl is-enabled --quiet uniquenotify.service 2>/dev/null; then
    systemctl disable uniquenotify.service > /dev/null 2>&1
    echo -e "${GREEN}✓ Service disabled${NC}"
fi

echo ""
echo -e "${BLUE}[2/6] Removing systemd service file...${NC}"

if [ -f "$SERVICE_FILE" ]; then
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${GREEN}✓ Service file removed${NC}"
else
    echo -e "${YELLOW}⚠ Service file not found${NC}"
fi

echo ""
echo -e "${BLUE}[3/6] Removing daemon script...${NC}"

if [ -f "$DAEMON_FILE" ]; then
    rm -f "$DAEMON_FILE"
    echo -e "${GREEN}✓ Daemon script removed${NC}"
else
    echo -e "${YELLOW}⚠ Daemon script not found${NC}"
fi

echo ""
echo -e "${BLUE}[4/6] Removing configuration and data...${NC}"

if [ -d "$CONFIG_DIR" ]; then
    rm -rf "$CONFIG_DIR"
    echo -e "${GREEN}✓ Configuration directory removed${NC}"
else
    echo -e "${YELLOW}⚠ Configuration directory not found${NC}"
fi

echo ""
echo -e "${BLUE}[5/6] Removing WHM plugin UI...${NC}"

if [ -d "$WHM_CGI_DIR" ]; then
    rm -rf "$WHM_CGI_DIR"
    echo -e "${GREEN}✓ WHM plugin UI removed${NC}"
else
    echo -e "${YELLOW}⚠ WHM plugin UI not found${NC}"
fi

echo ""
echo -e "${BLUE}[6/6] Unregistering from WHM...${NC}"

if [ -f "$APPCONFIG_FILE" ]; then
    /usr/local/cpanel/bin/unregister_appconfig "$APPCONFIG_FILE" > /dev/null 2>&1 || true
    rm -f "$APPCONFIG_FILE"
    echo -e "${GREEN}✓ Unregistered from WHM${NC}"
else
    echo -e "${YELLOW}⚠ AppConfig file not found${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      Uninstallation Completed Successfully!    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}NotifyGuard has been completely removed from your system.${NC}"
echo ""

if [ -n "${BACKUP_FILE}" ] && [ -f "${BACKUP_FILE}" ]; then
    echo -e "${BLUE}Your configuration backup is saved at:${NC}"
    echo -e "  ${YELLOW}${BACKUP_FILE}${NC}"
    echo ""
fi

echo -e "${BLUE}To reinstall in the future, run:${NC}"
echo -e "  ${YELLOW}bash <(curl -s https://raw.githubusercontent.com/noyonmiahdev/Unique-Notify/main/install.sh)${NC}"
echo ""
echo -e "${GREEN}Thank you for using NotifyGuard!${NC}"
echo ""
