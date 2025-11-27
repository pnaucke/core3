<?php
session_start();

$error = '';
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];

    if ($username === 'admin' && $password === 'admin') {
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
    <title>Login</title>
</head>
<body>
<h1>Login</h1>
<form method="POST">
    <label>Username</label><br>
    <input type="text" name="username" required><br><br>
    <label>Password</label><br>
    <input type="password" name="password" required><br><br>
    <input type="submit" value="Login">
</form>
<p style="color:red"><?php echo $error; ?></p>
</body>
</html>
