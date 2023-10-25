#!/bin/bash

# Function to check if a command exists
command_exists () {
    type "$1" &> /dev/null ;
}

# Function to install a package
install_package () {
    if ! command_exists $1; then
        echo "$1 could not be found, would you like to install it now? (yes/no)"
        read answer
        if [ "$answer" != "${answer#[Yy]}" ] ;then
            echo "Installing $1..."
            apt-get install $1 -y
            if [ $? -ne 0 ]; then
                echo "Failed to install $1"
                exit 1
            fi
        fi
    fi
}

# Function to update a package
update_package () {
    if command_exists $1; then
        echo "Updating $1..."
        apt-get update && apt-get upgrade $1 -y
        if [ $? -ne 0 ]; then
            echo "Failed to update $1"
            exit 1
        fi
    fi
}

# Function to generate a summary report from the detailed report
generate_summary_report () {
    echo "Generating summary report..."
    grep -i "vulnerability" report.txt > summary.txt
    if [ $? -ne 0 ]; then
        echo "Failed to generate summary report"
        exit 1
    fi
}

# ASCII Art
echo "========================================================"
echo "__  __             _____       _       _ _   "
echo "|  \\/  |           / ____|     | |     (_) |  "
echo "| \\  / | __ _ _ __| (___  _ __ | | ___  _| |_ "
echo "| |\\/| |/ _\` | '_ \\\\___ \\| '_ \\| |/ _ \\| | __|"
echo "| |  | | (_| | |_) |___) | |_) | | (_) | | |_ "
echo "|_|  |_|\__,_| .__/_____/| .__/|_|\\___/|_|\\__|"
echo "              | |         | |                  "
echo "              |_|         |_|                  "
echo "========================================================"
echo "Created by: Corvus Codex"
echo "Github: https://github.com/CorvusCodex/"
echo "Licence : MIT License"
echo "Support my work:"
echo "BTC: bc1q7wth254atug2p4v9j3krk9kauc0ehys2u8tgg3"
echo "ETH & BNB: 0x68B6D33Ad1A3e0aFaDA60d6ADf8594601BE492F0"
echo "Buy me a coffee: https://www.buymeacoffee.com/CorvusCodex"
echo "========================================================"

# Check if script is run as root
if [ "$EUID" -ne 0 ]
then 
    echo "Please run as root"
    exit
fi

# Check if Metasploit is installed and update it
if ! command_exists msfconsole; then install_package metasploit-framework; else update_package metasploit-framework; fi

# Check if Nmap is installed and update it
if ! command_exists nmap; then install_package nmap; else update_package nmap; fi

# Initialize the Metasploit database
echo "Initializing the Metasploit database..."
msfdb init

# Define the target network as a command-line argument
network=$1

# Start msfconsole with the commands and save output to a file
msfconsole -qx "
    workspace -a myworkspace;
    db_nmap -A -sV -O -p- --script=vuln $network;
    hosts -R $network;
    services -p 1-65535 -R $network;
    vulns;
    use auxiliary/scanner/http/dir_scanner;
    set RHOSTS $network;
    run;
    search type:exploit name:<service-name>;
    exit
" > report.txt


if [ $? -ne 0 ]; then
    echo "Failed to execute msfconsole commands"
    exit 1
fi

# Generate a summary report from the detailed report.txt file.
generate_summary_report

echo "Script executed successfully"
echo "Results saved to report.txt"
echo "Summary saved to summary.txt"

# ASCII Art End Message 
echo "========================================================"
echo "Buy me a coffee: https://www.buymeacoffee.com/CorvusCodex"
echo "========================================================"
