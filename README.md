# BMIR Internet Radio Archive Recorders

This project contains the scripts to install and configure several different internet radio archive recorders used at Burning Man Information Radio (BMIR 94.5 FM), at the annual Burning Man festival, in Black Rock City, Nevada, USA.

Several tools and techniques have been used to record the archives over the years.  As they have grown more diverse and complicated, his github project was created to store and share the scripts.


![Image of BMIR](https://raw.githubusercontent.com/sagittandy/bmir-archive-recorders/master/pix/bmir.archivers.2017.png)


## Studio Icecast + Streamripper on a Raspberry Pi microcomputer

These two processes will run on one raspberry pi microcomputer in the studio.  Orban Opticodec will 'upload' a digitized music stream to this icecast2 server (in addition to uploading to several music servers on the public internet.).  Streamripper on the RPI 'listens' to the stream from icecast on the RPI, and records it to mp3 files on the RPI.

This is the same Icecast + Streamripper technique which was used the last two years running on a computer, but now running on an RPI.  All the setup scripts were revamped and cleaned up, and are published in this repo in folder studio-rpi-icecast.

The RPI capabilities are similar to the desktop computer, including SSH tunnel for remote debug, and an auto-uploader to transfer MP3 files to a cloud server.  In addition, a script has been developed to publish rudimentary OS stats to the cloud server (such as CPU utilization, memory consumption, etc)

Benefits of RPI vs desktop computer are smaller size and lighter weight (good for transporting cross-country!), lower power, lower heat, and less dust susceptibility.

Expected design challenges unique to the RPI include selecting a highly-available power supply design, and trying to minimize wearing writes to the SDCard.

The RPI archiver is new and experimental at Burning Man 2019!!

## SSH tunnel for remote access

For Burning Man 2018, scripts were developed to implement an SSH tunnel from a cloud server to the archiver machine in the studio.  This allowed the author to SSH into the machine after he left Burning Man early, and do any required mantainence remotely.

This was first used at Burning Man 2018.

## Automatic uploader

During Burning Man 2018, scripts were written on-playa (actually in the developer's tent) to automatically upload the mp3 files from the icecast/streamripper computer in the studio to a cloud server, every two hours.  This serves as backup, and makes the files available for organization sooner.  And it eliminated the daily backup effort of copying mp3 files to USB keys!

The uploader was first used at Burning Man 2018.

## Studio Icecast + Streamripper on a desktop computer

These two processes will run on one standalone Ubuntu Linux computer in the studio.  Orban Opticodec will 'upload' a digitized music stream to this icecast2 server (in addition to uploading to several music servers on the public internet.).  Streamripper 'listens' to the stream from icecast and records it to mp3 files.

This technique was first used at Burning Man 2017.

## Studio TotalRecorder

A Behringer UMC204HD Audio Interface in the studio digitizes baseband audio from the studio mixer and transfers it via USB cable to an HP desktop computer in the studio.  The computer runs Windows 7 and commercial audio recorder software TotalRecorder.  http://www.totalrecorder.com/  TotalRecorder is configured to repeatedly record audio to mp3 files in 2-hour segments, synchronized with clock time.  MP3 files are manually copied to USB thumb drive daily, to provide backups.  Note:  This computer does not have antivirus software installed and is intentionally never connected to the internet.  TotalRecorder was first used in 2016.  TotalRecorder was not used in 2018.

## Android FM Recorder

A Motorola Moto-E android smartphone is used to record BMIR off-air.  The Moto-E contains internal FM receiver hardware.  An FM radio app authored by Motorola was installed.  The app free-runs continuously, and is set up to store AAC files to micro-SD memory chip.  The recorder app is manually stopped and immediately restarted every 6-12 hours to split the AAC files into manageable size.  The phone was powered by a 12-volt battery (UB12120) and 5v USB charger, housed in a Harbor Freight ammo box (#61451), in the archivist's tent.  It was first used in 2016.

A new Motorola Moto-E4 was purchased for use at Burning Man 2018.  This was used as a backup recorder, recording BMIR off-air from 94.5 FM.  It was operated by another volunteer at BMIR who stayed longer than I did.

## Offsite Streamripper

Streamripper has been run on an Ubuntu Linux VM at Digital Ocean for many years (starting 2010?).  It is configured to record mp3 files in 4-hour segments (unsynchronized to clock time).  It works well, but is subject to frequent outages due to the unreliable connection between the studio at Burning Man and internet routers in the default world.

## Uploader

This python script continuously uploads completed mp3 files from the studio to a cloud server, in order to provide backup.  It runs on the linux computer in the studio which houses icecast2 and streamripper.  The script uses scp to upload mp3 files, and relies upon ssh-key authentication being in place.  The script also calculates and compares md5sums for the local and remote files to ensure accuracy.  A json file in the studio computer contains the names of each file which has already been successfully uploaded, to avoid duplicate uploads.  The python script is invoked by cron, at ten minutes past every hour.  This uploader script was written on the playa, and first used, at Burning Man 2018.
