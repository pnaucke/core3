<?php
session_start();
if (!isset($_SESSION['loggedin'])) {
    header("Location: index.php");
    exit;
}

$db_host = getenv('DB_HOST') ?: 'localhost';
$db_name = getenv('DB_NAME') ?: 'innovatech';
$db_user = getenv('DB_USER') ?: 'admin';
$db_pass = getenv('DB_PASS') ?: '';
?>

<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <title>Home - Innovatech</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <nav>
        <a href="home.php">Home</a> |
        <a href="add.php">Add User</a> |
        <a href="delete.php">Delete User</a> |
        <a href="users.php">Users</a> |
        <a href="logout.php">Logout</a>
    </nav>
    
    <div class="container">
        <div class="welcome-message">
            <h1>Welcome <?php echo htmlspecialchars($_SESSION['username']); ?>!</h1>
        </div>
        
        <h2>Innovatech User Management System</h2>
        <p>This system allows you to manage users within the company.</p>
        
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-top: 30px;">
            <div style="background: #e8f4fc; padding: 20px; border-radius: 8px;">
                <h3>📋 View Users</h3>
                <p>See all registered users with their details.</p>
                <a href="users.php" style="color: #3498db; font-weight: 600;">Go to Users →</a>
            </div>
            
            <div style="background: #e8f4fc; padding: 20px; border-radius: 8px;">
                <h3>➕ Add User</h3>
                <p>Add a new user to the system.</p>
                <a href="add.php" style="color: #3498db; font-weight: 600;">Add User →</a>
            </div>
            
            <div style="background: #e8f4fc; padding: 20px; border-radius: 8px;">
                <h3>🗑️ Delete User</h3>
                <p>Remove a user from the system.</p>
                <a href="delete.php" style="color: #3498db; font-weight: 600;">Delete User →</a>
            </div>
        </div>
    </div>
</body>
</html>