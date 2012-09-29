#!/bin/bash
# wrapper for managing systemd services

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

(( $# == 2 )) &&
  systemctl "$1" "${2}.service"

(( $# <= 1 )) && {
    case "$1" in
        list) systemctl list-units ;;
       fail*) systemctl --failed   ;;
      reboot) systemctl reboot     ;;
       shut*) systemctl poweroff   ;;
           *) usage && exit        ;;
   esac
}
