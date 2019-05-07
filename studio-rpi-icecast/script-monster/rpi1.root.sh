#!/bin/bash
#-----------------------------------------------------------------------
# This script is intended to be run on the RPI with 
# freshly-flashed Micro SD card.
#
# Invoke:
#	sudo su -
#	cd /boot/studio-rpi-icecast/script-monster 
# 	./rpi1.root.sh <PASSWORD> <HOSTNAME>
#	where
#		<PASSWORD> is used for both pi and root
#		<HOSTNAME> is the new hostname of the RPI
#
# Run as root.
#
# Run this script from folder script-monster.
#
# AD 2019-0506-2100 Created
#-----------------------------------------------------------------------
export DELIMITER="----------------------------------------------------------------------------------"


echo ${DELIMITER}
echo "Confirming user root..."
if [[ $EUID -ne 0 ]]; then
   echo "EXIT ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


echo ${DELIMITER}
echo "Checking parameter count..."
if [ $# -ne 2 ] ; then
	echo "USER ERROR: Wrong number of parameters. Enter ./rpi1.root.sh <PASSWORD> <HOSTNAME> "
	exit 9
fi
echo "Confirmed parameter count."


echo ${DELIMITER}
echo "Getting password."
PASSWORD=${1}
echo "PASSWORD=${PASSWORD}"
 

echo ${DELIMITER}
echo "Getting hostname."
HOSTNAME=${2}
echo "HOSTNAME=${HOSTNAME}"


echo ${DELIMITER}
echo "Ensuring required prereq files..."
for FILENAME in authorized_keys id_rsa.pub.rpi id_rsa.rpi
do
	ls ${FILENAME}
	rc=$?
	if [ 0 != ${rc} ] ; then
		echo "ERROR ${rc} Required prereq file does not exist: ${FILENAME}"
		exit 1
	fi
done


echo ${DELIMITER}
echo "Changing root password..."
echo -e "${PASSWORD}\n${PASSWORD}" | passwd
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not change root password."
	exit 1
fi


echo ${DELIMITER}
echo "Changing user pi password..."
echo -e "${PASSWORD}\n${PASSWORD}" | passwd pi 
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not change user pi password."
        exit 1
fi


echo ${DELIMITER}
echo "Changing hostname in /etc/hosts..."
sed -ie "s:raspberrypi:${HOSTNAME}:g" /etc/hosts
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} Could not set hostname in /etc/hosts."
	exit 1
fi
cat /etc/hosts


echo ${DELIMITER}
echo "Changing hostname in /etc/hostname..."
sed -ie "s:raspberrypi:${HOSTNAME}:g" /etc/hostname 
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not set hostname in /etc/hostname."
        exit 1
fi
cat /etc/hostname


echo ${DELIMITER}
echo "Adding dobmir to /etc/hosts..."
echo "165.227.56.205  dobmir" >> /etc/hosts
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} Could not append dobmir to /etc/hosts."
        exit 1
fi
cat /etc/hosts


echo ${DELIMITER}
echo "Creating SSH keys for user pi..."
su -c "ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa" pi
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not create SSH keys for user pi."
        exit 1
fi
echo "ok"



echo ${DELIMITER}
echo "Copying authorized_keys file to /home/pi/.ssh/..."
cp authorized_keys /home/pi/.ssh/
chown pi /home/pi/.ssh/authorized_keys
chgrp pi /home/pi/.ssh/authorized_keys
chmod 644 /home/pi/.ssh/authorized_keys
echo "Assume ok"


echo ${DELIMITER}
echo "Copying ID_RSA files to /home/pi/.ssh/..."
# -rw------- 1 pi pi 1679 May  6 20:09 id_rsa
# -rw-r--r-- 1 pi pi  396 May  6 20:09 id_rsa.pub

cp id_rsa.pub.rpi /home/pi/.ssh/id_rsa.pub
chown pi /home/pi/.ssh/id_rsa.pub
chgrp pi /home/pi/.ssh/id_rsa.pub
chmod 644 /home/pi/.ssh/id_rsa.pub

cp id_rsa.rpi /home/pi/.ssh/id_rsa
chown pi /home/pi/.ssh/id_rsa
chgrp pi /home/pi/.ssh/id_rsa
chmod 600 /home/pi/.ssh/id_rsa

echo "Assume ok"
ls -al /home/pi/.ssh/


echo ${DELIMITER}
echo "Copying tools files from github to /home/pi/..."
cp -rp /boot/studio-rpi-icecast /home/pi/
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not copy tools files from github to /home/pi/."
        exit 1
fi
chown -R pi /home/pi/studio-rpi-icecast
chgrp -R pi /home/pi/studio-rpi-icecast
ls -l /home/pi/
echo "ok"


echo ${DELIMITER}
echo "Setting timezone to US PACIFIC..."  
timedatectl set-timezone America/Los_Angeles
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not set timezone."
        exit 1
fi


echo ${DELIMITER}
echo "Creating directory /home/pi/bin..."
su -c "mkdir -p /home/pi/bin" pi
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not create /home/pi/bin."
        exit 1
fi


echo ${DELIMITER}
echo "Updating raspbian operating system, then will need to reboot..."
sleep 3
apt-get update
apt-get -y dist-upgrade
apt-get -y autoremove
apt-get -y install zip



echo "Exit. Success!...  Please reboot:  shutdown -r now"

