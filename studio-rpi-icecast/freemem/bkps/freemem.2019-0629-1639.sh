#!/bin/bash
#-----------------------------------------------------------------------
# Checks consumed buff/cache memory, and if excessive, clears it.
#
# Setup: 
# 	Place this file in folder /home/pi/bin/
#
# Usage: 
#	Manual: Run this script as root: 
#
#		./freemem.sh
#
# Automatic execution: Either use systemd timer or cron:
#
# Systemd timer:
#	As root:
#	Move freemem.timer and freemem.service to /etc/systemd/system/
#	systemctl daemon-reload
#	systemctl enable freemem.timer  # Enable timer only
#	systemctl start freemem.timer	# Start timer only
#	systemctl list-timers --all
#
#
# AD 2019-0629-1500 Copyright BMIR 2019
#-----------------------------------------------------------------------
###set +H  # Turn off history expansion in order to use exclamation points in strings.
export DELIMITER="----------------------------------------------------------------------------------"
echo ${DELIMITER}

LOG_FILE="freemem.log"

# Ensure root
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as user root." 
   exit 1
fi
echo "Confirmed user root."


# Get hundredths of seconds from the first 2 digits of nanoseconds.
NANO_SECONDS=`date +%N`
CENTI_SECONDS="${NANO_SECONDS:0:2}"

# Format time as [year - month date - hour minute - seconds centiseconds]
DATE_NOW="`date +%Y-%m%d-%H%M-%S`${CENTI_SECONDS}"
echo "DATE_NOW=${DATE_NOW}"


# Get present buffer/cache value before clearing.
BUFF_CACHE_BEFORE=`top -bn1 | grep "KiB Mem" | awk '{print $10}'`
echo "BUFF_CACHE_BEFORE=${BUFF_CACHE_BEFORE}"


if [ ${BUFF_CACHE_BEFORE} -gt 300000 ] ; then
        # BUFF_CACHE_BEFORE_HTML_COLOR="${HTML_RED}"
	echo "RED"
	echo "Clearing buffer/cache memory..."
	echo 1 > /proc/sys/vm/drop_caches

	# Get present buffer/cache value after clearing.
	BUFF_CACHE_AFTER=`top -bn1 | grep "KiB Mem" | awk '{print $10}'`
	echo "BUFF_CACHE_AFTER=${BUFF_CACHE_AFTER}"

elif [ ${BUFF_CACHE_BEFORE} -gt 100000 ] ; then
        #BUFF_CACHE_BEFORE_HTML_COLOR="${HTML_YELLOW}"
	echo "YELLOW"
else
        # BUFF_CACHE_BEFORE_HTML_COLOR="${HTML_GREEN}"
	echo "GREEN"
fi


