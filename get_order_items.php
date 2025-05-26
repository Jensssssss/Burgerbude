<?php
include 'db.php'; // Stellen Sie sicher, dass die db.php-Datei korrekt eingebunden ist

header('Content-Type: application/json');
$data = json_decode(file_get_contents('php://input'), true);

if (isset($data['id'])) {
    $orderId = $data['id'];

    $sql = "
        SELECT bezeichnung, einzelpreis, anzahl
        FROM bestellung_artikel
        WHERE bestellung_id = ?
    ";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $orderId);
    $stmt->execute();
    $result = $stmt->get_result();
    $items = [];

    while ($row = $result->fetch_assoc()) {
        $items[] = $row;
    }

    $stmt->close();

    echo json_encode(['status' => 'success', 'items' => $items]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Keine Bestell-ID angegeben']);
}
?>
