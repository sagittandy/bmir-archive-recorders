#!/bin/bash
#-----------------------------------------------------------------------
# Launches FFMPEG to upload one mp3 file to an icecast2 server.
#
# Design point: This script is intended to be run from cron or other scheduler.
#   Schedule one instance with the name of the MP3 file.
#
# Design point: Only one instance of this script and ffmpeg may run at one time.
# When it starts, this script kills all other instances of this script and ffmpeg.
#
# Design point: This script tries to keep ffmpeg running continuously.
#   If it detects that ffmpeg is not running, it restarts it.
#   To ensure reasonable audio program continuity, it restarts ffmpeg
#   from the point in time in the MP3 at which it should have been playing.
#
# Caution: Be sure schedule invocations do not overlap.
#   If they do overlap, the latest schedule will win.
#
# Prereqs:
#       - Set all environment variables as checked in verify_vars().
#       - Install mp3info
#
# Invocation:
#       ./launch.ffmpeg.with.restart.sh <MP3_FILE_NAME>
#
# Note: Run this as a non-root user.
#
# AD 2020-0812 Copyright BMIR 2020
#-----------------------------------------------------------------------
export DELIM0="=================================================================================="
export DELIM1="----------------------------------------------------------------------------------"
logfile="/home/vmadmin/autodj.log"  # Hard-code a single fixed log file for any/all users


delim0()
{
    echo $DELIM0
	echo $DELIM0 >> $logfile
}


delim1()
{
    echo $DELIM1
	echo $DELIM1 >> $logfile
}


logmsg()
{
	date=`date`
	msg="$date: $$: $msg"
	echo $msg
	echo $msg >> $logfile
}


verify_vars()
{
    for VAR in FFMPEG_USERNAME FFMPEG_PASSWORD FFMPEG_HOST FFMPEG_PORT FFMPEG_MOUNT MP3_DIR MP3_FILE ; do
        if [[ -z "${!VAR}" ]] ; then
            msg="ERROR: Variable $VAR does not exist." ; logmsg
            EXIT_ERROR="True"
        fi
    done
    if [[ ! -z "${EXIT_ERROR}" ]] ; then
        msg="EXIT. ERROR. One or more variables do not exist." ; logmsg
        exit 9
    else
        msg="Ok. All required variables exist." ; logmsg
    fi
}


kill_all_clones()
{
    # Kills all other instances of this script (launched by the same user).
	tmpfile="$$.tmp"
	myfile=`basename "$0"`
	#msg="tmpfile=$tmpfile myfile=$myfile"; logmsg
	ps -ef | grep "${myfile}" | grep -v grep | grep -v $$ > $tmpfile
	while read p; do
		#msg="p: $p" ; logmsg
		stringarray=($p)
		clone_pid="${stringarray[1]}"
		msg="Killing clone pid: $clone_pid" ; logmsg
		kill $clone_pid
		msg="rc=$?" ; logmsg
	done <$tmpfile
	rm tmpfile
}


kill_all_ffmpegs()
{
    msg="Killing ALL running instances of ffmpeg..." ; logmsg
    ps -ef | grep "ffmpeg -re" | grep -v grep
    rc=$?
    if [ 0 != ${rc} ] ; then
        msg="No instances of ffmpeg are running." ; logmsg
    else
        msg="One or more ffmpegs are running. Killing all instances of ffmpeg..." ; logmsg
        killall ffmpeg
    fi
}


kill_my_ffmpegs()
{
    msg="Killing instances of ffmpeg launched by THIS script..." ; logmsg
	tmpfile="$$.tmp"
	myfile=`basename "$0"`
	msg="tmpfile=$tmpfile myfile=$myfile" ; logmsg
	ps -ef | grep "ffmpeg" | grep -v "${myfile}" | grep -v grep > $tmpfile
	cat $tmpfile
	while read p; do
		#msg="p: $p" ; logmsg
		stringarray=($p)
		ffmpeg_pid="${stringarray[1]}"
		launcher_pid="${stringarray[2]}"
		msg="ffmpeg_pid=$ffmpeg_pid launcher_pid=$launcher_pid" ; logmsg
		if [ "$$" == "$launcher_pid" ] ; then
			msg="Killing my ffmpeg." ; logmsg
			kill $ffmpeg_pid
			msg="rc=$?" ; logmsg
		else
			msg="Not my ffmpeg." ; logmsg
		fi
	done <$tmpfile
	rm $tmpfile
}


#- - - - - - - - -
# Here we go.
#- - - - - - - - -
delim0

# Ensure non-root
msg="Checking for non-root user." ; logmsg
if [[ $EUID -eq 0 ]]; then
   msg="INVOCATION ERROR: This script must be run as a non-root user." ; logmsg
   exit 1
fi


# Checking parameter count..."
if [ $# -ne 1 ] ; then
    msg="USER INVOCATION ERROR: Wrong number of parameters. Enter ./launch.ffmpeg.with.restart.sh <MP3_FILE_NAME>" ; logmsg
    exit 9
fi


# Getting Parms...
MP3_FILE=${1}
msg="MP3_FILE=${MP3_FILE}" ; logmsg


# Check env vars and cmdline parms...
verify_vars


# Ensure MP3 directory exists
msg="Checking that MP3 directory exists." ; logmsg
ls ${MP3_DIR}
rc=$?
if [ 0 != ${rc} ] ; then
	msg="INVOCATION ERROR: MP3 file directory ${MP3_DIR} does not exist." ; logmsg
	exit 1
fi
msg="OK. MP3 directory exists: ${MP3_DIR}" ; logmsg


# Ensure file exists
msg="Checking that MP3 file exists." ; logmsg
ls ${MP3_DIR}/${MP3_FILE}
rc=$?
if [ 0 != ${rc} ] ; then
        msg="INVOCATION ERROR: MP3 file does not exist: ${MP3_DIR}/${MP3_FILE}" ; logmsg
        exit 1
fi
msg="OK. MP3 file exists: ${MP3_FILE}" ; logmsg


# Check that mp3info exists.
which mp3info
rc=$?
if [ 0 != ${rc} ] ; then
    msg="ENVIRONMENT ERROR: mp3info is not installed or is not executable in path." ; logmsg
    exit 1
fi


# Kill any running instances of this script.
kill_all_clones


# Kill any languishing instances of ffmpeg.
kill_all_ffmpegs


# Calculate the total playing time of the MP3 file.
mp3_length_secs=`mp3info -p %S ${MP3_DIR}/${MP3_FILE}`
### msg="mp3_length_secs=${mp3_length_secs}" ; logmsg


# Set default sleep time.
sleep_secs_default=3


# Show parms.
msg="mp3_length_secs=${mp3_length_secs}s. sleep_secs_default=${sleep_secs_default}" ; logmsg


# Get the number of seconds since the epoch.
date_now=`date +%s`
date_start=${date_now}
msg="date_start=${date_start}" ; logmsg


# Calculate the stop time.
date_stop=$((${date_start}+${mp3_length_secs}))
msg="date_stop=${date_stop}" ; logmsg


#-----------------------------------------------------------------------
# Check repeatedly that ffmpeg is running.
# Restart ffmpeg if it dies, starting from the appropriate offset.
#-----------------------------------------------------------------------

while (( ${date_stop} > ${date_now} )); do
    secs_elapsed=$(( ${date_now} - ${date_start} ))
    secs_remaining=$(( ${date_stop} - ${date_now} ))

    if (( ${secs_remaining} > 7)); then
        sleep_secs=${sleep_secs_default}

        msg="Checking all instances of ffmpeg..." ; logmsg
        ps -ef | grep "ffmpeg -re" | grep -v grep
        rc=$?
        if [ 0 != ${rc} ] ; then
            seek_secs=${secs_elapsed}
            delim1
            msg="FFMPEG IS NOT running. Starting ffmpeg at ${seek_secs}s." ; logmsg
            nohup ffmpeg -re -ss ${seek_secs} -i ${MP3_DIR}/${MP3_FILE} -f mp3 icecast://${FFMPEG_USERNAME}:${FFMPEG_PASSWORD}@${FFMPEG_HOST}:${FFMPEG_PORT}/${FFMPEG_MOUNT} &
            sleep 1
            ### ps -ef | grep "ffmpeg -re" | grep -v grep # For debug only
            delim1
        else
            msg="Ok. ffmpeg is running." ; logmsg
        fi
    else
        # Do not try to restart ffmpeg this close to the end.
        sleep_secs=$((${secs_remaining}+7))
    fi

    msg="Time elapsed=${secs_elapsed}s. Time remaining=${secs_remaining}s. Sleeping for ${sleep_secs}s." ; logmsg
    sleep ${sleep_secs}

    date_now=`date +%s`
    ### msg="date_now=${date_now} date_stop=${date_stop}" ; logmsg
done


# Kill any languishing instances of ffmpeg STARTED BY THIS SCRIPT ONLY.
kill_my_ffmpegs


 msg="Exit. Elapsed time=${secs_elapsed}s." ; logmsg
