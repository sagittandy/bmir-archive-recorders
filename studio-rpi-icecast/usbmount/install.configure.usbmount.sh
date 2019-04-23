#!/bin/bash
#-----------------------------------------------------------------------
# Installs and sets up usbmount on RPI Raspbian Stretch Lite
#
# Credits:
#	https://www.raspberrypi.org/forums/viewtopic.php?t=205016
#		and this article:  Sat Feb 10, 2018 6:45 am
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./install.configure.usbmount.sh
#
#	Then reboot!!!
#
# Results: USB mounts under
#	/media/usb which symlinks to one of the following:
#	/media/usb0
#	/media/usb1
#	/media/usb2
#	/media/usb3
#	/media/usb4
#	/media/usb5
#	/media/usb6
#	/media/usb7
#
# Reference:
#	To uninstall completely, run as root:
#
#	apt-get --purge -y remove usbmount
#
# AD 2019-0422-2125 Copyright BMIR 2019
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"

# Define the two files to be edited below.
export USBMOUNT_CONFIG_FILE="/etc/usbmount/usbmount.conf"
export UDEVD_SERVICE_FILE="/lib/systemd/system/systemd-udevd.service"

# Ensure root
echo ${DELIMITER}
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


# Install
echo ${DELIMITER}
echo "Installing usbmount."
apt-get -y install usbmount
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get -y install usbmount."
	exit 1
fi
echo "Installed usbmount successfully."


# Show installed version
echo ${DELIMITER}
echo "Showing version."
OUTPUT_STRING="$(dpkg --list | grep usbmount)"
echo "${OUTPUT_STRING}"


echo ${DELIMITER}
echo "Verify usbmount config file exists. ${USBMOUNT_CONFIG_FILE}"
ls ${USBMOUNT_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} File ${USBMOUNT_CONFIG_FILE} does not exist."
	exit 1
fi


echo ${DELIMITER}
echo "Verify udevd service file exists. ${UDEVD_SERVICE_FILE}"
ls ${UDEVD_SERVICE_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} File ${UDEVD_SERVICE_FILE} does not exist."
	exit 1
fi


echo ${DELIMITER}
echo "Customize usbmount config file by setting mount options."
sed -ie "s:FS_MOUNTOPTIONS=\"\":FS_MOUNTOPTIONS=\"-fstype=vfat,gid=pi,uid=pi,umask=002,sync\":g" ${USBMOUNT_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing mount options in usbmount config file."
	exit 1
fi


# Show mount options
grep MOUNTOPTIONS ${USBMOUNT_CONFIG_FILE}


echo ${DELIMITER}
echo "Customize udevd service file by setting mount flags."
sed -ie "s:MountFlags=slave:MountFlags=shared:g" ${UDEVD_SERVICE_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing mount flags in udevd service file."
	exit 1
fi


#Show mount flags
grep MountFlags ${UDEVD_SERVICE_FILE}


echo ${DELIMITER}
echo "Success. Exit...  Please reboot to dynamically plug and play USB devices."

