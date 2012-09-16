#!/usr/bin/env bash

run_cleaner() {
    while read -rd '' db; do
        # for each file that is an sqlite database vacuum and reindex
        if [[ $(file "$db" | grep SQLite | cut -f1 -d:) ]]; then
            echo -en "${GRN} Cleaning${RST} $db"
            # Record size of each db before and after vacuuming
            s_old=$(stat -c%s "$db")
            sqlite3 "$db" "VACUUM;"
            sqlite3 "$db" "REINDEX;"
            s_new=$(stat -c%s "$db")
            # convert to kilobytes
            diff=$(((s_old - s_new) / 1024))
            echo -e "$(tput cr)$(tput cuf 40)${GRN}done${RST} [ -${YLW}${diff}${RST} KB ]"
    fi
    done < <(find . -maxdepth 1 -type f -print0)
}

if_running() {
    i=5 # after this timeout, we give up waiting (i*2 seconds)
    [[ $(ps aux | grep -v 'grep' | grep "$1" | grep "$user") ]] &&
        echo -n "Waiting for "$1" to exit"
    # Wait for <user's> <browser> to die
    while [[ $(ps aux | grep "$1" | grep -v 'grep') ]];do
        if (( $i == 0 )); then
            echo "giving up"
            return 1
        fi
        echo -n "."; sleep 2
        # tick tock
        ((i--))
    done
}

_firefox() {
    # Check for a <browser config> folder in each users home directory
    echo -en "\n[${YLW}$user${RST}] ${GRN}Scanning for firefox profiles${RST}"
    if [[ -f "/home/$user/.mozilla/firefox/profiles.ini" ]]; then
        echo -e "$(tput cr)$(tput cuf 45) [${GRN}found${RST}]"
        # We found one, now run the cleaner for each <browser profile>
        for profiledir in $(grep Path /home/$user/.mozilla/firefox/profiles.ini | sed 's/Path=//'); do
            cd /home/$user/.mozilla/firefox/$profiledir
            # Check if <browser> is *not* running before cleaning
            if_running 'firefox' && run_cleaner
        done
    else
        # This user has no <browser config>
        echo -e "$(tput cr)$(tput cuf 45) [${RED}none${RST}]"
    fi
}

_thunderbird() {
    echo -en "\n[${YLW}$user${RST}] ${GRN}Scanning for thunderbird profiles${RST}"
    if [[ -f "/home/$user/.thunderbird/profiles.ini" ]]; then
        echo -e "$(tput cr)$(tput cuf 45) [${GRN}found${RST}]"
        for profiledir in $(grep Path /home/$user/.thunderbird/profiles.ini | sed 's/Path=//'); do
            cd /home/$user/.thunderbird/$profiledir
            if_running 'thunderbird' && run_cleaner
        done
    else
        echo -e "$(tput cr)$(tput cuf 45) [${RED}none${RST}]"
    fi
}

_chromium() {
    for b in {chromium,google-chrome}; do
        echo -en "\n[${YLW}$user${RST}] ${GRN}Scanning for $b profiles${RST}"
        if [[ -d "/home/$user/.config/$b/Default" ]]; then
            echo -e "$(tput cr)$(tput cuf 45) [${GRN}found${RST}]"
            cd /home/$user/.config/$b/Default
            if_running "$b" && run_cleaner
        else
            echo -e "$(tput cr)$(tput cuf 45) [${RED}none${RST}]"
        fi
    done
}


##[ int main ]##
RED="\e[01;31m" GRN="\e[01;32m" YLW="\e[01;33m" RST="\e[00m"
priv="$USER"

# If we have sudo privs then run for all users on system, else just run on self
[[ "$EUID" = 0 ]] &&
    # This is slow but sometimes more accurate depending on distro
    #priv=$(grep 'home' /etc/passwd | cut -d':' -f6 | cut -c7-)

    # This is a couple milliseconds faster but assumes user names are same as the user's home directory
    priv=$(find /home -maxdepth 1 -type d | tail -n+2 | cut -d':' -f6 | cut -c7-)

for user in "$priv"; do
    _firefox
    _thunderbird
    _chromium
done
