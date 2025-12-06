<?php
session_start();

// Database configuratie via environment variables
$db_host = getenv('DB_HOST') ?: 'localhost';
$db_name = getenv('DB_NAME') ?: 'innovatech';
$db_user = getenv('DB_USER') ?: 'admin';
$db_pass = getenv('DB_PASS') ?: '';

$error = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];

    try {
        $conn = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8", $db_user, $db_pass);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        $stmt = $conn->prepare("SELECT * FROM hr WHERE name = ?");
        $stmt->execute([$username]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            if ($password === $user['password']) {
                $_SESSION['loggedin'] = true;
                $_SESSION['username'] = $user['name'];
                header("Location: home.php");
                exit;
            } else {
                $error = 'Ongeldig wachtwoord';
            }
        } else {
            $error = 'Gebruiker niet gevonden';
        }
    } catch (PDOException $e) {
        $error = 'Database fout: ' . $e->getMessage();
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
    </div>
</body>
</html>