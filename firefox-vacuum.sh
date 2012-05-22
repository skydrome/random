#!/usr/bin/env bash

RED="\e[01;31m" GRN="\e[01;32m" YLW="\e[01;33m" RST="\e[00m"

# Check if firefox is running, exit if it is
if [[ $(ps aux | grep 'firefox' | grep -v 'grep' | grep -v 'vacuum') ]]; then
    echo -e "${RED} Error: Firefox is still running.${RST}"
    exit 1
fi

# Check for a .mozilla folder in each users home directory
for dir in $(cat /etc/passwd | grep "home" | cut -d':' -f6); do
    echo -en "\n${GRN}Scanning for firefox profiles in ${YLW}${dir}${RST}  "
    if [[ -f "$dir/.mozilla/firefox/profiles.ini" ]]; then
        echo -e "[${GRN}found${RST}]"
        # Figure out the profiles name
        for profiledir in $(cat "$dir/.mozilla/firefox/profiles.ini" | grep 'Path=' | sed -e 's/Path=//'); do
            cd $dir/.mozilla/firefox/$profiledir
            # Vacuum each sqlite db
            for db in $(find . -maxdepth 1 -type f -name '*.sqlite'); do
                echo -en "${GRN} Cleaning${RST} ${db}"
                    # Record size of each db before and after vacuuming
                    s_old=$(stat -c%s "$db")
                    (sqlite3 $db "VACUUM;" && sqlite3 $db "REINDEX;")
                    s_new=$(stat -c%s "$db")
                    diff=$(((s_old - s_new) / 1024))
                echo -e "$(tput cr)$(tput cuf 36)${GRN}done${RST} [-${YLW}${diff}${RST} KB]"
            done
        done
    else echo -e "[${RED}none${RST}]"
    fi
done
