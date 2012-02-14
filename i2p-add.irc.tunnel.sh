#!/usr/bin/env bash

if [[ "$#" < 3 ]]; then
    cat << EOF
 USAGE:
 ./$(basename $0) <path> <host> <port>

 ARGS:
 path ....... Full path to your i2p tunnel list, if you have already
              ran I2P before this script, you may have to use
              /home/<user>/.i2p/i2ptunnel.config
 host ....... The IRC server's address you want to access
 port ....... A local open port to use

 EXAMPLE:
 ./$(basename $0) "/etc/i2p/i2ptunnel.config" "irc.sp00nf33d.i2p" "6669"

EOF
    exit 0
fi

die() {  # shout bloody messages
    echo -e "\e[1;31mERROR:\e[0;31m $1 \e[0m \n"
    exit 1
}

run_checks() {  # brain check
    [[ "${I2PTUNNEL##*/}" != "i2ptunnel.config" ]] && die "Wrong file"
    [[ ! -w "$I2PTUNNEL" ]] && die "$I2PTUNNEL : No write permission."
    [[ "$IRC_HOST" != @(*.*) ]] && die "$IRC_HOST : Not a valid hostname."
    [[ "$LOCAL_PORT" -eq 6668 || "$LOCAL_PORT" -lt 1024 || "$LOCAL_PORT" -gt 65535 ]] && die "$LOCAL_PORT : Invalid port."
    [[ "$NUM" -lt 7 ]] && die "$NUM : Not a valid tunnel identifier."
}

add_tunnel() {
cat >> "$I2PTUNNEL" << EOF
tunnel.${NUM}.name=IRC Proxy
tunnel.${NUM}.description=
tunnel.${NUM}.type=ircclient
tunnel.${NUM}.sharedClient=false
tunnel.${NUM}.interface=127.0.0.1
tunnel.${NUM}.listenPort=${LOCAL_PORT}
tunnel.${NUM}.targetDestination=${IRC_HOST}
tunnel.${NUM}.i2cpHost=127.0.0.1
tunnel.${NUM}.i2cpPort=7654
tunnel.${NUM}.option.inbound.nickname=IRC Proxy
tunnel.${NUM}.option.outbound.nickname=IRC Proxy
tunnel.${NUM}.option.i2cp.closeIdleTime=1200000
tunnel.${NUM}.option.i2cp.closeOnIdle=true
tunnel.${NUM}.option.i2cp.delayOpen=true
tunnel.${NUM}.option.i2cp.newDestOnResume=false
tunnel.${NUM}.option.i2cp.reduceIdleTime=600000
tunnel.${NUM}.option.i2cp.reduceOnIdle=true
tunnel.${NUM}.option.i2cp.reduceQuantity=1
tunnel.${NUM}.option.i2p.streaming.connectDelay=1000
tunnel.${NUM}.option.i2p.streaming.maxWindowSize=16
tunnel.${NUM}.option.inbound.length=3
tunnel.${NUM}.option.inbound.lengthVariance=0
tunnel.${NUM}.option.outbound.length=3
tunnel.${NUM}.option.outbound.lengthVariance=0
tunnel.${NUM}.startOnLoad=true
EOF
}

#[ VARIABLES ]#
I2PTUNNEL=$1   # path to our i2ptunnel.config file
IRC_HOST=$2    # our irc i2p hostname
LOCAL_PORT=$3  # our local port

# A default i2p installation already has 7 tunnels, labeled from 0 -> 6
# default is set to num=7 unless our 4th argument changes it.
NUM=${4:-7}

#[ MAIN ]#
run_checks  # make sure the user used their brain before keyboard
add_tunnel  # add our irc tunnel to their i2p tunnel list
echo "Done."
exit 0
