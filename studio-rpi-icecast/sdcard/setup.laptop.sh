#!/bin/bash
#-----------------------------------------------------------------------
# Post-flash preparation for a raspbian Micro SD card.
#
# Prereqs:
#	Requires files *not* stored in github for security reasons:
#	- authorized_keys
#	- id_rsa.pub.rpi
#	- id_rsa.rpi
#	- wpa_supplicant.conf
#
# Run this script on the laptop which flashed the SD card.
#
# Run this script as user (not root).
#
# Run this script from folder sdcard.
#
# AD 2019-0506-2007 Created
#-----------------------------------------------------------------------
export DELIMITER="----------------------------------------------------------------------------------"


echo ${DELIMITER}
echo "Ensure non-root..."
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: This script must be run as non-root." 
   exit 1
fi
echo "Confirmed non-root."


echo ${DELIMITER}
echo "Ensuring required prereq files..."
for FILENAME in authorized_keys id_rsa.pub.rpi id_rsa.rpi wpa_supplicant.conf
do
	ls ${FILENAME}
	rc=$?
	if [ 0 != ${rc} ] ; then
		echo "ERROR ${rc} Required prereq file does not exist: ${FILENAME}"
		exit 1
	fi
done


sleep 3
echo ${DELIMITER}
echo "Get the username..."
USER_NAME=$(whoami)
echo "USER_NAME=${USER_NAME}"


sleep 3
echo ${DELIMITER}
echo "Create ssh file on micro SD card..."
touch /media/${USER_NAME}/boot/ssh
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not create ssh file on micro SD card."
	exit 1
fi


sleep 3
echo ${DELIMITER}
echo "Copy wpa_supplicant file to micro SD card for Wi-Fi..."
cp wpa_supplicant.conf /media/${USER_NAME}/boot/
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not copy wpa_supplicant file to micro SD card."
	exit 1
fi


sleep 3
echo ${DELIMITER}
echo "Copy the tools folder from github into micro SD card."
cp -rp ../../studio-rpi-icecast /media/${USER_NAME}/boot/
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not copy tools folder from github to micro SD card."
	exit 1
fi



echo "Exit. Success!"
