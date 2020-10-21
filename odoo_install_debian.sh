#!/bin/bash
################################################################################
# Script for installing Odoo on Debian 10.0 (could be used for other version too)
# Authors: Yenthe Van Ginneken, César Cordero Rodríguez
# Maintainers: Yenthe Van Ginneken, César Cordero Rodríguez
#-------------------------------------------------------------------------------
# This script will install Odoo on your Debian 10.0 server. It can install multiple Odoo instances
# in one Debian because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################

OE_USER="odoo"
OE_HOME="/home/$OE_USER"
OE_HOME_EXT="/$OE_HOME/${OE_USER}-server"

# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)

# Set to true if you want to install it, false if you don't need it or have it already installed.
# If you want to install wkhtml please follow the instructions from this link:
# Install wkhtmltopdf on Ubuntu 20.04/18.04 / Debian 10
# https://computingforgeeks.com/install-wkhtmltopdf-on-ubuntu-debian-linux/
INSTALL_WKHTMLTOPDF="False"

# If you want to install Node.js and npm on please follow the instructions from this link:
# How to Install Node.js and npm on Debian 10 Linux
# https://linuxize.com/post/how-to-install-node-js-on-debian-10/
INSTALL_NODEJS="False"

# If you want to install virtualenv and virtualenvwrapper please follow this link:
# Virtualenv with Virtualenvwrapper on Ubuntu 18.04
# https://itnext.io/virtualenv-with-virtualenvwrapper-on-ubuntu-18-04-goran-aviani-d7b712d906d5
INSTALL_VIRTUALENVWRAPPER="False"

# Be sure of versión of python3 >= 3.7
# If you have a python versión < 3.7, then follow this link:
# How to Install Python 3.7 on Debian 9
# https://linuxize.com/post/how-to-install-python-3-7-on-debian-9/
PYTHON3=$(which python3)

VIRTUAL_ENVIRONMENT_NAME="odoo"

# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"

# Choose the Odoo version which you want to install. For example: 13.0, 12.0, 11.0 or saas-18. When using 'master' the master version will be installed.
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 13.0
OE_VERSION="14.0"

# Set this to True if you want to install the Odoo enterprise version!
IS_ENTERPRISE="False"

# Set this to True if you want to install Nginx!
INSTALL_NGINX="False"

# Set the superadmin password - if GENERATE_RANDOM_PASSWORD is set to "True" we will automatically generate a random password, otherwise we use this one
OE_SUPERADMIN="admin"

# Set to "True" to generate a random password, "False" to use the variable in OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="True"

OE_CONFIG="/etc/${OE_USER}-server.conf"

# Set the website name
WEBSITE_NAME="_"

# Set the default Odoo longpolling port (you still have to use -c /etc/odoo-server.conf for example to use this.)
LONGPOLLING_PORT="8072"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3! --"
sudo apt-get install git build-essential wget  libxslt1-dev -y
sudo apt-get install libzip-dev libldap2-dev libsasl2-dev  node-less gdebi -y


echo -e "\n---- Installing rtlcss for LTR support ----"
sudo npm install -g rtlcss

echo -e "\n---- Create ODOO system user ----"
# About the gecos option:
# What do the `--disabled-login` and `--gecos` options of `adduser` command stand for?
# https://askubuntu.com/questions/420784/what-do-the-disabled-login-and-gecos-options-of-adduser-command-stand
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO admin' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

sudo cd $OE_HOME
sudo su $OE_USER -c "mkvirtualenv --python $PYTHON3 $VIRTUAL_ENVIRONMENT_NAME"

echo -e "\n---- Install python packages/requirements ----"
# Is not adviced to use sudo with pip to alter system packages. See:
# What are the risks of running 'sudo pip'?
# https://stackoverflow.com/questions/21055859/what-are-the-risks-of-running-sudo-pip
pip install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt
#pip install python3 python3-pip python3-dev python3-venv python3-wheel python3-setuptools


echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"
sudo touch ${OE_CONFIG}

echo -e "* Creating server config file"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> ${OE_CONFIG}"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "* Generating random admin password"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> ${OE_CONFIG}"
if [ $OE_VERSION >= "12.0" ]; then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> ${OE_CONFIG}"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> ${OE_CONFIG}"

sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons\n' >> ${OE_CONFIG}"

sudo chown $OE_USER:$OE_USER ${OE_CONFIG}
sudo chmod 640 ${OE_CONFIG}

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/bash' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=${OE_CONFIG}' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

