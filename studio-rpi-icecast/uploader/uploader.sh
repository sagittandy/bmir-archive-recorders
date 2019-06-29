#!/bin/bash


# Get the name of the currently recording MP3 file.
CURRENT_MP3_FILE_PREFIX="UNDEFINED"
STREAMRIPPER_RUNNING=`ps -ef | grep streamripper | grep localhost | grep -v grep`
### echo "STREAMRIPPER_RUNNING=>>>${STREAMRIPPER_RUNNING}<<<"
if [ ! -z "${STREAMRIPPER_RUNNING}" ] ; then
	CURRENT_MP3_FILE_PREFIX=`echo ${STREAMRIPPER_RUNNING} | awk '{ printf $12; }'`
fi
### echo "CURRENT_MP3_FILE_PREFIX=${CURRENT_MP3_FILE_PREFIX}"



python /home/pi/bin/uploader.py ${CURRENT_MP3_FILE_PREFIX}

