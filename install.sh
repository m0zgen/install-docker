#!/bin/bash
# Author: Yevgeniy Goncharov aka xck, https://sys-adm.in
# Docker installer for Debian-based distros
# Reference: https://docs.docker.com/engine/install/debian/

set -e

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Functions
# ---------------------------------------------------\

# Help information
usage() {

    echo -e "\nJust run ./install.sh"
    exit 1

}

# Checks arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -q|--quiet) _Q=1; ;;
        -h|--help) usage ;; 
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Checks supporting distros
checkDistro() {
    # Checking distro
    if [ -e /etc/centos-release ]; then
        DISTRO=`cat /etc/redhat-release | awk '{print $1,$4}'`
        RPM=1
    elif [ -e /etc/fedora-release ]; then
        DISTRO=`cat /etc/fedora-release | awk '{print ($1,$3~/^[0-9]/?$3:$4)}'`
        RPM=2
    elif [ -e /etc/os-release ]; then
        DISTRO=`lsb_release -d | awk -F"\t" '{print $2}'`
        RPM=0
        DEB=1
    else
        DISTRO="UNKNOWN"
        RPM=0
        DEB=0
    fi
}

# Init official repo
# ---------------------------------------------------\

aptUpdate() {
    sudo apt update
}

pushDocker() {

    echo "Apt update starting..."
    aptUpdate

    echo "Install packages..."
    sudo apt -y install ca-certificates curl gnupg lsb-release

    echo "Install official Docker keys and Docker repo..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    echo "Apt update..."
    aptUpdate

    echo "Install Docker packages..."
    sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

    echo "Enable Docker services..."
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    echo -e "\nDone!\n"
    exit 0
}

instalDebian() {

    if ! [ -x "$(command -v docker)" ]; then
        echo "Docker installation process starting..."
        pushDocker
    else
        echo "Docker already installed. Exit. Bye."
        exit 1
    fi


}

checkDistro

if [[ "${DEB}" -eq "1" ]]; then
    instalDebian
else
    echo -e "Not supported distro. Exit..."
    exit 1
fi