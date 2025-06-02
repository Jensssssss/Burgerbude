#!/bin/bash
# --- OS Detection (nur zur Information) ---
if grep -qi "raspbian" /etc/os-release; then
    OS="Raspbian"
elif grep -qi "ubuntu" /etc/os-release; then
    OS="Ubuntu"
else
    OS="Unknown"
fi
echo "Detected OS: $OS"

# --- Konfiguration ---
MYSQL_ROOT_PASSWORD="MeinStarkesPasswort"
SQL_FILE="setup.sql"
PHP_SOURCE_DIR="web"

# Netzwerk-Konfiguration für DHCP/DNS/TFTP/PXE
SERVER_IP="192.168.178.103"
DHCP_RANGE_START="192.168.178.10"
DHCP_RANGE_END="192.168.178.100"
NETWORK="192.168.178.0"
NETMASK="255.255.255.0"

# Falls INTERFACE nicht manuell gesetzt wurde, ermittelt dieser Befehl die Standard-Schnittstelle
if [ -z "$INTERFACE" ]; then
    INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
fi
echo "Genutzte Netzwerkschnittstelle: $INTERFACE"

# Basis-Verzeichnis: Das Verzeichnis, in dem sich dieses Skript befindet
BASE_DIR="$(dirname "$0")"
echo "Basisverzeichnis: $BASE_DIR"

# --- Update & Installation der notwendigen Pakete ---
echo "🔄 Update & Installation der notwendigen Pakete..."
sudo apt update
sudo apt install -y debconf-utils git apache2 mariadb-server phpmyadmin isc-dhcp-server bind9 tftpd-hpa

# --- MariaDB Setup ---
echo "🔐 Konfiguriere MariaDB..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Setze das Root-Passwort
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD'); FLUSH PRIVILEGES;" | sudo mysql -u root
# Optional: Umstellung der Authentifizierung auf mysql_native_password
sudo mysql -e "UPDATE mysql.user SET plugin='mysql_native_password' WHERE User='root'; FLUSH PRIVILEGES;"

# --- PhpMyAdmin Setup ---
echo "⚙️  Konfiguriere PhpMyAdmin..."
# Debconf-Einstellungen für phpmyadmin setzen
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections

sudo apt install -y phpmyadmin
if [ ! -L /var/www/html/phpmyadmin ]; then
    sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
fi
sudo systemctl restart apache2

# --- SQL-Datei importieren ---
if [ -f "$BASE_DIR/$SQL_FILE" ]; then
    echo "▶️ Importiere SQL-Datei: $SQL_FILE"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" < "$BASE_DIR/$SQL_FILE"
else
    echo "❌ Fehler: SQL-Datei $SQL_FILE nicht gefunden!"
    exit 1
fi

# --- DB-Benutzer 'kaliburger' erstellen ---
echo "▶️ Erstelle Datenbankbenutzer 'kaliburger' mit Lese- und Schreibrechten auf der Datenbank 'kaliburger'..."
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE USER IF NOT EXISTS 'kaliburger'@'localhost' IDENTIFIED BY 'kaliburger';
GRANT SELECT, INSERT, UPDATE, DELETE ON kaliburger.* TO 'kaliburger'@'localhost';
FLUSH PRIVILEGES;
EOF

# --- PHP-Dateien kopieren ---
if [ -d "$BASE_DIR/$PHP_SOURCE_DIR" ]; then
    echo "📂 Kopiere PHP-Dateien aus $PHP_SOURCE_DIR nach /var/www/html/"
    sudo cp "$BASE_DIR/$PHP_SOURCE_DIR"/*.php /var/www/html/
    sudo chown www-data:www-data /var/www/html/*.php
    sudo chmod 644 /var/www/html/*.php
else
    echo "❌ Fehler: PHP-Verzeichnis '$PHP_SOURCE_DIR' existiert nicht!"
    exit 1
fi

# --- Netzwerk-Dienste: DHCP, DNS, TFTP & PXE ---
echo "🔄 Konfiguriere DHCP, DNS, TFTP & PXE Server..."

# DHCP Server-Konfiguration
echo "▶️ Konfiguriere den DHCP Server..."
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak 2>/dev/null
sudo bash -c "cat > /etc/dhcp/dhcpd.conf <<EOF
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;
log-facility local7;

subnet $NETWORK netmask $NETMASK {
    range $DHCP_RANGE_START $DHCP_RANGE_END;
    option routers $SERVER_IP;
    option domain-name-servers $SERVER_IP;
    filename \"Ubuntu-Kiosk.img\";
    next-server $SERVER_IP;
}
EOF"

# DHCP-Schnittstelle konfigurieren
echo "▶️ Lege die DHCP-Schnittstelle fest..."
sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.bak 2>/dev/null
sudo bash -c "cat > /etc/default/isc-dhcp-server <<EOF
INTERFACESv4=\"$INTERFACE\"
INTERFACESv6=\"\"
EOF"
sudo systemctl restart isc-dhcp-server

# TFTP Server-Konfiguration
echo "▶️ Konfiguriere den TFTP Server..."
# PXE-Ordner aus dem geklonten Repo nutzen
TFTP_DIR="$(realpath "$BASE_DIR/PXE")"
sudo cp /etc/default/tftpd-hpa /etc/default/tftpd-hpa.bak 2>/dev/null
sudo bash -c "cat > /etc/default/tftpd-hpa <<EOF
TFTP_USERNAME=\"tftp\"
TFTP_DIRECTORY=\"$TFTP_DIR\"
TFTP_ADDRESS=\"0.0.0.0:69\"
TFTP_OPTIONS=\"--secure\"
EOF"
sudo systemctl restart tftpd-hpa

# DNS Server-Konfiguration (Bind9)
echo "▶️ Konfiguriere den DNS Server (Bind9)..."
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak 2>/dev/null
sudo bash -c "cat > /etc/bind/named.conf.options <<EOF
options {
    directory \"/var/cache/bind\";

    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    dnssec-validation auto;
    listen-on { $SERVER_IP; };
    allow-query { any; };

    auth-nxdomain no;
    listen-on-v6 { none; };
};
EOF"
sudo systemctl restart bind9

# --- Firewall-Konfiguration (falls ufw vorhanden ist) ---
if command -v ufw &> /dev/null; then
    echo "▶️ Konfiguriere ufw: Öffne notwendige Ports..."
    sudo ufw allow 53/tcp
    sudo ufw allow 53/udp
    sudo ufw allow 80/tcp
    sudo ufw allow 67/udp
    sudo ufw allow 68/udp
    sudo ufw allow 69/udp
    sudo ufw reload
else
    echo "Hinweis: ufw ist nicht installiert. Falls eine andere Firewall genutzt wird, öffnen Sie bitte die Ports manuell."
fi

echo "✅ Alle Dienste wurden erfolgreich konfiguriert!"
echo "👉 PhpMyAdmin: http://<dein-server>/phpmyadmin"
echo "👉 Deine Website: http://<dein-server>/"
echo "👉 PXE Boot: Clients (IP-Bereich $DHCP_RANGE_START bis $DHCP_RANGE_END) erhalten per DHCP den Hinweis, direkt Ubuntu-Kiosk.img vom Server $SERVER_IP zu booten."
