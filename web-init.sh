#!/bin/bash
set -e

# Frissítem a rendszer csomaglistáját és telepítem a frissítéseket
yum update -y

# Engedélyezem a PHP 8.0 repository-t Amazon Linux 2-n
amazon-linux-extras enable php8.0
yum clean metadata

# Telepítem az Apache webszervert, PHP-t és a MySQL kliens modult, wget-et
yum install -y httpd php php-mysqlnd wget

# Engedélyezem és elindítom az Apache webszervert
systemctl enable httpd
systemctl start httpd

# Letöltöm és kicsomagolom a WordPress-t a web root könyvtárba
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* .
rm -rf wordpress latest.tar.gz

# Beállítom a megfelelő jogosultságokat az Apache számára
chown -R apache:apache /var/www/html

# Létrehozom a WordPress konfigurációs fájlt a mintából
cp wp-config-sample.php wp-config.php

# Beállítom az adatbázis kapcsolat paramétereit a WordPress konfigurációban
sed -i "s/database_name_here/wordpress/" wp-config.php
sed -i "s/username_here/wpuser/" wp-config.php
sed -i "s/password_here/wppass/" wp-config.php
sed -i "s/localhost/${db_host}/" wp-config.php

# Újraindítom az Apache webszervert a változások érvényesítéséhez
systemctl restart httpd