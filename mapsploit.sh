#!/bin/bash
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

# Initialize the Metasploit database
echo "Starting the Metasploit database..."
msfdb start

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

# Loop over each IP and run the scan 
for ip in "${ips[@]}"; do 

    # Start msfconsole with the commands and save output to a file named with IP address
    echo "Running scan on IP $ip with torify..."
    msfconsole -qx "
        workspace -a myworkspace;
        db_nmap -V -A -sV -O -p- --script=vuln $ip;
        hosts -R $ip;
        services -p 1-65535 -R $ip;
        vulns;
        exit
    " > report_$ip.txt

    echo "Scan completed for IP $ip. Now searching for exploits..."
    
    services=$(grep -oP 'Service: \K[^ ]+' report_$ip.txt)

    for service in $services; do
        echo "Searching for exploits for service: $service"
        msfconsole -qx "
            search type:exploit name:$service;
            exit
        " >> report_secondary_$ip.txt

        if [ $? -ne 0 ]; then
            echo "Failed to execute msfconsole command for service: $service"
            exit 1
        fi
    done

    echo "Exploit search completed for IP $ip."
    echo "Script executed successfully on IP $ip"
    echo "Results saved to report_$ip.txt"
    
    # If an email address was provided, send an email notification with the scan results
    if [ -n "$email" ]; then
        echo "Sending email notification to $email..."
        mail -s "Scan Results for IP $ip" $email < report_$ip.txt
    fi

done
