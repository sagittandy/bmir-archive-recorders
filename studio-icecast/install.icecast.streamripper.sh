#!/bin/bash
#-----------------------------------------------------------------------
# Installs icecast2 and streamripper on Ubuntu Linux 16.04 64bit
# (from deb packages)
#
# Usage: Edit the passwords below, as desired, before running this script.
#
# AD 2017-0321-2115  Copyright BMIR 2017
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"


# Define custom values for Icecast config file.
export ICECAST_CONFIG_FILE="/etc/icecast2/icecast.xml"
export ICECAST_HOSTNAME="localhost"
export ICECAST_RELAY_PASSWORD="relaypw"
export ICECAST_SOURCE_PASSWORD="sourcepw"
export ICECAST_ADMIN_PASSWORD="adminpw"


echo ${DELIMITER}
echo "Update apt-get."
apt-get update
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get update."
	exit 1
fi

echo ${DELIMITER}
echo "apt-get dist upgrade."
apt-get -y dist-upgrade
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get dist-upgrade."
	exit 1
fi


echo ${DELIMITER}
echo "apt-get -y install streamripper."
apt-get -y install streamripper
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} apt-get -y install streamripper."
	exit 1
fi


echo ${DELIMITER}
echo "Verify streamripper is installed."
which streamripper
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} which streamripper."
	exit 1
fi


echo ${DELIMITER}
echo "Fetch the icecast2 debian package."
curl -o /tmp/icecast2.deb http://ftp.gwdg.de/pub/opensuse/repositories/multimedia:/xiph/Debian_8.0/amd64/icecast2_2.4.2-2_amd64.deb
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} fetching icecast2 debian package."
	exit 1
fi


echo ${DELIMITER}
echo "Verify icecast2 deb file exists."
ls /tmp/icecast2.deb
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} File /tmp/icecast2.deb does not exist."
	exit 1
fi


echo ${DELIMITER}
echo "Intall the icecast2 debian package, non-interactively."
DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/icecast2.deb
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} from dpkg installing icecast2.deb."
	exit 1
fi

echo ${DELIMITER}
echo "Assimilate it."
apt-get update
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} from apt-get update."
	exit 1
fi


echo ${DELIMITER}
echo "Verify icecast2 is installed."
which icecast2
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} which icecast2."
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


# Todo someday: Create a function to do this, and add better checking.
echo ${DELIMITER}
echo "Customize hostname in icecast config file."
sed -ie "s:<hostname>localhost</hostname>:<hostname>${ICECAST_HOSTNAME}</hostname>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing hostname in icecast config file."
	exit 1
fi


echo ${DELIMITER}
echo "Customize source password in icecast config file."
sed -ie "s:<source-password>hackme</source-password>:<source-password>${ICECAST_SOURCE_PASSWORD}</source-password>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing source password in icecast config file."
	exit 1
fi


echo ${DELIMITER}
echo "Customize relay password in icecast config file."
sed -ie "s:<relay-password>hackme</relay-password>:<relay-password>${ICECAST_RELAY_PASSWORD}</relay-password>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing relay password in icecast config file."
	exit 1
fi


echo ${DELIMITER}
echo "Customize admin password in icecast config file."
sed -ie "s:<admin-password>hackme</admin-password>:<admin-password>${ICECAST_ADMIN_PASSWORD}</admin-password>:g" ${ICECAST_CONFIG_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} customizing admin password in icecast config file."
	exit 1
fi








echo ${DELIMITER}
echo "Success. Exit."
