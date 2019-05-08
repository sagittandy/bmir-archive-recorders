#!/bin/bash
#-----------------------------------------------------------------------
# This script is intended to be run on the RPI with a Micro SD card 
# after being initialized by running sdcard/setup.rpi.sh
#
# Invoke:
#	sudo su -
#	cd /boot/studio-rpi-icecast/
# 	./post.setup.rpi.sh
#
# Run as root.
#
# Run this script from folder studio-rpi-icecast/
#
# Does the following:
#
#	apt-get -y install ufw
#	./ufw/ufw.setup.sh
#
#	./usbmount/install.configure.usbmount.sh
#	mkdir /media/usb/bmir
#
#	./autossh/install.autossh.sh
#	./autossh/setup.autossh.service.sh
#
#	./icecast2/install.icecast.sh
#	./icecast2/configure.icecast2.sh
#	./icecast2/setup.icecast.service.sh
#
#	./streamripper/install.streamripper.sh
#	./streamripper/setup.streamripper.service.sh
#
#	./monitor/setup.monitor.timer.sh
#
#	./uploader/setup.uploader.timer.sh
#
#
# AD 2019-0507-2305 Created
#-----------------------------------------------------------------------
export DELIMITER="=================================================================================="


echo ${DELIMITER}
echo "Confirming user root..."
if [[ $EUID -ne 0 ]]; then
   echo "EXIT ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


echo ${DELIMITER}
echo "Checking parameter count..."
if [ $# -ne 0 ] ; then
	echo "USER ERROR: This script accepts no parameters. Enter ./post.setup.rpi.sh "
	exit 9
fi
echo "Confirmed no parameters."


echo ${DELIMITER}
echo "Ensuring most required prereq files..."
for FILENAME in ufw/ufw.setup.sh usbmount/install.configure.usbmount.sh autossh/autossh.service autossh/install.autossh.sh autossh/setup.autossh.service.sh icecast2/install.icecast2.sh icecast2/configure.icecast2.sh icecast2/setup.icecast.service.sh streamripper/install.streamripper.sh streamripper/setup.streamripper.service.sh monitor/setup.monitor.timer.sh uploader/setup.uploader.timer.sh
do
	ls ${FILENAME}
	rc=$?
	if [ 0 != ${rc} ] ; then
		echo "ERROR ${rc} Required prereq file does not exist: ${FILENAME}"
		exit 1
	fi
done


#-----------------------------------------------------------------------
echo ${DELIMITER}
echo "Installing ufw..."
sleep 3
apt-get -y install ufw
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not install ufw."
	exit 1
fi


echo ${DELIMITER}
echo "Configuring UFW..."
sleep 3
./ufw/ufw.setup.sh
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not configure UFW."
        exit 1
fi


#-----------------------------------------------------------------------
echo ${DELIMITER}
echo "Configuring USB Mount..."
sleep 3
./usbmount/install.configure.usbmount.sh
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} Could not configure USB Mount."
	exit 1
fi


echo ${DELIMITER}
echo "Creating archive folder 'bmir' on USB memory stick..."
sleep 3
mkdir /media/usb/bmir
ls /media/usb/bmir
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not create an archive folder 'bmir' on USB memory stick."
        exit 1
fi


#-----------------------------------------------------------------------
echo ${DELIMITER}
echo "Installing autossh..."
sleep 3
./autossh/install.autossh.sh
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} Could not install autossh."
	exit 1
fi


echo ${DELIMITER}
echo "Setting up autossh systemd service..."
sleep 3
cd autossh
./setup.autossh.service.sh
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not set up autossh systemd service."
        exit 1
fi
cd -


#-----------------------------------------------------------------------
echo ${DELIMITER}
echo "Installing icecast..."
sleep 3
./icecast2/install.icecast2.sh
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} Could not install icecast."
	exit 1
fi


echo ${DELIMITER}
echo "Configuring icecast..."
sleep 3
cd icecast2
./configure.icecast2.sh
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not configure icecast."
        exit 1
fi
cd -


echo ${DELIMITER}
echo "Configuring icecast systemd service..."
sleep 3
cd icecast2
./setup.icecast.service.sh
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not set up icecast systemd service."
        exit 1
fi
cd -


#-----------------------------------------------------------------------
echo ${DELIMITER}
echo "Installing streamripper..."
sleep 3
./streamripper/install.streamripper.sh
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} Could not install streamripper."
	exit 1
fi


echo ${DELIMITER}
echo "Setting up streamripper systemd service..."
sleep 3
cd streamripper
./setup.streamripper.service.sh
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not set up streamripper systemd service."
        exit 1
fi
cd -


#-----------------------------------------------------------------------
echo ${DELIMITER}
echo "Setting up monitor systemd service..."
sleep 3
cd monitor
./setup.monitor.timer.sh
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not set up monitor systemd timer."
        exit 1
fi
cd -


#-----------------------------------------------------------------------
echo ${DELIMITER}
echo "Setting up uploader systemd service..."
sleep 3
cd uploader
./setup.uploader.timer.sh
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not set up uploader systemd timer."
        exit 1
fi
cd -


echo "Exit. Success!...  Please reboot:  shutdown -r now"

