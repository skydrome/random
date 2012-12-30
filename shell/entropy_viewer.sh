#!/usr/bin/env bash

timer="${1:-0.15}"
poolsize=$(cat /proc/sys/kernel/random/poolsize)

while true; do
    ((i++))

    avail=$(cat /proc/sys/kernel/random/entropy_avail)
    total=$((total+avail))
    perc=$(((avail*100)/poolsize))
    printf "\n current: %4u    avg: %4u\n " "$avail" "$((total/i))"

    while ((perc > 0)); do
        printf "%s" "▁"
        perc=$((perc-4))
    done
    printf " \n 0%25u\n" "$poolsize"

    sleep $timer
    tput cuu 2; tput el; tput cuu 2
done
