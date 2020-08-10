#!/bin/bash
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
# TODO: Add echo 1 to apd-get update to accept the maintainers menu.lst
#
# AD 2020-0805-0730 Created
# Copyright BMIR 2020
#-----------------------------------------------------------------------
export DELIMITER="-----------------------------------------------------"


#-----------------------------------------------------------------------
# Helper function issues remote SSH command and exits on error.
#-----------------------------------------------------------------------
rexec()
{
    echo ${DELIMITER}
    date
	echo "Ok. Issuing remote command: ${CMD}"
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
    echo "Ok. Enabling UFW for SSH only..."
    USR="root"
    CMD="ufw disable" ; rexec
    CMD="ufw default deny incoming" ; rexec
    CMD="ufw default allow outgoing" ; rexec
    CMD="ufw allow ssh" ; rexec
    CMD="ufw --force enable" ; rexec
    CMD="ufw status" ; rexec
}


set_timezone_uspt()
{
    echo "Ok. Setting timezone to US PACIFIC..."
    USR="root"
    CMD="timedatectl set-timezone America/Los_Angeles" ; rexec
    CMD="date" ; rexec
}


install_streamripper()
{
    echo "Ok. Installing streamripper..."
    USR="root"
    CMD="apt-get -y install streamripper" ; rexec
    CMD="which streamripper" ; rexec
    CMD="streamripper --version" ; rexec
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


setup_archiver_part0()
{
    set_timezone_uspt
    install_ufw
    enable_ufw_ssh
    update_os
    reboot
}
# Todo: Write a pinger/ssher to wait til the VM is back up.
setup_archiver_part1()
{
    create_user
    enable_sudo
    copy_ssh_keys
    install_streamripper
    disable_root_ssh
}

prv_setup_archiver_common()  # Helper function; not intended to be called externally.
{
    verify_user_name_password

    # Configuratble files common to all streams and services.
    declare -a FILE_LIST_COMMON=("setup.streamripper.service.sh" "streamripper.archiver.sh" "streamripper.service")
    for FILE_NAME in "${FILE_LIST_COMMON[@]}"
    do
        ### echo "${FILE_NAME}"

        echo "Ok. Verifying file exists: ${FILE_NAME}"
        if [ -f "common/${FILE_NAME}" ] ; then
            echo "Ok. common/${FILE_NAME} exists."
        else
            echo "EXIT USER ERROR: File does not exist: common/${FILE_NAME}"
            exit 9
        fi

        echo "Ok. Copying file to local directory."
        cp common/${FILE_NAME} .
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
        sed -i -e "s:<USER_NAME>:${USER_NAME}:g" ${FILE_NAME}
        rc=$?
        if [ 0 != ${rc} ] ; then
        	echo "EXIT ERROR editing USER_NAME in file: ${FILE_NAME}."
            exit 9
        fi

        declare -a ENV_VAR_NAMES=("SERVICE_RADIOSTREAM" "SERVICE_DIR" "SERVICE_NAME" "SERVICE_PREFIX")
        for ENV_VAR_NAME in "${ENV_VAR_NAMES[@]}"
        do
            echo "Ok. Editing environment variable ${ENV_VAR_NAME} in local file: ${FILE_NAME}"
            # Note: The explanation point in the following sed command dereferences the variable.
            sed -i -e "s|<${ENV_VAR_NAME}>|${!ENV_VAR_NAME}|g" ${FILE_NAME}
            rc=$?
            if [ 0 != ${rc} ] ; then
            	echo "EXIT ERROR editing ${ENV_VAR_NAME} in file: ${FILE_NAME}."
                exit 9
            fi
        done

        echo "Ok. Copying file to VM..."
        USR=${USER_NAME}
        SRC_FILE="${FILE_NAME}"
        # Special handling to rename the service file.
        if [ "streamripper.service" == ${FILE_NAME} ] ; then
            DST_FILE="/home/${USR}/${SERVICE_PREFIX}-${FILE_NAME}"
        else
            DST_FILE="/home/${USR}/${FILE_NAME}"
        fi
        rpush
    done

    echo "Ok. Setting up and starting streamripper service..."
    USR="${USER_NAME}"
    CMD="echo -e \"${USER_PASSWORD}\n\" | sudo -S ./setup.streamripper.service.sh" ; rexec

    # Todo: Verify the service is running?
}


setup_archiver_shoutingfire()
{
    verify_user_name_password
    SERVICE_DIR="shoutingfire"
    SERVICE_NAME="sf-streamripper"
    SERVICE_PREFIX="sf"
    SERVICE_RADIOSTREAM="shoutingfire-ice.streamguys1.com/live"
    prv_setup_archiver_common
}


setup_archiver_bmir_test()
{
    verify_user_name_password
    SERVICE_DIR="bmirtest"
    SERVICE_NAME="bmirtest-streamripper"
    SERVICE_PREFIX="bmirtest"
    SERVICE_RADIOSTREAM="http://stream.bmir.org/test"
    prv_setup_archiver_common
}


setup_archiver_bmir()
{
    verify_user_name_password
    SERVICE_DIR="bmir"
    SERVICE_NAME="bmir-streamripper"
    SERVICE_PREFIX="bmir"
    SERVICE_RADIOSTREAM="http://stream.bmir.org/live"
    prv_setup_archiver_common
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
elif [ "install_streamripper" == ${ACTION} ] ; then
        install_streamripper
elif [ "create_user" == ${ACTION} ] ; then
        create_user
elif [ "enable_sudo" == ${ACTION} ] ; then
        enable_sudo
elif [ "copy_ssh_keys" == ${ACTION} ] ; then
        copy_ssh_keys
elif [ "disable_root_ssh" == ${ACTION} ] ; then
        disable_root_ssh

elif [ "setup_archiver_part0" == ${ACTION} ] ; then
        setup_archiver_part0
elif [ "setup_archiver_part1" == ${ACTION} ] ; then
        setup_archiver_part1
elif [ "setup_archiver_shoutingfire" == ${ACTION} ] ; then
        setup_archiver_shoutingfire
elif [ "setup_archiver_bmir_test" == ${ACTION} ] ; then
        setup_archiver_bmir_test
elif [ "setup_archiver_bmir" == ${ACTION} ] ; then
        setup_archiver_bmir

else
    echo "EXIT USER ERROR: Action ${ACTION} is not recognized. Specify update_os, install_ufw, etc"
    exit 9
fi
