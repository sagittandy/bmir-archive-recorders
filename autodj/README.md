# AutoDJ

These scripts provide upload capability for an mp3 file.  They use ffmpeg to stream an mp3 file to a liquidsoap server in support of DJs who submitted pre-recorded shows (instead of streaming live).  They were designed to be invoked from cron or the cmd line.

There are two versions of the script:

*launch.ffmpeg.with.restart.sh*  This was the original script. It was used in production during BM2020. It was invoked by cron.  Its main feature is ensuring that ffmpeg continues to run, and if ffmpeg dies, the script restarts ffmpeg from the correct time offset into the program (aka seek).  However, this script lacks the feature of being able to start the script manually after the scheduled start time (because when the script starts, it always starts the program at time zero).

*launch.ffmpeg.scheduled.sh*  This is a newer version of the script.  It was tested but not used in production.  This script adds the feature of being able to start/restart the script after the program's scheduled start time, and the script starts ffmpeg at the appropriate offset.

For future events, the newer script is recommended.
