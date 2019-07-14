'''----------------------------------------------------------------------
uploader.py

This script uploads mp3 files from the BMIR icecast/streamripper/archiver
machine located in the BMIR on-playa studio to another linux box 
located in the cloud which is accessible by scp via sshkey auth.

Also verifies files on both sides have same md5sum

Prereqs:  
	- The user account running this program must have SSH KEY auth
	  to access the target cloud server.

	- The hostname of the target cloud server must be defined
	  in /etc/hosts

	- The config file must be in the same folder as where
	  this program is invoked: /home/pi/bin/

	- Create destination folder in target cloud server
	  as specified in uploader.json.  Example /home/pi/bmir/

Setup:
	Move files to /home/pi/bin/:
		uploader.json
		uploader.py
		uploader.sh (ensure file permission executable)

	Set up cron to run this every two hours
		As user pi (the user which will run this python script),
			crontab -e
		Add line
			10 * * * * cd /home/pi/bin && ./uploader.sh

		Cron specification tester: https://crontab.guru/

Usage: Intended to be invoked at 10 mins past every hour (by cron)
       to upload the latest mp3 file from the archiver whenever available.

       (Because the archiver generates new files every two hours,
       this script will upload every two hours, and do nothing inbetween.)

AD 2019-0714-1700 Enhanced to check remote MD5s first before uploading
AD 2019-0407-2247 Updated slightly for RPI
AD 2018-0823-0922 (written from scratch on-playa, so no snark please!)
AD 2018-0823-0922 Copyright BMIR 2018,2019
----------------------------------------------------------------------'''
from subprocess import Popen, PIPE
import shlex
import json
import os.path
import sys
import time

# Hard-code everything to simplify invocation from cron
USERNAME = 'pi'
HOSTNAME = 'dobmir'
CONFIG_FILE = 'uploader.json'
global g_loglevel
g_loglevel = 5

delimeter = '-------------------------------------------------'


def getSopTimestamp():
    """Returns the current system timestamp in a nice format."""
    formatting_string = "[" + "%" + "Y-" + "%" + "m" + "%" + "d-" + "%" + "H" + "%" + "M-" + "%" + "S00]"
    return time.strftime(formatting_string)


def sop(msgloglevel,methodname,message):
    """Prints the specified method name and message with a nicely formatted timestamp.
    (sop is an acronym for System.out.println() in java)"""
    global g_loglevel

    timestamp = getSopTimestamp()
    if msgloglevel <= g_loglevel:
        print "%s %s: %s" % (timestamp, methodname, message)


def show_exitcode_stdout_stderr(exitcode, out, err):
	'''Prints the specified values.'''
	sop(5,"","exitcode: %i" % exitcode)
	sop(5,"","out: " + out)
	sop(5,"","err: " + err)


def make_remote_directory(username, hostname, fully_qualified_dirname):
	'''Issues an SSH command to the specified machine to
	create the specified fully qualified directory.

	Returns the exitcode (zero=success).'''
	m = 'make_remote_directory'

	target = username + '@' + hostname

	sop(3,m,'Entry. Creating directory %s' % (fully_qualified_dirname))

	# Define the command. 
	args = ['ssh', target, 'mkdir', '-p', fully_qualified_dirname]

	for arg in args:
		sop(5,m,'arg: >>>%s<<<' % arg)

	proc = Popen(args, stdout=PIPE, stderr=PIPE)
	out, err = proc.communicate()
	exitcode = proc.returncode
	show_exitcode_stdout_stderr(exitcode, out, err)

	if 0 == exitcode:
		sop(3,m,'Exit. Created directory %s' % (fully_qualified_dirname))
	else:
		sop(0,m,'EXIT/ERROR: Directory not created. Returning ' + exitcode)

	return exitcode


def get_remote_file_md5sum(username, hostname, fully_qualified_filename):
	'''Issues an SSH command to the specified machine which
	calculates the MD5SUM of the specified fully qualified file.
	Returns the exitcode (zero=success) and md5sum string on success.'''
	m = 'get_remote_file_md5sum'
	md5sum = 'UNDEFINED'

	target = username + '@' + hostname

	# Define the command. 
	args = ['ssh', target, 'md5sum', fully_qualified_filename]

	for arg in args:
		sop(5,m,'arg: >>>%s<<<' % arg)

	proc = Popen(args, stdout=PIPE, stderr=PIPE)
	out, err = proc.communicate()
	exitcode = proc.returncode
	show_exitcode_stdout_stderr(exitcode, out, err)

	if 0 == exitcode:
		args = shlex.split(out)
		md5sum = args[0]
		sop(5,m,'extracted md5sum: >>>%s<<<' % (md5sum))

	return exitcode, md5sum


# Works but not needed...
#
#def get_remote_file_exists(username, hostname, fully_qualified_filename):
#	'''Issues an SSH command to the specified machine which
#	determines whether the specified fully qualified file exists.
#	Returns the exitcode (zero=success).'''
#	m = 'get_remote_file_exists'
#
#	target = username + '@' + hostname
#
#	# Define the command. 
#	args = ['ssh', target, 'ls', fully_qualified_filename]
#
#	for arg in args:
#		sop(5,m,'arg: >>>%s<<<' % arg)
#
#	proc = Popen(args, stdout=PIPE, stderr=PIPE)
#	out, err = proc.communicate()
#	exitcode = proc.returncode
#	show_exitcode_stdout_stderr(exitcode, out, err)
#
#	return exitcode
#


def upload_file(username, hostname, fully_qualified_local_filename, fully_qualified_remote_filename):
	'''Issues an SCP command to upload the specified file.
	Returns the exitcode (zero=success) on success.'''
	m = 'upload_file'

	target = username + '@' + hostname + ':' + fully_qualified_remote_filename

	# Define the command. 
	args = ['scp', '-p', fully_qualified_local_filename, target]

	sop(3,m,'Entry. Uploading %s to %s' % (fully_qualified_local_filename, target))
	for arg in args:
		sop(5,m,'arg: >>>%s<<<' % arg)

	proc = Popen(args, stdout=PIPE, stderr=PIPE)
	out, err = proc.communicate()
	exitcode = proc.returncode
	show_exitcode_stdout_stderr(exitcode, out, err)

	if 0 == exitcode:
		sop(3,m,'Exit. Uploaded %s to %s' % (fully_qualified_local_filename, target))
	else:
		sop(0,m,'EXIT/ERROR: File not uploaded: %s. Returning %s' % (fully_qualified_local_filename, exitcode))

	return exitcode


def get_local_file_md5sum(fully_qualified_filename):
	'''Calculates the MD5SUM of the specified fully qualified local file.
	Returns the exitcode (zero=success) and md5sum string on success.'''
	m = 'get_local_file_md5sum'
	md5sum = 'UNDEFINED'

	# Define the command.  Dash-a preserves timestamp.
	args = ['md5sum', fully_qualified_filename]

	for arg in args:
		sop(5,m,'arg: >>>%s<<<' % arg)

	proc = Popen(args, stdout=PIPE, stderr=PIPE)
	out, err = proc.communicate()
	exitcode = proc.returncode
	show_exitcode_stdout_stderr(exitcode, out, err)

	if 0 == exitcode:
		args = shlex.split(out)
		md5sum = args[0]
		sop(5,m,('extracted md5sum: >>>%s<<<' % (md5sum)))

	return exitcode, md5sum


def analyze_files(currentMp3FilePrefix):
	'''Reads config file, looks at existing local files,
	then uploads any files which have not been uploaded.'''
	m = 'analyze_files'

	sop(3,m,'Entry. currentMp3FilePrefix=%s' % (currentMp3FilePrefix))

	# Ensure config file exists.
	if not os.path.isfile(CONFIG_FILE):
		sop(0,m,'INVOCATION ERROR: Config file does not exist: %s' % (CONFIG_FILE))
		sys.exit(-1)

	# Open config file.
	with open(CONFIG_FILE) as f:
		config = json.load(f)

	# Extract values from config file.
	local_base_dir = config['local_base_dir']
	remote_base_dir = config['remote_base_dir']
	uploaded_files = config['uploaded_files']

	# debug
	sop(5,m,'local_base_dir: %s' % (local_base_dir))    
	sop(5,m,'remote_base_dir: %s' % (remote_base_dir))    
	sop(5,m,'len(uploaded_files): %i' % (len(uploaded_files)))

	# Ensure local base directory exists.
	if not os.path.isdir(local_base_dir):
		sop(0,m,'INVOCATION ERROR: local base directory does not exist: %s' % (local_base_dir))
		sys.exit(-1)

	# Note: We do not need to ensure remote base directory exists
	# because code below automatically creates it.

	# Examine each directory under the local_base_dir.
	local_dir_list = os.listdir(local_base_dir)
        for local_dir in local_dir_list:
		sop(5,m,'local dir: %s' % (local_dir))
		fq_local_dir = os.path.join(local_base_dir, local_dir)
		sop(5,m,'fq_local dir: %s' % (fq_local_dir))

		# Ensure directory.
		if not os.path.isdir(fq_local_dir):
			sop(5,m,'Not directory. Continuing.')
			continue

		# Examine each mp3 file under each directory.
		local_mp3_list = os.listdir(fq_local_dir)
	        for local_mp3 in local_mp3_list:
			sop(5,m,'local mp3: %s' % (local_mp3))
			fq_local_mp3 = os.path.join(fq_local_dir, local_mp3)
			sop(5,m,'fq_local mp3: %s' % (fq_local_mp3))
			mp3_suffix = os.path.join(local_dir, local_mp3)
			sop(5,m,'mp3 suffix: %s' % (mp3_suffix))
		
			# Ensure file.
			if not os.path.isfile(fq_local_mp3):
				sop(3,m,'Not file. Continuing.')
				continue

			# Ensure mp3
			if not local_mp3.endswith('.mp3'):
				sop(3,m,'Not mp3. Continuing.')
				continue

			# Ignore currently in-process recording file.
			# Evaluate parameter passed-in by uploader.sh: CURRENT_MP3_FILE_PREFIX
			if local_mp3 == currentMp3FilePrefix + '.mp3':
				sop(3,m,'Skip currently recording file. %s' % (local_mp3))
				continue

			# Check if local mp3 file has been uploaded.
			if mp3_suffix not in uploaded_files:
				sop(3,m,'Uploading: %s' % (mp3_suffix))

				fq_remote_dir = remote_base_dir + '/' + local_dir
				fq_remote_mp3 = fq_remote_dir + '/' + local_mp3

				# debug
				sop(5,m,'fq_remote_dir: %s' % (fq_remote_dir))
				sop(5,m,'fq_remote_mp3: %s' % (fq_remote_mp3))

				# Create the remote directory.
				rc = make_remote_directory(USERNAME, HOSTNAME, fq_remote_dir)
				if 0 != rc: 
					sop(0,m,'EXIT ERROR: Could not create remote directory' + local_dir)
					sys.exit(-1)

				# Get the MD5SUM of the local file.
				rc,local_md5sum = get_local_file_md5sum(fq_local_mp3)
				if 0 != rc: 
					sop(0,m,'EXIT ERROR: Could not get local md5sum: %s' % (fq_local_mp3))
					sys.exit(-1)
				sop(5,m,'===> %s' % (local_md5sum))

				# Check if the remote file already exists by getting its MD5SUM.
				rc,remote_md5sum = get_remote_file_md5sum(USERNAME, HOSTNAME, fq_remote_mp3)
				sop(5,m,'===> rc=%i local_md5sum=%s remote_md5sum=%s' % (rc, local_md5sum, remote_md5sum))
				if 0 != rc or local_md5sum != remote_md5sum:
					sop(0,m,'Uploading file because remote file does not exist or MD5SUMs are not equal')

					# Upload the mp3 file if the remote does not already exist or MD5SUMs don't match.
					rc = upload_file(USERNAME, HOSTNAME, fq_local_mp3, fq_remote_mp3)
					if 0 != rc: 
						sop(0,m,'EXIT ERROR: Could not upload file: ' + fq_remote_mp3)
						sys.exit(-1)

					# Get the MD5SUM of the uploaded remote file.
					rc,remote_md5sum = get_remote_file_md5sum(USERNAME, HOSTNAME, fq_remote_mp3)
					if 0 != rc: 
						sop(0,m,'EXIT ERROR: Could not get remote md5sum: %s' % (fq_remote_mp3))
						sys.exit(-1)
					sop(5,m,'===> %s %s' % (local_md5sum, remote_md5sum))

				# Ensure MD5SUMs for local and remote files match after upload.				
				if local_md5sum != remote_md5sum:
					sop(0,m,'EXIT ERROR: MD5SUMs are not equal')
					sys.exit(-1)

				# Add the filename to the config database.
				uploaded_files.append(mp3_suffix)
				with open(CONFIG_FILE, 'w') as outfile:
					json.dump(config, outfile)

	sop(3,m,'Exit.')



# - - - - - - - - - - - -

m = 'UNIT_TEST'


#print delimeter
# UNIT TEST get-remote-md5sum - happy path
#exitcode,md5sum = get_remote_file_md5sum(USERNAME, HOSTNAME, '/home/pi/bmir2018/ice/0822/bmir.2018-0822-0000.2018-0822-0200.mp3')
#sop(5,m,'exitcode=%i' % (exitcode))
#sop(5,m,'md5sum=%s' % (md5sum))

#print delimeter
# UNIT TEST get-remote-md5sum - file not found
#exitcode,md5sum = get_remote_file_md5sum(USERNAME, HOSTNAME, '/home/pi/bmir2018/ice/0822/testme.mp3')
#sop(5,m,'exitcode=%i' % (exitcode))
#sop(5,m,'md5sum=%s' % (md5sum))

#print delimeter
# UNIT TEST mkdir happy path
#dirstr = '/home/pi/bmir2018/ice/eraseme'
#exitcode = make_remote_directory(USERNAME, HOSTNAME, dirstr)
#sop(5,m,'exitcode=%i' % (exitcode))

#print delimeter
# misc unit test
#exitcode,md5sum = get_remote_file_md5sum(USERNAME, HOSTNAME, dirstr + '/ers.txt')
#sop(5,m,'exitcode=%i' % (exitcode))
#sop(5,m,'md5sum=%s' % (md5sum))

#print delimeter
# UNIT TEST get-local-md5sum - happy path
#exitcode,md5sum = get_local_file_md5sum('/home/pi/.bashrc')
#sop(5,m,'exitcode=%i' % (exitcode))
#sop(5,m,'md5sum=%s' % (md5sum))

#print delimeter
# UNIT TEST get-local-md5sum - file not found
#exitcode,md5sum = get_local_file_md5sum('/home/pi/nonexistent.mp3')
#sop(5,m,'exitcode=%i' % (exitcode))
#sop(5,m,'md5sum=%s' % (md5sum))

#-----------------------------------------
# Main.  The program starts here!
#-----------------------------------------
m = "main"
sop(5,m,"Entry.")

# Parse parms
currentMp3FilePrefix = "UNDEFINED"
if 2 == len(sys.argv):
	currentMp3FilePrefix = sys.argv[1]
	sop(5,m,'Parsed currentMp3FilePrefix=%s' % (currentMp3FilePrefix))

# Go!
analyze_files(currentMp3FilePrefix)

