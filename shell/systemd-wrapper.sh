#!/bin/bash
# wrapper for managing systemd services

usage() {
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
exit 0
}

(( $# >= 2 )) && {
    [[ "$1" = @(*start|stop|*able) ]] &&
        action="$1" || usage
    shift
    sudo systemctl --system daemon-reload
    for arg in $* ;do
        echo "${action}ing $arg ... "
        sudo systemctl $action $arg
    done
    exit
}

(( $# <= 1 )) && {
    case "$1" in
        list) systemctl list-units ;;
       fail*) systemctl --failed   ;;
      reboot) echo -n "reboot: [y/n]: "
                while read -n1 answer; do
                case $answer in
                    y|Y|Yes|YES|yes) systemctl reboot ;;
                    *) exit 0 ;;
                esac;done
              ;;
       shut*) systemctl poweroff   ;;
           *) usage
    esac
}
