<?php
session_start();
if (!isset($_SESSION['loggedin'])) {
    header("Location: lndex.php");
    exit;
}

$message = '';
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id = $_POST['id'];

    $conn = new PDO("mysql:host=localhost;dbname=BookWorld", "root", "");
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    try {
        $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
        $stmt->execute([$id]);
        if ($stmt->rowCount()) {
            $message = "User verwijderd";
        } else {
            $message = "Geen user gevonden met id $id";
        }
    } catch (Exception $e) {
        $message = "Foutmelding: " . $e->getMessage();
    }
}
?>

<h1>Delete User</h1>
<form method="POST">
    <label>User ID</label><br>
    <input type="number" name="id" required><br><br>
    <input type="submit" value="Send">
</form>
<p><?php echo $message; ?></p>
<a href="home.php">Terug</a>
