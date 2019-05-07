#!/bin/bash
#-----------------------------------------------------------------------
# Sets up uploader.service on RPI Raspbian Stretch Lite
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./setup.uploader.service.sh
#
#
# AD 2019-0506-2356 Copyright BMIR 2019
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"


export SERVICE="uploader"


echo ${DELIMITER}
echo "Ensuring root user..."
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


echo ${DELIMITER}
echo "Ensuring required prereq files..."
for FILENAME in ${SERVICE}.service ${SERVICE}.timer ${SERVICE}.sh ${SERVICE}.py ${SERVICE}.json 
do
	ls ${FILENAME}
	rc=$?
	if [ 0 != ${rc} ] ; then
		echo "ERROR ${rc} Required prereq file does not exist: ${FILENAME}"
		exit 1
	fi
done
echo "ok"


echo ${DELIMITER}
echo "Copying service scripts to bin directory..."
sleep 3
for FILENAME in ${SERVICE}.sh ${SERVICE}.py ${SERVICE}.json
do
        cp ${FILENAME} /home/pi/bin/
        rc=$?
        if [ 0 != ${rc} ] ; then
		echo "ERROR ${rc} Could not copy script to bin directory. ${FILENAME}"
        	exit 1
        fi
	chmod +x /home/pi/bin/${FILENAME}
	chown pi /home/pi/bin/${FILENAME}
	chgrp pi /home/pi/bin/${FILENAME}
done


echo ${DELIMITER}
echo "Copying service file..."
sleep 3
cp ${SERVICE}.service /etc/systemd/system/
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not copy service file to /etc/systemd/system/."
	exit 1
fi


echo ${DELIMITER}
echo "Copying timer file..."
sleep 3
cp ${SERVICE}.timer /etc/systemd/system/
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not copy timer file to /etc/systemd/system/."
        exit 1
fi


echo ${DELIMITER}
echo "Reloading daemon..."
sleep 3
systemctl daemon-reload


echo ${DELIMITER}
echo "Enabling timer..."
sleep 3
systemctl enable ${SERVICE}.timer
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not copy enable timer."
        exit 1
fi


echo ${DELIMITER}
echo "Starting timer..."
sleep 3
systemctl start ${SERVICE}.timer
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not copy start timer."
        exit 1
fi


echo ${DELIMITER}
echo "Showing timer status..."
sleep 3
systemctl list-timers --all
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not copy show timer status."
        exit 1
fi


echo ${DELIMITER}
echo "Exit. Success!"
