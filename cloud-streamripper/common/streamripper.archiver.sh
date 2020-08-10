#!/bin/bash
#-----------------------------------------------------------------------
# streamripper.archiver.sh
#
# Setup:
#	Place this file in /home/pi/bin/streamripper.archiver.sh
#	Ensure permissions executable
#
# Credits:
# Original name:  KRUIArchiver.sh
# Author:  Tony Andrys
# Original Source:  https://github.com/tonyandrys/kruiarchiver
#
# Stores internet radio streams in two-hour increments and archives them appropriately.
# Originally written for KRUI (http://www.krui.fm), but adaptable anywhere.
# Ripping engine powered by streamripper, written by Greg Sharp (gregsharp@users.sourceforge.net).
# Modified for use by BMIR by Andy 2017-0610
#
# Usage preferred: Run this from systemd/systemctl
#
# Usage interactive: Run this as a non-root user.
#
#	Run in foreground:  ./streamripper.archiver.sh
#	Run in background:  nohup ./streamripper.archiver.sh &
#
# AD 2019-0407-1407 Updated slightly for RPI Raspbian Stretch Lite
# AD 2018-0725-0347
# AD 2017-0610 Copyright BMIR 2017,2019
#-----------------------------------------------------------------------
# Ensure env vars
if [[ -z "${SERVICE_PREFIX}" ]]; then
	echo "INVOCATION ERROR: Environment variable SERVICE_PREFIX is not defined."
	exit 9
fi
if [[ -z "${SERVICE_RADIOSTREAM}" ]]; then
	echo "INVOCATION ERROR: Environment variable SERVICE_RADIOSTREAM is not defined."
	exit 9
fi
if [[ -z "${SERVICE_DEST_PATH}" ]]; then
	echo "INVOCATION ERROR: Environment variable SERVICE_DEST_PATH is not defined."
	exit 9
fi


# Assimilate env vars
PREFIX=${SERVICE_PREFIX}			### bmir
RADIOSTREAM=${SERVICE_RADIOSTREAM}	### http://localhost:8000/bmir
DEST_PATH=${SERVICE_DEST_PATH}		### /home/user/bmir
echo "DEST_PATH=${DEST_PATH}"
ERR_LOG=${DEST_PATH}/error.log
echo "ERR_LOG=$ERR_LOG"


update_timestamp()
{
	# Get hundredths of seconds from the first 2 digits of nanoseconds.
	### NANO_SECONDS=`date +%N`
	### CENTI_SECONDS="${NANO_SECONDS:0:2}"

	# Format time as year - month date - hour minute - seconds centiseconds
	DATE_NOW="`date +%Y-%m%d-%H%M`"     ### -%S`${CENTI_SECONDS}"

	echo "DATE_NOW=${DATE_NOW}"
}


# Create the MP3 directory if it does not already exist.
ls ${DEST_PATH}
rc=$?
if [ 0 != ${rc} ] ; then
        echo "ERROR ${rc} DEST_PATH does not exist. Creating it: ${DEST_PATH}"
        mkdir -p ${DEST_PATH}
fi


while [ 1 -le 2 ]
do

	##
	#Global parameters
	#These are editable, but will eventually be configured through the main interface.
	##
	prefix=${PREFIX} #Prefix used when naming files.
	### stamp=$(date "+%p" | tr '[:upper:]' '[:lower:]') # Yes, this is required because the BSD date won't give you a lowercame am/pm.
	radiostream=${RADIOSTREAM}  # "http://krui.student-services.uiowa.edu:8000/listen.m3u" #Webstream to rip audio from.
	### filename="$prefix--$(date "+%I-%M-%S").$stamp" #Name of outputted file.

	update_timestamp
	filename="$prefix.${DATE_NOW}" #Name of outputted file.
	echo "filename=$filename"

	dest_path=${DEST_PATH}  # "/Users/tony/development/scripts/archives" #Absolute path for recordings. No trailing slash!
	audio_sizecap=300000 #Size cap of audio storage path in megabytes. As the size approaches the cap, emails will be sent.

	# Time algorithm used to calculate the length of the recording.
	currentSeconds=$(date "+%S") #unadjusted with leading zero.
	currentMinutes=$(date "+%M")
	currentHours=$(date "+%H")

	echo "currentMinutes=$currentMinutes"
	echo "currentSeconds=$currentSeconds"
	echo "currentHours=$currentHours"

	# Strip leading zero
	if [ $currentSeconds -eq 0 ]
	then
	    echo "===A==="
	    currentSeconds=0 #Set to zero to avoid issues with cutting "00" by zero
	elif [ $currentSeconds -lt 10 ]
	then
	    echo "===B==="
	    currentSeconds=$(date "+%S" | cut -f 2 -d '0') #Cut the leading zero off of the field if it exists
	fi

	# Strip leading zero
 	if [ $currentMinutes -eq 0 ]
	then
		echo "===C==="
		currentMinutes=0 #Set to zero to avoid issues with cutting "00" by zero
	elif [ $currentMinutes -lt 10 ]
	then
		echo "===D==="
		currentMinutes=$(echo $currentMinutes | cut -f 2 -d '0') #Cut the leading zero off of the field if it exists
	fi

	# Strip leading zero
 	if [ $currentHours -eq 0 ]
	then
		echo "===E==="
		currentHours=0 #Set to zero to avoid issues with cutting "00" by zero
	elif [ $currentHours -lt 10 ]
	then
		echo "===F==="
		currentHours=$(echo $currentHours | cut -f 2 -d '0') #Cut the leading zero off of the field if it exists
	fi

	echo "currentMinutes=$currentMinutes"
	echo "currentSeconds=$currentSeconds"
	echo "currentHours=$currentHours"

	adjSecondsTotal=$(($(($currentMinutes*60)) + $currentSeconds))
	oddEven=$(($currentHours%2))
	if [ $oddEven -eq 0 ]
	then
		durationSecs=7200
	else
		durationSecs=3600
	fi
	echo "durationSecs=$durationSecs adjSecondsTotal=$adjSecondsTotal"
	adjSecondsRemaining=$(($durationSecs - $adjSecondsTotal))
	echo "adjSecondsRemaining=$adjSecondsRemaining"
	riptime=$adjSecondsRemaining

	#logging statement
	echo "# Archiver starting: ($(date "+%m-%d-%y") at $(date "+%I:%M:%S%p"))" >> $ERR_LOG

	echo "---------------------------------"
	echo "-         KRUI Archiver         -"
	echo "---------------------------------"

	# Check that functioning copy of streamripper is available for use
	echo -n "> Checking for streamripper..."
	#/usr/bin/streamripper -v > /dev/null 2>> $ERR_LOG
	which streamripper
	if [ $? == 0 ]
	then
		echo "OK!"
	else
		printf "\n** FATAL ERROR: streamripper cannot be found! Streamripper must in the same directory as this script or in your '$PATH'."
		exit 1
	fi

	# Ensure we have internet access.
	echo -n "> Checking for an internet connection..."
	### ping -c 1 www.google.com > /dev/null 2>> $ERR_LOG
	ping -c 1 localhost > /dev/null 2>> $ERR_LOG
	if [ "$?" == 0 ]
	then
		echo "OK!"
	else
		printf "\n* WARNING: Unable to verify internet access. You may have issues connecting to streams outside of your LAN.\n"
	fi

	# Check if we can access to the storage path...
	echo -n "> Checking if the storage path is writable..."
	if [ -w $dest_path  ]
	then
		echo "OK!"
	else
		echo "** FATAL ERROR: $dest_path is not accessible! Ensure the directory exists and is writable by this application, then restart." | tee -a $ERR_LOG
		exit 1
	fi

	# Get size of audio directory...
	current_size=$(du -sm $dest_path | cut -f 1)

	# Check to see if we need to warn about audio storage path size...
	# Currently configured to warn when we approach 90% of cap
	warn_size=$(($audio_sizecap-$(($audio_sizecap/10))))

	# Ensure a folder to store the ripped file exists before moving on...
	echo -n "> Checking for folder in $dest_path for today's date..."
	### fullpath=$dest_path/$(date "+%m-%d-%y")/
	### result=$(ls $dest_path|grep $(date "+%m-%d-%y"))

	fullpath=$dest_path/$(date "+%m%d")/
	result=$(ls $dest_path|grep $(date "+%m%d"))

	if test -z $result
	then
		printf "\n* $fullpath does not exist! Creating...\n"
		mkdir $fullpath 2>> $ERR_LOG
		if [ $? != 0 ]
		then
			printf "** FATAL ERROR: Could not create $fullpath. Check permissions and try again.\n"| tee -a $ERR_LOG
			exit 1
		fi
	else
		echo "OK!"
	fi

	echo -n "> Checking size of storage directory..."
	if [ $current_size -ge $audio_sizecap  ]
	then
		printf "\n* FATAL ERROR: Audio size cap reached! The application cannot continue.\n" | tee -a $ERR_LOG
		exit 1

	elif [ $current_size -ge $warn_size ]
	then
		printf "\n* WARNING: Audio size is approaching your storage cap. Backup your files soon!\n"
	else
		echo "OK!"
	fi
	printf "\n###\n"
	echo "# Audio will be recorded from $radiostream"
	echo "# Stream will be ripped to disk as $filename.mp3 for $riptime seconds."
	echo "# Finished audio will be stored to $fullpath"
	echo "# Audio storage directory is currently $(echo $current_size)MB of the $(echo $audio_sizecap)MB cap."
	printf "###\n\n"
	# AD 2019-0612 Added -A option (uppercase) to suppress splits based on ID3 metadata.
	/usr/bin/streamripper $radiostream -A -a $filename -s -l $riptime -d $fullpath -c
	echo "Recording has halted!"
	printf "> Appending stop time to ripped file... \n"
	cd $fullpath
	base=$(basename $filename .mp3)
	### newfilename=$base-$(date "+%I-%M-%S").$stamp.mp3

	update_timestamp
	newfilename="$base.${DATE_NOW}.mp3" #Name of outputted file.
	echo "newfilename=$newfilename"



	mv $base.mp3 $newfilename 2>> $ERR_LOG
	if [ "$?" == 0 ]
	then
		echo "OK! ($newfilename)"
	else
		echo "* WARNING: Could not rename file."
	fi
	printf "> Cleaning up cuesheets...\n"
	rm *.cue > /dev/null 2>> $ERR_LOG
	cd ..
	echo "OK!"
	echo "# Archiver shutting down: ($(date "+%m-%d-%y") at $(date "+%I:%M:%S%p"))" >> $ERR_LOG
done
