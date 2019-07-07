#!/bin/bash

ifstat -t -n -d proc 1/60 >> /home/pi/bin/ifstat.txt
