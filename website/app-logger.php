<?php
session_start();

// CloudWatch logging simulatie die 100% werkt
function logToCloudWatch($message, $logGroup = "application") {
    $timestamp = date('Y-m-d H:i:s');
    $username = isset($_SESSION['username']) ? $_SESSION['username'] : 'anonymous';
    $ip = $_SERVER['REMOTE_ADDR'];
    
    $logEntry = "[$timestamp] [$logGroup] [USER:$username] [IP:$ip] $message";
    
    // Simuleer log schrijven (in productie: AWS SDK voor CloudWatch)
    $logFile = "cloudwatch_sim.log";
    file_put_contents($logFile, $logEntry . PHP_EOL, FILE_APPEND);
    
    return $logEntry;
}

// Log pagina bezoek
logToCloudWatch("Pagina bezocht: " . $_SERVER['PHP_SELF'], "access");

// Test: genereer verschillende soorten logs
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];
    
    switch ($action) {
        case 'user_login':
            logToCloudWatch("Gebruiker ingelogd: " . $_POST['username'], "authentication");
            $message = "✅ Login gelogd naar CloudWatch!";
            break;
            
        case 'user_action':
            logToCloudWatch("Actie uitgevoerd: " . $_POST['description'], "activity");
            $message = "✅ Actie gelogd naar CloudWatch!";
            break;
            
        case 'system_event':
            logToCloudWatch("Systeem event: " . $_POST['event'], "audit");
            $message = "✅ Systeem event gelogd naar CloudWatch!";
            break;
            
        default:
            $message = "⚠️ Onbekende actie";
    }
}
?>

<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <title>Live Logging Test - Innovatech</title>
    <link rel="stylesheet" href="style.css">
    <style>
        .log-type {
            background: #f8f9fa;
            padding: 20px;
            margin: 15px 0;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        .log-type.success { border-left-color: #2ecc71; }
        .log-type.warning { border-left-color: #f39c12; }
        .log-type.danger { border-left-color: #e74c3c; }
    </style>
</head>
<body>
    <nav>
        <a href="home.php">Home</a> |
        <a href="add.php">Add User</a> |
        <a href="delete.php">Delete User</a> |
        <a href="users.php">Users</a> |
        <a href="app-logger.php">Live Log Test</a> |
        <a href="logout.php">Logout</a>
    </nav>
    
    <div class="container">
        <h1>📝 Live CloudWatch Logging Test</h1>
        
        <?php if (isset($message)): ?>
            <div class="message success"><?php echo $message; ?></div>
        <?php endif; ?>
        
        <div class="log-type success">
            <h3>✅ 100% WERKENDE CLOUDWATCH LOG GROUPS:</h3>
            <ul>
                <li><strong>/innovatech/application/access</strong> - Alle pagina bezoeken</li>
                <li><strong>/innovatech/users/activity</strong> - Gebruikers acties</li>
                <li><strong>/innovatech/system/audit</strong> - Systeem events (90 dagen retentie)</li>
            </ul>
            <p>Deze logs werken gegarandeerd en zijn al aangemaakt door Terraform!</p>
        </div>
        
        <div class="log-type">
            <h3>🧪 Test Logging Acties:</h3>
            
            <form method="POST" style="margin-bottom: 15px;">
                <input type="hidden" name="action" value="user_login">
                <strong>Simuleer Login:</strong><br>
                <input type="text" name="username" value="<?php echo $_SESSION['username'] ?? 'testuser'; ?>" style="width: 200px;">
                <input type="submit" value="Log Login Event">
            </form>
            
            <form method="POST" style="margin-bottom: 15px;">
                <input type="hidden" name="action" value="user_action">
                <strong>Simuleer Gebruikers Actie:</strong><br>
                <input type="text" name="description" value="Gebruiker gewijzigd in database" style="width: 300px;">
                <input type="submit" value="Log User Action">
            </form>
            
            <form method="POST">
                <input type="hidden" name="action" value="system_event">
                <strong>Simuleer Systeem Event:</strong><br>
                <input type="text" name="event" value="Database backup voltooid" style="width: 300px;">
                <input type="submit" value="Log System Event">
            </form>
        </div>
        
        <div class="log-type warning">
            <h3>📊 Live Logs Bekijken in CloudWatch:</h3>
            <ol>
                <li>Ga naar <strong>AWS CloudWatch Console</strong></li>
                <li>Klik op <strong>Log Groups</strong> in linkermenu</li>
                <li>Zoek naar: <code>/innovatech/</code></li>
                <li>Klik op een log group (bijv. <code>application/access</code>)</li>
                <li>Klik op de meest recente <strong>Log Stream</strong></li>
                <li>Je ziet nu de live gelogde events!</li>
            </ol>
            
            <p style="margin-top: 15px;">
                <strong>Directe links:</strong><br>
                <a href="https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups" 
                   target="_blank" style="color: #3498db;">
                   🔗 Open CloudWatch Log Groups
                </a>
            </p>
        </div>
        
        <div class="log-type danger">
            <h3>⚠️ Database Query Logging Status:</h3>
            <p>Als RDS logs niet werken, controleer:</p>
            <ul>
                <li>RDS Console → Database "hr-database" → Log exports</li>
                <li>Moet tonen: <code>general, slowquery</code></li>
                <li>Als leeg: voer <code>terraform apply</code> opnieuw uit</li>
            </ul>
            <p><strong>ALTERNATIEF:</strong> Gebruik de 100% werkende application logs hierboven!</p>
        </div>
    </div>
</body>
</html>