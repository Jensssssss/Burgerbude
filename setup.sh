#!/bin/bash

# --- Konfiguration ---
MYSQL_ROOT_PASSWORD="MeinStarkesPasswort"
SQL_FILE="setup.sql"
PHP_SOURCE_DIR="web"

# --- Vorbereitung ---
echo "🔄 Update & Pakete installieren..."
sudo apt update
sudo apt install -y debconf-utils git apache2 mariadb-server phpmyadmin

# --- MariaDB Setup ---
echo "🔐 Konfiguriere MariaDB..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Root-Passwort setzen
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD'); FLUSH PRIVILEGES;" | sudo mysql -u root

# --- PhpMyAdmin Setup ---
echo "⚙️  Konfiguriere PhpMyAdmin..."
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections

# PhpMyAdmin installieren & Apache neu starten
sudo apt install -y phpmyadmin
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin 2>/dev/null || true
sudo systemctl restart apache2

# --- SQL-Datei importieren ---
if [ -f "$(dirname "$0")/$SQL_FILE" ]; then
    echo "▶️ Importiere SQL-Datei: $SQL_FILE"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" < "$(dirname "$0")/$SQL_FILE"
else
    echo "❌ Fehler: SQL-Datei $SQL_FILE nicht gefunden!"
    exit 1
fi

# --- PHP-Dateien kopieren ---
if [ -d "$(dirname "$0")/$PHP_SOURCE_DIR" ]; then
    echo "📂 Kopiere PHP-Dateien aus $PHP_SOURCE_DIR nach /var/www/html/"
    sudo cp "$(dirname "$0")/$PHP_SOURCE_DIR"/*.php /var/www/html/
    sudo chown www-data:www-data /var/www/html/*.php
    sudo chmod 644 /var/www/html/*.php
else
    echo "❌ Fehler: PHP-Verzeichnis '$PHP_SOURCE_DIR' existiert nicht!"
    exit 1
fi

echo "✅ Einrichtung abgeschlossen!"
echo "👉 PhpMyAdmin: http://<dein-server>/phpmyadmin"
echo "👉 Deine Seite: http://<dein-server>/"
