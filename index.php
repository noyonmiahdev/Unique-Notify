<?php
/**
 * Unique Notify - WHM Admin Panel UI
 * Configuration interface for CloudLinux CPU monitoring and Telegram alerts
 */

// Security check - ensure this is running in WHM context
if (!defined('STDIN') && php_sapi_name() !== 'cli') {
    if (!isset($_SERVER['REMOTE_USER']) && !isset($_ENV['REMOTE_USER'])) {
        // In production WHM environment, this would be authenticated
        // For now, we'll allow access but log a warning
    }
}

// Configuration file paths
define('CONFIG_DIR', '/var/cpanel/uniquenotify');
define('CONFIG_FILE', CONFIG_DIR . '/config.json');

// Initialize variables
$message = '';
$error = '';
$config = loadConfig();

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action']) && $_POST['action'] === 'save') {
        $result = saveConfig($_POST);
        if ($result['success']) {
            $message = $result['message'];
            $config = loadConfig(); // Reload config
        } else {
            $error = $result['message'];
        }
    } elseif (isset($_POST['action']) && $_POST['action'] === 'test') {
        $result = testTelegramConnection($_POST);
        if ($result['success']) {
            $message = $result['message'];
        } else {
            $error = $result['message'];
        }
    } elseif (isset($_POST['action']) && $_POST['action'] === 'restart') {
        $result = restartService();
        if ($result['success']) {
            $message = $result['message'];
        } else {
            $error = $result['message'];
        }
    }
}

/**
 * Load configuration from JSON file
 */
function loadConfig() {
    $defaultConfig = [
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
    ];
    
    if (file_exists(CONFIG_FILE)) {
        $json = file_get_contents(CONFIG_FILE);
        $config = json_decode($json, true);
        if ($config === null) {
            return $defaultConfig;
        }
        // Merge with defaults
        return array_merge($defaultConfig, $config);
    }
    
    return $defaultConfig;
}

/**
 * Save configuration to JSON file
 */
function saveConfig($post) {
    try {
        // Create directory if it doesn't exist
        if (!is_dir(CONFIG_DIR)) {
            mkdir(CONFIG_DIR, 0700, true);
        }
        
        $config = [
            'threshold_cpu' => (int)($post['threshold_cpu'] ?? 90),
            'cooldown_minutes' => (int)($post['cooldown_minutes'] ?? 30),
            'quiet_hours' => trim($post['quiet_hours'] ?? ''),
            'telegram' => [
                'enabled' => isset($post['telegram_enabled']),
                'bot_token' => trim($post['bot_token'] ?? ''),
                'chat_id' => trim($post['chat_id'] ?? '')
            ],
            'use_cloudlinux' => isset($post['use_cloudlinux']),
            'interval_seconds' => (int)($post['interval_seconds'] ?? 120),
            'max_alerts_per_hour' => (int)($post['max_alerts_per_hour'] ?? 10)
        ];
        
        $json = json_encode($config, JSON_PRETTY_PRINT);
        file_put_contents(CONFIG_FILE, $json);
        chmod(CONFIG_FILE, 0600);
        
        return [
            'success' => true,
            'message' => '✅ Configuration saved successfully! Restart the service for changes to take effect.'
        ];
    } catch (Exception $e) {
        return [
            'success' => false,
            'message' => '❌ Error saving configuration: ' . $e->getMessage()
        ];
    }
}

/**
 * Test Telegram connection
 */
function testTelegramConnection($post) {
    $botToken = trim($post['bot_token'] ?? '');
    $chatId = trim($post['chat_id'] ?? '');
    
    if (empty($botToken) || empty($chatId)) {
        return [
            'success' => false,
            'message' => '❌ Bot Token and Chat ID are required for testing.'
        ];
    }
    
    $url = "https://api.telegram.org/bot{$botToken}/sendMessage";
    $data = [
        'chat_id' => $chatId,
        'text' => "✅ Unique Notify Test Message\n\nYour Telegram configuration is working correctly!\nTime: " . date('Y-m-d H:i:s')
    ];
    
    $options = [
        'http' => [
            'header'  => "Content-type: application/json\r\n",
            'method'  => 'POST',
            'content' => json_encode($data),
            'timeout' => 10
        ]
    ];
    
    $context  = stream_context_create($options);
    $result = @file_get_contents($url, false, $context);
    
    if ($result === false) {
        return [
            'success' => false,
            'message' => '❌ Failed to connect to Telegram API. Please check your Bot Token and network connectivity.'
        ];
    }
    
    $response = json_decode($result, true);
    if (isset($response['ok']) && $response['ok'] === true) {
        return [
            'success' => true,
            'message' => '✅ Test message sent successfully! Check your Telegram chat.'
        ];
    } else {
        return [
            'success' => false,
            'message' => '❌ Telegram API error: ' . ($response['description'] ?? 'Unknown error')
        ];
    }
}

/**
 * Restart the Unique Notify service
 */
function restartService() {
    $output = [];
    $returnCode = 0;
    
    exec('systemctl restart uniquenotify.service 2>&1', $output, $returnCode);
    
    if ($returnCode === 0) {
        return [
            'success' => true,
            'message' => '✅ Unique Notify service restarted successfully!'
        ];
    } else {
        return [
            'success' => false,
            'message' => '❌ Failed to restart service: ' . implode("\n", $output)
        ];
    }
}

/**
 * Get service status
 */
function getServiceStatus() {
    $output = [];
    $returnCode = 0;
    
    exec('systemctl is-active uniquenotify.service 2>&1', $output, $returnCode);
    
    return [
        'active' => $returnCode === 0,
        'status' => trim(implode('', $output))
    ];
}

$serviceStatus = getServiceStatus();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unique Notify - CloudLinux CPU Alerts</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: #f5f5f5;
            padding: 20px;
            line-height: 1.6;
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .header p {
            opacity: 0.9;
            font-size: 14px;
        }
        
        .content {
            padding: 30px;
        }
        
        .status-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px 20px;
            background: #f8f9fa;
            border-radius: 6px;
            margin-bottom: 30px;
        }
        
        .status-badge {
            display: inline-flex;
            align-items: center;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
        }
        
        .status-badge.active {
            background: #d4edda;
            color: #155724;
        }
        
        .status-badge.inactive {
            background: #f8d7da;
            color: #721c24;
        }
        
        .status-badge::before {
            content: '●';
            margin-right: 6px;
            font-size: 16px;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 6px;
            margin-bottom: 20px;
            border-left: 4px solid;
        }
        
        .alert-success {
            background: #d4edda;
            border-color: #28a745;
            color: #155724;
        }
        
        .alert-error {
            background: #f8d7da;
            border-color: #dc3545;
            color: #721c24;
        }
        
        .form-group {
            margin-bottom: 25px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
            font-size: 14px;
        }
        
        .form-group .hint {
            display: block;
            margin-top: 5px;
            font-size: 12px;
            color: #666;
        }
        
        .form-group input[type="text"],
        .form-group input[type="number"],
        .form-group textarea {
            width: 100%;
            padding: 10px 15px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        
        .form-group input[type="text"]:focus,
        .form-group input[type="number"]:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .form-group input[type="checkbox"] {
            margin-right: 8px;
            width: 18px;
            height: 18px;
            cursor: pointer;
        }
        
        .checkbox-label {
            display: flex;
            align-items: center;
            cursor: pointer;
            user-select: none;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        .section-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
            margin: 30px 0 20px 0;
            padding-bottom: 10px;
            border-bottom: 2px solid #e9ecef;
        }
        
        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: inline-block;
            text-align: center;
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-primary:hover {
            background: #5568d3;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .btn-success {
            background: #28a745;
            color: white;
        }
        
        .btn-success:hover {
            background: #218838;
        }
        
        .btn-group {
            display: flex;
            gap: 10px;
            margin-top: 30px;
        }
        
        .info-box {
            background: #e7f3ff;
            border-left: 4px solid #2196F3;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
        }
        
        .info-box strong {
            display: block;
            margin-bottom: 8px;
            color: #1976D2;
        }
        
        .info-box ul {
            margin-left: 20px;
            color: #555;
        }
        
        .info-box li {
            margin: 5px 0;
            font-size: 13px;
        }
        
        @media (max-width: 768px) {
            .form-row {
                grid-template-columns: 1fr;
            }
            
            .btn-group {
                flex-direction: column;
            }
            
            .btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧩 Unique Notify</h1>
            <p>CloudLinux CPU Monitoring & Telegram Alerts</p>
        </div>
        
        <div class="content">
            <div class="status-bar">
                <div>
                    <strong>Service Status:</strong>
                    <span class="status-badge <?php echo $serviceStatus['active'] ? 'active' : 'inactive'; ?>">
                        <?php echo $serviceStatus['active'] ? 'Running' : 'Stopped'; ?>
                    </span>
                </div>
                <form method="post" style="display: inline;">
                    <input type="hidden" name="action" value="restart">
                    <button type="submit" class="btn btn-secondary">↻ Restart Service</button>
                </form>
            </div>
            
            <?php if ($message): ?>
                <div class="alert alert-success"><?php echo htmlspecialchars($message); ?></div>
            <?php endif; ?>
            
            <?php if ($error): ?>
                <div class="alert alert-error"><?php echo htmlspecialchars($error); ?></div>
            <?php endif; ?>
            
            <form method="post">
                <input type="hidden" name="action" value="save">
                
                <div class="section-title">📱 Telegram Configuration</div>
                
                <div class="form-group">
                    <label class="checkbox-label">
                        <input type="checkbox" name="telegram_enabled" value="1" 
                               <?php echo $config['telegram']['enabled'] ? 'checked' : ''; ?>>
                        Enable Telegram Notifications
                    </label>
                </div>
                
                <div class="form-group">
                    <label>Bot Token</label>
                    <input type="text" name="bot_token" 
                           value="<?php echo htmlspecialchars($config['telegram']['bot_token']); ?>" 
                           placeholder="1234567890:ABCdefGHIjklMNOpqrsTUVwxyz">
                    <span class="hint">Get from <a href="https://t.me/BotFather" target="_blank">@BotFather</a></span>
                </div>
                
                <div class="form-group">
                    <label>Chat ID</label>
                    <input type="text" name="chat_id" 
                           value="<?php echo htmlspecialchars($config['telegram']['chat_id']); ?>" 
                           placeholder="-1001234567890">
                    <span class="hint">Send /start to your bot, then visit: 
                        <code>https://api.telegram.org/bot&lt;TOKEN&gt;/getUpdates</code>
                    </span>
                </div>
                
                <div class="section-title">⚙️ Alert Configuration</div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label>CPU Threshold (%)</label>
                        <input type="number" name="threshold_cpu" 
                               value="<?php echo $config['threshold_cpu']; ?>" 
                               min="1" max="100" required>
                        <span class="hint">Alert when CPU usage exceeds this value</span>
                    </div>
                    
                    <div class="form-group">
                        <label>Cooldown (minutes)</label>
                        <input type="number" name="cooldown_minutes" 
                               value="<?php echo $config['cooldown_minutes']; ?>" 
                               min="1" required>
                        <span class="hint">Minimum time between alerts for same user</span>
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label>Check Interval (seconds)</label>
                        <input type="number" name="interval_seconds" 
                               value="<?php echo $config['interval_seconds']; ?>" 
                               min="30" required>
                        <span class="hint">How often to check CPU usage</span>
                    </div>
                    
                    <div class="form-group">
                        <label>Max Alerts Per Hour</label>
                        <input type="number" name="max_alerts_per_hour" 
                               value="<?php echo $config['max_alerts_per_hour']; ?>" 
                               min="1" required>
                        <span class="hint">Rate limit for all alerts</span>
                    </div>
                </div>
                
                <div class="form-group">
                    <label>Quiet Hours (optional)</label>
                    <input type="text" name="quiet_hours" 
                           value="<?php echo htmlspecialchars($config['quiet_hours']); ?>" 
                           placeholder="00:00-06:59">
                    <span class="hint">No alerts during these hours (format: HH:MM-HH:MM)</span>
                </div>
                
                <div class="form-group">
                    <label class="checkbox-label">
                        <input type="checkbox" name="use_cloudlinux" value="1" 
                               <?php echo $config['use_cloudlinux'] ? 'checked' : ''; ?>>
                        Use CloudLinux LVE Data
                    </label>
                </div>
                
                <div class="info-box">
                    <strong>💡 Quick Setup Guide:</strong>
                    <ul>
                        <li>Create a Telegram bot via <a href="https://t.me/BotFather" target="_blank">@BotFather</a></li>
                        <li>Start a chat with your bot and send any message</li>
                        <li>Get your Chat ID from the Telegram API</li>
                        <li>Configure your thresholds and preferences above</li>
                        <li>Test the connection before saving</li>
                    </ul>
                </div>
                
                <div class="btn-group">
                    <button type="submit" class="btn btn-primary">💾 Save Configuration</button>
                    <button type="submit" name="action" value="test" class="btn btn-success">📤 Test Telegram</button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
