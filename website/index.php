<?php
session_start();

// Database config blijft voor andere pagina's
$db_host = 'hr-database.cboq60ou0623.eu-central-1.rds.amazonaws.com';
$db_name = 'innovatech';
$db_user = 'admin';
$db_pass = 'admin123';

// HARCODED HR LOGIN (override database check)
$valid_logins = [
    'admin' => 'admin123',
    // Voeg meer gebruikers toe indien nodig
];

$error = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];

    // Check tegen hardcoded logins
    if (isset($valid_logins[$username]) && $valid_logins[$username] === $password) {
        $_SESSION['loggedin'] = true;
        $_SESSION['username'] = $username;
        header("Location: home.php");
        exit;
    } else {
        $error = 'Ongeldige gebruikersnaam of wachtwoord';
    }
}
?>

<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <title>Login - Innovatech</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="login-container">
        <h1 style="text-align: center; color: #2c3e50; margin-bottom: 10px;">Innovatech</h1>
        <p style="text-align: center; color: #7f8c8d; margin-bottom: 30px;">User Management System</p>
        
        <h2 style="text-align: center; margin-bottom: 25px;">Login</h2>
        
        <?php if ($error): ?>
            <div class="message error"><?php echo htmlspecialchars($error); ?></div>
        <?php endif; ?>
        
        <form method="POST">
            <label>Gebruikersnaam</label>
            <input type="text" name="username" required placeholder="Voer gebruikersnaam in">
            
            <label>Wachtwoord</label>
            <input type="password" name="password" required placeholder="Voer wachtwoord in">
            
            <input type="submit" value="Inloggen">
        </form>
        
        <p style="text-align: center; margin-top: 20px; color: #7f8c8d; font-size: 14px;">
            Log in met je HR-account gegevens
        </p>
        
        <p style="text-align: center; margin-top: 10px; color: #95a5a6; font-size: 12px;">
            Gebruiker: admin | Wachtwoord: admin123
        </p>
    </div>
</body>
</html>