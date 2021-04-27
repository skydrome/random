#!/usr/bin/env bash

CERT_NAME="$1"
XCHAT_DIR=(
    "$2"
    "$HOME/.config/hexchat/certs"
)

SUBJECT="/C=AN/ST=ON/L=YM/O=OUS/CN=$HOSTNAME/emailAddress=anon@mous"

if [[ ! $1 ]]; then
    echo -e " Usage:\n ./$(basename $0) [Network Name]"
    exit 0
fi

for configdir in ${XCHAT_DIR[@]}; do
    [[ -d "$configdir" ]] && break
done

if [[ ! -d "$configdir" ]]; then
    echo "Cant find your hexchat config. Specify it manually:"
    echo " ./$(basename $0) [Network Name] [Path to HexChat Config Dir]"
    exit 1
fi

if [[ -f "$configdir/$1.pem" ]]; then
    echo "$1.pem already exists"
    exit 1
fi

cd $(mktemp -d)
    # 10yrs
    openssl req -newkey rsa:4096 -nodes -days 3650 -x509 -keyout tmp.key -out tmp.cert -subj "$SUBJECT"
    if [[ $? = 0 ]]; then
        echo "writing certificate to '$CERT_NAME.pem'"
        cat tmp.cert tmp.key > "${CERT_NAME}.pem"
        chmod 400 "${CERT_NAME}.pem"
        mv "${CERT_NAME}.pem" "$configdir"
        rm -rf $(pwd)
    else
        echo "certificate generation failed..."
        exit 2
    fi

echo -e "\n----- NICKSERV FINGERPRINT -----"
echo -e "SHA1:  $(openssl x509 -noout -fingerprint -in "$configdir/${CERT_NAME}.pem" -sha1   |sed -e 's/^.*=//;s/://g')\n"
echo -e "SHA256:$(openssl x509 -noout -fingerprint -in "$configdir/${CERT_NAME}.pem" -sha256 |sed -e 's/^.*=//;s/://g')\n"
