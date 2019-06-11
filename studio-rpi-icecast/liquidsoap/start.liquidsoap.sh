#!/bin/bash
#-----------------------------------------------------------------------
# Starts liquidsoap, which uploads mp3 files to icecast2.
#
# Prereqs:  Set all environment variables as desired.
#
# Usage: Run this as a non-root user.
#
#	Run in foreground:  ./start.liquidsoap.sh
#	Run in background:  nohup ./start.liquidsoap.sh &
#
# AD 2019-0513-2139 Updated for use with systemd.
# AD 2017-0610  Copyright BMIR 2017
#-----------------------------------------------------------------------
# Define custom values for Icecast config file.
export ICECAST_HOST="arc"
export ICECAST_PORT=8000
export ICECAST_SOURCE_PASSWORD="sourcepw"
export MP3_DIR="/home/pi/mp3"
export M3U_FILE="testclips.m3u"
 

# Ensure non-root
echo "Checking for non-root user."
echo ${DELIMITER}
if [[ $EUID -eq 0 ]]; then
   echo "INVOCATION ERROR: This script must be run as a non-root user." 
   exit 1
fi
echo "OK. Confirmed non-root."


# Ensure MP3 directory exists
echo "Checking that MP3 directory exists."
ls ${MP3_DIR}
rc=$?
if [ 0 != ${rc} ] ; then
	echo "INVOCATION ERROR: MP3 file directory ${MP3_DIR} does not exist."
	exit 1
fi
echo "OK. MP3 directory exists: ${MP3_DIR}"


# Ensure MP3 files exist
echo "Checking that MP3 files exist."
ls ${MP3_DIR}/*.mp3
rc=$?
if [ 0 != ${rc} ] ; then
        echo "INVOCATION ERROR: MP3 files do not exist in ${MP3_DIR}"
        exit 1
fi
echo "OK. MP3 files exist."


# Ensure M3U file exists
echo "Checking that M3U file exists."
ls ${MP3_DIR}/${M3U_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
        echo "INVOCATION ERROR: M3U file does not exist: ${MP3_DIR}/${M3U_FILE}"
        exit 1
fi
echo "OK. M3U file exists."


# Start liquidsoap in the foreground.
liquidsoap "output.icecast(%mp3, host=\"$ICECAST_HOST\", description=\"Liquidsoap tester for BMIR\", port=$ICECAST_PORT, password=\"$ICECAST_SOURCE_PASSWORD\", mount=\"bmir\", mksafe(playlist(\"$MP3_DIR/$M3U_FILE\")))"



