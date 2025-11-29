<?php
session_start();
if (!isset($_SESSION['loggedin'])) {
    header("Location: index.php");
    exit;
}

try {
    $conn = new PDO("mysql:host=localhost;dbname=BookWorld", "root", "");
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $conn->query("SELECT * FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    echo "Foutmelding: " . $e->getMessage();
}
?>

<h1>Users</h1>
<nav>
    <a href="home.php">Home</a> |
    <a href="add.php">Add User</a> |
    <a href="delete.php">Delete User</a> |
    <a href="users.php">Users</a> |
    <a href="logout.php">Logout</a>
</nav>

<table border="1" cellpadding="5">
    <tr>
        <th>ID</th>
        <th>Name</th>
        <th>Department</th>
        <th>Status</th>
        <th>Role</th>
    </tr>
    <?php foreach ($users as $user): ?>
    <tr>
        <td><?php echo $user['id']; ?></td>
        <td><?php echo $user['name']; ?></td>
        <td><?php echo $user['department']; ?></td>
        <td><?php echo $user['status']; ?></td>
        <td><?php echo $user['role']; ?></td>
    </tr>
    <?php endforeach; ?>
</table>
