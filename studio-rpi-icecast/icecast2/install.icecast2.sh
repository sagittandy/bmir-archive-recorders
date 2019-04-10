#!/bin/bash
#-----------------------------------------------------------------------
# Installs icecast2 on RPI Raspbian Stretch Lite
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./install.icecast2.sh
#
# Reference:
#	To uninstall completely, run as root:
#
#	apt-get --purge -y remove icecast2
#
# AD 2019-0407-1308 Copyright BMIR 2019
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"


# Ensure root
echo ${DELIMITER}
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


# Quiet
echo ${DELIMITER}
echo "Suppressing interactive configuration during installation."
export DEBIAN_FRONTEND=noninteractive


# Install
echo ${DELIMITER}
echo "Installing icecast2 streaming client."
apt-get -y install icecast2
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get -y install icecast2 streaming client."
	exit 1
fi
echo "Installed icecast2 successfully."


# Verify executable
echo ${DELIMITER}
echo "Verifying icecast2 is executable."
which icecast2
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} which icecast2."
	exit 1
fi
echo "Confirmed icecast2 is executable."


# Show installed version
echo ${DELIMITER}
echo "Showing version."
icecast2 --version
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not display icecast2 version."
	exit 1
fi


echo ${DELIMITER}
echo "Success. Exit."

