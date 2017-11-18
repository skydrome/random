#!/usr/bin/env bash
export LC_ALL=C

#++++++++++#++++++++++#++++++++++#++++++++#
PASSKEY=''
HOST=""
OPTS="--user-agent uTorrent/2220"
PEER_ID='-UT2220-%85O%CB%44%F6JPz%FP21%4E'
#++++++++++#++++++++++#++++++++++#++++++++#

# install ruby script to get torrent info_hash
if [[ ! -x "$HOME/bin/hash.rb" ]]; then
    sudo pacman -S --noconfirm --needed -q ruby
    gem install -Nq bencode

    cd "$HOME/bin"
cat > hash.rb <<EOF
#!/usr/bin/env ruby
require 'bencode'
require 'digest/sha1'
ARGV.each do|file|
    torrent     = BEncode.load_file( file )
    info_hash   = Digest::SHA1.hexdigest( torrent['info'].bencode )
    puts "#{info_hash.upcase}"
end
EOF
    chmod +x hash.rb
fi

urldecode() {
    echo "$1" |sed -e's/%\([0-9A-F][0-9A-F]\)/\\\\\x\1/g' |xargs echo -e
}

engage_afterburner() {
    local mb gb lo hi
    mb=1000000
    gb=1000000000

    # Assuming announce every 30minutes and upload at 1 MB/s
    # 1mB/s * 60 * 30 = 1.8GB

    lo=$(( mb * 250 ))
    hi=$(( gb * 2 ))

    shuf -i ${lo}-${hi} -n1
}

cd "$HOME/Downloads"
find . -maxdepth 1 -type f -name '*.torrent' -print0 |while IFS= read -r -d '' f; do
    # convert spaces to underlines in filenames
    file=$(echo "$f" |sed 's/ /\_/g')
    [[ ! -f "$file" ]] && mv "$f" "$file"

    # get info_hash and decode alphanum characters
    hash.rb "$file" | sed "s/.\{2\}/&\n/g" |sed '$ d' \
        | while read line; do
            _test=$(urldecode "%${line}")
            case "$_test" in
            [a-zA-Z]) # good decode
                      _HASH+="$_test" ;;
                   *) # character is rubbish keep it encoded
                      _HASH+="%$line" ;;
            esac
        # for some reason this variable disappears out of this loop
        echo "$_HASH" >.tmp
    done
    HASH=$(cat .tmp)
    rm -f .tmp

    # and bob's your auntie
    curl $OPTS ${HOST}/${PASSKEY}/announce?info_hash=${HASH}&peer_id=${PEER_ID}&port=31515&uploaded=$(engage_afterburner)&downloaded=0&left=0&compact=1&event=completed

done
