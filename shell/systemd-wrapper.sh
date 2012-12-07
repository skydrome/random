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
exit
}

(( $# >= 2 )) && {
    [[ "$1" = @(*start|stop|*able) ]] &&
        action="$1" || usage
    shift
    sudo systemctl --system daemon-reload
    for arg in $* ;do
        echo -n "${action}ing $arg ... "
        sudo systemctl $action $arg
        [[ $? = 0 ]] && echo 'done' || echo 'fail'
        #sleep 2
    done
    exit
}

(( $# <= 1 )) && {
    case "$1" in
        list) systemctl list-units ;;
       fail*) systemctl --failed   ;;
      reboot) systemctl reboot     ;;
       shut*) systemctl poweroff   ;;
           *) usage
    esac
}
