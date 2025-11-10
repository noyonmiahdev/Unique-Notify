#!/usr/bin/env python3
"""
NotifyGuard/Unique Notify - CloudLinux CPU Monitoring Daemon
A lightweight daemon that monitors CloudLinux LVE CPU usage and sends Telegram alerts
when users exceed configured thresholds.
"""

import json
import time
import subprocess
import os
import sys
import logging
from datetime import datetime, timedelta
from pathlib import Path
import socket

try:
    import requests
except ImportError:
    print("Error: 'requests' module not found. Installing...")
    subprocess.run([sys.executable, "-m", "pip", "install", "requests"], check=True)
    import requests

# Configuration paths
CONFIG_DIR = "/var/cpanel/uniquenotify"
CONFIG_FILE = f"{CONFIG_DIR}/config.json"
STATE_FILE = f"{CONFIG_DIR}/state.json"
LOG_FILE = f"{CONFIG_DIR}/daemon.log"

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class NotifyGuard:
    """Main daemon class for CPU monitoring and alerting"""
    
    def __init__(self):
        self.config = self.load_config()
        self.state = self.load_state()
        self.hostname = socket.gethostname()
        
    def load_config(self):
        """Load configuration from config.json"""
        default_config = {
            "threshold_cpu": 90,
            "cooldown_minutes": 30,
            "quiet_hours": "",
            "telegram": {
                "enabled": True,
                "bot_token": "",
                "chat_id": ""
            },
            "use_cloudlinux": True,
            "interval_seconds": 120,
            "max_alerts_per_hour": 10
        }
        
        try:
            if os.path.exists(CONFIG_FILE):
                with open(CONFIG_FILE, 'r') as f:
                    config = json.load(f)
                    # Merge with defaults to ensure all keys exist
                    for key, value in default_config.items():
                        if key not in config:
                            config[key] = value
                    return config
            else:
                logger.warning(f"Config file not found at {CONFIG_FILE}, using defaults")
                # Create config directory if it doesn't exist
                os.makedirs(CONFIG_DIR, exist_ok=True)
                with open(CONFIG_FILE, 'w') as f:
                    json.dump(default_config, f, indent=2)
                os.chmod(CONFIG_FILE, 0o600)
                return default_config
        except Exception as e:
            logger.error(f"Error loading config: {e}")
            return default_config
    
    def load_state(self):
        """Load state from state.json"""
        default_state = {
            "last_alerts": {},
            "alert_count_hour": 0,
            "alert_hour_start": None
        }
        
        try:
            if os.path.exists(STATE_FILE):
                with open(STATE_FILE, 'r') as f:
                    return json.load(f)
            else:
                return default_state
        except Exception as e:
            logger.error(f"Error loading state: {e}")
            return default_state
    
    def save_state(self):
        """Save state to state.json"""
        try:
            os.makedirs(CONFIG_DIR, exist_ok=True)
            with open(STATE_FILE, 'w') as f:
                json.dump(self.state, f, indent=2)
        except Exception as e:
            logger.error(f"Error saving state: {e}")
    
    def is_quiet_hours(self):
        """Check if current time is within quiet hours"""
        quiet_hours = self.config.get('quiet_hours', '')
        if not quiet_hours or quiet_hours.strip() == '':
            return False
        
        try:
            start_str, end_str = quiet_hours.split('-')
            start_time = datetime.strptime(start_str.strip(), '%H:%M').time()
            end_time = datetime.strptime(end_str.strip(), '%H:%M').time()
            current_time = datetime.now().time()
            
            if start_time <= end_time:
                return start_time <= current_time <= end_time
            else:
                # Handle overnight quiet hours (e.g., 22:00-06:00)
                return current_time >= start_time or current_time <= end_time
        except Exception as e:
            logger.error(f"Error parsing quiet hours: {e}")
            return False
    
    def should_send_alert(self, username):
        """Check if alert should be sent based on cooldown and rate limits"""
        # Check quiet hours
        if self.is_quiet_hours():
            logger.info(f"Skipping alert for {username} - quiet hours")
            return False
        
        # Check hourly rate limit
        current_time = datetime.now()
        if self.state.get('alert_hour_start'):
            hour_start = datetime.fromisoformat(self.state['alert_hour_start'])
            if (current_time - hour_start).total_seconds() > 3600:
                # Reset hourly counter
                self.state['alert_count_hour'] = 0
                self.state['alert_hour_start'] = current_time.isoformat()
        else:
            self.state['alert_hour_start'] = current_time.isoformat()
        
        max_alerts = self.config.get('max_alerts_per_hour', 10)
        if self.state['alert_count_hour'] >= max_alerts:
            logger.warning(f"Max alerts per hour ({max_alerts}) reached")
            return False
        
        # Check cooldown for specific user
        last_alerts = self.state.get('last_alerts', {})
        if username in last_alerts:
            last_alert_time = datetime.fromisoformat(last_alerts[username])
            cooldown_minutes = self.config.get('cooldown_minutes', 30)
            if (current_time - last_alert_time).total_seconds() < cooldown_minutes * 60:
                logger.info(f"Skipping alert for {username} - cooldown period")
                return False
        
        return True
    
    def get_cloudlinux_cpu_usage(self):
        """Get CPU usage from CloudLinux LVE"""
        users_cpu = []
        
        try:
            # Check if lveinfo is available
            result = subprocess.run(['which', 'lveinfo'], 
                                    capture_output=True, text=True)
            if result.returncode != 0:
                logger.error("lveinfo command not found. CloudLinux may not be installed.")
                return users_cpu
            
            # Run lveinfo to get CPU usage
            cmd = ['lveinfo', '--period=1m', '--display-username', '--show=cpu']
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode != 0:
                logger.error(f"lveinfo failed: {result.stderr}")
                return users_cpu
            
            # Parse output
            lines = result.stdout.strip().split('\n')
            for line in lines[2:]:  # Skip header lines
                parts = line.split()
                if len(parts) >= 3:
                    try:
                        username = parts[1]
                        cpu_usage = float(parts[2].rstrip('%'))
                        users_cpu.append({
                            'username': username,
                            'cpu': cpu_usage
                        })
                    except (ValueError, IndexError):
                        continue
            
        except subprocess.TimeoutExpired:
            logger.error("lveinfo command timed out")
        except Exception as e:
            logger.error(f"Error getting CloudLinux CPU usage: {e}")
        
        return users_cpu
    
    def send_telegram_alert(self, username, cpu_usage):
        """Send Telegram notification"""
        telegram_config = self.config.get('telegram', {})
        
        if not telegram_config.get('enabled', False):
            logger.info("Telegram notifications disabled")
            return False
        
        bot_token = telegram_config.get('bot_token', '')
        chat_id = telegram_config.get('chat_id', '')
        
        if not bot_token or not chat_id:
            logger.error("Telegram bot_token or chat_id not configured")
            return False
        
        threshold = self.config.get('threshold_cpu', 90)
        current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        message = f"""⚠️ High CPU Alert
Host: {self.hostname}
User: {username}
CPU: {cpu_usage:.1f}% ≥ {threshold}%
Time: {current_time}"""
        
        try:
            url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
            payload = {
                'chat_id': chat_id,
                'text': message,
                'parse_mode': 'HTML'
            }
            
            response = requests.post(url, json=payload, timeout=10)
            
            if response.status_code == 200:
                logger.info(f"Telegram alert sent for {username} (CPU: {cpu_usage:.1f}%)")
                return True
            else:
                logger.error(f"Telegram API error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending Telegram alert: {e}")
            return False
    
    def check_and_alert(self):
        """Main monitoring loop iteration"""
        threshold = self.config.get('threshold_cpu', 90)
        
        # Get CPU usage data
        users_cpu = self.get_cloudlinux_cpu_usage()
        
        if not users_cpu:
            logger.debug("No CPU usage data available")
            return
        
        # Check each user against threshold
        for user_data in users_cpu:
            username = user_data['username']
            cpu_usage = user_data['cpu']
            
            if cpu_usage >= threshold:
                logger.info(f"High CPU detected: {username} = {cpu_usage:.1f}%")
                
                if self.should_send_alert(username):
                    if self.send_telegram_alert(username, cpu_usage):
                        # Update state
                        if 'last_alerts' not in self.state:
                            self.state['last_alerts'] = {}
                        self.state['last_alerts'][username] = datetime.now().isoformat()
                        self.state['alert_count_hour'] = self.state.get('alert_count_hour', 0) + 1
                        self.save_state()
    
    def run(self):
        """Main daemon loop"""
        logger.info("NotifyGuard daemon starting...")
        logger.info(f"Hostname: {self.hostname}")
        logger.info(f"CPU Threshold: {self.config.get('threshold_cpu')}%")
        logger.info(f"Check Interval: {self.config.get('interval_seconds')}s")
        logger.info(f"Cooldown: {self.config.get('cooldown_minutes')} minutes")
        
        interval = self.config.get('interval_seconds', 120)
        
        while True:
            try:
                self.check_and_alert()
                time.sleep(interval)
            except KeyboardInterrupt:
                logger.info("Daemon stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                time.sleep(interval)


def main():
    """Entry point"""
    daemon = NotifyGuard()
    daemon.run()


if __name__ == '__main__':
    main()
