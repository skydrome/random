#!/usr/bin/env bash

webserver='httpd'  # name of webserver process

while true; do
    for ip in $(lsof -ni | grep "$webserver" | grep -iv listen | awk '{print $8}' | cut -d : -f 2 | sort | uniq | sed s/"http->"//); do
        numconns=$(lsof -ni | grep -c $ip)
        echo "$ip : $numconns"
        if (( "$numconns" > 10 )); then
            echo "$(date) $ip has $numconns connections.  Total connections to prod spider:  $(lsof -ni | grep "$webserver" | grep -iv listen | wc -l)" >> /root/dos.log
            iptables -I INPUT -s "$ip" -p tcp -j REJECT --reject-with tcp-reset
        fi
    done
sleep 60
done
