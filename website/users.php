<?php
session_start();
if (!isset($_SESSION['loggedin'])) {
    header("Location: login.php");
    exit;
}

$conn = new PDO("mysql:host=localhost;dbname=BookWorld", "root", "");
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$stmt = $conn->query("SELECT * FROM users");
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<h1>Users</h1>
<table border="1">
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
<a href="home.php">Terug</a>
