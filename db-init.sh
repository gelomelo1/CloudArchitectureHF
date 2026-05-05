#!/bin/bash
set -e

# Frissítem a rendszer csomaglistáját és telepítem a frissítéseket
yum update -y

# Telepítem a MariaDB 10.5 verziót
amazon-linux-extras install -y mariadb10.5

# Telepítem a MariaDB szerver csomagot
yum install -y mariadb-server

# Engedélyezem és elindítom a MariaDB szolgáltatást
systemctl enable mariadb
systemctl start mariadb

# Létrehozom a WordPress adatbázist, ha még nem létezik
mysql -e "CREATE DATABASE IF NOT EXISTS wordpress;"

# Létrehozok egy adatbázis felhasználót jelszóval, ha még nem létezik
mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY 'wppass';"

# Teljes hozzáférést adok a felhasználónak a WordPress adatbázishoz
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';"

# Alkalmazom a jogosultság módosításokat
mysql -e "FLUSH PRIVILEGES;"