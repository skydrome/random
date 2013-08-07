#!/usr/bin/env bash

I2P=/opt/i2p

if (( "$#" < 1 )); then
    echo "This script looks up an I2P destination by b32 address"
    echo "If the destination is not found, \"null\" is printed"
    echo
    echo "Usage: $0 <b32>"
    echo
    echo "Do not include the .b32.i2p part at the end"
    exit 1
fi

java -cp $I2P/lib/i2p.jar net.i2p.client.naming.LookupDest "$1"
