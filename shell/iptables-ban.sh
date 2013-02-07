#!/bin/bash

our_ip() {
    tmp="/tmp/$(basename $0).cache"
    if [[ ! -f "$tmp" || $(( $(date +"%s") - $(stat -c "%Y" $tmp) )) > 86400 ]]; then
        IP=$(dig myip.opendns.com @resolver1.opendns.com +short) ||
        IP=$(curl -s http://ifconfig.us) ||
        IP=$(wget -qO- http://icanhazip.com) ||
        IP=$(wget -qO- http://checkip.dyndns.org | sed 's/.*ss:\ //;s/<\/b.*//') ||
        IP=$(wget -qO- http://myip.dnsomatic.com) ||
        IP=$(wget -qO- http://ipecho.net/plain) ||
        IP=$(curl --silent 'https://www.google.com/search?q=what+is+my+ip' | sed 's/.*Client IP address: //;s/).*//;q')
        echo $IP >"$tmp"
    fi
    echo $(cat "$tmp")
}

check() {
    OLD_IFS=$IFS IFS=.
    set -- $1
    if (( $# == 4 )); then
        for seg; do
            case $seg in
                *[!0-9]*)
                    echo "invalid: $seg"
                    exit ;;

                *)  (( seg > 255 )) && {
                        echo "invalid: $seg"
                        exit
                    } ;;
            esac
        done
    else
        echo "invalid: length"
        exit
    fi
    IFS=$OLD_IFS

    [[ $addr = @($(our_ip)|127.0.0.1) ]] && {
        echo "invalid: dont ban yourself!"
        exit
    }
}

read -p "Enter the IP to BAN and press [ENTER]: " addr
check "$addr"

echo -n "Adding $addr to iptables ... "
iptables -A INPUT -s $addr -j DROP
[[ $? = 0 ]] && echo 'done' || echo 'failed'
