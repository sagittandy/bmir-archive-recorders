#!/bin/bash

# RUN THIS AS ROOT!!!

icecast2 -b -c /etc/icecast2/icecast.xml

netstat -na | grep LIST | grep 8000
ps -ef | grep icecast | grep -v grep  

