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

$message = '';
$message_class = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id = $_POST['id'];

    try {
        $conn = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        $checkStmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
        $checkStmt->execute([$id]);
        $user = $checkStmt->fetch();

        if ($user) {
            $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
            $stmt->execute([$id]);
            $message = "User #$id successfully deleted!";
            $message_class = "success";
        } else {
            $message = "No user found with ID $id";
            $message_class = "error";
        }
    } catch (Exception $e) {
        $message = "Error: " . $e->getMessage();
        $message_class = "error";
    }
}
?>

<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <title>Delete User - Innovatech</title>
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
    
    <div class="form-container">
        <h1>Delete User</h1>
        
        <?php if ($message): ?>
            <div class="message <?php echo $message_class; ?>">
                <?php echo $message; ?>
            </div>
        <?php endif; ?>
        
        <form method="POST">
            <label>User ID to Delete</label>
            <input type="number" name="id" required placeholder="Enter user ID" min="1">
            
            <input type="submit" value="Delete User" style="background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);">
        </form>
        
        <p style="text-align: center; margin-top: 20px;">
            <a href="users.php" style="color: #3498db;">← View all users first</a>
        </p>
        
        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 6px; margin-top: 20px;">
            <p style="color: #666; font-size: 14px;">
                <strong>Note:</strong> Enter the User ID from the users list. This action cannot be undone.
            </p>
        </div>
    </div>
</body>
</html>