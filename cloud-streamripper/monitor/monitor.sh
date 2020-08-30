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

send_sms_twilio()
{
    # Ensure env vars
    if [[ -z "${TWILIO_SID}" ]]; then
    	echo "INVOCATION ERROR: Environment variable TWILIO_SID is not defined."
    	exit 9
    fi
    if [[ -z "${TWILIO_TOKEN}" ]]; then
    	echo "INVOCATION ERROR: Environment variable TWILIO_TOKEN is not defined."
    	exit 9
    fi
    if [[ -z "${TWILIO_SRC}" ]]; then
    	echo "INVOCATION ERROR: Environment variable TWILIO_SRC is not defined."
    	exit 9
    fi
    if [[ -z "${TWILIO_DST}" ]]; then
    	echo "INVOCATION ERROR: Environment variable TWILIO_DST is not defined."
    	exit 9
    fi
    if [[ -z "${MSG_BODY}" ]]; then
    	echo "INVOCATION ERROR: Environment variable MSG_BODY is not defined."
    	exit 9
    fi

    echo "Sending SMS text message to ${TWILIO_DST}"
    echo "MSG_BODY=${MSG_BODY}"

    # Send it!
    curl -X POST https://api.twilio.com/2010-04-01/Accounts/${TWILIO_SID}/Messages.json \
    --data-urlencode "Body=${MSG_BODY}" \
    --data-urlencode "From=${TWILIO_SRC}" \
    --data-urlencode "To=${TWILIO_DST}" \
    -u ${TWILIO_SID}:${TWILIO_TOKEN}

    rc=$?
    echo ""
    echo "rc=${rc}"
}

# Ensure env vars
if [[ -z "${SERVICE_NAME}" ]]; then
	echo "INVOCATION ERROR: Environment variable SERVICE_NAME is not defined."
	exit 9
fi
if [[ -z "${SERVICE_PREFIX}" ]]; then
	echo "INVOCATION ERROR: Environment variable SERVICE_PREFIX is not defined."
	exit 9
fi
if [[ -z "${SERVICE_DEST_PATH}" ]]; then
	echo "INVOCATION ERROR: Environment variable SERVICE_DEST_PATH is not defined."
	exit 9
fi
if [[ -z "${SERVICE_RADIOSTREAM}" ]]; then
	echo "INVOCATION ERROR: Environment variable SERVICE_RADIOSTREAM is not defined."
	exit 9
fi
if [[ -z "${MP3_DIR}" ]]; then
	echo "INVOCATION ERROR: Environment variable MP3_DIR is not defined."
	exit 9
fi


export OUTFILE="${SERVICE_NAME}.html"
### export REMOTE_USER="pi"
### export REMOTE_SERVER="dobmir"
### export REMOTE_FOLDER="/home/pi/bmir"
export LOCAL_FOLDER="${SERVICE_DEST_PATH}"
#export LOCAL_FILESYSTEM="/dev/root"
#export USB_FILESYSTEM="/media/"
#export USB_FOLDER="/media/usb/bmir"
export RMS_AMP_FILE="${SERVICE_PREFIX}.rms.amplitudes.txt"
export DISK_USAGE_FILE="${SERVICE_PREFIX}.disk.usage.txt"
export CURRENT_MP3_FILE="${SERVICE_PREFIX}.current.mp3"
export ICECAST_STATS_FILE="${SERVICE_PREFIX}.icecast.stats.json"
export ERS_TXT_FILE="${SERVICE_PREFIX}.ers.txt"
export STREAMRIPPER_OUTAGE_FILE="${SERVICE_PREFIX}.streamripper.outage.txt"
export FILESYSTEM_OUTAGE_FILE="${SERVICE_PREFIX}.filesystem.outage.txt"

export PLACEHOLDER_ICECAST_COLOR="PLACEHOLDER_ICECAST_COLOR"
export PLACEHOLDER_ICECAST_VALUE="PLACEHOLDER_ICECAST_VALUE"
export PLACEHOLDER_STREAMRIPPER_COLOR="PLACEHOLDER_STREAMRIPPER_COLOR"
export PLACEHOLDER_STREAMRIPPER_VALUE="PLACEHOLDER_STREAMRIPPER_VALUE"
export PLACEHOLDER_DATE_NOW_VALUE="PLACEHOLDER_DATE_NOW_VALUE"
export PLACEHOLDER_EPOCH_SECS_VALUE="PLACEHOLDER_EPOCH_SECS_VALUE"
export PLACEHOLDER_RX_DATA_COLOR="PLACEHOLDER_RX_DATA_COLOR"
export PLACEHOLDER_RX_DATA_VALUE="PLACEHOLDER_RX_DATA_VALUE"
export PLACEHOLDER_FILESYSTEM_COLOR="PLACEHOLDER_FILESYSTEM_COLOR"
export PLACEHOLDER_FILESYSTEM_VALUE="PLACEHOLDER_FILESYSTEM_VALUE"
export PLACEHOLDER_AMPLITUDE_COLOR="PLACEHOLDER_AMPLITUDE_COLOR"
export PLACEHOLDER_AMPLITUDE_VALUE="PLACEHOLDER_AMPLITUDE_VALUE"
export PLACEHOLDER_SWAP_COLOR="PLACEHOLDER_SWAP_COLOR"
export PLACEHOLDER_SWAP_VALUE="PLACEHOLDER_SWAP_VALUE"
#export PLACEHOLDER_BUFF_CACHE_COLOR="PLACEHOLDER_BUFF_CACHE_COLOR"
#export PLACEHOLDER_BUFF_CACHE_VALUE="PLACEHOLDER_BUFF_CACHE_VALUE"
export PLACEHOLDER_AVAIL_COLOR="PLACEHOLDER_AVAIL_COLOR"
export PLACEHOLDER_AVAIL_VALUE="PLACEHOLDER_AVAIL_VALUE"
export PLACEHOLDER_CURRENT_RC_VALUE="PLACEHOLDER_CURRENT_RC_VALUE"
export PLACEHOLDER_FILE_COUNT_COLOR="PLACEHOLDER_FILE_COUNT_COLOR"
export PLACEHOLDER_FILE_COUNT_STUDIO_VALUE="PLACEHOLDER_FILE_COUNT_STUDIO_VALUE"
export PLACEHOLDER_FILE_COUNT_CLOUD_VALUE="PLACEHOLDER_FILE_COUNT_CLOUD_VALUE"

export HTML_GREEN="#00FF00"
export HTML_YELLOW="#FFFF00"
export HTML_RED="#FA8072"  # Salmon

# Assemble the URL of this monitor's folder, assuming the first IP is the real one.
hip=`hostname -I | cut -d " " -f1`
monitor_url="http://${hip}/${SERVICE_NAME}/"

# Ensure non-root
### echo ${DELIMITER}
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: This script must be run as non-root."
   exit 1
fi
### echo "Confirmed non-root."


# Initial cleanup
rm ${OUTFILE}

SERVICE_DIR_UPPER=`echo "$SERVICE_DIR" | tr '[:lower:]' '[:upper:]'`

# HTML start
echo "<HTML><meta http-equiv=\"refresh\" content=\"30\">" >> ${OUTFILE}
echo "<BODY>" >> ${OUTFILE}
echo "<TITLE>${SERVICE_DIR_UPPER} Studio Archiver System Status</TITLE>" >> ${OUTFILE}
echo "<H3>${SERVICE_DIR_UPPER} Archiver System Status</H3>" >> ${OUTFILE}
echo "<a href=\"./\">Parent Directory</a><br>" >> ${OUTFILE}
echo "<a href=\"${OUTFILE}\">${OUTFILE}</a><br>" >> ${OUTFILE}
echo "<a href=\"${CURRENT_MP3_FILE}\">${CURRENT_MP3_FILE}</a> rc=${PLACEHOLDER_CURRENT_RC_VALUE}" >> ${OUTFILE}

echo "<H3>Summary</H3>" >> ${OUTFILE}

echo "Last Updated: ${PLACEHOLDER_DATE_NOW_VALUE}<br>" >> ${OUTFILE}
echo "Epoch Seconds: ${PLACEHOLDER_EPOCH_SECS_VALUE}<br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_AVAIL_COLOR}\"><b>Available Memory: ${PLACEHOLDER_AVAIL_VALUE} MB</b></span><br>" >> ${OUTFILE}
#echo "<span style=\"background-color: ${PLACEHOLDER_SWAP_COLOR}\"><b>Swap File Size: ${PLACEHOLDER_SWAP_VALUE} KB</b></span><br>" >> ${OUTFILE}
#echo "<span style=\"background-color: ${PLACEHOLDER_ICECAST_COLOR}\"><b>Icecast Process: ${PLACEHOLDER_ICECAST_VALUE}</b></span><br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_STREAMRIPPER_COLOR}\"><b>Streamripper Process: ${PLACEHOLDER_STREAMRIPPER_VALUE}</b></span><br>" >> ${OUTFILE}
#echo "<span style=\"background-color: ${PLACEHOLDER_RX_DATA_COLOR}\"><b>Received Data: ${PLACEHOLDER_RX_DATA_VALUE} KB/minute</b></span><br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_FILESYSTEM_COLOR}\"><b>Filesystem Growth: ${PLACEHOLDER_FILESYSTEM_VALUE} KB/minute</b></span><br>" >> ${OUTFILE}
echo "<span style=\"background-color: ${PLACEHOLDER_AMPLITUDE_COLOR}\"><b>RMS Amplitude: ${PLACEHOLDER_AMPLITUDE_VALUE}</b></span><br>" >> ${OUTFILE}
#echo "<span style=\"background-color: ${PLACEHOLDER_BUFF_CACHE_COLOR}\"><b>Buffer/Cache Memory Size: ${PLACEHOLDER_BUFF_CACHE_VALUE} Kb</b></span><br>" >> ${OUTFILE}
#echo "<span style=\"background-color: ${PLACEHOLDER_FILE_COUNT_COLOR}\"><b>MP3 File Counts: Studio=${PLACEHOLDER_FILE_COUNT_STUDIO_VALUE} Cloud=${PLACEHOLDER_FILE_COUNT_CLOUD_VALUE} </b></span><br>" >> ${OUTFILE}

echo "<H3>Files</H3>" >> ${OUTFILE}
echo "<PRE>" >> ${OUTFILE}


# Timestamps...

# Get hundredths of seconds from the first 2 digits of nanoseconds.
NANO_SECONDS=`date +%N`
CENTI_SECONDS="${NANO_SECONDS:0:2}"

# Format time as [year - month date - hour minute - seconds centiseconds]
DATE_NOW="`date +%Y-%m%d-%H%M-%S`${CENTI_SECONDS}"


# Overlay the date value on top of the page.
sed -i "s:${PLACEHOLDER_DATE_NOW_VALUE}:${DATE_NOW}:g" ${OUTFILE}


# Overlay the epoch time (in seconds) on top of the page.
EPOCH_SECS=`date +%s`
sed -i "s:${PLACEHOLDER_EPOCH_SECS_VALUE}:${EPOCH_SECS}:g" ${OUTFILE}


# Archiver today's files on Studio Raspberry Pi
echo ${DELIMITER} >> ${OUTFILE}
echo "Today's files in archiver..." >> ${OUTFILE}
DATE=`date +%m%d`
ls -lrt ${MP3_DIR}/${DATE} >> ${OUTFILE}

# Archiver today's files on the Cloud VM
#echo ${DELIMITER} >> ${OUTFILE}
#echo "Today's files in Cloud..." >> ${OUTFILE}
#DATE=`date +%m%d`
#ssh -o "StrictHostKeyChecking=no" pi@dobmir ls -lrt /home/pi/bmir/${DATE} >> ${OUTFILE}


# Compare file counts on Studio RPI and Cloud VM
#FILE_COUNT_STUDIO=`ls -l /media/usb/bmir/${DATE}/bmir*.mp3  | wc -l`
#FILE_COUNT_CLOUD=`ssh -o "StrictHostKeyChecking=no" pi@dobmir ls -lrt /home/pi/bmir/${DATE}/bmir*.mp3 | wc -l`
#FILE_COUNT_DELTA=`echo "${FILE_COUNT_STUDIO}-${FILE_COUNT_CLOUD}"|bc`
# Temporary hack.  TODO fix this when a backup exists in spaces or another VM.
FILE_COUNT_STUDIO=123
FILE_COUNT_CLOUD=123
FILE_COUNT_DELTA=0
if [ "${FILE_COUNT_DELTA}" = "0" ] || [ "${FILE_COUNT_DELTA}" = "1" ] || [ "${FILE_COUNT_DELTA}" = "2" ] ; then
	FILE_COUNT_HTML_COLOR="${HTML_GREEN}"
else
	FILE_COUNT_HTML_COLOR="${HTML_YELLOW}"
fi
sed -i "s:${PLACEHOLDER_FILE_COUNT_COLOR}:${FILE_COUNT_HTML_COLOR}:g" ${OUTFILE}
sed -i "s:${PLACEHOLDER_FILE_COUNT_STUDIO_VALUE}:${FILE_COUNT_STUDIO}:g" ${OUTFILE}
sed -i "s:${PLACEHOLDER_FILE_COUNT_CLOUD_VALUE}:${FILE_COUNT_CLOUD}:g" ${OUTFILE}


echo ${DELIMITER} >> ${OUTFILE}
echo "</PRE>" >> ${OUTFILE}
echo "<H3>Details</H3>" >> ${OUTFILE}
echo "<PRE>" >> ${OUTFILE}


# Timestamp
echo ${DELIMITER} >> ${OUTFILE}
echo "${SERVICE_NAME} System Status" >> ${OUTFILE}
date >> ${OUTFILE}
hostname >> ${OUTFILE}
uptime >> ${OUTFILE}
#sysctl -a | grep vm.swappiness >> ${OUTFILE}
#sysctl -a | grep vm.vfs_cache_pressure >> ${OUTFILE}


# Running processes
echo ${DELIMITER} >> ${OUTFILE}
echo "Running processes..." >> ${OUTFILE}
ps -ef | grep streamripper | grep -v grep >> ${OUTFILE}
#ps -ef | grep icecast | grep -v grep >> ${OUTFILE}
ps -ef | grep uploader | grep -v grep >> ${OUTFILE}
#ps -ef | grep autossh | grep -v grep >> ${OUTFILE}
#ps -ef | grep ifstat | grep -v grep >> ${OUTFILE}


# Highlight running processes at top of web page.

#ICECAST_RUNNING=`ps -ef | grep icecast | grep -v grep`
ICECAST_RUNNING="Yes"  # Not really!
if [ -z "${ICECAST_RUNNING}" ] ; then
	ICECAST_HTML_COLOR="${HTML_RED}"
	ICECAST_VALUE="Stopped"
else
	ICECAST_HTML_COLOR="${HTML_GREEN}"
	ICECAST_VALUE="Running"
fi
sed -i "s:${PLACEHOLDER_ICECAST_COLOR}:${ICECAST_HTML_COLOR}:g" ${OUTFILE}
sed -i "s:${PLACEHOLDER_ICECAST_VALUE}:${ICECAST_VALUE}:g" ${OUTFILE}


#STREAMRIPPER_RUNNING=`ps -ef | grep streamripper | grep "${SERVICE_RADIOSTREAM}" | grep -v grep`
#echo "SERVICE_RADIOSTREAM 1 =${SERVICE_RADIOSTREAM}"
#echo "STREAMRIPPER_RUNNING 1 =>>>${STREAMRIPPER_RUNNING}<<<"
#if [ -z ${STREAMRIPPER_RUNNING} ] ; then
ps -ef | grep streamripper | grep "${SERVICE_RADIOSTREAM}" | grep -v grep
rc=$?
#echo "rc=${rc}"
if [ 0 != ${rc} ] ; then
    echo "Inferred NOT running"
	STREAMRIPPER_HTML_COLOR="${HTML_RED}"
	STREAMRIPPER_VALUE="Stopped"
else
    echo "Inferred RUNNING"
	STREAMRIPPER_HTML_COLOR="${HTML_GREEN}"
	STREAMRIPPER_VALUE="Running"
fi
echo "STREAMRIPPER_HTML_COLOR=${STREAMRIPPER_HTML_COLOR}"
echo "STREAMRIPPER_VALUE=${STREAMRIPPER_VALUE}"
sed -i "s:${PLACEHOLDER_STREAMRIPPER_COLOR}:${STREAMRIPPER_HTML_COLOR}:g" ${OUTFILE}
sed -i "s:${PLACEHOLDER_STREAMRIPPER_VALUE}:${STREAMRIPPER_VALUE}:g" ${OUTFILE}

# Send SMS Text Message when a streamripper outage is detected.
# Note: File STREAMRIPPER_OUTAGE_FILE serves to remember whether an SMS was sent.
if [ "Running" == "${STREAMRIPPER_VALUE}" ] ; then
	if [ -f ${STREAMRIPPER_OUTAGE_FILE} ] ; then
		echo "Streamripper is restored. Removing outage file."
        MSG_BODY="OK ${SERVICE_PREFIX}: Streamripper running ${monitor_url}"
		send_sms_twilio
		rm ${STREAMRIPPER_OUTAGE_FILE}
	else
		echo "Streamripper is running. Doing nothing."
	fi
else # Not running.
	if [ -f ${STREAMRIPPER_OUTAGE_FILE} ] ; then
		echo "Streamripper outage continues and SMS already sent. Doing nothing."
	else
		echo "Streamripper stopped. Sending SMS."
		MSG_BODY="ERR ${SERVICE_PREFIX}: Streamripper stopped ${monitor_url}"
		send_sms_twilio
		touch ${STREAMRIPPER_OUTAGE_FILE}
	fi
fi


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
#NANO_SECONDS=`date +%N`
#CENTI_SECONDS="${NANO_SECONDS:0:2}"

# Format time as [year - month date - hour minute - seconds centiseconds]
#DATE_NOW="`date +%Y-%m%d-%H%M-%S`${CENTI_SECONDS}"
### echo "DATE_NOW=${DATE_NOW}"

# Create initial swap value file, if it does not exist.
#if [ ! -f swap.txt ] ; then
#	### echo "Creating swap.txt file with initial swap value: ${SWAP_NOW}"
#	KIB_MEM=`top -bn1 | grep "KiB Mem"`
#       KIB_SWAP=`top -bn1 | grep "KiB Swap"`
#        echo "${SWAP_NOW} ${DATE_NOW} ${KIB_MEM}" >> swap.txt
#        echo "${SWAP_NOW} ${DATE_NOW} ${KIB_SWAP}" >> swap.txt
#fi
#
# Read the most recent swap value from the last line of the swap value file.
#SWAP_PREV=`tail -1 swap.txt | awk '{print $1}'`
### echo "SWAP_PREV=${SWAP_PREV}"
#
# Compare the previous and current swap values.
# If different, save current value to file.
#if [ "${SWAP_PREV}" == "${SWAP_NOW}" ] ; then
#	echo "Ok. Swap has not grown."
#else
#        ### echo "Appending swap.txt file with current swap value: ${SWAP_NOW}"
#	KIB_MEM=`top -bn1 | grep "KiB Mem"`
#	KIB_SWAP=`top -bn1 | grep "KiB Swap"`
#	echo "${SWAP_NOW} ${DATE_NOW} ${KIB_MEM}" >> swap.txt
#	echo "${SWAP_NOW} ${DATE_NOW} ${KIB_SWAP}" >> swap.txt
#fi
#
## Report the last several swap changes and timestamps.
#echo ${DELIMITER} >> ${OUTFILE}
#echo "Most recent swap value changes..." >> ${OUTFILE}
#tail -9 swap.txt >> ${OUTFILE}

# Write the swap file usage number into the top of the HTML file.
if [ ${SWAP_NOW} > 2048 ] ; then
        SWAP_HTML_COLOR="${HTML_RED}"
elif [ ${SWAP_NOW} > 0 ] ; then
        SWAP_HTML_COLOR="${HTML_YELLOW}"
else
        SWAP_HTML_COLOR="${HTML_GREEN}"
fi
sed -i "s:${PLACEHOLDER_SWAP_COLOR}:${SWAP_HTML_COLOR}:g" ${OUTFILE}
sed -i "s:${PLACEHOLDER_SWAP_VALUE}:${SWAP_NOW}:g" ${OUTFILE}



# Filesystem usage
echo ${DELIMITER} >> ${OUTFILE}
echo "Filesystem usage..." >> ${OUTFILE}
df -k | grep Filesystem >> ${OUTFILE}


# MP3 folder size
echo "MP3 folder size..." >> ${OUTFILE}
du -sk ${MP3_DIR}/* >> ${OUTFILE}


# USB MP3 folder size
#echo ${DELIMITER} >> ${OUTFILE}
#echo "USB MP3 folder size..." >> ${OUTFILE}
#du -sk ${USB_FOLDER}/* >> ${OUTFILE}


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
#echo ${DELIMITER} >> ${OUTFILE}
#echo "Icecast stats..." >> ${OUTFILE}
#rm -f ${ICECAST_STATS_FILE}
#curl -o ${ICECAST_STATS_FILE} http://localhost:8000/status-json.xsl
#ls -l ${ICECAST_STATS_FILE} >> ${OUTFILE}
#cat ${ICECAST_STATS_FILE} >> ${OUTFILE}
#echo "" >> ${OUTFILE}


# Get the current mp3 folder disk usage
echo ${DELIMITER} >> ${OUTFILE}
echo "Current mp3 folder usage..." ## >> ${OUTFILE}
du -sk ${MP3_DIR} > ${ERS_TXT_FILE}
### ls -l ERS_TXT_FILE
MP3_FOLDER_SIZE=`awk '{ printf $1; }' ${ERS_TXT_FILE}`
### echo "MP3_FOLDER_SIZE=${MP3_FOLDER_SIZE}"
rm ${ERS_TXT_FILE}
echo "Done with current mp3 folder usage."

# Save the last several minutes of mp3 folder disk usage
### ls -l ${DISK_USAGE_FILE}
### cat ${DISK_USAGE_FILE}
echo "Tailing disk usage file..."
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
	DISK_USAGE_DELTA_PREV=${DISK_USAGE_DELTA}
	DISK_USAGE_DELTA=`echo "${DISK_USAGE_INT}-${DISK_USAGE_LAST}"|bc`
	DISK_USAGE_LAST=${DISK_USAGE_INT}
	### echo "Delta: DISK_USAGE_DELTA=${DISK_USAGE_DELTA}"
	DISK_USAGE_UNCLIPPED=${DISK_USAGE_DELTA}
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
	echo "${SPLAT_STRING} ${DISK_USAGE_UNCLIPPED}" >> ${OUTFILE}
done < "${DISK_USAGE_FILE}"

# Calculate disk growth over the last two minutes.
DISK_USAGE_DELTA_2MIN=`echo "${DISK_USAGE_UNCLIPPED}+${DISK_USAGE_DELTA_PREV}"|bc`
#echo "DISK_USAGE_DELTA_2MIN=${DISK_USAGE_DELTA_2MIN}"

# Write the last disk usage number into the top of the HTML file.
if [ ${DISK_USAGE_DELTA} -ge 900 ] ; then
	FILESYSTEM_HTML_COLOR="${HTML_GREEN}"
elif [ ${DISK_USAGE_DELTA_2MIN} -ge 1700 ] ; then
	FILESYSTEM_HTML_COLOR="${HTML_YELLOW}"
else
	FILESYSTEM_HTML_COLOR="${HTML_RED}"
fi
sed -i "s:${PLACEHOLDER_FILESYSTEM_COLOR}:${FILESYSTEM_HTML_COLOR}:g" ${OUTFILE}
sed -i "s:${PLACEHOLDER_FILESYSTEM_VALUE}:${DISK_USAGE_DELTA}:g" ${OUTFILE}


# Send SMS Text Message when a streamripper outage is detected.
# Note: File FILESYSTEM_OUTAGE_FILE serves to remember whether an SMS was sent.
if [ "${FILESYSTEM_HTML_COLOR}" == "${HTML_RED}" ] ; then
	if [ -f ${FILESYSTEM_OUTAGE_FILE} ] ; then
		echo "Filesystem outage continues and SMS already sent. Doing nothing."
	else
		echo "Filesystem stopped growing. Sending SMS."
		MSG_BODY="ERR ${SERVICE_PREFIX}: Filesystem not growing ${monitor_url}"
		send_sms_twilio
		touch ${FILESYSTEM_OUTAGE_FILE}
	fi
else # Growing
	if [ -f ${FILESYSTEM_OUTAGE_FILE} ] ; then
		echo "Filesystem is growing. Removing outage file."
        MSG_BODY="OK ${SERVICE_PREFIX}: Filesystem is growing ${monitor_url}"
		send_sms_twilio
		rm ${FILESYSTEM_OUTAGE_FILE}
	else
		echo "Filesystem is growing. Doing nothing."
	fi
fi


# Analyze the last minute of the current MP3 file
### echo ${DELIMITER} >> ${OUTFILE}
### echo "Analyzing last minutes of current MP3 file..." >> ${OUTFILE}
ps -ef | grep streamripper | grep "${SERVICE_RADIOSTREAM}" > ${ERS_TXT_FILE}
echo "Catting ERS_TXT_FILE ${ERS_TXT_FILE}..."
ls -l ${ERS_TXT_FILE}
cat ${ERS_TXT_FILE}
MP3_FILE=`awk '{ printf $12; }' ${ERS_TXT_FILE}`
echo "MP3_FILE=${MP3_FILE}"
echo "Tailing mp3 file >>>${MP3_FILE}<<<..."
tail -c 1000000 ${MP3_DIR}/${DATE}/${MP3_FILE}.mp3 > ${CURRENT_MP3_FILE}
ls -l ${CURRENT_MP3_FILE}
sox ${CURRENT_MP3_FILE} -n stat > ${ERS_TXT_FILE} 2>&1 | tail -1
### cat ${ERS_TXT_FILE} >> ${OUTFILE}
RMS_AMP_FLOAT=`grep RMS ${ERS_TXT_FILE} | grep amplitude | awk '{ print $3 }'`
### echo ${RMS_AMP_FLOAT} >> ${OUTFILE}


# Save the last several minutes of amplitude values
### ls -l ${RMS_AMP_FILE}
### cat ${RMS_AMP_FILE}
echo "Tailing RMS amp file ${RMS_AMP_FILE}.tmp..."
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
if [ ${RMS_INT} -ge 30 ] ; then
	AMPLITUDE_HTML_COLOR="${HTML_GREEN}"
elif [ ${RMS_INT} -ge 10 ] ; then
	AMPLITUDE_HTML_COLOR="${HTML_YELLOW}"
else
	AMPLITUDE_HTML_COLOR="${HTML_RED}"
fi
sed -i "s:${PLACEHOLDER_AMPLITUDE_COLOR}:${AMPLITUDE_HTML_COLOR}:g" ${OUTFILE}
sed -i "s:${PLACEHOLDER_AMPLITUDE_VALUE}:${RMS_INT}:g" ${OUTFILE}


# Append recent buffer/cache memory sizes to bottom of HTML file.
#if [ -f freemem.txt ] ; then
#	echo ${DELIMITER} >> ${OUTFILE}
#	echo "Buffer/cache memory sizes in most recent hours..." >> ${OUTFILE}
#	tail -29 freemem.txt >> ${OUTFILE}
#fi


# Write the current buffer/cache memory size to top of HTML file.
#BUFF_CACHE=`top -bn1 | grep "KiB Mem" | awk '{print $10}'`
#echo "BUFF_CACHE=${BUFF_CACHE}"
#if [ ${BUFF_CACHE} -gt 400000 ] ; then
#	BUFF_CACHE_HTML_COLOR="${HTML_RED}"
#elif [ ${BUFF_CACHE} -gt 330000 ] ; then
#	BUFF_CACHE_HTML_COLOR="${HTML_YELLOW}"
#else
#	BUFF_CACHE_HTML_COLOR="${HTML_GREEN}"
#fi
#sed -i "s:${PLACEHOLDER_BUFF_CACHE_COLOR}:${BUFF_CACHE_HTML_COLOR}:g" ${OUTFILE}
#sed -i "s:${PLACEHOLDER_BUFF_CACHE_VALUE}:${BUFF_CACHE}:g" ${OUTFILE}


# Append current available memory to bottom of log file
AVAIL_MEM=`free -m | grep "Mem:" | awk '{print $7}'`
BUFF_CACHE=`free -m | grep "Mem:" | awk '{print $6}'`
echo "AVAIL_MEM=${AVAIL_MEM}"
echo "${DATE_NOW} avail=${AVAIL_MEM} buff/cache=${BUFF_CACHE}" >> availmem.txt


# Append recent Available memory sizes to bottom of HTML file.
echo ${DELIMITER} >> ${OUTFILE}
echo "Available memory sizes in most recent minutes..." >> ${OUTFILE}
tail -29 availmem.txt >> ${OUTFILE}


# Write the currently available memory size to top of HTML file.
if [ ${AVAIL_MEM} -gt 300 ] ; then
	AVAIL_HTML_COLOR="${HTML_GREEN}"
elif [ ${AVAIL_MEM} -gt 100 ] ; then
	AVAIL_HTML_COLOR="${HTML_YELLOW}"
else
	AVAIL_HTML_COLOR="${HTML_RED}"
fi
sed -i "s:${PLACEHOLDER_AVAIL_COLOR}:${AVAIL_HTML_COLOR}:g" ${OUTFILE}
sed -i "s:${PLACEHOLDER_AVAIL_VALUE}:${AVAIL_MEM}:g" ${OUTFILE}


# Append recent network traffic statistics to bottom of HTML file.
#echo ${DELIMITER} >> ${OUTFILE}
#echo "Network traffic in most recent minutes..." >> ${OUTFILE}
#tail -29 ifstat.txt >> ${OUTFILE}


# Write recent network traffic value to top of HTML file.
#RX_DATA_SEC_ETH=`tail -1 ifstat.txt | awk '{print $2}'`
#echo "RX_DATA_SEC_ETH=${RX_DATA_SEC_ETH}"

#RX_DATA_SEC_WIFI=`tail -1 ifstat.txt | awk '{print $4}'`
#echo "RX_DATA_SEC_WIFI=${RX_DATA_SEC_WIFI}"

#RX_DATA_SEC=`echo "${RX_DATA_SEC_ETH}+${RX_DATA_SEC_WIFI}"|bc`
#echo "RX_DATA_SEC=${RX_DATA_SEC}"

#RX_DATA_MIN=`echo "${RX_DATA_SEC}*60"|bc`
#echo "RX_DATA_MIN=${RX_DATA_MIN}"
#if (( $(echo "${RX_DATA_MIN} > 800" |bc -l) )); then
#	RX_DATA_COLOR="${HTML_GREEN}"
#elif (( $(echo "${RX_DATA_MIN} > 400" |bc -l) )); then
#	RX_DATA_COLOR="${HTML_YELLOW}"
#else
#	RX_DATA_COLOR="${HTML_RED}"
#fi
#sed -i "s:${PLACEHOLDER_RX_DATA_COLOR}:${RX_DATA_COLOR}:g" ${OUTFILE}
#sed -i "s:${PLACEHOLDER_RX_DATA_VALUE}:${RX_DATA_MIN}:g" ${OUTFILE}


# Done
echo ${DELIMITER} >> ${OUTFILE}


# HTML finish
echo "</PRE></BODY></HTML>" >> ${OUTFILE}


# Upload the most recent 4 seconds from the current mp3 file
tail -c 64000 ${MP3_DIR}/${DATE}/${MP3_FILE}.mp3 > ${CURRENT_MP3_FILE}
### scp -o "StrictHostKeyChecking=no" ${CURRENT_MP3_FILE} ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_FOLDER}/
rc=$?
sed -i "s:${PLACEHOLDER_CURRENT_RC_VALUE}:${rc}:g" ${OUTFILE}


# Upload HTML
### scp -o "StrictHostKeyChecking=no" ${OUTFILE} ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_FOLDER}/
### rc=$?
### if [ 0 != ${rc} ] ; then
### 	echo "ERROR ${rc} could not upload output file."
### 	exit 1
### fi


# Also upload the most recent 4 seconds from the current mp3 file
#ps -ef | grep streamripper | grep localhost > ${ERS_TXT_FILE}
#MP3_FILE=`awk '{ printf $11; }' ERS_TXT_FILE`
#tail -c 64000 /media/usb/bmir/${DATE}/${MP3_FILE}.mp3 > ${CURRENT_MP3_FILE}
#scp -o "StrictHostKeyChecking=no" ${CURRENT_MP3_FILE} ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_FOLDER}/

# Experiment to identify processes which get backlogged intermittently.
toplogfile="top.log"
toptmpfile="top.tmp"
# Records the 'top' command from the last few hours.
toplog()
{
        echo $DELIMITER >> $toplogfile
        date >> $toplogfile
        top -bn1 > $toptmpfile
        head -16 $toptmpfile >> $toplogfile
        rm $toptmpfile

        tail -4096 $toplogfile > $toptmpfile
        rm $toplogfile
        mv $toptmpfile $toplogfile
}
toplog
