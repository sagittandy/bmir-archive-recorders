#!/bin/bash
# streamripper.archiver.sh
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
# Usage: Run this as a non-root user.
#
#	Run in foreground:  ./streamripper.archiver.sh
#	Run in background:  nohup ./streamripper.archiver.sh &
#
###
PREFIX=BMIR
RADIOSTREAM=http://localhost:8000/bmir
### DEST_PATH=/tmp/mp3/streamripper
DEST_PATH=/home/ding/bmir2017

while [ 1 -le 2 ]
do

	##
	#Global parameters
	#These are editable, but will eventually be configured through the main interface.
	##
	prefix=${PREFIX} #Prefix used when naming files.
	stamp=$(date "+%p" | tr '[:upper:]' '[:lower:]') # Yes, this is required because the BSD date won't give you a lowercame am/pm.
	radiostream=${RADIOSTREAM}  # "http://krui.student-services.uiowa.edu:8000/listen.m3u" #Webstream to rip audio from.
	filename="$prefix--$(date "+%I-%M-%S").$stamp" #Name of outputted file.
	dest_path=${DEST_PATH}  # "/Users/tony/development/scripts/archives" #Absolute path for recordings. No trailing slash!
	audio_sizecap=300000 #Size cap of audio storage path in megabytes. As the size approaches the cap, emails will be sent.

	# Time algorithm used to calculate the length of the recording.
	currentSeconds=$(date "+%S") #unadjusted with leading zero.
	currentMinutes=$(date "+%M")
	currentHour=$(date "+%H")
	if [ $currentSeconds -eq 0 ]
	then
	    currentSeconds=0 #Set the date to zero to avoid issues with cutting "00" by zero
	elif [ $currentSeconds -lt 10 ]
	then
		currentSeconds=$(date "+%S" | cut -f 2 -d '0') #Cut the leading zero off of the field if it exists
	fi
	adjSecondsTotal=$(($(($currentMinutes*60)) + $currentSeconds))
	oddEven=$(($currentHour%2))
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
	echo "# Archiver starting: ($(date "+%m-%d-%y") at $(date "+%I:%M:%S%p"))" >> error.log

	echo "---------------------------------"
	echo "-         KRUI Archiver         -"
	echo "---------------------------------"

	# Check that functioning copy of streamripper is available for use
	echo -n "> Checking for streamripper..."
	/usr/bin/streamripper -v > /dev/null 2>> error.log
	if [ $? == 0 ]
	then
		echo "OK!"
	else
		printf "\n** FATAL ERROR: streamripper cannot be found! Streamripper must in the same directory as this script or in your '$PATH'."
		exit 1
	fi

	# Ensure we have internet access.
	echo -n "> Checking for an internet connection..."
	### ping -c 1 www.google.com > /dev/null 2>> error.log
	ping -c 1 localhost > /dev/null 2>> error.log
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
		echo "** FATAL ERROR: $dest_path is not accessible! Ensure the directory exists and is writable by this application, then restart." | tee -a error.log
		exit 1
	fi

	# Get size of audio directory...
	current_size=$(du -sm $dest_path | cut -f 1)

	# Check to see if we need to warn about audio storage path size...
	# Currently configured to warn when we approach 90% of cap
	warn_size=$(($audio_sizecap-$(($audio_sizecap/10))))

	# Ensure a folder to store the ripped file exists before moving on...
	echo -n "> Checking for folder in $dest_path for today's date..."
	fullpath=$dest_path/$(date "+%m-%d-%y")/
	result=$(ls $dest_path|grep $(date "+%m-%d-%y"))

	if test -z $result
	then
		printf "\n* $fullpath does not exist! Creating...\n"
		mkdir $fullpath 2>> error.log
		if [ $? != 0 ]
		then
			printf "** FATAL ERROR: Could not create $fullpath. Check permissions and try again.\n"| tee -a error.log
			exit 1
		fi
	else
		echo "OK!"
	fi

	echo -n "> Checking size of storage directory..."
	if [ $current_size -ge $audio_sizecap  ]
	then
		printf "\n* FATAL ERROR: Audio size cap reached! The application cannot continue.\n" | tee -a error.log
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
	/usr/bin/streamripper $radiostream -a $filename -s -l $riptime -d $fullpath -c
	echo "Recording has halted!"
	printf "> Appending stop time to ripped file... \n"
	cd $fullpath
	base=$(basename $filename .mp3)
	newfilename=$base-$(date "+%I-%M-%S").$stamp.mp3
	mv $base.mp3 $newfilename 2>> ../error.log
	if [ "$?" == 0 ]
	then
		echo "OK! ($newfilename)"
	else
		echo "* WARNING: Could not rename file."
	fi
	printf "> Cleaning up cuesheets...\n"
	rm *.cue > /dev/null 2>> ../error.log
	cd ..
	echo "OK!"
	echo "# Archiver shutting down: ($(date "+%m-%d-%y") at $(date "+%I:%M:%S%p"))" >> error.log
done
