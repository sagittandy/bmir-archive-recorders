#!/bin/bash
#-----------------------------------------------------------------------
# Sets up liquidsoap.service on Ubuntu
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./setup.liquidsoap.service.sh
#
#
# AD 2019-0513-2147 Copyright BMIR 2019
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"


export SERVICE="liquidsoap"


echo ${DELIMITER}
echo "Ensuring root user..."
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


echo ${DELIMITER}
echo "Ensuring required prereq files..."
for FILENAME in ${SERVICE}.service
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
        echo "ERROR ${rc} could not copy enable service."
        exit 1
fi


echo ${DELIMITER}
echo "Starting service..."
sleep 3
systemctl start ${SERVICE}.service
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not copy start service."
        exit 1
fi


echo ${DELIMITER}
echo "Showing service status..."
sleep 3
systemctl --no-pager status ${SERVICE}.service
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} could not copy show service status."
        exit 1
fi


echo ${DELIMITER}
echo "Exit. Success!"
