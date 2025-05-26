<?php
include 'db.php';
session_start();

header('Content-Type: application/json');

$cart = json_decode($_POST['cart'], true);
$response = [];

if (count($cart) > 0) {
    // Start transaction
    $conn->begin_transaction();

    try {
        // Insert into bestellungen table
        $stmt = $conn->prepare("INSERT INTO bestellungen (zeitpunkt) VALUES (NOW())");
        $stmt->execute();
        $bestellung_id = $conn->insert_id;
        $stmt->close();

        // Insert each cart item into bestellung_artikel table
        $stmt = $conn->prepare("INSERT INTO bestellung_artikel (bezeichnung, einzelpreis, anzahl, bestellung_id) VALUES (?, ?, ?, ?)");
        foreach ($cart as $item) {
            $bezeichnung = $item['name'];
            $einzelpreis = $item['price'];
            $anzahl = $item['quantity'];

            $stmt->bind_param("sdii", $bezeichnung, $einzelpreis, $anzahl, $bestellung_id);
            $stmt->execute();
        }
        $stmt->close();

        // Commit transaction
        $conn->commit();

        $response['status'] = 'success';
        $response['message'] = 'Vielen Dank für die Bestellung!';
        $response['bestellung_id'] = $bestellung_id; // Add the order ID to the response
    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        $response['status'] = 'error';
        $response['message'] = 'Fehler bei der Bestellung: ' . $e->getMessage();
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Warenkorb ist leer!';
}

echo json_encode($response);
?>
