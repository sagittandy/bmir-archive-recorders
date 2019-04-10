#!/bin/bash
#-----------------------------------------------------------------------
# Starts liquidsoap, which uploads mp3 files to icecast2.
#
# Setup: change hostname 'arc' to the desired hostname
#        place mp3 files in MP3_DIR
#        place testclips.m3u in MP3_DIR
#
# Usage: Run this as a non-root user.
#
#	Run in foreground:  ./start.liquidsoap.sh
#	Run in background:  nohup ./start.liquidsoap.sh &
#
# AD 2017-0610  Copyright BMIR 2017,2019
#-----------------------------------------------------------------------

# Define custom values for Icecast config file.
export ICECAST_PORT=8000
export ICECAST_SOURCE_PASSWORD="sourcepw"
export MP3_DIR="/tmp/mp3"

# todo: add check for non-root user

# Start liquidsoap in the foreground.
liquidsoap "output.icecast(%mp3, host=\"arc\", port=$ICECAST_PORT, password=\"$ICECAST_SOURCE_PASSWORD\", mount=\"bmir\", mksafe(playlist(\"$MP3_DIR/testclips.m3u\")))"




