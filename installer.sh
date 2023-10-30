#!/bin/bash

# Function to check if a command exists
command_exists () {
    type "$1" &> /dev/null ;
}

# Function to install a package
install_package () {
    if ! command_exists $1; then
        echo "$1 could not be found, installing it now..."
        apt-get install $1 -y
        if [ $? -ne 0 ]; then
            echo "Failed to install $1"
            exit 1
        fi
    else
        echo "$1 is already installed."
    fi
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]
then 
    echo "Please run as root"
    exit
fi

# Update the package list
apt-get update

# Check if cron is installed, if not, install it
install_package cron

# Check if mailutils is installed, if not, install it
install_package mailutils

# Check if Metasploit is installed, if not, install it
install_package metasploit-framework

# Check if Nmap is installed, if not, install it
install_package nmap

# Check if tor is installed, if not, install it
install_package tor

# Check if torsocks is installed, if not, install it
install_package torsocks

echo "All necessary packages have been installed."
