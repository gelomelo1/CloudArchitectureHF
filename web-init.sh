#!/bin/bash
set -e

yum update -y

# PHP 8 (Amazon Linux 2)
amazon-linux-extras enable php8.0
yum clean metadata

yum install -y httpd php php-mysqlnd wget

systemctl enable httpd
systemctl start httpd

cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* .
rm -rf wordpress latest.tar.gz

chown -R apache:apache /var/www/html

cp wp-config-sample.php wp-config.php

sed -i "s/database_name_here/wordpress/" wp-config.php
sed -i "s/username_here/wpuser/" wp-config.php
sed -i "s/password_here/wppass/" wp-config.php
sed -i "s/localhost/${db_host}/" wp-config.php

systemctl restart httpd