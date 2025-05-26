<?php
$servername = "localhost";
$username = "kaliburger";
$password = "kaliburger";
$dbname = "kaliburger";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Set UTF-8 encoding
$conn->set_charset("utf8mb4");
?>