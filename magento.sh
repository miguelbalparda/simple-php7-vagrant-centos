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
apt-get install libjpeg62
apt-get install zip

cp /usr/local/php7/libphp7.so /usr/lib/apache2/modules/
cp /usr/local/php7/php7.load /etc/apache2/mods-available/

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf /var/www/html
mkdir /vagrant/httpdocs
ln -fs /vagrant/httpdocs /var/www/html

# Set handlerxx
# --------------------
HANDLER=$(echo "<FilesMatch \.php$>
SetHandler application/x-httpd-php
</FilesMatch>")
echo "$HANDLER" >> /etc/apache2/apache2.conf
INFO=$(echo "<?php phpinfo() ;?>")
echo "$INFO" >> /var/www/html/info.php
# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
NameVirtualHost *:8080
Listen 8080
<VirtualHost *:80>
  DocumentRoot "/var/www/html"
  ServerName localhost
  <Directory "/var/www/html">
    AllowOverride All
  </Directory>
</VirtualHost>
<VirtualHost *:8080>
  DocumentRoot "/var/www/html"
  ServerName localhost
  <Directory "/var/www/html">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

a2dismod mpm_event
a2enmod mpm_prefork
a2enmod php7

# Mysql
# --------------------
# Ignore the post install questions
export DEBIAN_FRONTEND=noninteractive
# Install MySQL quietly
apt-get -q -y install mysql-server-5.5

mysql -u root -e "CREATE DATABASE IF NOT EXISTS magentodb"
mysql -u root -e "GRANT ALL PRIVILEGES ON magentodb.* TO 'magentouser'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -e "FLUSH PRIVILEGES"


# Magento
# --------------------
# http://www.magentocommerce.com/wiki/1_-_installation_and_configuration/installing_magento_via_shell_ssh

# Download and extract
if [[ ! -f "/vagrant/httpdocs/index.php" ]]; then
  cd /vagrant/httpdocs
  wget http://www.magentocommerce.com/downloads/assets/${MAGE_VERSION}/magento-${MAGE_VERSION}.tar.gz
  tar -zxvf magento-${MAGE_VERSION}.tar.gz
  mv magento/* magento/.htaccess .
  chmod -R o+w media var
  chmod o+w app/etc
  sudo chown www-data:www-data -R *
  sudo find . -type d -exec chmod 755 {} \;
  sudo find . -type f -exec chmod 644 {} \;
  # Clean up downloaded file and extracted dir
  rm -rf magento*
fi


# Run installer
if [ ! -f "/vagrant/httpdocs/app/etc/local.xml" ]; then
  cd /vagrant/httpdocs
  sudo /usr/local/php7/bin/php -f install.php -- --license_agreement_accepted yes \
  --locale en_US --timezone "America/Los_Angeles" --default_currency USD \
  --db_host localhost --db_name magentodb --db_user magentouser --db_pass password \
  --url "http://127.0.0.1:8080/" --use_rewrites no --session_save db \
  --use_secure no --secure_base_url "http://127.0.0.1:8080/" --use_secure_admin no \
  --skip_url_validation yes \
  --admin_lastname Owner --admin_firstname Store --admin_email "admin@example.com" \
  --admin_username admin --admin_password password123123
  /usr/local/php7/bin/php -f shell/indexer.php reindexall
  fi

# Install n98-magerun
# --------------------
cd /vagrant/httpdocs
wget https://raw.github.com/netz98/n98-magerun/master/n98-magerun.phar
chmod +x ./n98-magerun.phar
sudo mv ./n98-magerun.phar /usr/local/bin/
sudo service apache2 restart
