#!/usr/bin/env bash

if [[ $UID != 0 ]]; then
    echo 'Run with sudo'
    exit 1
fi

url='http://www.mvps.org/winhelp2002/hosts.txt'

echo "Downloading '$url'... "
wget "$url" -O- > /tmp/hosts
if [[ $? != 0 ]]; then
    echo 'FAILED'
    exit 1
fi
echo 'OK'

grep '^127' /tmp/hosts |
    sed 's/^127\.0\.0\.1\s*/0.0.0.0 /g; s/ #.*//; s/\x0D$//' |
        sort -u >> /etc/hosts

rm /tmp/hosts
echo 'DONE'
