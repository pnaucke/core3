<?php
session_start();
session_destroy();
header("Location: lndex.php");
exit;
?>
