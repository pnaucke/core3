<?php
session_start();
if (!isset($_SESSION['loggedin'])) {
    header("Location: index.php");
    exit;
}
?>

<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <title>Home</title>
</head>
<body>
<h1>Welkom <?php echo $_SESSION['username']; ?></h1>
<p>Hier kan je users beheren</p>
<nav>
    <a href="home.php">Home</a> |
    <a href="add.php">Add User</a> |
    <a href="delete.php">Delete User</a> |
    <a href="users.php">Users</a> |
    <a href="logout.php">Logout</a>
</nav>
</body>
</html>
