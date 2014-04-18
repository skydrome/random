#!/usr/bin/env bash

# leave unset for random values
up=
down=
ping=
serverid=

CURL="curl -s"
#CURL+=" --socks5-hostname 127.0.0.1:9050"

get_location() {
    local loc lat lon
    loc=($($CURL ipinfo.io \
        |grep loc |sed 's/"loc": "//;s/",//;s/ //g;s/,/ /'))

    lat="$(echo ${loc[0]} |cut -d'.' -f1)."
    lon="$(echo ${loc[1]} |cut -d'.' -f1)."

    echo $($CURL http://www.speedtest.net/speedtest-servers.php \
        |grep "lat=\"$lat.*lon=\"$lon" \
        |head -n1 |sed 's/.*id="//;s/"  host.*//;s/".*\/>//')
}

get_rand() {
    echo $(( $(tr -cd '[:digit:]'</dev/urandom \
        |head -c 6 |sed 's/ //g;s/^0*//') % 1999900))
}

spoof() {
    local u d p s h
    u=${up:-$(get_rand)}; d=${down:-$(get_rand)}; p=${ping:-$((RANDOM % 100 + 1))}
    s=${serverid:-$(get_location)}
    h=$(echo -n "$p-$u-$d-297aae72" |md5sum |cut -d' ' -f1)

    echo $($CURL 'http://www.speedtest.net/api/api.php'\
            --referer 'http://c.speedtest.net/flash/speedtest.swf' \
            -F hash="$h" -F ping="$p" -F upload="$u" -F download="$d" -F serverid="$s" \
        |cut -d'&' -f1 |cut -d'=' -f2)
}

echo " http://www.speedtest.net/result/$(spoof).png "
