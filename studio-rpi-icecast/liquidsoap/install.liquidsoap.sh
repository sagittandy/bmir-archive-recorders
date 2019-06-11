#!/bin/bash
#-----------------------------------------------------------------------
# Installs liquidsoap on RPI Raspbian Stretch Lite
#
#	NOTE: LIQUIDSOAP DID NOT WORK ON APRIL 2019 VERSION OF STRETCH
#	HAD TO BUILD USING OPAM.  SEARCH LINUXJOUNAL!!!
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./install.liquidsoap.sh
#
# Reference:
#	To uninstall completely, run as root:
#
#	apt-get --purge -y remove liquidsoap
#
# AD 2019-0407-1210 Copyright BMIR 2019
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
echo "Installing liquidsoap streaming client."
apt-get -y install liquidsoap
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get -y install liquidsoap streaming client."
	exit 1
fi
echo "Installed liquidsoap successfully."


# Verify executable
echo ${DELIMITER}
echo "Verifying liquidsoap is executable."
which liquidsoap
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} which liquidsoap."
	exit 1
fi
echo "Confirmed liquidsoap is executable."


# Show installed version
echo ${DELIMITER}
echo "Showing version."
liquidsoap --version
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not display liquidsoap version."
	exit 1
fi


echo ${DELIMITER}
echo "Success. Exit."

