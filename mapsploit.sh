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

# Function to generate a summary report from the detailed report.txt file.
generate_summary_report () {
    echo "Generating summary report..."
    grep -i "vulnerability" report.txt > summary.txt
    if [ $? -ne 0 ]; then
        echo "Failed to generate summary report"
        exit 1
    fi
}

# Function to stop tor service
stop_tor () {
    if pgrep tor > /dev/null; then
        echo "Stopping tor service..."
        sudo systemctl stop tor
    fi
}

# Stop tor service when script exits
trap stop_tor EXIT

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

# Check if cron is installed, if not, install it
install_package cron

# Check if mail is installed, if not, install it
install_package mailutils

# Check if Metasploit is installed and update it
if ! command_exists msfconsole; then install_package metasploit-framework; else update_package metasploit-framework; fi

# Check if Nmap is installed and update it
if ! command_exists nmap; then install_package nmap; else update_package nmap; fi

# Check if tor is installed, if not, install it
install_package tor

# Check if torify is installed, if not, install it
install_package torsocks

# Initialize the Metasploit database
echo "Initializing the Metasploit database..."
msfdb init

# Define the target IPs as a command-line argument (comma-separated)
IFS=',' read -ra ips <<< "$1"

# Define the cron schedule as an optional second command-line argument
schedule=$2

# Define the email address as an optional third command-line argument
email=$3

# If a cron schedule was provided, add a cron job to run this script with the same IPs at the specified times
if [ -n "$schedule" ]; then
    (crontab -l ; echo "$schedule $0 $1") | crontab -
    echo "Cron job added to run this script on IPs $1 with schedule $schedule"
fi

# Start the tor service for anonymity 
if command_exists tor && command_exists macchanger; then 
    echo "Starting anonymous mode..."
    service tor start 

    echo "Changing MAC address..."
    macchanger -r eth0 
fi 

# Loop over each IP and run the scan 
for ip in "${ips[@]}"; do 

    # Start msfconsole with the commands and save output to a file named with IP address for uniqueness 
    echo "Running scan on IP $ip with torify..."
    torify msfconsole -qx "
        workspace -a myworkspace;
        db_nmap -A -sV -O -p- --script=vuln $ip;
        hosts -R $ip;
        services -p 1-65535 -R $ip;
        vulns;
        use auxiliary/scanner/http/dir_scanner;
        set RHOSTS $ip;
        run;
        exit
    " > report_$ip.txt &

    if [ $? -ne 0 ]; then
        echo "Failed to execute msfconsole commands on IP $ip"
        exit 1
    fi

    # Generate a summary report from the detailed report.txt file.
    generate_summary_report

    echo "Script executed successfully on IP $ip"
    echo "Results saved to report_$ip.txt"
    echo "Summary saved to summary.txt"

    # If an email address was provided, send an email notification with the scan results
    if [ -n "$email" ]; then
        echo "Sending email notification to $email..."
        mail -s "Scan Results for IP $ip" $email < report_$ip.txt
    fi

done

# Wait for all background processes to finish
wait

# Stop the tor service after the operations are done
if command_exists tor; then 
    echo "Stopping anonymous mode...
