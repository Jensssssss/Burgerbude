CREATE DATABASE kaliburger CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;


USE kaliburger;


CREATE TABLE artikel (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bezeichnung VARCHAR(255) NOT NULL,
    beschreibung TEXT,
    typ ENUM('burger', 'getraenke', 'nachtisch') NOT NULL,
    preis DECIMAL(10, 2) NOT NULL,
    status ENUM('normal', 'angebot', 'ausverkauft') DEFAULT 'normal'
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;


CREATE TABLE bestellungen (
    id INT AUTO_INCREMENT PRIMARY KEY,
    zeitpunkt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;


CREATE TABLE bestellung_artikel (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bezeichnung VARCHAR(255) NOT NULL,
    einzelpreis DECIMAL(10,2) NOT NULL,
    anzahl INT NOT NULL,
    gesamtpreis DECIMAL(10,2) GENERATED ALWAYS AS (einzelpreis * anzahl) STORED,
    bestellung_id INT,
    FOREIGN KEY (bestellung_id) REFERENCES bestellungen(id)
);



-- Beispiel-Daten einfügen
INSERT INTO artikel (bezeichnung, beschreibung, typ, preis) VALUES
('Cheeseburger', 'Ein köstlicher Cheeseburger mit saftigem Rindfleisch, Käse und frischen Zutaten.', 'burger', 4.50),
('Double Cheeseburger', 'Ein köstlicher Cheeseburger mit doppeltem Rindfleisch und extra Käse.', 'burger', 5.49),
('Veggie Burger', 'Ein leckerer Burger mit einer herzhaften Gemüsescheibe und frischen Zutaten.', 'burger', 4.99),
('Classic Burger', 'Ein klassischer Burger mit saftigem Rindfleisch, frischem Salat und Tomaten.', 'burger', 5.99),
('Chicken Burger', 'Ein knuspriger Hühnchenburger mit Salat und Mayo.', 'burger', 6.49),
('Double Bacon Burger', 'Ein doppelter Burger mit extra Speck und Käse.', 'burger', 7.99),
('Cola', 'Eine erfrischende Cola.', 'getraenke', 1.99),
('Fanta', 'Ein spritziges Orangengetränk.', 'getraenke', 1.99),
('Mineralwasser', 'Erfrischendes Mineralwasser ohne Kohlensäure.', 'getraenke', 1.49),
('Eisbecher', 'Ein köstlicher Eisbecher mit Vanilleeis und Schokoladensauce.', 'nachtisch', 3.99),
('Schoko-Eisbecher', 'Ein köstlicher Eisbecher mit Schokoladeneis und Schokoladensauce.', 'nachtisch', 3.50),
('Vanille-Eisbecher', 'Ein leckerer Eisbecher mit Vanilleeis und frischen Erdbeeren.', 'nachtisch', 3.99); 



CREATE TABLE generation_config (
  enabled         TINYINT(1) NOT NULL DEFAULT 0,
  interval_minutes INT       NOT NULL DEFAULT 10,
  last_run        DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Und direkt einen Default-Eintrag einfügen:
INSERT INTO generation_config (enabled, interval_minutes, last_run) VALUES (0, 10, NOW());
