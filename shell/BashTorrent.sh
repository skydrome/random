#!/usr/bin/env bash
#shellcheck disable=SC2317

#++++++++++#++++++++++#++++++++++#++++++++#
OPTS+=(--user-agent uTorrent/2220)
OPTS+=(--proxy socks5h://127.0.0.1:9050)
PEER_ID='-UT2220-jVbyEgNLh5q5'
PORT=$(shuf -i 6881-64999 -n1)
ANNOUNCE_INTERVAL=1800
#++++++++++#++++++++++#++++++++++#++++++++#

# install ruby to get torrent info
command -v ruby >/dev/null ||
    sudo pacman -S --noconfirm --needed -q ruby
ruby -e "require 'bencode'" >/dev/null ||
    gem install bencode

twenty_bite_me() {
    local padding
    # echo -n "[+] padding PEER_ID to 20 bytes... " >&2
    padding=$(head -c 1000 /dev/urandom |tr -dc 'a-zA-Z0-9' |head -c $((20 - ${#PEER_ID})))
    # echo "$padding" >&2
    echo "${PEER_ID}${padding}"
}

urldecode() {
    printf '%b\n' "${1//%/\\x}" |tr -d '\0'
}

engage_afterburner() {
    local mb gb lo hi fire
    mb=1000000
    gb=1000000000

    # Assuming announce every 30minutes and upload at 1 MB/s
    # 1mB/s * 60 * 30 = 1.8GB

    lo=$(( mb * 250 ))
    hi=$(( gb * 2 ))

    fire=$(shuf -i ${lo}-${hi} -n1)
    echo "[+] sending... $((fire / mb)) mb" >&2
    echo "$fire"
}

get_torrent_info() {
    local IFS='|'
    read -r name announce_url hash < <(TORRENT="$1" ruby <<RUBY
        require 'bencode'
        require 'digest/sha1'
        begin
          torrent = BEncode.load_file(ENV['TORRENT'])
          name = torrent['info']['name']
          announce_url = torrent['announce']
          info_hash = Digest::SHA1.hexdigest(torrent['info'].bencode)
          puts "#{name}|#{announce_url}|#{info_hash}"
        end
RUBY
    ) || {
        echo "Error parsing torrent" >&2
        return 1
    }
}

cd "$HOME/Downloads" ||exit 1

while true; do
    for ((i=ANNOUNCE_INTERVAL; i>=0; i-=1)); do
        [[ ! $__ranonce__ ]] && i=0
        minutes=$((i / 60))
        seconds=$((i % 60))
        printf "\rNext announce in %02d:%02d" "$minutes" "$seconds"
        sleep 1
    done
    echo -ne "\r"

    total=$(find . -maxdepth 1 -type f -name '*.torrent' |wc -l)
    current=0

    while IFS= read -r -d '' file; do
        get_torrent_info "$file"

        ((++current))
        echo "[$current/$total] $name" >&2
        #echo "[+] torrent hash... $hash" >&2

        unset HASH
        for ((i=0; i<${#hash}; i+=2)); do
            line="${hash:$i:2}"
            _test=$(urldecode "%${line}")
            case "$_test" in
                [a-zA-Z]) # good decode
                    HASH+="$_test" ;;
                *) # character is rubbish keep it encoded
                    HASH+="%$line" ;;
            esac
        done
        #echo "[+] encoded hash... $HASH" >&2

        # and bob's your auntie
        url="${announce_url}?info_hash=${HASH}&peer_id=$(twenty_bite_me)&port=${PORT}&uploaded=$(engage_afterburner)&downloaded=0&left=0&compact=1&numwant=0&event=completed"
        curl -s "${OPTS[@]}" "$url" --output - |ruby -rbencode -e "puts BEncode.load(STDIN).inspect"
        #echo "curl ${OPTS[*]} '$url'"
        echo

    done < <(find . -maxdepth 1 -type f -name '*.torrent' -print0)
    __ranonce__=1
done
