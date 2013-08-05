#!/usr/bin/env bash

source ~/.backup

LOCATIONS+=(
    #/mnt/usb
    #/tmp/backup.$(date -I)
)

BACKUP+=(
    #/home
    #/etc
)

EXCLUDE+=(
    /dev
    /etc/mtab
    /proc
    /run
    /sys
    /tmp
    #/var/cache/pacman/pkg
    /var/lib/pacman/sync
    *.o
    *.so
    .cache
    .ccache
    .DS_Store
    .gimp-*/swap
    .gimp-*/tmp
    .gvfs
    .java
    .kde*/cache-*
    .kde*/socket-*
    .kde*/tmp-*
    .local/share/Trash
    .mozilla/firefox/*/Cache
    .thumbnails
    .Trash
    .zcompcache
    .zcompdump
    ld.so.cache
    lost+found
    Thumbs.db
)

INCLUDE=(
    .backup
)

OPTS="--archive --relative --executability --owner --hard-links
      --delete --delete-excluded --sparse --progress"

type -P schedtool &>/dev/null &&
    NICE="schedtool -D -e" || {
        ionice -c  3 -p $$
        renice -n 10 -p $$
    }

for (( i=0; i<${#EXCLUDE[@]}; i++ )); do
    EXCLUDE[$i]="--exclude ${EXCLUDE[$i]}"
done

_rsync() {
    [[ -d "$1" || $(mkdir -p "$1") ]] &&
        eval "sudo "$NICE" \
            rsync "$OPTS" \
                  "${EXCLUDE[@]}" "${INCLUDE[@]}" \
                  "${BACKUP[@]}" "$1"" && ran=true
}

for f in ${LOCATIONS[@]}; do
    _rsync $f
done

[[ $ran ]] && sync &
