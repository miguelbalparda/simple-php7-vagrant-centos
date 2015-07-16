simple-php7-vagrant
======================

A VERY simple Apache2/PHP7 environment provisioner for [Vagrant](http://www.vagrantup.com/).

* Creates a running Apache2/PHP7 development environment with a few simple commands.
* Runs on Ubuntu (Trusty 14.04 64 Bit) \w PHP7, MySQL 5.5, Apache 2.2

## Getting Started

**Prerequisites**

* Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* Install [Vagrant](http://www.vagrantup.com/)
* Clone or [download](https://github.com/miguelbalparda/simple-php7-vagrant/archive/master.zip) this repository to the root of your project directory `git clone https://github.com/miguelbalparda/simple-php7-vagrant.git`
* In your project directory, run `vagrant up`

The first time you run this, Vagrant will download the bare Ubuntu box image. This can take a little while as the image is a few-hundred Mb. This is only performed once.

Vagrant will configure the base system before downloading Magento and running the installer.

## Usage

* In your browser, head to `127.0.0.1:8080`
* You should see the default Wordpress installation process
* Database name is wp, user = wp / password = password

[Full Vagrant command documentation](http://docs.vagrantup.com/v2/cli/index.html)

**Why no Puppet/Chef?**
Admittedly, Puppet and Chef are excellent solutions for predictable and documented system configurations. The emphasis for this provisioner is on unopinionated simplicity. There are some excellent Puppet / Chef Magento configurations on Github with far more bells and whistles.

**Original VM**
[Simple Magento Vagrant](https://github.com/r-baker/simple-magento-vagrant)

**Known issues**

If you see the Create configuration file screen when accesing http://127.0.0.1:8080/index.php restart apache and it should go away.

