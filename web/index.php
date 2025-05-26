


<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);



include 'db.php';  
?>
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kali's Burgerbude</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>

<div class="header">
    <img src="images/logo3.png" alt="Logo"> 
</div>

<div class="content">
    <div class="articles">
        <?php 
        if (!$conn) {
            die("Verbindung zur Datenbank fehlgeschlagen: " . $conn->connect_error);
        }

        $sql = "SELECT * FROM artikel";
        $result = $conn->query($sql);

        if ($result === false) {
            die("Fehler bei der Abfrage: " . $conn->error);
        }

        if ($result->num_rows > 0) {
            while($row = $result->fetch_assoc()) {
                echo '<div class="article">';
                if ($row["status"] === "angebot") {
                    echo '<div class="status angebot">Angebot</div>';
                }
                echo '<h2>' . htmlspecialchars($row["bezeichnung"], ENT_QUOTES, 'UTF-8') . '</h2>';
                echo '<img src="images/' . htmlspecialchars($row["id"], ENT_QUOTES, 'UTF-8') . '.jpg" alt="' . htmlspecialchars($row["bezeichnung"], ENT_QUOTES, 'UTF-8') . '">';
                echo '<p class="description">' . htmlspecialchars($row["beschreibung"], ENT_QUOTES, 'UTF-8') . '</p>';
                echo '<p class="price">' . htmlspecialchars($row["preis"], ENT_QUOTES, 'UTF-8') . ' €</p>';
                
                if ($row["status"] === "ausverkauft") {
                    echo '<button class="order-button" disabled>Ausverkauft</button>';
                } else {
                    echo '<button class="order-button" data-id="' . htmlspecialchars($row["id"], ENT_QUOTES, 'UTF-8') . '" data-name="' . htmlspecialchars($row["bezeichnung"], ENT_QUOTES, 'UTF-8') . '" data-price="' . htmlspecialchars($row["preis"], ENT_QUOTES, 'UTF-8') . '">Bestellen</button>';
                }

                echo '</div>';
            }
        } else {
            echo "<p>Keine Artikel gefunden</p>";
        }
        ?>
    </div>

    <div class="cart">
        <h2>Warenkorb</h2>
        <div id="cart-items">
             
        </div>
        <div class="cart-total">
            Gesamt: <span id="total-price">0.00</span> €
        </div>
        <button id="checkout">Zur Kasse</button>
    </div>
</div>

<div class="popup" id="popup">
    <input type="hidden" id="popup-article-id">
    <input type="hidden" id="popup-article-price">  
    <h2 id="popup-article-name"></h2>
    <div>
        <button class="minus">-</button>
        <input type="number" id="quantity" value="1" min="1">
        <button class="plus">+</button>
    </div>
    <button id="popup-abort">Abbruch</button>
    <button id="popup-add">In den Warenkorb</button>
</div>
 
<div class="popup" id="confirmation-popup">
    <h2>Vielen Dank für die Bestellung!</h2>
    <p id="confirmation-popup-message">Ihre Bestell-ID ist <span id="order-id"></span>.</p>
    <button id="confirmation-close">Schließen</button>
</div>

<script src="js/scripts.js"></script>
</body>
</html>
