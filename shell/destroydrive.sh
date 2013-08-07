#!/usr/bin/env bash

if [[ ! $(type -P "openssl") || \
        ! $(type -P "pv") || \
        ! $(type -P "hdparm") ]]; then
    echo "Please make sure the following are installed:
 OpenSSL
 HDPARM
 PV"
    exit 1
else
    echo "
        # NOTE: http://billauer.co.il/frandom.html
        #       http://www.issihosts.com/haveged
        # if you have a large hard drive, you will want to use frandom
        # along with running the haveged daemon for a great speed boost
        "
    echo -n "Continuing in 10 seconds... "; i=9
    while (($i > 0)); do echo -en "\b$i.\b \b"; sleep 1; ((i--)); done
fi
exit

if [[ "$1" = /dev/* && -b "$1" ]]; then
        key=$(tr -cd '[:graph:] ' < /dev/urandom | head -c 48)
        openssl enc -aes256 -k "$key" < /dev/urandom | pv -trb > "$1"
        # reset drive configuration back to factory defaults
        hdparm --yes-i-know-what-i-am-doing --dco-restore "$1"
else
    echo -e "Please supply a valid hard drive to wipe: EX: /dev/sda \n"
fi

# If you need to unlock your drive:
#hdparm --user-master u --security-set-pass p <device>
#hdparm --user-master u --security-unlock p   <device>
#hdparm --user-master u --security-disable p  <device>

# If your drive supports secure erase:
#hdparm --user-master u --security-erase p <device>
