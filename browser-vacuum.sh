#!/usr/bin/env bash

RED="\e[01;31m" GRN="\e[01;32m" YLW="\e[01;33m" RST="\e[00m"

_worker() {
RED="\e[01;31m" GRN="\e[01;32m" YLW="\e[01;33m" RST="\e[00m"
if [[ $(file $1 | grep SQL | cut -f1 -d:) ]]; then
    echo -en "${GRN} Cleaning${RST} $1"
    # Record size of each db before and after vacuuming
    s_old=$(stat -c%s "$1")
    (sqlite3 "$1" "VACUUM;" && sqlite3 "$1" "REINDEX;")
    s_new=$(stat -c%s "$1")
    diff=$(((s_old - s_new) / 1024))
    echo -e "$(tput cr)$(tput cuf 36)${GRN}done${RST}  [ -${YLW}${diff}${RST} KB ]"
fi
}

_running() {
    # Check if browser is running, wait for it to exit
    [[ $(ps aux | grep "$1" | grep -v 'grep' | grep -v 'vacuum') ]] &&
        echo -n "Waiting for "$1" to exit"
    while [[ $(ps aux | grep "$1" | grep -v 'grep' | grep -v 'vacuum') ]]; do
        echo -n "."; sleep 2
    done
}

_firefox() {
    _running 'firefox'
    # Check for a .mozilla folder in each users home directory
    for dir in $(cat /etc/passwd | grep "home" | cut -d':' -f6); do
        echo -en "\n${GRN}Scanning for firefox profiles in ${YLW}${dir}${RST}  "
        if [[ -f "$dir/.mozilla/firefox/profiles.ini" ]]; then
            echo -e " [${GRN}found${RST}]"
            # Figure out the profiles name
            for profiledir in $(grep Path $dir/.mozilla/firefox/profiles.ini | sed 's/Path=//'); do
                cd $dir/.mozilla/firefox/$profiledir
                find . -maxdepth 1 -name '*.sqlite' -print0 | xargs -0 -n1 -I{} bash -c "_worker {}"
            done
        else
            echo -e "[${RED}none${RST}]"
        fi
    done
}

_chromium() {
    _running 'chromium'
    # Check for a .config/chromium folder in each users home directory
    for dir in $(cat /etc/passwd | grep "home" | cut -d':' -f6); do
        echo -en "\n${GRN}Scanning for chromium profiles in ${YLW}${dir}${RST}  "
        if [[ -d "$dir/.config/chromium/Default" ]]; then
            echo -e "[${GRN}found${RST}]"
            cd $dir/.config/chromium/Default
            find . -maxdepth 1 -type f -print0 | xargs -0 -n1 -I{} bash -c "_worker {}"
        else
            echo -e "[${RED}none${RST}]"
        fi
    done
}

export -f _worker
_firefox
_chromium
