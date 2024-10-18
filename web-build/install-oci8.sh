#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the Oracle Instant Client directory
ORACLE_DIR="/opt/oracle/instantclient"

# Create Oracle directory
echo "Creating Oracle directory..."
mkdir -p $ORACLE_DIR

# Unzip the existing files
echo "Unzipping Oracle Instant Client files..."
unzip -o /var/www/html/.ddev/web-build/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -d $ORACLE_DIR
unzip -o /var/www/html/.ddev/web-build/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d $ORACLE_DIR

# Create symbolic links
echo "Creating symbolic links..."
ln -sf $ORACLE_DIR/libclntsh.so.12.1 $ORACLE_DIR/libclntsh.so
ln -sf $ORACLE_DIR/libocci.so.12.1 $ORACLE_DIR/libocci.so

# Configure dynamic linker run-time bindings
echo "Configuring dynamic linker run-time bindings..."
echo $ORACLE_DIR > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig

# Install OCI8 for PHP
echo "Installing OCI8 extension for PHP..."

export OCI_HOME=$ORACLE_DIR
export LD_LIBRARY_PATH=$ORACLE_DIR:$LD_LIBRARY_PATH

pecl channel-update pecl.php.net
echo "instantclient,$ORACLE_DIR" | pecl install oci8

echo "extension=oci8.so" > /usr/local/etc/php/conf.d/docker-php-ext-oci8.ini

echo "Oracle Instant Client and OCI8 installation completed."