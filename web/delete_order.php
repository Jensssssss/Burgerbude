<?php
include 'db.php'; // Stellen Sie sicher, dass die db.php-Datei korrekt eingebunden ist

header('Content-Type: application/json');
$data = json_decode(file_get_contents('php://input'), true);

if (isset($data['id'])) {
    $orderId = $data['id'];

    // Begin transaction
    $conn->begin_transaction();

    try {
        // Delete from bestellung_artikel table
        $stmt = $conn->prepare("DELETE FROM bestellung_artikel WHERE bestellung_id = ?");
        $stmt->bind_param("i", $orderId);
        $stmt->execute();
        $stmt->close();

        // Delete from bestellungen table
        $stmt = $conn->prepare("DELETE FROM bestellungen WHERE id = ?");
        $stmt->bind_param("i", $orderId);
        $stmt->execute();
        $stmt->close();

        // Commit transaction
        $conn->commit();

        echo json_encode(['status' => 'success']);
    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'Fehler beim Löschen der Bestellung: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Keine Bestell-ID angegeben']);
}
?>
