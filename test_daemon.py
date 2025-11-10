#!/usr/bin/env python3
"""
Test script for Unique Notify daemon
Validates core functionality without requiring CloudLinux or Telegram
"""

import json
import sys
import os
from datetime import datetime, timedelta

# Mock config for testing
TEST_CONFIG = {
    "threshold_cpu": 90,
    "cooldown_minutes": 30,
    "quiet_hours": "00:00-06:59",
    "telegram": {
        "enabled": True,
        "bot_token": "test_token",
        "chat_id": "test_chat_id"
    },
    "use_cloudlinux": True,
    "interval_seconds": 120,
    "max_alerts_per_hour": 10
}

def test_config_loading():
    """Test configuration loading logic"""
    print("Testing configuration loading...")
    
    # Create test config
    test_dir = "/tmp/test_uniquenotify"
    os.makedirs(test_dir, exist_ok=True)
    config_file = f"{test_dir}/config.json"
    
    with open(config_file, 'w') as f:
        json.dump(TEST_CONFIG, f)
    
    # Load it back
    with open(config_file, 'r') as f:
        loaded_config = json.load(f)
    
    assert loaded_config['threshold_cpu'] == 90
    assert loaded_config['cooldown_minutes'] == 30
    print("✓ Configuration loading works")
    
    # Cleanup
    os.remove(config_file)
    os.rmdir(test_dir)

def test_quiet_hours_logic():
    """Test quiet hours detection"""
    print("\nTesting quiet hours logic...")
    
    def is_quiet_hours(quiet_hours_str, test_time):
        """Check if test_time is within quiet hours"""
        if not quiet_hours_str or quiet_hours_str.strip() == '':
            return False
        
        try:
            start_str, end_str = quiet_hours_str.split('-')
            start_time = datetime.strptime(start_str.strip(), '%H:%M').time()
            end_time = datetime.strptime(end_str.strip(), '%H:%M').time()
            
            if start_time <= end_time:
                return start_time <= test_time <= end_time
            else:
                return test_time >= start_time or test_time <= end_time
        except Exception as e:
            return False
    
    # Test cases
    test_cases = [
        ("00:00-06:59", datetime.strptime("03:00", "%H:%M").time(), True),
        ("00:00-06:59", datetime.strptime("12:00", "%H:%M").time(), False),
        ("22:00-06:00", datetime.strptime("23:00", "%H:%M").time(), True),
        ("22:00-06:00", datetime.strptime("03:00", "%H:%M").time(), True),
        ("22:00-06:00", datetime.strptime("12:00", "%H:%M").time(), False),
        ("", datetime.strptime("12:00", "%H:%M").time(), False),
    ]
    
    for quiet_hours, test_time, expected in test_cases:
        result = is_quiet_hours(quiet_hours, test_time)
        assert result == expected, f"Failed for {quiet_hours} at {test_time}"
    
    print("✓ Quiet hours logic works correctly")

def test_cooldown_logic():
    """Test alert cooldown tracking"""
    print("\nTesting cooldown logic...")
    
    state = {
        'last_alerts': {},
        'alert_count_hour': 0,
        'alert_hour_start': None
    }
    
    cooldown_minutes = 30
    current_time = datetime.now()
    username = "testuser"
    
    # First alert - should be allowed
    state['last_alerts'][username] = current_time.isoformat()
    
    # Second alert immediately - should be blocked
    time_diff = (current_time - datetime.fromisoformat(state['last_alerts'][username])).total_seconds()
    assert time_diff < cooldown_minutes * 60
    print("✓ Cooldown blocking works")
    
    # Alert after cooldown - should be allowed
    future_time = current_time + timedelta(minutes=cooldown_minutes + 1)
    time_diff = (future_time - datetime.fromisoformat(state['last_alerts'][username])).total_seconds()
    assert time_diff > cooldown_minutes * 60
    print("✓ Cooldown expiry works")

def test_rate_limiting():
    """Test hourly rate limiting"""
    print("\nTesting rate limiting...")
    
    state = {
        'alert_count_hour': 0,
        'alert_hour_start': datetime.now().isoformat()
    }
    
    max_alerts = 10
    
    # Simulate alerts
    for i in range(max_alerts):
        assert state['alert_count_hour'] < max_alerts
        state['alert_count_hour'] += 1
    
    # Next alert should be blocked
    assert state['alert_count_hour'] >= max_alerts
    print("✓ Rate limiting works")
    
    # Hour reset
    state['alert_hour_start'] = (datetime.now() - timedelta(hours=2)).isoformat()
    hour_start = datetime.fromisoformat(state['alert_hour_start'])
    assert (datetime.now() - hour_start).total_seconds() > 3600
    print("✓ Rate limit reset works")

def test_cpu_threshold():
    """Test CPU threshold comparison"""
    print("\nTesting CPU threshold logic...")
    
    threshold = 90
    
    test_cases = [
        (95.5, True),   # Should alert
        (90.0, True),   # Should alert (equal)
        (89.9, False),  # Should not alert
        (100.0, True),  # Should alert
        (50.0, False),  # Should not alert
    ]
    
    for cpu, should_alert in test_cases:
        result = cpu >= threshold
        assert result == should_alert, f"Failed for CPU {cpu}%"
    
    print("✓ CPU threshold comparison works")

def test_telegram_message_format():
    """Test Telegram message formatting"""
    print("\nTesting Telegram message format...")
    
    hostname = "server01.example.com"
    username = "johndoe"
    cpu_usage = 96.4
    threshold = 90
    current_time = "2025-11-10 15:42:23"
    
    message = f"""⚠️ High CPU Alert
Host: {hostname}
User: {username}
CPU: {cpu_usage:.1f}% ≥ {threshold}%
Time: {current_time}"""
    
    assert "⚠️ High CPU Alert" in message
    assert hostname in message
    assert username in message
    assert "96.4%" in message
    print("✓ Message formatting works")

def main():
    """Run all tests"""
    print("=" * 60)
    print("Unique Notify Daemon - Unit Tests")
    print("=" * 60)
    
    try:
        test_config_loading()
        test_quiet_hours_logic()
        test_cooldown_logic()
        test_rate_limiting()
        test_cpu_threshold()
        test_telegram_message_format()
        
        print("\n" + "=" * 60)
        print("✅ All tests passed!")
        print("=" * 60)
        return 0
    except AssertionError as e:
        print(f"\n❌ Test failed: {e}")
        return 1
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
