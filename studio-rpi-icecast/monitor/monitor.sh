#!/bin/bash
#-----------------------------------------------------------------------
# Uploads rudimentary statistics to a cloud server in HTML format
#
# Prereqs:
#	User must have SSH key access to the cloud server.
#
# Setup: 
# 	Place this file in folder /home/pi/bin/
#
# Usage: 
#	Manual: Run this script as non-root: 
#
#		./monitor.sh
#
# Automatic execution: Either use systemd timer or cron:
#
# Systemd timer:
#	As root:
#	Move monitor.timer and monitor.service to /etc/systemd/system/
#	systemctl daemon-reload
#	systemctl enable monitor.service monitor.timer # Enable both
#	systemctl start monitor.timer	# Start timer only
#	systemctl list-timers --all
#
# Cron:
#	Set up cron to run this every two minutes
#	As user pi (the user which will run this python script),
#		crontab -e
#		Add line
#			*/2 * * * * cd /home/pi/bin && ./monitor.sh
#
#	Cron specification tester: https://crontab.guru/ 
#
# Consumption:
#	Browse to the remote server to view the HTML.
#	The HTML auto-updates every minute (via meta refresh)
#
# AD 2019-0408-2002 Copyright BMIR 2019
#-----------------------------------------------------------------------
export DELIMITER="----------------------------------------------------------------------------------"

export OUTFILE="bmir.archiver.status.html"
export REMOTE_USER="pi"
export REMOTE_SERVER="dobmir"
export REMOTE_FOLDER="/home/pi/bmir"
export LOCAL_FOLDER="/home/pi/bmir"
export LOCAL_FILESYSTEM="/dev/root"
export USB_FILESYSTEM="/media/"
export USB_FOLDER="/media/usb/bmir"


# Ensure non-root
echo ${DELIMITER}
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: This script must be run as non-root." 
   exit 1
fi
echo "Confirmed non-root."


# Initial cleanup
rm ${OUTFILE}


# HTML start
echo "<HTML><meta http-equiv=\"refresh\" content=\"60\">" >> ${OUTFILE}
echo "<BODY>" >> ${OUTFILE}
echo "<TITLE>BMIR Archiver System Status</TITLE>" >> ${OUTFILE}
echo "<H3>BMIR Archiver System Status</H3>" >> ${OUTFILE}
echo "<PRE>" >> ${OUTFILE}


# Timestamp
echo ${DELIMITER} >> ${OUTFILE}
echo "BMIR Archiver System Status" >> ${OUTFILE}
date >> ${OUTFILE}
hostname >> ${OUTFILE}

# Running processes
echo ${DELIMITER} >> ${OUTFILE}
echo "Running processes..." >> ${OUTFILE}
ps -ef | grep streamripper | grep -v grep >> ${OUTFILE}
ps -ef | grep icecast | grep -v grep >> ${OUTFILE}
ps -ef | grep uploader | grep -v grep >> ${OUTFILE}
ps -ef | grep autossh | grep -v grep >> ${OUTFILE}


# Filesystem usage
echo ${DELIMITER} >> ${OUTFILE}
echo "Filesystem usage..." >> ${OUTFILE}
df -k | grep Filesystem >> ${OUTFILE}
df -k | grep ${LOCAL_FILESYSTEM} >> ${OUTFILE}
df -k | grep ${USB_FILESYSTEM} >> ${OUTFILE}


# CPU and Memory
echo ${DELIMITER} >> ${OUTFILE}
echo "CPU and memory..." >> ${OUTFILE}
top -bn1 | grep Tasks >> ${OUTFILE}
top -bn1 | grep Cpu >> ${OUTFILE}
top -bn1 | grep KiB >> ${OUTFILE}


# MP3 folder size
echo ${DELIMITER} >> ${OUTFILE}
echo "MP3 folder size..." >> ${OUTFILE}
du -sk ${LOCAL_FOLDER}/* >> ${OUTFILE}


# USB MP3 folder size
echo ${DELIMITER} >> ${OUTFILE}
echo "USB MP3 folder size..." >> ${OUTFILE}
du -sk ${USB_FOLDER}/* >> ${OUTFILE}


# Listening ports
echo ${DELIMITER} >> ${OUTFILE}
echo "Listening ports..." >> ${OUTFILE}
netstat -na | grep LIST | grep tcp >> ${OUTFILE}


# IP addresses
echo ${DELIMITER} >> ${OUTFILE}
echo "IP addresses..." >> ${OUTFILE}
ip -4 ad sh | grep inet >> ${OUTFILE}


# Done
echo ${DELIMITER} >> ${OUTFILE}


# HTML finish
echo "</PRE></BODY></HTML>" >> ${OUTFILE}


# Upload
scp ${OUTFILE} ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_FOLDER}/
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not upload output file."
	exit 1
fi


