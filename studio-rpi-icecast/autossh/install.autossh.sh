#!/bin/bash
#-----------------------------------------------------------------------
# Installs autossh on RPI Raspbian Stretch Lite
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./install.autossh.sh
#
# Reference:
#	To uninstall completely, run as root:
#
#	apt-get --purge -y remove autossh
#
# AD 2019-0407-2138 Copyright BMIR 2019
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"


# Ensure root
echo ${DELIMITER}
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


# Install
echo ${DELIMITER}
echo "Installing autossh."
apt-get -y install autossh
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get -y install autossh."
	exit 1
fi
echo "Installed autossh successfully."


# Verify executable
echo ${DELIMITER}
echo "Verifying autossh is executable."
which autossh
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} which autossh."
	exit 1
fi
echo "Confirmed autossh is executable."


# Show installed version
echo ${DELIMITER}
echo "Showing version."
autossh -V
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not display autossh version."
	exit 1
fi


echo ${DELIMITER}
echo "Success. Exit."

