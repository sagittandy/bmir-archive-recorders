#!/bin/bash
#-----------------------------------------------------------------------
# Sets up Ubuntu Firewall for use on RPi archiver.
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./ufw.setup.sh
#
# AD 2019-0408 Updated slightly for RPi
# AD 2018-0409 Copyright BMIR 2018,2019
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"

echo ${DELIMITER}
echo "Ensuring root user..."
sleep 3
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


echo ${DELIMITER}
echo "Denying incoming..."
sleep 3
ufw default deny incoming
rc=$?
if [ 0 != ${rc} ] ; then
	echo "UFW ERROR ${rc} could not deny incoming."
	exit 1
fi


echo ${DELIMITER}
echo "Allowing outgoing..."
sleep 3
ufw default allow outgoing
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not allow outgoing."
	exit 1
fi


echo ${DELIMITER}
echo "Allowing ssh..."
sleep 3
ufw allow ssh
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not allow SSH port 22."
	exit 1
fi


echo ${DELIMITER}
echo "Allowing 8000/tcp..."
sleep 3
ufw allow 8000/tcp
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not allow Icecast2 port 8000."
	exit 1
fi


echo ${DELIMITER}
echo "Enabling UFW..."
sleep 3
ufw --force enable
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not enable UFW."
	exit 1
fi


echo ${DELIMITER}
echo "Checking status..."
sleep 3
ufw status
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not get status."
	exit 1
fi



echo ${DELIMITER}
echo "Exit.  Success!"
