#!/usr/bin/env bash

umask 077
CERT_NAME="$1"
XCHAT_DIR=("$2"
           "~/.xchat"
           "~/.xchat2"
           "~/.config/hexchat/certs")
SUBJECT="/C=AN/ST=ON/L=YM/O=OUS/CN=$HOSTNAME/emailAddress=anon@mous"

if [[ ! $1 ]]; then
    echo -e "\n Usage:"
    echo -e " ./$(basename $0) [Network Name]\n"
    exit 1
fi

for configdir in ${XCHAT_DIR[@]}; do
    [[ -d "$configdir" ]] && break
done

if [[ ! -d "$configdir" ]]; then
    echo -e "\n Cant find your xchat config. Specify it manually:"
    echo -e " ./$(basename $0) [Network Name] [Path to XChat Config Dir]\n"
    exit 1
fi

cd "$configdir"
    openssl req -newkey rsa:2048 -nodes -days 365 -x509 -keyout tmp.key -out tmp.cert -subj "$SUBJECT"
    if [[ $? = 0 ]]; then
        echo "Writing certificate to $CERT_NAME.pem"
        cat tmp.cert tmp.key > ${CERT_NAME}.pem
        rm tmp.cert tmp.key
    else
        echo "Certificate generation failed..."
        exit 2
    fi

echo -e "\n----- NICKSERV FINGERPRINT -----"
echo -e "$(openssl x509 -sha1 -noout -fingerprint -in "$CERT_NAME.pem" | sed -e 's/^.*=//;s/://g;y/ABCDEF/abcdef/')\n"

