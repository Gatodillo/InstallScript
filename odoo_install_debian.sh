#!/bin/bash
# Basic Odoo install script. This script does not install Odoo enterprise!
# Based in the work of https://github.com/Yenthe666/InstallScript/blob/14.0/odoo_install_debian.sh
# and https://www.odoo.com/documentation/14.0/setup/install.html#id7 
#
# This scripts needs to be executed inside a virtual environment created with virtualenvwrapper.
# Instruccions for install virtualenv and virtualenvwrapper on Debian 10 can be found at:
# https://itnext.io/virtualenv-with-virtualenvwrapper-on-ubuntu-18-04-goran-aviani-d7b712d906d5
# Odoo needs Python3 >= 3.6. Instructions to install Python 3.7 can be found at:
# https://linuxize.com/post/how-to-install-python-3-7-on-debian-9/
# As example: mkvirtualenv --python /usr/local/bin/python37 odoo
# Then chmod +x ./odoo_install_debian.sh && ./odoo_install_debian.sh
#
# To install wkhtml2pdf check:
# https://computingforgeeks.com/install-wkhtmltopdf-on-ubuntu-debian-linux/
################################################################################

OE_USER="$(whoami)"
OE_HOME="/home/$OE_USER"
OE_VIRTUALENV_NAME="odoo"
OE_CONFIG="/etc/${OE_USER}-${OE_VIRTUALENV_NAME}-server.conf"
OE_VERSION="14.0"

echo "OE_USER: $OE_USER"
echo "OE_HOME: $OE_HOME"
echo "OE_CONGIF: $OE_CONFIG"
echo "OE_VERSION: $OE_VERSION"
echo "OE_VIRTUALENV_NAME: $OE_VIRTUALENV_NAME"

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
echo "sudo su - postgres -c \"createuser -s $OE_USER\" 2> /dev/null || true"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true
sudo su $OE_USER -c "createdb $OE_USER"

echo -e "\n---- Create ODOO system user ----"
echo "sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO admin' --group $OE_USER

echo -e "\n---- Create Log directory ----"
echo "sudo mkdir /var/log/$OE_USER"
sudo mkdir /var/log/$OE_USER
echo "sudo chown $OE_USER:$OE_USER /var/log/$OE_USER"
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

echo -e "\n---- Create custom module directory ----"
echo -e "sudo su $OE_USER -c 'mkdir $OE_HOME/$OE_VIRTUALENV_NAME/custom'"
sudo su $OE_USER -c "mkdir $OE_HOME/$OE_VIRTUALENV_NAME"

echo -e "sudo su $OE_USER -c 'mkdir $OE_HOME/$OE_VIRTUALENV_NAME/custom'"
sudo su $OE_USER -c "mkdir $OE_HOME/$OE_VIRTUALENV_NAME/custom"

echo -e "sudo su $OE_USER -c 'mkdir $OE_HOME/$OE_VIRTUALENV_NAME/custom/addons'"
sudo su $OE_USER -c "mkdir $OE_HOME/$OE_VIRTUALENV_NAME/custom/addons"

echo -e "\n---- Install python packages/requirements ----"
echo -e "pip install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt"
pip install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt

echo -e "\n==== Installing ODOO Server ===="
echo -e "sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME/$OE_VIRTUALENV_NAME/${OE_VIRTUALENV_NAME}-server"
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME/$OE_VIRTUALENV_NAME/${OE_VIRTUALENV_NAME}-server

#minimal option --database and --limit-time-real 100000
#https://www.odoo.com/documentation/14.0/reference/cmdline.html#reference-cmdline-config
/home/debian/odoo/odoo-server/odoo-bin --limit-time-real 100000 --database odoo


# After first start:
# Warning, your Odoo database manager is not protected.
# Please set a master password to secure it.
# Passsword: odoo-admin 
# Create database (we don´t use the database created previously?)
# eq4 / odoo-demo
# Start odoo-bin with the new database -d-database demo (or your database name)