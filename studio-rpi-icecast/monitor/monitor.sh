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
set +H  # Turn off history expansion in order to use exclamation points in strings.

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
export DISK_USAGE_FILE="disk.usage.txt"

export PLACEHOLDER_ICECAST_COLOR="PLACEHOLDER_ICECAST_COLOR"
export PLACEHOLDER_ICECAST_VALUE="PLACEHOLDER_ICECAST_VALUE"
export PLACEHOLDER_STREAMRIPPER_COLOR="PLACEHOLDER_STREAMRIPPER_COLOR"
export PLACEHOLDER_STREAMRIPPER_VALUE="PLACEHOLDER_STREAMRIPPER_VALUE"
export PLACEHOLDER_FILESYSTEM_COLOR="PLACEHOLDER_FILESYSTEM_COLOR"
export PLACEHOLDER_FILESYSTEM_VALUE="PLACEHOLDER_FILESYSTEM_VALUE"
export PLACEHOLDER_AMPLITUDE_COLOR="PLACEHOLDER_AMPLITUDE_COLOR"
export PLACEHOLDER_AMPLITUDE_VALUE="PLACEHOLDER_AMPLITUDE_VALUE"
export PLACEHOLDER_SWAP_COLOR="PLACEHOLDER_SWAP_COLOR"
export PLACEHOLDER_SWAP_VALUE="PLACEHOLDER_SWAP_VALUE"
export PLACEHOLDER_BUFF_CACHE_COLOR="PLACEHOLDER_BUFF_CACHE_COLOR"
export PLACEHOLDER_BUFF_CACHE_VALUE="PLACEHOLDER_BUFF_CACHE_VALUE"

export HTML_GREEN="#00FF00"
export HTML_YELLOW="#FFFF00"
export HTML_RED="#FA8072"  # Salmon

# Ensure non-root
### echo ${DELIMITER}
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: This script must be run as non-root." 
   exit 1
fi
### echo "Confirmed non-root."


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

echo "<H3>Summary</H3>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_ICECAST_COLOR}\"><b>Icecast Process: ${PLACEHOLDER_ICECAST_VALUE}</b></span><br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_STREAMRIPPER_COLOR}\"><b>Streamripper Process: ${PLACEHOLDER_STREAMRIPPER_VALUE}</b></span><br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_FILESYSTEM_COLOR}\"><b>Filesystem Growth: ${PLACEHOLDER_FILESYSTEM_VALUE} Kb</b></span><br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_AMPLITUDE_COLOR}\"><b>RMS Amplitude: ${PLACEHOLDER_AMPLITUDE_VALUE}</b></span><br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_BUFF_CACHE_COLOR}\"><b>Buffer/Cache Memory Size: ${PLACEHOLDER_BUFF_CACHE_VALUE} Kb</b></span><br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_SWAP_COLOR}\"><b>Swap File Size: ${PLACEHOLDER_SWAP_VALUE} Kb</b></span><br>" >> ${OUTFILE}

echo "<H3>Details</H3>" >> ${OUTFILE}
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


# Highlight running processes at top of web page.

ICECAST_RUNNING=`ps -ef | grep icecast | grep -v grep`
### echo "ICECAST_RUNNING=>>>${ICECAST_RUNNING}"
if [ -z "${ICECAST_RUNNING}" ] ; then
	ICECAST_HTML_COLOR="${HTML_RED}"
	ICECAST_VALUE="Stopped"
else
	ICECAST_HTML_COLOR="${HTML_GREEN}"
	ICECAST_VALUE="Running"
fi
### echo "ICECAST_HTML_COLOR=${ICECAST_HTML_COLOR}"
### echo "ICECAST_VALUE=${ICECAST_VALUE}"
sed -ie "s:${PLACEHOLDER_ICECAST_COLOR}:${ICECAST_HTML_COLOR}:g" ${OUTFILE}
sed -ie "s:${PLACEHOLDER_ICECAST_VALUE}:${ICECAST_VALUE}:g" ${OUTFILE}

STREAMRIPPER_RUNNING=`ps -ef | grep streamripper | grep localhost | grep -v grep`
### echo "STREAMRIPPER_RUNNING=>>>${STREAMRIPPER_RUNNING}"
if [ -z "${STREAMRIPPER_RUNNING}" ] ; then
	STREAMRIPPER_HTML_COLOR="${HTML_RED}"
	STREAMRIPPER_VALUE="Stopped"
else
	STREAMRIPPER_HTML_COLOR="${HTML_GREEN}"
	STREAMRIPPER_VALUE="Running"
fi
### echo "STREAMRIPPER_HTML_COLOR=${STREAMRIPPER_HTML_COLOR}"
### echo "STREAMRIPPER_VALUE=${STREAMRIPPER_VALUE}"
sed -ie "s:${PLACEHOLDER_STREAMRIPPER_COLOR}:${STREAMRIPPER_HTML_COLOR}:g" ${OUTFILE}
sed -ie "s:${PLACEHOLDER_STREAMRIPPER_VALUE}:${STREAMRIPPER_VALUE}:g" ${OUTFILE}



# CPU and Memory
echo ${DELIMITER} >> ${OUTFILE}
echo "CPU and memory..." >> ${OUTFILE}
top -bn1 | grep Tasks >> ${OUTFILE}
top -bn1 | grep Cpu >> ${OUTFILE}
top -bn1 | grep KiB >> ${OUTFILE}


# Swap Values

# Get present swap value.
SWAP_NOW=`top -bn1 | grep "KiB Swap" | awk '{print $7}'`
### echo "SWAP_NOW=${SWAP_NOW}"

# Get hundredths of seconds from the first 2 digits of nanoseconds.
NANO_SECONDS=`date +%N`
CENTI_SECONDS="${NANO_SECONDS:0:2}"

# Format time as [year - month date - hour minute - seconds centiseconds]
DATE_NOW="`date +%Y-%m%d-%H%M-%S`${CENTI_SECONDS}"
### echo "DATE_NOW=${DATE_NOW}"

# Create initial swap value file, if it does not exist.
if [ ! -f swap.txt ] ; then
	### echo "Creating swap.txt file with initial swap value: ${SWAP_NOW}"
	KIB_MEM=`top -bn1 | grep "KiB Mem"`
        KIB_SWAP=`top -bn1 | grep "KiB Swap"`
        echo "${SWAP_NOW} ${DATE_NOW} ${KIB_MEM}" >> swap.txt
        echo "${SWAP_NOW} ${DATE_NOW} ${KIB_SWAP}" >> swap.txt
fi

# Read the most recent swap value from the last line of the swap value file.
SWAP_PREV=`tail -1 swap.txt | awk '{print $1}'`
### echo "SWAP_PREV=${SWAP_PREV}"

# Compare the previous and current swap values.
# If different, save current value to file.
if [ "${SWAP_PREV}" == "${SWAP_NOW}" ] ; then
	echo "Ok. Swap has not grown."
else
        ### echo "Appending swap.txt file with curent swap value: ${SWAP_NOW}"
	KIB_MEM=`top -bn1 | grep "KiB Mem"`
	KIB_SWAP=`top -bn1 | grep "KiB Swap"`
	echo "${SWAP_NOW} ${DATE_NOW} ${KIB_MEM}" >> swap.txt
	echo "${SWAP_NOW} ${DATE_NOW} ${KIB_SWAP}" >> swap.txt
fi

# Report the last several swap changes and timestamps.
echo ${DELIMITER} >> ${OUTFILE}
echo "Most recent swap value changes..." >> ${OUTFILE}
tail -9 swap.txt >> ${OUTFILE} 

# Write the swap file usage number into the top of the HTML file.
if [ ${SWAP_NOW} -gt 2048 ] ; then
        SWAP_HTML_COLOR="${HTML_RED}"
elif [ ${SWAP_NOW} -gt 0 ] ; then
        SWAP_HTML_COLOR="${HTML_YELLOW}"
else
        SWAP_HTML_COLOR="${HTML_GREEN}"
fi
sed -ie "s:${PLACEHOLDER_SWAP_COLOR}:${SWAP_HTML_COLOR}:g" ${OUTFILE}
sed -ie "s:${PLACEHOLDER_SWAP_VALUE}:${SWAP_NOW}:g" ${OUTFILE}




# Filesystem usage
echo ${DELIMITER} >> ${OUTFILE}
echo "Filesystem usage..." >> ${OUTFILE}
df -k | grep Filesystem >> ${OUTFILE}
df -k | grep ${LOCAL_FILESYSTEM} >> ${OUTFILE}
df -k | grep ${USB_FILESYSTEM} >> ${OUTFILE}


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


# Get the current mp3 folder disk usage
### echo ${DELIMITER} >> ${OUTFILE}
### echo "Current mp3 folder usage..." >> ${OUTFILE}
du -sk ${USB_FOLDER} > ers.txt
### ls -l ers.txt
MP3_FOLDER_SIZE=`awk '{ printf $1; }' ers.txt`
### echo "MP3_FOLDER_SIZE=${MP3_FOLDER_SIZE}"
rm ers.txt


# Save the last several minutes of mp3 folder disk usage
### ls -l ${DISK_USAGE_FILE}
### cat ${DISK_USAGE_FILE} 
tail -29 ${DISK_USAGE_FILE} > ${DISK_USAGE_FILE}.tmp 
cp ${DISK_USAGE_FILE}.tmp ${DISK_USAGE_FILE} 
rm ${DISK_USAGE_FILE}.tmp 
echo ${MP3_FOLDER_SIZE} >> ${DISK_USAGE_FILE} 
### cat ${DISK_USAGE_FILE} 


### echo "Print the last several minutes of amplitude values" 
echo ${DELIMITER} >> ${OUTFILE}
DISK_USAGE_LAST="0"
DISK_USAGE_MAX="1234"
echo "Disk usage growth in filesystem (in KB) during most recent minutes..." >> ${OUTFILE}
while IFS= read -r line
do
	### echo "File read loop ${DISK_USAGE_FILE}. Entry. ---------------------------"
	DISK_USAGE_INT=`echo ${line}` 
	### echo "Initial: DISK_USAGE_LAST=${DISK_USAGE_LAST}"
	### echo "Initial: DISK_USAGE_INT=${DISK_USAGE_INT}"
	if [ "${DISK_USAGE_LAST}" -eq "0" ]; then
		# Skip the initial value
		DISK_USAGE_LAST=${DISK_USAGE_INT}
		### echo "Skipping initial value..."
		continue
	fi
	### echo "Processing value..." 
	DISK_USAGE_DELTA=`echo "${DISK_USAGE_INT}-${DISK_USAGE_LAST}"|bc`
	DISK_USAGE_LAST=${DISK_USAGE_INT}
	### echo "Delta: DISK_USAGE_DELTA=${DISK_USAGE_DELTA}"
	if [ "${DISK_USAGE_DELTA}" -gt "${DISK_USAGE_MAX}" ] ; then 
		### echo "Clipping at DISK_USAGE_MAX ${DISK_USAGE_MAX}"
		DISK_USAGE_DELTA=${DISK_USAGE_MAX}
	### else
	### 	echo "Less than ${DISK_USAGE_MAX}" 
	fi	
	# Create a string with length based upon DISK_USAGE_DELTA.
	# Todo: Optimize this horrible code :-)
	SPLAT_STRING=""
	### echo "DISK_USAGE_DELTA=${DISK_USAGE_DELTA}"
	DISK_USAGE_SPLATS=`echo "${DISK_USAGE_DELTA}/10"|bc`
	### echo "DISK_USAGE_SPLATS=${DISK_USAGE_SPLATS}"
	i="0"
	while [ $i -lt "${DISK_USAGE_SPLATS}" ] ; do
		### echo "i=${i} SPLAT_STRING=${SPLAT_STRING}"
		SPLAT_STRING="${SPLAT_STRING}*"
		i=$[$i+1]
	done
	### echo "SPLAT_STRING is: ${SPLAT_STRING}"
	echo "${SPLAT_STRING} ${DISK_USAGE_DELTA}" >> ${OUTFILE}	
done < "${DISK_USAGE_FILE}"


# Write the last disk usage number into the top of the HTML file.
if [ ${DISK_USAGE_DELTA} -ge 900 ] ; then
	FILESYSTEM_HTML_COLOR="${HTML_GREEN}"
elif [ ${DISK_USAGE_DELTA} -ge 600 ] ; then
	FILESYSTEM_HTML_COLOR="${HTML_YELLOW}"
else 
	FILESYSTEM_HTML_COLOR="${HTML_RED}"
fi
sed -ie "s:${PLACEHOLDER_FILESYSTEM_COLOR}:${FILESYSTEM_HTML_COLOR}:g" ${OUTFILE}
sed -ie "s:${PLACEHOLDER_FILESYSTEM_VALUE}:${DISK_USAGE_DELTA}:g" ${OUTFILE}


# Analyze the last minute of the current MP3 file
### echo ${DELIMITER} >> ${OUTFILE}
### echo "Analyzing last minutes of current MP3 file..." >> ${OUTFILE}
ps -ef | grep streamripper | grep localhost > ers.txt
MP3_FILE=`awk '{ printf $12; }' ers.txt`
### echo "MP3_FILE=${MP3_FILE}"
### echo "Ready to tail..."
tail -c 1000000 /media/usb/bmir/${DATE}/${MP3_FILE}.mp3 > current.mp3
ls -l current.mp3
sox current.mp3 -n stat > ers.txt 2>&1 | tail -1 
### cat ers.txt >> ${OUTFILE}
RMS_AMP_FLOAT=`grep RMS ers.txt | grep amplitude | awk '{ print $3 }'`
### echo ${RMS_AMP_FLOAT} >> ${OUTFILE}


# Save the last several minutes of amplitude values
### ls -l ${RMS_AMP_FILE}
### cat ${RMS_AMP_FILE}
tail -29 ${RMS_AMP_FILE} > ${RMS_AMP_FILE}.tmp
cp ${RMS_AMP_FILE}.tmp ${RMS_AMP_FILE}
### echo "RMS_AMP_FLOAT=$RMS_AMP_FLOAT"
echo ${RMS_AMP_FLOAT} >> ${RMS_AMP_FILE}
### ls -l ${RMS_AMP_FILE}
### cat ${RMS_AMP_FILE}


### echo "Print the last several minutes of amplitude values" 
echo ${DELIMITER} >> ${OUTFILE}
RMS_MAX="300"


echo "RMS amplitude values of most recent minutes of current MP3 file..." >> ${OUTFILE}
while IFS= read -r line
do
	### echo "File read loop ${RMS_AMP_FILE}. Entry. ---------------------------"
	### echo "line=>>>${line}<<<"
	if [ "${line}" == "" ] ; then
		### echo "Setting RMS_INT to zero because line is blank."
                RMS_INT="0"
	else
		RMS_INT=`echo "1000*${line}/1"|bc`
	fi
	if [ "${RMS_INT}" -gt "${RMS_MAX}" ] ; then 
		### echo "Clipping at RMS_MAX ${RMS_MAX}"
		RMS_INT=${RMS_MAX}
	### else
	###	echo "Accepting RMS_INT ${RMS_INT}, less than RMS_MAX ${RMS_MAX}" 
	fi	
	# Create a string with length based upon RMS_INT.
	# Todo: Optimize this horrible code :-)
	SPLAT_STRING=""
	RMS_INT_HALF=`echo "${RMS_INT}/2"|bc`
	### echo "RMS_INT_HALF=${RMS_INT_HALF}"
	i="0"
	while [ $i -lt "${RMS_INT_HALF}" ] ; do
		SPLAT_STRING="${SPLAT_STRING}*"
		i=$[$i+1]
	done
	### echo "${SPLAT_STRING}"
	### echo "${RMS_INT} ${SPLAT_STRING}" >> ${OUTFILE}
	echo "${SPLAT_STRING} ${RMS_INT}" >> ${OUTFILE}	
done < "${RMS_AMP_FILE}"


# Write the last amplitude number into the top of the HTML file.
if [ ${RMS_INT} -ge 120 ] ; then
	AMPLITUDE_HTML_COLOR="${HTML_GREEN}"
elif [ ${RMS_INT} -ge 60 ] ; then
	AMPLITUDE_HTML_COLOR="${HTML_YELLOW}"
else 
	AMPLITUDE_HTML_COLOR="${HTML_RED}"
fi
sed -ie "s:${PLACEHOLDER_AMPLITUDE_COLOR}:${AMPLITUDE_HTML_COLOR}:g" ${OUTFILE}
sed -ie "s:${PLACEHOLDER_AMPLITUDE_VALUE}:${RMS_INT}:g" ${OUTFILE}


# Append recent buffer/cache memory sizes to bottom of HTML file.
if [ -f freemem.txt ] ; then
	echo ${DELIMITER} >> ${OUTFILE}
	echo "Buffer/cache memory sizes in most recent hours..." >> ${OUTFILE}
	tail -29 freemem.txt >> ${OUTFILE} 
fi


# Write the current buffer/cache memory size to top of HTML file.
BUFF_CACHE=`top -bn1 | grep "KiB Mem" | awk '{print $10}'`
echo "BUFF_CACHE=${BUFF_CACHE}"
if [ ${BUFF_CACHE} -gt 400000 ] ; then
	BUFF_CACHE_HTML_COLOR="${HTML_RED}"
elif [ ${BUFF_CACHE} -gt 330000 ] ; then
	BUFF_CACHE_HTML_COLOR="${HTML_YELLOW}"
else 
	BUFF_CACHE_HTML_COLOR="${HTML_GREEN}"
fi
sed -ie "s:${PLACEHOLDER_BUFF_CACHE_COLOR}:${BUFF_CACHE_HTML_COLOR}:g" ${OUTFILE}
sed -ie "s:${PLACEHOLDER_BUFF_CACHE_VALUE}:${BUFF_CACHE}:g" ${OUTFILE}


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



