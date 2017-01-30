#!/usr/bin/env bash

#
# COPYRIGHT: You're free to use, modify, redistribute.
#   ONLY IF: What you do with it improves upon the original.
#
# In other words, you cannot use anything from this to write something
# that is inferior to what you took it from.
#

RED="\e[01;31m" GRN="\e[01;32m" YLW="\e[01;33m" RST="\e[00m"
format="$(tput cr)$(tput cuf 45)"
total=0

spinner() {
    local _format="$(tput cr)$(tput cuf 51)"
    local str="oO0o.." tmp
    echo -en "$_format"
    while [[ -d /proc/$1 ]]; do
        tmp=${str#?}
        printf "\e[00;31m %c " "$str"
            str="$tmp${str%$tmp}"
            sleep 0.05
        printf "\b\b\b"
    done
    printf "  \b\b\e[00m"
}

run_cleaner() {
    # for each file that is a sqlite database, vacuum and reindex
    local _format="$(tput cr)$(tput cuf 46)"
    while read -r db; do
        echo -en "${GRN} Cleaning${RST}  ${db##'./'}"
        # record size of each file before and after vacuuming
        s_old=$(stat -c%s "$db")
        (   trap '' INT TERM
            sqlite3 "$db" "VACUUM;" && sqlite3 "$db" "REINDEX;"
        ) & spinner $!
        s_new=$(stat -c%s "$db")
        # convert to kilobytes
        diff=$(((s_old - s_new) / 1024))
        total=$((diff + total))
        if (( $diff > 0 ))
            then diff="\e[01;33m- ${diff}${RST} KB"
        elif (( $diff < 0 ))
            then diff="\e[01;30m+ $((diff * -1)) KB${RST}"
            else diff="\e[00;33m∘${RST}"
        fi
        echo -e "${_format} ${GRN}done ${diff}"
    done < <(find . -maxdepth 1 -type f -print0 | xargs -0 file -e ascii | sed -n "s/:.*SQLite.*//p")
    echo
}

if_running() {
    i=7 # after this timeout, we stop waiting (i*2 seconds seems good)
    [[ $(ps aux | grep -v 'grep' | grep "$1" | grep "$user") ]] &&
        echo -n "Waiting for "$1" to exit"
    # wait for <browser> to terminate
    while [[ $(ps aux | grep "$1" | grep -v 'grep') ]];do
        if (( $i == 0 )); then
            # waited long enough, ask if it should be killed
            read -p " kill it? [y|n]: " ans
            if [[ "$ans" = @(y|Y|yes) ]]; then
                kill -TERM $(pgrep -u "$user" "$1")
                sleep 4
                # if still running, give monzy the microphone
                [[ $(ps aux | grep -v 'grep' | grep "$1" | grep "$user") ]] &&
                    kill -KILL $(pgrep -u "$user" "$1")
                break
            fi
        fi
        echo -n "."; sleep 2
        ((i--))
    done
}


# if ran with sudo, then run against all users on system
priv="$USER"
[[ "$EUID" = 0 ]] &&
    # sometimes more accurate depending on distro
    #priv=$(grep 'home' /etc/passwd |cut -d':' -f6 |cut -c7-)

    # assumes user names are same as the user's home directory
    priv=$(find /home -maxdepth 1 -type d |tail -n+2 |cut -c7-)

for user in $priv; do
#[ FIREFOX ICECAT SEAMONKEY ]#
    # check for a <browser config> folder in each users home directory
    for b in {firefox,icecat,seamonkey,aurora}; do
        echo -en "[${YLW}$user${RST}] ${GRN}Scanning for $b${RST}"
        if [[ -f "/home/$user/.mozilla/$b/profiles.ini" ]]; then
            echo -e "$format [${GRN}found${RST}]"
            # check if <browser> is *not* running before cleaning
            if_running "$b"
            # we found one, now run the cleaner for each <browser profile>
            while read -r profiledir; do
                echo -e "[${YLW}$(echo $profiledir | cut -d'.' -f2)${RST}]"
                cd "/home/$user/.mozilla/$b/$profiledir"
                run_cleaner
            done < <(grep Path /home/$user/.mozilla/$b/profiles.ini | sed 's/Path=//')
        else
            # this user has no <browser config>
            echo -e "$format [${RED}none${RST}]"
            sleep 0.1; tput cuu 1; tput el
        fi
    done

#[ CHROMIUM GOOGLE-CHROME VIVALDI]#
    for b in {chromium,chromium-beta,chromium-dev,google-chrome,google-chrome-beta,google-chrome-unstable,vivaldi,vivaldi-snapshot,vivaldi-beta}; do
        echo -en "[${YLW}$user${RST}] ${GRN}Scanning for $b${RST}"
        if [[ -d "/home/$user/.config/$b/Default" ]]; then
            cd /home/$user/.config/$b
            echo -e "$format [${GRN}found${RST}]"
            if_running "$b"
            while read -r profiledir; do
                echo -e "[${YLW}${profiledir##'./'}${RST}]"
                cd "/home/$user/.config/$b/$profiledir"
                run_cleaner
            done < <(find . -maxdepth 1 -type d -iname "Default" -o -iname "Profile*")
        else
            echo -e "$format [${RED}none${RST}]"
            sleep 0.1; tput cuu 1; tput el
        fi
    done
done

(( $total > 0 )) &&
    echo -e "Total Space Cleaned: ${YLW}${total}${RST} KB" || echo "Nothing done."
