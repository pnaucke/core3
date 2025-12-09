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

try {
    $conn = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $conn->query("SELECT * FROM users ORDER BY id DESC");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $error = "Database fout: " . $e->getMessage();
}
?>

<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <title>Users - Innovatech</title>
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
        <h1>Users Management</h1>
        
        <?php if (isset($error)): ?>
            <div class="message error"><?php echo $error; ?></div>
        <?php endif; ?>
        
        <table>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Department</th>
                <th>Status</th>
                <th>Role</th>
            </tr>
            <?php foreach ($users as $user): ?>
            <tr>
                <td><?php echo htmlspecialchars($user['id']); ?></td>
                <td><?php echo htmlspecialchars($user['name']); ?></td>
                <td><?php echo htmlspecialchars($user['email']); ?></td>
                <td><?php echo htmlspecialchars($user['department']); ?></td>
                <td class="status-<?php echo strtolower($user['status']); ?>">
                    <?php echo htmlspecialchars($user['status']); ?>
                </td>
                <td>
                    <span class="role-badge role-<?php echo strtolower($user['role']); ?>">
                        <?php echo htmlspecialchars($user['role']); ?>
                    </span>
                </td>
            </tr>
            <?php endforeach; ?>
        </table>
        
        <p style="margin-top: 20px; color: #666; text-align: center;">
            Total users: <?php echo count($users); ?>
        </p>
    </div>
</body>
</html>