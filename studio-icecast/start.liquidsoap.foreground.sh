#!/bin/bash

export DELIMITER="-----------------------------------------------------"

# Define custom values for Icecast config file.
export ICECAST_PORT=8000
export ICECAST_SOURCE_PASSWORD="sourcepw"
export MP3_DIR="/tmp/mp3"

# Start liquidsoap in the foreground.
liquidsoap "output.icecast(%mp3, host=\"localhost\", port=$ICECAST_PORT, password=\"$ICECAST_SOURCE_PASSWORD\", mount=\"testclips\", mksafe(playlist(\"$MP3_DIR/testclips.m3u\")))"



