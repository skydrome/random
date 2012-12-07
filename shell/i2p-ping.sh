#!/usr/bin/env bash

I2P=/opt/i2p
DEST="$1"

pinger() {
    java -cp $I2P/lib/i2ptunnel.jar:$I2P/lib/mstreaming.jar:$I2P/lib/streaming.jar:$I2P/lib/i2p.jar net.i2p.i2ptunnel.I2PTunnel -cli "$@"
}

cd $I2P/.i2p

if [[ "$DEST" ]]; then
    coproc PING { pinger; }
    KILLPID=$!
    trap 'kill $KILLPID' 0

    out=${PING[0]}
    in=${PING[1]}

    echo "ping -n 10 -t 20000 $DEST" >&$in
    while read -rt60 line <&$out
    do
        echo "[$(date -u +%H:%M:%S)]  $line"
        case "$line" in
            *Pinger\ closed*)
                echo quit >&$in
                exit 0 ;;
        esac
    done

    echo "[TIMEOUT]"
    exit 2
else
    pinger
fi
