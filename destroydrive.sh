#!/usr/bin/env bash

if [[ ! $(type -P "openssl") || \
        ! $(type -P "pv") || \
        ! $(type -P "hdparm") ]]; then
    echo "Please make sure the following are installed:
 OpenSSL
 HDPARM
 PV"
    exit 1
fi

if [[ "$1" = /dev/* && -b "$1" ]]; then
        # NOTE: http://billauer.co.il/frandom.html
        # if you have a large hard drive, you may want to try frandom
        # it claims to be 10-50x faster
        key=$(tr -cd '[:graph:] ' < /dev/urandom | head -c 48)
        openssl enc -aes256 -k "$key" < /dev/urandom | pv -trb > "$1"
        hdparm --yes-i-know-what-i-am-doing --dco-restore "$1"
else
    echo -e "Please supply a valid hard drive to wipe: EX: /dev/sda \n"
fi
