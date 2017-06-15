#!/bin/bash
#-----------------------------------------------------------------------
# Starts liquidsoap, which uploads mp3 files to icecast2.
#
# Usage: Run this as a non-root user.
#
#	Run in foreground:  ./start.liquidsoap.sh
#	Run in background:  nohup ./start.liquidsoap.sh &
#
# AD 2017-0610  Copyright BMIR 2017
#-----------------------------------------------------------------------

# Define custom values for Icecast config file.
export ICECAST_PORT=8000
export ICECAST_SOURCE_PASSWORD="sourcepw"
export MP3_DIR="/tmp/mp3"

# Start liquidsoap in the foreground.
liquidsoap "output.icecast(%mp3, host=\"localhost\", port=$ICECAST_PORT, password=\"$ICECAST_SOURCE_PASSWORD\", mount=\"testclips\", mksafe(playlist(\"$MP3_DIR/testclips.m3u\")))"



