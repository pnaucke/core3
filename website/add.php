<?php
session_start();
if (!isset($_SESSION['loggedin'])) {
    header("Location: login.php");
    exit;
}

$message = '';
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $name = $_POST['name'];
    $department = $_POST['department'];
    $status = $_POST['status'];
    $role = $_POST['role'];

    $conn = new PDO("mysql:host=localhost;dbname=BookWorld", "root", "");
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    try {
        $stmt = $conn->prepare("INSERT INTO users (name, department, status, role) VALUES (?, ?, ?, ?)");
        $stmt->execute([$name, $department, $status, $role]);
        $message = "User aangemaakt";
    } catch (Exception $e) {
        $message = "Foutmelding: " . $e->getMessage();
    }
}
?>

<h1>Add User</h1>
<form method="POST">
    <label>Name</label><br>
    <input type="text" name="name" required><br>
    <label>Department</label><br>
    <input type="text" name="department" required><br>
    <label>Status</label><br>
    <input type="text" name="status" required><br>
    <label>Role</label><br>
    <input type="text" name="role" required><br><br>
    <input type="submit" value="Send">
</form>
<p><?php echo $message; ?></p>
<a href="home.php">Terug</a>
