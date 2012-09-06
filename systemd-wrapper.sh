#!/bin/bash
# wrapper for managing systemd services

arg1=$1

usage () {
cat <<EOF

    start      |  start a service
    restart    |  reload unit configuration
    stop       |  in the name of love
    enable     |  start at boot

    is-enabled |  check status
    status     |  current state
    disable    |  do not load at boot

    list       |  list all running services
    fail       |  list failed services

    reboot     |  restart
    shut       |  poweroff

EOF
}

actions=("start" "restart" "stop" "enable" "disable")

for i in "${actions[@]}"; do
    [[ "$i" = "$arg1" ]] && super="yes"
done

if [[ $# == 2 && "$super" == "yes" ]]; then
    sudo systemctl "$1" "$2".service
elif (( $# == 2 )); then
    systemctl "$1" "$2".service
fi

if (( $# <= 1 )); then
    case "$1" in
        list) systemctl list-units ;;
       fail*) systemctl --failed   ;;
      reboot) systemctl reboot     ;;
       shut*) systemctl poweroff   ;;
           *) usage && exit        ;;
   esac
fi
