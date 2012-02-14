#!/usr/bin/env bash

if [[ $# = 0 ]]; then
    echo "Please supply an apache error log file as an argument."
else

today=$(date +"%b %d")
blocks=$(grep "$today" $1 |grep "code 403" | wc -l)
problems=$(grep "$today" $1 | grep "code 403" | awk -F "/" '{print $6}' | awk -F " " '{print $1,$2,$3,$4,$5}'| sort | uniq)

    echo "##########- ModSecurity Report $today -###########"
    echo "403's Today $blocks"
    echo "#---------- Here is a list of Problems ----------#"
    echo "$problems "
    echo "##################################################"
fi
exit
