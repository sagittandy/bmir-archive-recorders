#!/bin/bash
#-----------------------------------------------------------------------
# Installs ifstat on RPI Raspbian Stretch Lite
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./install.ifstat.sh
#
# Reference:
#	To uninstall completely, run as root:
#
#	apt-get --purge -y remove ifstat
#
# AD 2019-0705 Copyright BMIR 2019
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
echo "Installing ifstat."
apt-get -y install ifstat
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get -y install ifstat."
	exit 1
fi
echo "Installed ifstat successfully."


# Verify executable
echo ${DELIMITER}
echo "Verifying ifstat is executable."
which ifstat
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} which ifstat."
	exit 1
fi
echo "Confirmed ifstat is executable."


# Show installed version
echo ${DELIMITER}
echo "Showing version."
ifstat -v
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not display ifstat version."
	exit 1
fi


echo ${DELIMITER}
echo "Success. Exit."

