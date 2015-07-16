#!/usr/bin/env bash

SAMPLE_DATA=$1
MAGE_VERSION="1.9.1.0"
DATA_VERSION="1.9.0.0"

# Update Apt
# --------------------
apt-get update

# Install Apache & PHP
# http://php7.zend.com/install-ubuntu.php
# --------------------
apt-get install -y apache2

wget http://repos.zend.com/zend-server/early-access/php7/php-7.0-beta1-DEB-x86_64.tar.gz
tar xzPf php-7.0-beta1-DEB-x86_64.tar.gz
apt-get update && apt-get install -y \
libcurl4-openssl-dev \
libmcrypt-dev \
libxml2-dev \
libjpeg-dev \
libfreetype6-dev \
libmysqlclient-dev \
libt1-dev \
libgmp-dev \
libpspell-dev \
libicu-dev \
librecode-dev \
libxpm4
apt-get install -y libjpeg62
apt-get install -y zip

cp /usr/local/php7/libphp7.so /usr/lib/apache2/modules/
cp /usr/local/php7/php7.load /etc/apache2/mods-available/

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf /var/www/html
mkdir /vagrant/httpdocs
ln -fs /vagrant/httpdocs /var/www/html
sudo chown www-data:www-data -R /var/www/html

# Set handlerxx
# --------------------
HANDLER=$(echo "<FilesMatch \.php$>
SetHandler application/x-httpd-php
</FilesMatch>")
echo "$HANDLER" >> /etc/apache2/apache2.conf
# Replace contents of default Apache vhost
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

echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

a2dismod mpm_event
a2enmod mpm_prefork
a2enmod rewrite
a2enmod php7

# Mysql
# --------------------
# Ignore the post install questions
export DEBIAN_FRONTEND=noninteractive
# Install MySQL quietly
apt-get -q -y install mysql-server-5.5

mysql -u root -e "CREATE DATABASE IF NOT EXISTS wp"
mysql -u root -e "GRANT ALL PRIVILEGES ON wp.* TO 'wp'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -e "FLUSH PRIVILEGES"


# Magento
# --------------------
# http://www.magentocommerce.com/wiki/1_-_installation_and_configuration/installing_magento_via_shell_ssh

# Download and extract
if [[ ! -f "/vagrant/httpdocs/index.php" ]]; then
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
  sudo chown www-data:www-data -R *
  sudo find . -type d -exec chmod 755 {} \;
  sudo find . -type f -exec chmod 644 {} \;

fi
sudo service apache2 restart