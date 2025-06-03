<?php
include 'db.php'; 

$sql = "
    SELECT b.id, b.zeitpunkt, SUM(ba.gesamtpreis) as gesamtpreis
    FROM bestellungen b
    JOIN bestellung_artikel ba ON b.id = ba.bestellung_id
    GROUP BY b.id, b.zeitpunkt
    ORDER BY b.zeitpunkt DESC
";
$result = $conn->query($sql);
?>

<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="30">

    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kali's Burgerbude</title>
    <link rel="stylesheet" href="css/bestellungen.css">
</head>
<body>

<div class="header">
    <img src="images/logo3.png" alt="Logo">
</div>

<div class="content">
    <h1>Bestellungen</h1>
    <div class="orders">
        <?php
        if ($result->num_rows > 0) {
            echo '<table>';
            echo '<tr><th>Bestell-ID</th><th>Zeitpunkt</th><th>Gesamtpreis</th><th>Aktionen</th></tr>';
            while($row = $result->fetch_assoc()) {
                echo '<tr>';
                echo '<td>' . htmlspecialchars($row["id"], ENT_QUOTES, 'UTF-8') . '</td>';
                echo '<td>' . htmlspecialchars($row["zeitpunkt"], ENT_QUOTES, 'UTF-8') . '</td>';
                echo '<td>' . number_format($row["gesamtpreis"], 2, ',', '.') . ' €</td>';
                echo '<td>';
                echo '<button class="delete-order" data-id="' . htmlspecialchars($row["id"], ENT_QUOTES, 'UTF-8') . '">Löschen</button> ';
                echo '<button class="view-items" data-id="' . htmlspecialchars($row["id"], ENT_QUOTES, 'UTF-8') . '">Artikel anzeigen</button>';
                echo '</td>';
                echo '</tr>';
            }
            echo '</table>';
        } else {
            echo "<p>Keine Bestellungen gefunden</p>";
        }
        ?>
    </div>
</div>
 
<div class="popup" id="popup">
    <h2>Bestellungsdetails</h2>
    <div id="order-items"></div>
    <button id="close-popup">Schließen</button>
</div>

<script>


document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('.delete-order').forEach(button => {
        button.addEventListener('click', () => {
            if (confirm('Möchten Sie diese Bestellung wirklich löschen?')) {
                deleteOrder(button.dataset.id);
            }
        });
    });

    document.querySelectorAll('.view-items').forEach(button => {
        button.addEventListener('click', () => {
            viewOrderItems(button.dataset.id);
        });
    });

    document.getElementById('close-popup').addEventListener('click', () => {
        document.getElementById('popup').style.display = 'none';
    });
});

function deleteOrder(orderId) {
    fetch('delete_order.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ id: orderId })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            alert('Bestellung erfolgreich gelöscht');
            location.reload();
        } else {
            alert('Fehler beim Löschen der Bestellung: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Ein Fehler ist aufgetreten: ' + error.message);
    });
}

function viewOrderItems(orderId) {
    fetch('get_order_items.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ id: orderId })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            let items = data.items;
            let orderItemsDiv = document.getElementById('order-items');
            orderItemsDiv.innerHTML = '';
            items.forEach(item => {
                orderItemsDiv.innerHTML += `<p>${item.anzahl} x ${item.bezeichnung} - ${item.einzelpreis} €</p>`;
            });
            document.getElementById('popup').style.display = 'block';
        } else {
            alert('Fehler beim Abrufen der Artikel: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Ein Fehler ist aufgetreten: ' + error.message);
    });
}
</script>

</body>
</html>
