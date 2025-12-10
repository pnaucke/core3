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
    $name = $_POST['name'];
    $email = $_POST['email'];
    $department = $_POST['department'];
    $status = $_POST['status'];
    $role = $_POST['role'];
    $hr_password = $_POST['hr_password'] ?? '';

    try {
        $conn = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        $stmt = $conn->prepare("INSERT INTO users (name, email, department, status, role) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$name, $email, $department, $status, $role]);
        
        if ($role === 'HR' && !empty($hr_password)) {
            $stmt_hr = $conn->prepare("INSERT INTO hr (name, password) VALUES (?, ?)");
            $stmt_hr->execute([$name, $hr_password]);
            $message = "User successfully added! HR account created.";
        } else {
            $message = "User successfully added!";
        }
        
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

            <label>Email</label>
            <input type="text" name="email" required placeholder="Enter your email">
            
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
            <select name="role" required id="roleSelect">
                <option value="">Select role</option>
                <option value="Manager">Manager</option>
                <option value="Accountant">Accountant</option>
                <option value="Cleaner">Cleaner</option>
                <option value="HR">HR</option>
            </select>
            
            <div id="hrPasswordField" style="display: none;">
                <label>HR Login Password (required for HR users)</label>
                <input type="password" name="hr_password" placeholder="Enter password for HR login">
            </div>
            
            <input type="submit" value="Add User">
        </form>
        
        <p style="text-align: center; margin-top: 20px;">
            <a href="users.php" style="color: #3498db;">← Back to Users List</a>
        </p>
        
        <script>
            document.getElementById('roleSelect').addEventListener('change', function() {
                var hrPasswordField = document.getElementById('hrPasswordField');
                if (this.value === 'HR') {
                    hrPasswordField.style.display = 'block';
                } else {
                    hrPasswordField.style.display = 'none';
                }
            });
        </script>
    </div>
</body>
</html>