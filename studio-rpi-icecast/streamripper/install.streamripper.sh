#!/bin/bash
#-----------------------------------------------------------------------
# Installs streamripper on RPI Raspbian Stretch Lite
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./install.streamripper.sh
#
# Reference:
#	To uninstall completely, run as root:
#
#	apt-get --purge -y remove streamripper
#
# AD 2019-0407-1234 Copyright BMIR 2019
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
echo "Installing streamripper streaming music downloader."
apt-get -y install streamripper
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get -y install streamripper streaming music downloader."
	exit 1
fi
echo "Installed streamripper successfully."


# Verify executable
echo ${DELIMITER}
echo "Verifying streamripper is executable."
which streamripper
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} which streamripper."
	exit 1
fi
echo "Confirmed streamripper is executable."


# Show installed version
echo ${DELIMITER}
echo "Showing version."
streamripper --version
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not display streamripper version."
	exit 1
fi


echo ${DELIMITER}
echo "Success. Exit."

