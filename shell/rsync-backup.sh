#!/usr/bin/env bash

# read user config
source ~/.backup

# additional backup locations
LOCATIONS+=(
    #/mnt/usb
    #/tmp/backup.$(date -I)
)

# addition backup sources
BACKUP+=(
    #/home
    #/etc
)

# global excludes
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

# global includes
INCLUDE=(
    /home/$USER/.backup
)

# rsync options
OPTS="--archive --relative --executability --owner --hard-links
      --delete --delete-excluded --sparse --protect-args --progress"

# throttle IO priority to the background
type -P schedtool &>/dev/null &&
    NICE="schedtool -D -e" || {
        ionice -c  3 -p $$
        renice -n 10 -p $$
    }

# convert excludes array into rsync options
for (( i=0; i<${#EXCLUDE[@]}; i++ )); do
    EXCLUDE[$i]="--exclude '${EXCLUDE[$i]}'"
done

# create backup location and commence backup
_rsync() {
    [[ -d "$1" || $(mkdir -p "$1") ]] &&
        eval "sudo "$NICE" $(which rsync) \
                   "$OPTS" \
                   "${EXCLUDE[@]}" \
                   "${INCLUDE[@]}" \
                   "${BACKUP[@]}" "$1"" && ran=true
}

for f in ${LOCATIONS[@]}; do
    _rsync $f
done

# flush fs cache to disk
[[ $ran ]] && sync &
