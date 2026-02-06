#!/usr/bin/env bash
# use client.pem for default

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

for configdir in "${XCHAT_DIR[@]}"; do
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

cd "$(mktemp -d)" ||exit 1
    echo "writing certificate to '$CERT_NAME.pem'"
    openssl req -newkey ed25519 -nodes -days 7300 -x509 -keyout "${CERT_NAME}.pem" -out "${CERT_NAME}.pem" -subj "$SUBJECT"
    if (( $? == 0 )); then
        chmod 400 "${CERT_NAME}.pem"
        mv -v "${CERT_NAME}.pem" "$configdir"
        rm -r "$(pwd)"
    else
        echo "certificate generation failed..."
        exit 2
    fi

echo "FINGERPRINTS:"
echo "SHA256: $(openssl x509 -noout -fingerprint -in "$configdir/${CERT_NAME}.pem" -sha256 |awk -F= '{gsub(":",""); print($2)}')"
echo "SHA512: $(openssl x509 -noout -fingerprint -in "$configdir/${CERT_NAME}.pem" -sha512 |awk -F= '{gsub(":",""); print($2)}')"
