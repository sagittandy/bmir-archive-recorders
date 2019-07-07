#!/bin/bash
#-----------------------------------------------------------------------
# Sets up ifstat.service on RPI Raspbian Stretch Lite
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./setup.ifstat.service.sh
#
#
# AD 2019-0705 Copyright BMIR 2019
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"


export SERVICE="ifstat"


echo ${DELIMITER}
echo "Ensuring root user..."
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


echo ${DELIMITER}
echo "Ensuring required prereq files..."
for FILENAME in ${SERVICE}.service ifstat.sh 
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
echo "Copying ifstat.sh to bin directory..."
sleep 3
cp ifstat.sh /home/pi/bin/
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not copy ifstat.sh to /home/pi/bin/."
        exit 1
fi
# For good measure, set permissions to executable.
chmod +x /home/pi/bin/ifstat.sh
chown pi /home/pi/bin/ifstat.sh
chgrp pi /home/pi/bin/ifstat.sh


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
echo "Reloading daemon..."
sleep 3
systemctl daemon-reload


echo ${DELIMITER}
echo "Enabling service..."
sleep 3
systemctl enable ${SERVICE}.service
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not enable service."
        exit 1
fi


echo ${DELIMITER}
echo "Starting service..."
sleep 3
systemctl start ${SERVICE}.service
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not start service."
        exit 1
fi


echo ${DELIMITER}
echo "Showing service status..."
sleep 3
systemctl --no-pager status ${SERVICE}.service
rc=$?
if [ 0 != ${rc} ] ; then
        echo "WARNING ${rc} Could not show service status. May be caused by icecast2 not running or MP3 programming not being streamed."
        exit 1
fi


echo ${DELIMITER}
echo "Exit. Success!"
