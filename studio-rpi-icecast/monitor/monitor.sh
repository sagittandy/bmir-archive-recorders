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
#	systemctl enable monitor.timer  # Enable timer only
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
export RMS_AMP_FILE="rms.amplitudes.txt"

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
echo "<HTML><meta http-equiv=\"refresh\" content=\"30\">" >> ${OUTFILE}
echo "<BODY>" >> ${OUTFILE}
echo "<TITLE>BMIR Archiver System Status</TITLE>" >> ${OUTFILE}
echo "<H3>BMIR Archiver System Status</H3>" >> ${OUTFILE}
echo "<a href=\"./\">Parent Directory</a><br>" >> ${OUTFILE}
echo "<a href=\"bmir.cloud.status.html\">bmir.cloud.status.html</a><br>" >> ${OUTFILE}
echo "<a href=\"current.mp3\">current.mp3</a>" >> ${OUTFILE}
echo "<PRE>" >> ${OUTFILE}


# Timestamp
echo ${DELIMITER} >> ${OUTFILE}
echo "BMIR Archiver System Status" >> ${OUTFILE}
date >> ${OUTFILE}
hostname >> ${OUTFILE}
uptime >> ${OUTFILE}

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
# echo ${DELIMITER} >> ${OUTFILE}
# echo "MP3 folder size..." >> ${OUTFILE}
# du -sk ${LOCAL_FOLDER}/* >> ${OUTFILE}


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


# Systemctl timers
echo ${DELIMITER} >> ${OUTFILE}
echo "Systemctl timers..." >> ${OUTFILE}
systemctl --no-pager list-timers >> ${OUTFILE}


# Icecast stats
echo ${DELIMITER} >> ${OUTFILE}
echo "Icecast stats..." >> ${OUTFILE}
rm -f icecast.stats.json
curl -o icecast.stats.json http://localhost:8000/status-json.xsl
ls -l icecast.stats.json >> ${OUTFILE}
cat icecast.stats.json >> ${OUTFILE}
echo "" >> ${OUTFILE}


# Archiver today's files
echo ${DELIMITER} >> ${OUTFILE}
echo "Today's files..." >> ${OUTFILE}
DATE=`date +%m%d`
ls -lrt /media/usb/bmir/${DATE} >> ${OUTFILE}


# Analyze the last minute of the current MP3 file
### echo ${DELIMITER} >> ${OUTFILE}
### echo "Analyzing last minutes of current MP3 file..." >> ${OUTFILE}
ps -ef | grep streamripper | grep localhost > ers.txt
MP3_FILE=`awk '{ printf $11; }' ers.txt`
tail -c 1000000 /media/usb/bmir/${DATE}/${MP3_FILE}.mp3 > current.mp3
sox current.mp3 -n stat > ers.txt 2>&1 | tail -1 
### cat ers.txt >> ${OUTFILE}
RMS_AMP_FLOAT=`grep RMS ers.txt | grep amplitude | awk '{ print $3 }'`
### echo ${RMS_AMP_FLOAT} >> ${OUTFILE}


# Save the last several minutes of amplitude values
### ls -l ${RMS_AMP_FILE}
### cat ${RMS_AMP_FILE}
tail -29 ${RMS_AMP_FILE} > ${RMS_AMP_FILE}.tmp
cp ${RMS_AMP_FILE}.tmp ${RMS_AMP_FILE}
echo ${RMS_AMP_FLOAT} >> ${RMS_AMP_FILE}
### ls -l ${RMS_AMP_FILE}
### cat ${RMS_AMP_FILE}


echo "Print the last several minutes of amplitude values" 
echo ${DELIMITER} >> ${OUTFILE}
RMS_MAX="300"
echo "RMS amplitude values of most recent minutes of current MP3 file..." >> ${OUTFILE}
while IFS= read -r line
do
	RMS_INT=`echo "1000*${line}/1"|bc` 
	echo $RMS_INT
	if [ "${RMS_INT}" -gt "${RMS_MAX}" ] ; then 
		echo "Clipping at RMS_MAX ${RMS_MAX}"
		RMS_INT=${RMS_MAX}
	else
		echo "Less than ${RMS_MAX}" 
	fi	
	# Create a string with length based upon RMS_INT.
	# Todo: Optimize this horrible code :-)
	SPLAT_STRING=""
	RMS_INT_HALF=`echo "${RMS_INT}/2"|bc`
	echo "RMS_INT_HALF=${RMS_INT_HALF}"
	i="0"
	while [ $i -lt "${RMS_INT_HALF}" ] ; do
		SPLAT_STRING="${SPLAT_STRING}*"
		i=$[$i+1]
	done
	echo "${SPLAT_STRING}"
	### echo "${RMS_INT} ${SPLAT_STRING}" >> ${OUTFILE}
	echo "${SPLAT_STRING} ${RMS_INT}" >> ${OUTFILE}	
done < "${RMS_AMP_FILE}"


# Done
echo ${DELIMITER} >> ${OUTFILE}


# HTML finish
echo "</PRE></BODY></HTML>" >> ${OUTFILE}


# Upload HTML
scp ${OUTFILE} ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_FOLDER}/
rc=$?
if [ 0 != ${rc} ] ; then
	echo "ERROR ${rc} could not upload output file."
	exit 1
fi


# Also upload the most recent 4 seconds from the current mp3 file
### ps -ef | grep streamripper | grep localhost > ers.txt
### MP3_FILE=`awk '{ printf $11; }' ers.txt`
tail -c 64000 /media/usb/bmir/${DATE}/${MP3_FILE}.mp3 > current.mp3
scp current.mp3 ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_FOLDER}/



