#!/bin/bash
set -e

yum update -y

# MariaDB install (Amazon Linux 2 safe version)
amazon-linux-extras install -y mariadb10.5

yum install -y mariadb-server

systemctl enable mariadb
systemctl start mariadb

mysql -e "CREATE DATABASE IF NOT EXISTS wordpress;"
mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY 'wppass';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';"
mysql -e "FLUSH PRIVILEGES;"