#!/usr/bin/env python3
"""
Test script for validating uniquenotify.conf AppConfig file
Ensures the AppConfig format is correct and compatible with cPanel/WHM
"""

import yaml
import sys
import os

def test_appconfig_format():
    """Test that uniquenotify.conf has the correct format"""
    print("Testing AppConfig file format...")
    
    appconfig_file = "uniquenotify.conf"
    
    if not os.path.exists(appconfig_file):
        print(f"✗ AppConfig file not found: {appconfig_file}")
        return False
    
    try:
        with open(appconfig_file, 'r') as f:
            config = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"✗ Invalid YAML syntax: {e}")
        return False
    
    # Check required fields
    required_fields = ['name', 'version', 'description', 'url']
    for field in required_fields:
        if field not in config:
            print(f"✗ Missing required field: {field}")
            return False
    
    # Check for deprecated fields that cause registration issues
    deprecated_fields = ['feature', 'icon']
    for field in deprecated_fields:
        if field in config:
            print(f"✗ Deprecated field found: {field} (this may cause registration failures)")
            return False
    
    # Validate field types
    if not isinstance(config['name'], str) or not config['name'].strip():
        print("✗ 'name' must be a non-empty string")
        return False
    
    if not isinstance(config['version'], str) or not config['version'].strip():
        print("✗ 'version' must be a non-empty string")
        return False
    
    if not isinstance(config['description'], str) or not config['description'].strip():
        print("✗ 'description' must be a non-empty string")
        return False
    
    if not isinstance(config['url'], str) or not config['url'].strip():
        print("✗ 'url' must be a non-empty string")
        return False
    
    # Validate URL format
    if not config['url'].startswith('/'):
        print("✗ 'url' must start with '/'")
        return False
    
    print("✓ AppConfig format is valid")
    print(f"  - name: {config['name']}")
    print(f"  - version: {config['version']}")
    print(f"  - description: {config['description']}")
    print(f"  - url: {config['url']}")
    
    return True

def main():
    """Run all tests"""
    print("=" * 60)
    print("Unique Notify - AppConfig Validation Tests")
    print("=" * 60)
    print()
    
    try:
        if test_appconfig_format():
            print()
            print("=" * 60)
            print("✅ All AppConfig tests passed!")
            print("=" * 60)
            return 0
        else:
            print()
            print("=" * 60)
            print("❌ AppConfig validation failed!")
            print("=" * 60)
            return 1
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
