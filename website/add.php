<?php
session_start();
if (!isset($_SESSION['loggedin'])) {
    header("Location: index.php");
    exit;
}

$message = '';
$message_class = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $name = $_POST['name'];
    $department = $_POST['department'];
    $status = $_POST['status'];
    $role = $_POST['role'];

    try {
        $conn = new PDO("mysql:host=localhost;dbname=innovatech", "root", "");
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        $stmt = $conn->prepare("INSERT INTO users (name, department, status, role) VALUES (?, ?, ?, ?)");
        $stmt->execute([$name, $department, $status, $role]);
        
        $message = "User successfully added!";
        $message_class = "success";
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
    <title>Add User - Innovatech</title>
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
        <h1>Add New User</h1>
        
        <?php if ($message): ?>
            <div class="message <?php echo $message_class; ?>">
                <?php echo $message; ?>
            </div>
        <?php endif; ?>
        
        <form method="POST">
            <label>Full Name</label>
            <input type="text" name="name" required placeholder="Enter full name">
            
            <label>Department</label>
            <input type="text" name="department" required placeholder="Enter department">
            
            <label>Status</label>
            <select name="status" required>
                <option value="">Select status</option>
                <option value="Active">Active</option>
                <option value="Inactive">Inactive</option>
                <option value="On Leave">On Leave</option>
            </select>
            
            <label>Role</label>
            <select name="role" required>
                <option value="">Select role</option>
                <option value="Manager">Manager</option>
                <option value="Accountant">Accountant</option>
                <option value="Cleaner">Cleaner</option>
            </select>
            
            <input type="submit" value="Add User">
        </form>
        
        <p style="text-align: center; margin-top: 20px;">
            <a href="users.php" style="color: #3498db;">← Back to Users List</a>
        </p>
    </div>
</body>
</html>