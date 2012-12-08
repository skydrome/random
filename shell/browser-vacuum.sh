#!/usr/bin/env bash

#
# COPYRIGHT: You're free to use, modify, redistribute.
#   ONLY IF: What you do with it improves upon the original.
#
# In other words, you cannot use anything from this to write something
# that is inferior to what you took it from.
#

total=0
run_cleaner() {
    while read -rd '' db; do
        # for each file that is an sqlite database vacuum and reindex
        if [[ $(file "$db" | grep SQLite | cut -f1 -d:) ]]; then
            echo -en "${GRN} Cleaning${RST} $db"
            # Record size of each db before and after vacuuming
            s_old=$(stat -c%s "$db")
            (
                trap '' INT TERM
                sqlite3 "$db" "VACUUM;" && sqlite3 "$db" "REINDEX;"
            )
            s_new=$(stat -c%s "$db")
            # convert to kilobytes
            diff=$(((s_old - s_new) / 1024))
            total=$((diff + total))
            (( $diff == 0 )) && diff="∘" || diff="- ${diff}${RST} KB"
            echo -e "$(tput cr)$(tput cuf 46) ${GRN}done${RST} ${YLW}${diff}"
    fi
    done < <(find . -maxdepth 1 -type f -print0)
}

if_running() {
    i=7 # after this timeout, we give up waiting (i*2 seconds)
    [[ $(ps aux | grep -v 'grep' | grep "$1" | grep "$user") ]] &&
        echo -n "Waiting for "$1" to exit"
    # Wait for <user's> <browser> to die
    while [[ $(ps aux | grep "$1" | grep -v 'grep') ]];do
        if (( $i == 0 )); then
            # waited long enough, ask to kill it
            read -p " kill it? [y|n]: " ans
            if [[ "$ans" = @(y|Y|yes) ]]; then
                kill -TERM $(pgrep -u "$user" "$1")
                sleep 4
                # if still running, give monzy the microphone (stanford killdashnine)
                [[ $(ps aux | grep -v 'grep' | grep "$1" | grep "$user") ]] &&
                    kill -KILL $(pgrep -u "$user" "$1")
                break
            fi
        fi
        echo -n "."; sleep 2
        ((i--))
    done
    echo ""
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


for user in $priv; do
#[ FIREFOX ICECAT SEAMONKEY ]#
    # Check for a <browser config> folder in each users home directory
    for b in {firefox,icecat,seamonkey}; do
        echo -en "[${YLW}$user${RST}] ${GRN}Scanning for $b${RST}"
        if [[ -f "/home/$user/.mozilla/$b/profiles.ini" ]]; then
            echo -e "$(tput cr)$(tput cuf 45) [${GRN}found${RST}]"
            # We found one, now run the cleaner for each <browser profile>
            for profiledir in $(grep Path /home/$user/.mozilla/$b/profiles.ini | sed 's/Path=//'); do
                cd /home/$user/.mozilla/$b/$profiledir
                # Check if <browser> is *not* running before cleaning
                if_running "$b" && run_cleaner
            done
        else
            # This user has no <browser config>
            echo -e "$(tput cr)$(tput cuf 45) [${RED}none${RST}]"
            sleep 0.1; tput cuu 1; tput el
        fi
    done

#[ THUNDERBIRD ]#  Useless
#    echo -en "[${YLW}$user${RST}] ${GRN}Scanning for thunderbird${RST}"
#    if [[ -f "/home/$user/.thunderbird/profiles.ini" ]]; then
#        echo -e "$(tput cr)$(tput cuf 45) [${GRN}found${RST}]"
#        for profiledir in $(grep Path /home/$user/.thunderbird/profiles.ini | sed 's/Path=//'); do
#            cd /home/$user/.thunderbird/$profiledir
#            if_running 'thunderbird' && run_cleaner
#        done
#    else
#        echo -e "$(tput cr)$(tput cuf 45) [${RED}none${RST}]"
#    fi

#[ CHROMIUM GOOGLE-CHROME ]#
    for b in {chromium,google-chrome}; do
        echo -en "[${YLW}$user${RST}] ${GRN}Scanning for $b${RST}"
        if [[ -d "/home/$user/.config/$b/Default" ]]; then
            echo -e "$(tput cr)$(tput cuf 45) [${GRN}found${RST}]"
            cd /home/$user/.config/$b/Default
            if_running "$b" && run_cleaner
        else
            echo -e "$(tput cr)$(tput cuf 45) [${RED}none${RST}]"
            sleep 0.1; tput cuu 1; tput el
        fi
    done
done

(( $total > 0 )) &&
    echo -e "\nTotal Space Cleaned: ${YLW}${total}${RST} KB" ||
    echo -e "Nothing done."
