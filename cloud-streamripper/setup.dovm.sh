#!/bin/bash

#TODO: ALSO: Rename streamripper.archiver.sh


#-----------------------------------------------------------------------
# Sets up Ubuntu VM at digitalocean.
#
# Prereqs:
#   Create a new droplet using an SSH key pair for user root
#
# Invoke:
#	./setup.dovm.sh <IP> <PRIVATE_SSH_KEY_FILENAME> <ACTION>
#   where
#       ACTION is os_update ufe_setup etc
#
# Example
#   ./setup.dovm.sh 192.168.1.123 /home/fred/.ssh/dovmroot.id_rsa osupdate
#
# Environment Variables
#   To create new user, export USER_NAME and USER_PASSWORD
#
# To set up a complete arhiver, for example bmir, issue the following
#   . creds/setenv.sudo.user.sh
#   . creds/setenv.twilio.<ACCOUNT>.sh
#   . creds/setenv.s3fs.bmir.sh
#   ./setup.dovm.sh <IP> <PRIVATE_SSH_KEY_FILENAME> <ACTION>, where action=
#        secure_vm
#        create_sudo_user
#        setup_archiver_bmir
#        setup_monitor_bmir
#
# To set up a new server with S3FS, issue the following
#   . creds/setenv.sudo.user.sh
#   . creds/setenv.s3fs.<S3FS_NAME>.sh
#   ./setup.dovm.sh <IP> <PRIVATE_SSH_KEY_FILENAME>
#        secure_vm
#        create_sudo_user
#        setup_s3fs
#        mount_s3fs
#   and optionally
#       unmount_s3fs
#
#
#
#
#
#
# TODO: Add echo 1 to apd-get update to accept the maintainers menu.lst
#
# TODO: Automate creation of symbolic links for apache2:
#       ln -s /home/vmadmin/bmir-monitor bmir-monitor
#       ln -s /home/vmadmin/bmir-streamripper bmir
#
# AD 2020-0805-0730 Created
# Copyright BMIR 2020
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"
S3FS_MOUNT_ROOT="/s3"


#-----------------------------------------------------------------------
# Helper function issues remote SSH command and exits on error.
#-----------------------------------------------------------------------
rexec()
{
    for VAR_NAME in USR CMD VM_IP
    do
        if [[ -z "${!VAR_NAME}" ]] ; then
            echo "EXIT USER ERROR: Variable ${VAR_NAME} is not defined."
            exit 9
        fi
    done

    echo ${DELIMITER}
    date
	echo "Ok. Issuing remote command as user '${USR}': ${CMD}"
    sleep 1
	ssh -t -i ${VM_ROOT_KEYFILE} -o StrictHostKeyChecking=no ${USR}@${VM_IP} ${CMD}
    rc=$?
    echo "rc=${rc}"
    if [ 0 != ${rc} ] ; then
    	echo "ERROR issuing remote command to ${VM_IP}."
        date
        exit 9
    fi
    sleep 1
}


#-----------------------------------------------------------------------
# Helper function transfers a file and exits on error.
#-----------------------------------------------------------------------
rpush()
{
    echo ${DELIMITER}
    date
	echo "Ok. Copying file from local ${SRC_FILE} to ${VM_IP} ${DST_FILE}"
    sleep 1
	scp -i ${VM_ROOT_KEYFILE} -o StrictHostKeyChecking=no ${SRC_FILE} ${USR}@${VM_IP}:${DST_FILE}
    rc=$?
    echo "rc=${rc}"
    if [ 0 != ${rc} ] ; then
    	echo "ERROR transferring file to ${VM_IP}."
        date
        exit 9
    fi
    sleep 1
}


#-----------------------------------------------------------------------
# Action sets
#-----------------------------------------------------------------------


verify_user_name_password()
{
    if [[ -z "${USER_NAME}" ]] ; then
        echo "EXIT USER ERROR: Environment variable USER_NAME does not exist."
        exit 9
    else
        echo "Ok. USER_NAME=${USER_NAME} is defined."
    fi
    if [[ -z "${USER_PASSWORD}" ]] ; then
        echo "EXIT USER ERROR: Environment variable USER_PASSWORD does not exist."
        exit 9
    else
        echo "Ok. Variables USER_NAME and USER_PASSWORD are defined."
    fi
}


hostname()
{
    USR="root"
    CMD="hostname" ; rexec
}


reboot()
{
    echo "Ok. Issuing 'shutdown -r now' command...."
    USR="root"
    CMD="shutdown -r now" ; rexec
}


update_os()
{
    echo "Ok. Issuing 'osupdate' actions...."
    USR="root"
    CMD="apt-get -y update" ; rexec
    CMD="apt-get -y dist-upgrade" ; rexec
    CMD="apt-get -y autoremove" ; rexec
}


install_ufw()
{
    echo "Ok. Installing UFW..."
    USR="root"
    CMD="apt-get -y install ufw" ; rexec
    CMD="ufw status" ; rexec
}


enable_ufw_ssh()
{
    echo "Ok. Enabling UFW..."
    USR="root"
    CMD="ufw disable" ; rexec
    CMD="ufw default deny incoming" ; rexec
    CMD="ufw default allow outgoing" ; rexec
    CMD="ufw allow ssh" ; rexec
    if [ "True" == ${ENABLE_HTTP} ] ; then
        CMD="ufw allow http" ; rexec
    fi
    CMD="ufw --force enable" ; rexec
    CMD="ufw status" ; rexec
}


enable_ufw_ssh_http()
{
    echo "Ok. Enabling UFW for SSH and HTTP..."
    ENABLE_HTTP="True"
    enable_ufw_ssh
}


set_timezone_uspt()
{
    echo "Ok. Setting timezone to US PACIFIC..."
    USR="root"
    CMD="timedatectl set-timezone America/Los_Angeles" ; rexec
    CMD="date" ; rexec
}


disable_misc_timers()
{
    USR="root"
    CMD="systemctl stop apt-daily.timer" ; rexec
    CMD="systemctl disable apt-daily.timer" ; rexec
    CMD="systemctl stop apt-daily-upgrade.timer" ; rexec
    CMD="systemctl disable apt-daily-upgrade.timer" ; rexec
    CMD="systemctl stop motd-news.timer" ; rexec
    CMD="systemctl disable motd-news.timer" ; rexec
}


prv_install_package()
{
    verify_user_name_password
    echo "Ok. Installing ${PACKAGE_NAME}..."
    USR="${USER_NAME}"
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S apt-get -y install ${PACKAGE_NAME}" ; rexec
    CMD="which ${PACKAGE_NAME}" ; rexec
    CMD="dpkg -l | grep ${PACKAGE_NAME}" ; rexec
}


install_s3fs()
{
    PACKAGE_NAME="s3fs"
    prv_install_package
}


install_streamripper()
{
    PACKAGE_NAME="streamripper"
    prv_install_package
}


install_liquidsoap()
{
    PACKAGE_NAME="liquidsoap"
    prv_install_package
}


install_ffmpeg()
{
    PACKAGE_NAME="ffmpeg"
    prv_install_package
}


install_mp3info()
{
    PACKAGE_NAME="mp3info"
    prv_install_package
}


create_user()
{
    verify_user_name_password
    echo "Ok. Creating user..."
    USR="root"
    CMD="echo -e \"${USER_PASSWORD}\n${USER_PASSWORD}\" | adduser  --gecos \"\" ${USER_NAME}" ; rexec
    CMD="ls -l /home/" ; rexec
}


enable_sudo()
{
    verify_user_name_password
    echo "Ok. Enable sudo capability for user ${USER_NAME}"
    USR="root"
    CMD="usermod -aG sudo ${USER_NAME}" ; rexec
}


copy_ssh_keys()
{
    verify_user_name_password
    echo "Ok. Copying SSH keys from root to ${USER_NAME}..."
    USR="root"
    CMD="cp -r ~/.ssh /home/${USER_NAME}/" ; rexec
    CMD="chown -R ${USER_NAME} /home/${USER_NAME}/.ssh" ; rexec
    CMD="chgrp -R ${USER_NAME} /home/${USER_NAME}/.ssh" ; rexec
}


disable_root_ssh()
{
    verify_user_name_password
    echo "Ok. Disabling root login via SSH..."
    USR="${USER_NAME}"
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S sed -i \"s:PermitRootLogin yes:PermitRootLogin no:g\" /etc/ssh/sshd_config" ; rexec
    CMD="grep PermitRootLogin /etc/ssh/sshd_config" ; rexec
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S service ssh restart" ; rexec
}


secure_vm()
{
    set_timezone_uspt
    disable_misc_timers
    install_ufw
    enable_ufw_ssh_http
    update_os
    reboot
}


create_sudo_user()
{
    verify_user_name_password
    create_user
    enable_sudo
    copy_ssh_keys
    disable_root_ssh
}

prv_setup_archiver_common()  # Helper function; not intended to be called externally.
{
    verify_user_name_password
    install_streamripper

    # Configuratble files common to all streams and services.
    declare -a FILE_LIST=("setup.streamripper.service.sh" "streamripper.archiver.sh" "streamripper.service")
    for FILE_NAME in "${FILE_LIST[@]}"
    do
        ### echo "${FILE_NAME}"

        echo "Ok. Verifying file exists: ${FILE_NAME}"
        if [ -f "streamripper/${FILE_NAME}" ] ; then
            echo "Ok. streamripper/${FILE_NAME} exists."
        else
            echo "EXIT USER ERROR: File does not exist: streamripper/${FILE_NAME}"
            exit 9
        fi

        echo "Ok. Copying file to local directory."
        cp streamripper/${FILE_NAME} .
        rc=$?
        if [ 0 != ${rc} ] ; then
        	echo "EXIT ERROR copying file locally: ${FILE_NAME}."
            exit 9
        fi

        echo "Ok. Verifying file exists: ${FILE_NAME}"
        if [ -f "${FILE_NAME}" ] ; then
            echo "Ok. ${FILE_NAME} exists."
        else
            echo "EXIT USER ERROR: File does not exist: ${FILE_NAME}"
            exit 9
        fi

        echo "Ok. Editing USER_NAME locally: ${FILE_NAME}"
        sed -i "" -e "s:<USER_NAME>:${USER_NAME}:g" ${FILE_NAME}
        rc=$?
        if [ 0 != ${rc} ] ; then
        	echo "EXIT ERROR editing USER_NAME in file: ${FILE_NAME}."
            exit 9
        fi

        # Edit env vars in file.
        declare -a ENV_VAR_NAMES=("SERVICE_RADIOSTREAM" "SERVICE_DIR" "SERVICE_NAME" "SERVICE_DEST_PATH" "SERVICE_PREFIX")
        for ENV_VAR_NAME in "${ENV_VAR_NAMES[@]}"
        do
            echo "Ok. Editing environment variable ${ENV_VAR_NAME} in local file: ${FILE_NAME}"
            # Note: The explanation point in the following sed command dereferences the variable.
            sed -i "" -e "s|<${ENV_VAR_NAME}>|${!ENV_VAR_NAME}|g" ${FILE_NAME}
            rc=$?
            if [ 0 != ${rc} ] ; then
            	echo "EXIT ERROR editing ${ENV_VAR_NAME} in file: ${FILE_NAME}."
                exit 9
            fi
        done

        echo "Ok. Renaming and copying file to VM..."
        USR=${USER_NAME}
        SRC_FILE="${FILE_NAME}"
        DST_FILE="/home/${USR}/${SERVICE_PREFIX}-${FILE_NAME}"
        rpush

    done

    echo "Ok. Setting up and starting streamripper service..."
    USR="${USER_NAME}"
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S ./${SERVICE_PREFIX}-setup.streamripper.service.sh" ; rexec



    # Todo: Verify the service is running?
}


setup_archiver_shoutingfire()
{
    verify_user_name_password
    export SERVICE_DIR="shoutingfire"
    export SERVICE_NAME="sf-streamripper"
    export SERVICE_DEST_PATH="/home/${USER_NAME}/${SERVICE_NAME}"
    export SERVICE_PREFIX="sf"
    export SERVICE_RADIOSTREAM="shoutingfire-ice.streamguys1.com/live"
    prv_setup_archiver_common
}


setup_archiver_bmir_test()
{
    verify_user_name_password
    export SERVICE_DIR="bmirtest"
    export SERVICE_NAME="bmirtest-streamripper"
    export SERVICE_DEST_PATH="/home/${USER_NAME}/${SERVICE_NAME}"
    export SERVICE_PREFIX="bmirtest"
    export SERVICE_RADIOSTREAM="http://stream.bmir.org/test"
    prv_setup_archiver_common
}


setup_archiver_bmir()
{
    verify_user_name_password
    export SERVICE_DIR="bmir"
    export SERVICE_NAME="bmir-streamripper"
    export SERVICE_DEST_PATH="/home/${USER_NAME}/${SERVICE_NAME}"
    export SERVICE_PREFIX="bmir"
    export SERVICE_RADIOSTREAM="http://stream.bmir.org/live"
    prv_setup_archiver_common
}


verify_twilio_vars()
{
    echo "Checking env vars to send sms text messages via twilio."
    if [[ -z "${TWILIO_SID}" ]]; then
        echo "INVOCATION ERROR: Environment variable TWILIO_SID is not defined."
        exit 9
    fi
    if [[ -z "${TWILIO_TOKEN}" ]]; then
        echo "INVOCATION ERROR: Environment variable TWILIO_TOKEN is not defined."
        exit 9
    fi
    if [[ -z "${TWILIO_SRC}" ]]; then
        echo "INVOCATION ERROR: Environment variable TWILIO_SRC is not defined."
        exit 9
    fi
    if [[ -z "${TWILIO_DST}" ]]; then
        echo "INVOCATION ERROR: Environment variable TWILIO_SRC is not defined."
        exit 9
    fi
}


prv_setup_monitor_common()  # Helper function; not intended to be called externally.
{
    verify_user_name_password
    verify_twilio_vars

    USR="${USER_NAME}"
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S apt-get -y install sox" ; rexec
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S apt-get -y install libsox-fmt-mp3" ; rexec
    CMD="mkdir -p ${SERVICE_DEST_PATH}" ; rexec

    # Configuratble files common to all streams and services.
    declare -a FILE_LIST=("monitor.service" "monitor.sh" "monitor.timer" "setup.monitor.timer.sh")
    for FILE_NAME in "${FILE_LIST[@]}"
    do
        ### echo "${FILE_NAME}"

        echo "Ok. Verifying file exists: ${FILE_NAME}"
        if [ -f "monitor/${FILE_NAME}" ] ; then
            echo "Ok. monitor/${FILE_NAME} exists."
        else
            echo "EXIT USER ERROR: File does not exist: monitor/${FILE_NAME}"
            exit 9
        fi

        echo "Ok. Copying file to local directory."
        cp monitor/${FILE_NAME} .
        rc=$?
        if [ 0 != ${rc} ] ; then
        	echo "EXIT ERROR copying file locally: ${FILE_NAME}."
            exit 9
        fi

        echo "Ok. Verifying file exists: ${FILE_NAME}"
        if [ -f "${FILE_NAME}" ] ; then
            echo "Ok. ${FILE_NAME} exists."
        else
            echo "EXIT USER ERROR: File does not exist: ${FILE_NAME}"
            exit 9
        fi

        echo "Ok. Editing USER_NAME locally: ${FILE_NAME}"
        sed -i "" -e "s:<USER_NAME>:${USER_NAME}:g" ${FILE_NAME}
        rc=$?
        if [ 0 != ${rc} ] ; then
        	echo "EXIT ERROR editing USER_NAME in file: ${FILE_NAME}."
            exit 9
        fi

        # Edit env vars in file.
        declare -a ENV_VAR_NAMES=("SERVICE_RADIOSTREAM" "SERVICE_DIR" "SERVICE_NAME" "SERVICE_DEST_PATH" "SERVICE_PREFIX" "MP3_DIR" "TWILIO_SID" "TWILIO_TOKEN" "TWILIO_SRC" "TWILIO_DST")
        for ENV_VAR_NAME in "${ENV_VAR_NAMES[@]}"
        do
            echo "Ok. Editing environment variable ${ENV_VAR_NAME} in local file: ${FILE_NAME}"
            # Note: The explanation point in the following sed command dereferences the variable.
            sed -i "" -e "s|<${ENV_VAR_NAME}>|${!ENV_VAR_NAME}|g" ${FILE_NAME}
            rc=$?
            if [ 0 != ${rc} ] ; then
            	echo "EXIT ERROR editing ${ENV_VAR_NAME} in file: ${FILE_NAME}."
                exit 9
            fi
        done

        echo "Ok. Renaming and copying file to VM..."
        USR=${USER_NAME}
        SRC_FILE="${FILE_NAME}"
        DST_FILE="/home/${USR}/${SERVICE_PREFIX}-${FILE_NAME}"
        rpush
    done

    echo "Ok. Setting up and starting monitor service..."
    USR="${USER_NAME}"
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S ./${SERVICE_PREFIX}-setup.monitor.timer.sh" ; rexec

    # Todo: Verify the service is running?
}


setup_monitor_shoutingfire()
{
    verify_user_name_password
    verify_twilio_vars
    export SERVICE_DIR="shoutingfire"
    export SERVICE_NAME="sf-monitor"
    export SERVICE_DEST_PATH="/home/${USER_NAME}/${SERVICE_NAME}"
    export SERVICE_PREFIX="sf"
    export SERVICE_RADIOSTREAM="shoutingfire-ice.streamguys1.com/live"
    export MP3_DIR="/home/${USER_NAME}/sf-streamripper"
    prv_setup_monitor_common
}


setup_monitor_bmir_test()
{
    verify_user_name_password
    verify_twilio_vars
    export SERVICE_DIR="bmirtest"
    export SERVICE_NAME="bmirtest-monitor"
    export SERVICE_DEST_PATH="/home/${USER_NAME}/${SERVICE_NAME}"
    export SERVICE_PREFIX="bmirtest"
    export SERVICE_RADIOSTREAM="http://stream.bmir.org/test"
    export MP3_DIR="/home/${USER_NAME}/bmirtest-streamripper"
    prv_setup_monitor_common
}


setup_monitor_bmir()
{
    verify_user_name_password
    verify_twilio_vars
    export SERVICE_DIR="bmir"
    export SERVICE_NAME="bmir-monitor"
    export SERVICE_DEST_PATH="/home/${USER_NAME}/${SERVICE_NAME}"
    export SERVICE_PREFIX="bmir"
    export SERVICE_RADIOSTREAM="http://stream.bmir.org/live"
    export MP3_DIR="/home/${USER_NAME}/bmir-streamripper"
    prv_setup_monitor_common
}


set_s3fs_mount_folder()
{
    S3FS_MOUNT_FOLDER="${S3FS_MOUNT_ROOT}/${S3FS_NAME}"
}


set_s3fs_creds_file_name()
{
    S3FS_CREDS_FILE_NAME="/home/${USER_NAME}/.s3fs-${S3FS_NAME}-creds"
}


setup_s3fs()
{
    # Verify variables
    for VAR_NAME in USER_NAME USER_PASSWORD S3FS_NAME S3FS_KEY S3FS_VALUE APACHE_UID APACHE_GID APACHE_USER
    do
        if [[ -z "${!VAR_NAME}" ]] ; then
            echo "EXIT USER ERROR: Variable ${VAR_NAME} is not defined."
            exit 9
        fi
    done

    # Prompt the user to confirm which s3fs will be mounted.
    echo "SETTING UP s3fs '${S3FS_NAME}' on VM '${VM_IP}'. Are you sure?"
    read -p "Enter 'y' to proceed.  Ctrl-c to exit." -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Proceeding."
    else
        exit 0
    fi

    # Install s3fs
    install_s3fs

    # Verify the User ID and Group ID numbers which are running Apache2.
    USR="${USER_NAME}"
    CMD="grep ${APACHE_UID}:${APACHE_GID}:${APACHE_USER} /etc/passwd" ; rexec

    # Enable non-root users to access the s3fs folder.
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S sed -i \"s:#user_allow_other:user_allow_other:g\" /etc/fuse.conf" ; rexec
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S cat /etc/fuse.conf" ; rexec

    # Create credentials file for consumption by s3fs.
    # For example, /home/vmadmin/.s3fs-creds
    set_s3fs_creds_file_name
    CMD="echo ${S3FS_KEY}:${S3FS_VALUE} > ${S3FS_CREDS_FILE_NAME}" ; rexec
    CMD="cat ${S3FS_CREDS_FILE_NAME}" ; rexec
    CMD="chmod 600 ${S3FS_CREDS_FILE_NAME}" ; rexec
    CMD="ls -l ${S3FS_CREDS_FILE_NAME}" ; rexec

    # Create target folder for s3fs mount.
    # For example, /s3/bmir/
    set_s3fs_mount_folder
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S mkdir -p ${S3FS_MOUNT_FOLDER}" ; rexec
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S chown -R ${APACHE_USER}:${APACHE_USER} ${S3FS_MOUNT_FOLDER}" ; rexec
    CMD="ls -l ${S3FS_MOUNT_ROOT}" ; rexec
    CMD="ls -l ${S3FS_MOUNT_FOLDER}" ; rexec
}


mount_s3fs()
{
    # TODO FUTURE:  CONVERT THIS TO SYSTEMD MOUNT

    # Verify variables
    for VAR_NAME in USER_NAME USER_PASSWORD S3FS_URL S3FS_NAME S3FS_KEY S3FS_VALUE APACHE_UID APACHE_GID APACHE_USER
    do
        if [[ -z "${!VAR_NAME}" ]] ; then
            echo "EXIT USER ERROR: Variable ${VAR_NAME} is not defined."
            exit 9
        fi
    done

    # Assemble variables.
    set_s3fs_mount_folder
    set_s3fs_creds_file_name

    # Prompt the user to confirm which s3fs will be mounted.
    echo "MOUNTING s3fs '${S3FS_NAME}' to folder '${S3FS_MOUNT_FOLDER}' on VM '${VM_IP}'. Are you sure?"
    read -p "Enter 'y' to proceed.  Ctrl-c to exit." -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Proceeding."
    else
        exit 0
    fi

    # Mount S3FS.
    USR=${USER_NAME}
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S s3fs -d ${S3FS_NAME} ${S3FS_MOUNT_FOLDER} -o url=${S3FS_URL} -o use_cache=/tmp -o allow_other -o use_path_request_style -o uid=${APACHE_UID} -o gid=${APACHE_GID} -o passwd_file=${S3FS_CREDS_FILE_NAME}" ; rexec
    CMD="ls -l ${S3FS_MOUNT_FOLDER}" ; rexec
}


unmount_s3fs()
{
    # Verify variables
    for VAR_NAME in USER_NAME USER_PASSWORD S3FS_URL S3FS_NAME S3FS_KEY S3FS_VALUE APACHE_UID APACHE_GID APACHE_USER
    do
        if [[ -z "${!VAR_NAME}" ]] ; then
            echo "EXIT USER ERROR: Variable ${VAR_NAME} is not defined."
            exit 9
        fi
    done

    # Assemble variables.
    set_s3fs_mount_folder
    set_s3fs_creds_file_name

    # Prompt the user to confirm which s3fs will be unmounted.
    echo "UNMOUNTING s3fs '${S3FS_NAME}' folder '${S3FS_MOUNT_FOLDER}' on VM '${VM_IP}'. Are you sure?"
    read -p "Enter 'y' to proceed.  Ctrl-c to exit." -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Proceeding."
    else
        exit 0
    fi

    # Unmount s3fs.  Example: sudo umount -l /s3/bmir
    USR=${USER_NAME}
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S umount -l ${S3FS_MOUNT_FOLDER}" ; rexec
    CMD="ls -l ${S3FS_MOUNT_ROOT}" ; rexec
}


#-----------------------------------------------------------------------
# The script starts here...
#-----------------------------------------------------------------------

# Parse Parms.

echo ${DELIMITER}
echo "Ok. Checking parameter count..."
echo "dollarpound=$#"
if [ $# -ne 3 ] ; then
    echo "USER INVOCATION ERROR: Wrong number of parameters. Enter ./setup.dovm.sh <IP> <PRIVATE_SSH_KEY_FILENAME> <ACTION>"
    exit 9
fi
echo "Ok. Confirmed parameter count."

echo ${DELIMITER}
echo "Ok. Getting IP of the VM."
VM_IP=${1}
echo "VM_IP=${VM_IP}"

echo ${DELIMITER}
echo "Ok. Getting private root key filename of the VM."
VM_ROOT_KEYFILE=${2}
echo "VM_ROOT_KEYFILE=${VM_ROOT_KEYFILE}"

# Ensure file exists
if [ -f "${VM_ROOT_KEYFILE}" ]; then
    echo "Ok. ${VM_ROOT_KEYFILE} exists."
else
    echo "EXIT USER ERROR: ${VM_ROOT_KEYFILE} does not exist."
    exit 9
fi

echo ${DELIMITER}
echo "Ok. Getting action for the VM."
ACTION=${3}
echo "ACTION=${ACTION}"

# Do it...

#if [ "prv_setup_archiver_common" == ${ACTION} ] ; then  # FOR DEBUG ONLY
#      prv_setup_archiver_common
#if [ "prv_setup_monitor_common" == ${ACTION} ] ; then  # FOR DEBUG ONLY
#      prv_setup_monitor_common
if [ "hostname" == ${ACTION} ] ; then
      hostname
elif [ "reboot" == ${ACTION} ] ; then
        reboot
elif [ "update_os" == ${ACTION} ] ; then
        update_os
elif [ "install_ufw" == ${ACTION} ] ; then
        install_ufw
elif [ "enable_ufw_ssh" == ${ACTION} ] ; then
        enable_ufw_ssh
elif [ "set_timezone_uspt" == ${ACTION} ] ; then
        set_timezone_uspt
elif [ "disable_misc_timers" == ${ACTION} ] ; then
        disable_misc_timers
elif [ "install_streamripper" == ${ACTION} ] ; then
        install_streamripper
elif [ "install_liquidsoap" == ${ACTION} ] ; then
        install_liquidsoap
elif [ "install_ffmpeg" == ${ACTION} ] ; then
        install_ffmpeg
elif [ "install_s3fs" == ${ACTION} ] ; then
        install_s3fs
elif [ "install_mp3info" == ${ACTION} ] ; then
        install_mp3info
elif [ "create_user" == ${ACTION} ] ; then
        create_user
elif [ "enable_sudo" == ${ACTION} ] ; then
        enable_sudo
elif [ "copy_ssh_keys" == ${ACTION} ] ; then
        copy_ssh_keys
elif [ "disable_root_ssh" == ${ACTION} ] ; then
        disable_root_ssh

elif [ "setup_s3fs" == ${ACTION} ] ; then
        setup_s3fs
elif [ "mount_s3fs" == ${ACTION} ] ; then
        mount_s3fs
elif [ "unmount_s3fs" == ${ACTION} ] ; then
        unmount_s3fs
elif [ "umount_s3fs" == ${ACTION} ] ; then
        unmount_s3fs

elif [ "secure_vm" == ${ACTION} ] ; then
        secure_vm
elif [ "create_sudo_user" == ${ACTION} ] ; then
        create_sudo_user

elif [ "setup_archiver_shoutingfire" == ${ACTION} ] ; then
        setup_archiver_shoutingfire
elif [ "setup_archiver_bmir_test" == ${ACTION} ] ; then
        setup_archiver_bmir_test
elif [ "setup_archiver_bmir" == ${ACTION} ] ; then
        setup_archiver_bmir

elif [ "setup_monitor_shoutingfire" == ${ACTION} ] ; then
        setup_monitor_shoutingfire
elif [ "setup_monitor_bmir_test" == ${ACTION} ] ; then
        setup_monitor_bmir_test
elif [ "setup_monitor_bmir" == ${ACTION} ] ; then
        setup_monitor_bmir

else
    echo "EXIT USER ERROR: Action ${ACTION} is not recognized. Specify update_os, install_ufw, etc"
    exit 9
fi
