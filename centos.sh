#!/usr/bin/env bash

# Install Apache & PHP dependencies
# --------------------
sudo yum -y update
sudo yum -y install httpd
sudo systemctl start httpd.service
sudo systemctl enable httpd.service

sudo yum install -y \
recode-devel \
aspell-devel \
libmcrypt-devel \
t1lib-devel \
libXpm-devel \
libpng-devel \
libjpeg-turbo-devel \
bzip2-devel \
openssl-libs \
libicu-devel

sudo yum -y install epel-release

# Install precompiled PHP7 from Zend repos
# --------------------
wget http://repos.zend.com/zend-server/early-access/php7/php-7.0-beta1-RHEL-x86_64.tar.gz
sudo tar xzPf php-7.0-beta1-RHEL-x86_64.tar.gz
sudo  cp /usr/local/php7/libphp7.so /etc/httpd/modules/

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf /var/www/html
mkdir /vagrant/httpdocs
ln -fs /vagrant/httpdocs /var/www/html
sudo chown apache:apache -R /var/www/html

# Set handler for PHP in Apache config
# --------------------
HANDLER=$(echo "LoadModule php7_module        /usr/lib64/httpd/modules/libphp7.so  
<FilesMatch \.php$>
SetHandler application/x-httpd-php
</FilesMatch>")
echo "$HANDLER" >> /etc/httpd/conf/httpd.conf

# Create Apache vhost
# --------------------
VHOST=$(cat <<EOF
NameVirtualHost *:8080
Listen 8080
<VirtualHost *:80>
  DirectoryIndex index.php
  DocumentRoot "/var/www/html/wordpress"
  ServerName localhost
  <Directory "/var/www/html/wordpress">
    AllowOverride All
  </Directory>
</VirtualHost>
<VirtualHost *:8080>
  DirectoryIndex index.php
  DocumentRoot "/var/www/html/wordpress"
  ServerName localhost
  <Directory "/var/www/html/wordpress">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

echo "$VHOST" >> /etc/httpd/conf/httpd.conf

# Install MariaDB
# ---------------
sudo yum -y install mariadb-server mariadb
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service

mysql -u root -e "CREATE DATABASE IF NOT EXISTS wp"
mysql -u root -e "GRANT ALL PRIVILEGES ON wp.* TO 'wp'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -e "FLUSH PRIVILEGES"
sudo yum -y install unzip

# Download and extract Wordpress
# ------------------------------
if [[ ! -f "/vagrant/httpdocs/wordpress/index.php" ]]; then
  cd /var/www/html
  wget http://wordpress.org/latest.zip
  unzip latest.zip
  echo '<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.php [L]
  </IfModule>' >> /var/www/html/wordpress/.htaccess
  INFO=$(echo "<?php phpinfo() ;?>")
  echo "$INFO" >> /var/www/html/wordpress/info.php
  sudo chown apache:apache -R *
  sudo find . -type d -exec chmod 755 {} \;
  sudo find . -type f -exec chmod 644 {} \;
fi

# Restart apache
# ---------------
sudo systemctl restart httpd.service
