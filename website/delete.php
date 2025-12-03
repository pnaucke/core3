<?php
session_start();
if (!isset($_SESSION['loggedin'])) {
    header("Location: index.php");
    exit;
}

$message = '';
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id = $_POST['id'];

    try {
        $conn = new PDO("mysql:host=localhost;dbname=BookWorld", "root", "");
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
        $stmt->execute([$id]);

        if ($stmt->rowCount()) {
            $message = "User verwijderd";
        } else {
            $message = "Geen user gevonden met ID $id";
        }
    } catch (Exception $e) {
        $message = "Foutmelding: " . $e->getMessage();
    }
}
?>

<h1>Delete User</h1>
<nav>
    <a href="home.php">Home</a> |
    <a href="add.php">Add User</a> |
    <a href="delete.php">Delete User</a> |
    <a href="users.php">Users</a> |
    <a href="logout.php">Logout</a>
</nav>

<form method="POST">
    <label>User ID</label><br>
    <input type="number" name="id" required><br><br>
    <input type="submit" value="Send">
</form>
<p><?php echo $message; ?></p>
