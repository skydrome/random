#!/usr/bin/env bash

RED="\e[01;31m" GRN="\e[01;32m" YLW="\e[01;33m" RST="\e[00m"

run_cleaner() {
    while read -rd '' db; do
    if [[ $(file "$db" | grep SQLite | cut -f1 -d:) ]]; then
        echo -en "${GRN} Cleaning${RST} $db"
        # Record size of each db before and after vacuuming
        s_old=$(stat -c%s "$db")
        sqlite3 "$1" "VACUUM;" && sqlite3 "$db" "REINDEX;"
        s_new=$(stat -c%s "$db")
        diff=$(((s_old - s_new) / 1024))
        echo -e "$(tput cr)$(tput cuf 40)${GRN}done${RST} [ -${YLW}${diff}${RST} KB ]"
    fi
    done < <(find . -maxdepth 1 -type f -print0)
}

if_running() {
    # TODO: pgrep against $USER from /home/$USER
    # Check if browser is running, wait for it to exit
    [[ $(ps aux | grep "$1" | grep -v 'grep') ]] &&
        echo -n "Waiting for "$1" to exit"
    while [[ $(ps aux | grep "$1" | grep -v 'grep') ]]; do
        echo -n "."; sleep 2
    done
}

_firefox() {
    # Check for a .mozilla folder in each users home directory
    for dir in $(cat /etc/passwd | grep "home" | cut -d':' -f6); do
        echo -en "\n${GRN}Scanning for firefox profiles in ${YLW}${dir}${RST}  "
        if [[ -f "$dir/.mozilla/firefox/profiles.ini" ]]; then
            echo -e " [${GRN}found${RST}]"
            # Figure out the profiles name
            for profiledir in $(grep Path $dir/.mozilla/firefox/profiles.ini | sed 's/Path=//'); do
                cd $dir/.mozilla/firefox/$profiledir
                if_running 'firefox'
                run_cleaner
            done
        else
            echo -e "[${RED}none${RST}]"
        fi
    done
}

_chromium() {
    # Check for a .config/chromium folder in each users home directory
    for dir in $(cat /etc/passwd | grep "home" | cut -d':' -f6); do
        echo -en "\n${GRN}Scanning for chromium profiles in ${YLW}${dir}${RST} "
        if [[ -d "$dir/.config/chromium/Default" ]]; then
            echo -e "[${GRN}found${RST}]"
            cd $dir/.config/chromium/Default
            if_running 'chromium'
            run_cleaner
        else
            echo -e "[${RED}none${RST}]"
        fi
    done
}

_firefox
_chromium
