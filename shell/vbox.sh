#!/bin/bash

vm="${2:-}"
password="${3:-}"

case "$1" in
    start)
        vboxmanage startvm "$vm" --type headless ||exit 1
        i=0
        while [[ ! $(vboxmanage showvminfo "$vm" |grep State |grep -E "running|paused") ]]; do
            if (( i > 5 )); then
                echo "Failed to start!"
                exit 1
            fi
            ((i++))
            sleep 5
        done
        if [[ ! -z "$password" || "$password" = "" ]]; then
            echo "$password" >pass
            vboxmanage controlvm "$vm" removeallencpasswords
            sleep 1
            vboxmanage controlvm "$vm" addencpassword "$vm" pass --removeonsuspend yes
            rm -f pass
        fi
        ;;

    save)
        echo "Saving machine state ..."
        vboxmanage controlvm "$vm" savestate
        ;;
    stop)
        echo "Stopping VM ..."
        vboxmanage controlvm "$vm" poweroff
        ;;
    *)
        echo "Usage:"
        echo "$(basename $0)  start|stop|save [vm name] [password]"
        ;;
esac
