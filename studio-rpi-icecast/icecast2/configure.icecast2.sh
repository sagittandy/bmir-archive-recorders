#!/bin/bash
#-----------------------------------------------------------------------
# Configures icecast2 on RPI Raspbian Stretch Lite
#
# Prereq:
#	Install iccast2
#
# Usage: 
#	Run this script as root: 
#
#	sudo ./configure.icecast2.sh
#
# AD 2019-0407-1317 Copyright BMIR 2019
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"

# Define custom values for Icecast config file.
export ICECAST_CONFIG_FILE="/etc/icecast2/icecast.xml"
export ICECAST_LOG_FILE_DIRECTORY="/var/log/icecast2"
export ICECAST_PORT="8000"
export ICECAST_HOSTNAME="localhost"
export ICECAST_RELAY_PASSWORD="relaypw"
export ICECAST_SOURCE_PASSWORD="sourcepw"
export ICECAST_ADMIN_PASSWORD="adminpw"

export ICECAST_RUNNER_USERNAME="pi"
export MP3_DIR="/home/${ICECAST_RUNNER_USERNAME}/bmir"


# Ensure root
echo ${DELIMITER}
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


echo ${DELIMITER}
ls ${MP3_DIR}
rc=$?
if [ 0 != ${rc} ] ; then
        #echo "ERROR ${rc} MP3 file directory does not exist: ${MP3_DIR}"
        #exit 1
	mkdir ${MP3_DIR}
	chown ${ICECAST_RUNNER_USERNAME} ${MP3_DIR}
	chgrp ${ICECAST_RUNNER_USERNAME} ${MP3_DIR}
	echo "Created MP3 file directory ${MP3_DIR}"
else
	echo "MP3 file directory exists: ${MP3_DIR}"
fi


# Verify executable
echo ${DELIMITER}
echo "Verifying icecast2 is executable."
which icecast2
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} which icecast2."
	exit 1
fi
echo "Confirmed icecast2 is executable."


# Show installed version
echo ${DELIMITER}
echo "Showing version."
icecast2 --version
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not display icecast2 version."
	exit 1
fi


echo ${DELIMITER}
echo "Verify icecast2 config file exists. ${ICECAST_CONFIG_FILE}"
ls ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} File ${ICECAST_CONFIG_FILE} does not exist."
	exit 1
fi


echo ${DELIMITER}
echo "Showing original icecast2 config file. ${ICECAST_CONFIG_FILE}"
cat ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} Could not display ${ICECAST_CONFIG_FILE} does not exist."
	exit 1
fi


#Make a backup
echo "Making backup of icecast config file."
cp -p ${ICECAST_CONFIG_FILE} /tmp/icecast.config.file.orig.xml


# Todo someday: Create a function to do this, and add better checking.
echo ${DELIMITER}
echo "Customize hostname in icecast config file."
sed -i "s:<hostname>localhost</hostname>:<hostname>${ICECAST_HOSTNAME}</hostname>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing hostname in icecast config file."
	exit 1
fi


echo ${DELIMITER}
echo "Customize source password in icecast config file."
sed -i "s:<source-password>hackme</source-password>:<source-password>${ICECAST_SOURCE_PASSWORD}</source-password>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing source password in icecast config file."
	exit 1
fi


echo ${DELIMITER}
echo "Customize relay password in icecast config file."
sed -i "s:<relay-password>hackme</relay-password>:<relay-password>${ICECAST_RELAY_PASSWORD}</relay-password>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing relay password in icecast config file."
	exit 1
fi


echo ${DELIMITER}
echo "Customize admin password in icecast config file."
sed -i "s:<admin-password>hackme</admin-password>:<admin-password>${ICECAST_ADMIN_PASSWORD}</admin-password>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing admin password in icecast config file."
	exit 1
fi


echo ${DELIMITER}
echo "Uncomment changeowner in icecast config file, step 1 of 2."
sed -i "s:<changeowner>: --> <changeowner>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} uncommenting changeowner in icecast config file, step 1 of 2."
	exit 1
fi


echo ${DELIMITER}
echo "Uncomment changeowner in icecast config file, step 2 of 2."
sed -i "s:</changeowner>:</changeowner> <!-- :g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
    echo "ERROR ${rc} uncommenting changeowner in icecast config file, step 2 of 2."
	exit 1
fi


echo ${DELIMITER}
echo "Verify icecast2 log file directory exists ${ICECAST_LOG_FILE_DIRECTORY}"
ls ${ICECAST_LOG_FILE_DIRECTORY}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} Log file directory {ICECAST_LOG_FILE_DIRECTORY} does not exist."
	exit 1
fi


echo ${DELIMITER}
echo "Make the icecast config file permissions 666"
chmod 666 ${ICECAST_CONFIG_FILE}
ls -l ${ICECAST_CONFIG_FILE}


echo ${DELIMITER}
echo "Open permissions to write icecast log files. ${ICECAST_LOG_FILE_DIRECTORY}"
chmod 777 ${ICECAST_LOG_FILE_DIRECTORY}
rc=$?
if [ 0 != ${rc} ] ; then
    echo "ERROR ${rc} opening permissions to write icecast log files. ${ICECAST_LOG_FILE_DIRECTORY}"
	exit 1
fi


echo ${DELIMITER}
echo "Starting the server in 3 seconds... (else ctrl-c)"
sleep 3


echo ${DELIMITER}
echo "Starting the icecast2 server."
icecast2 -b -c ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
    echo "ERROR ${rc} starting the icecast2 server."
	exit 1
fi


echo ${DELIMITER}
echo "Wait briefly for the server to start."
sleep 3


echo ${DELIMITER}
echo "Verify the icecast port ${ICECAST_PORT} is listening."
netstat -na | grep LISTEN | grep ${ICECAST_PORT} | grep -v grep
rc=$?
if [ 0 != ${rc} ] ; then
    echo "ERROR ${rc} verifying the icecast port ${ICECAST_PORT} is listening."
	exit 1
fi


echo ${DELIMITER}
echo "Verify we can fetch statistics from the icecast server."
curl http://admin:${ICECAST_ADMIN_PASSWORD}@localhost:${ICECAST_PORT}/admin/stats
rc=$?
if [ 0 != ${rc} ] ; then
    echo "ERROR ${rc} verifying we can fetch statistics from the icecast server."
	exit 1
fi


echo ${DELIMITER}
echo "Showing icecast2 config file. ${ICECAST_CONFIG_FILE}"
cat ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} Could not display ${ICECAST_CONFIG_FILE} does not exist."
	exit 1
fi


echo ${DELIMITER}
echo "Showing all listening tcp ports for debug..."
netstat -na | grep LIST | grep tcp | more


echo ${DELIMITER}
echo "Showing running icecast2 process for debug..."
ps -ef | grep icecast2


echo ${DELIMITER}
echo "Stopping the icecast server."
killall icecast2


echo ${DELIMITER}
echo "Success. Exit."

