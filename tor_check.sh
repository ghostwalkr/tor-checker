#!/bin/bash
# Checks if an IP is a TOR exit node

query_ip=$1
exitnode_file="/tmp/torchecker-exitnodelist.tmp"

usage() {
	echo "usage: $0 <ip>"
}

# Check number of arguments
if [ $# != 1 ]; then
	echo "[!] Error: script takes 1 argument (IPv4 address)"
	usage
	exit 1
fi

# Check if argument is an IPv4 address
echo "$query_ip" | egrep -q "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
if [ $? != 0 ]; then
	echo "[!] Error: "$query_ip" is not an IPv4 address"
	usage
	exit 1
fi

# Update TOR exit node list
echo "[*] Trying to ping torproject.org..."
ping -c 2 torproject.org &> /dev/null
if [ $? != 0 ]; then
	echo "[!] Couldn't ping torproject.org. Check your internet connection."
	exit 1
else
	echo "[*] Successfully pinged torproject.org"
fi

echo "[*] Updating TOR exit node list..."
which curl &> /dev/null # Check for curl
if [ $? == 0 ]; then
	curl -o $exitnode_file -s https://check.torproject.org/exit-addresses &> /dev/null
else
	which wget &> /dev/null # Check for wget
	if [ $? == 0 ]; then
		wget -O $exitnode_file -q https://check.torproject.org/exit-addresses &> /dev/null
	else
		echo "[!] Couldn't find wget or curl. Please install wget or curl"
		exit 1
	fi
fi

# Remove all text from downloaded file except TOR exit node IPs
egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" $exitnode_file > $exitnode_file.new
rm $exitnode_file
mv $exitnode_file.new $exitnode_file

for ip in $( cat $exitnode_file )
do
	if [ "$query_ip" == "$ip" ]; then
		echo "[*] $query_ip is a TOR exit node"
		exit 0
	fi
done

echo "[*] $query_ip is not a TOR exit node"
exit 0
