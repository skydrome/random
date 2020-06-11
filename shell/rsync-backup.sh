#!/usr/bin/env bash
# github.com/skydrome/random/blob/master/shell/rsync-backup.sh             v1.0

# read user config
source ~/.backup

# additional backup locations
LOCATIONS+=(
    #/mnt/usb{1,2,3}
    #/tmp/backup.$(date -I)
)

# addition backup sources
BACKUP+=(
    #/home
    #/etc
)

# global excludes
EXCLUDE+=(
    /dev /etc/mtab /proc /run /sys /tmp /var/{abs,tmp}
    #/var/cache/pacman/pkg
    /var/lib/pacman/sync
    *.o *.so *.po
    autom4te.cache
    .cache
    .ccache
    .cargo
    .gimp-*/{swap,tmp}
    .gvfs
    .java
    .kde*/{cache,socket,tmp}-*
    .local/share/Trash .Trash lost+found
    .lock .sock .socket
    .mozilla/firefox/*/{Cache,cookies.sqlite}
    .config/chromium/*/{Cookies,History,Local}*
    .zcompcache .zcompdump
    .DS_Store .thumbnails Thumbs.db
    ld.so.cache
    fontconfig
)

# global includes
INCLUDE=(
    /home/$USER/.backup
    #/etc/{bashrc,conf.d}
)

# rsync options
OPTS="-a -u --delete --delete-excluded --protect-args --progress"



# # throttle IO priority to the background
# type -P schedtool &>/dev/null &&
#     NICE="schedtool -D -e" || {
#         ionice -c  3 -p $$
#         renice -n 10 -p $$
#     }

# convert excludes array into rsync options
for (( i=0; i<${#EXCLUDE[@]}; i++ )); do
    EXCLUDE[$i]="--exclude='${EXCLUDE[$i]}'"
done

# create backup location and commence backup
for f in ${LOCATIONS[@]}; do
    #[[ -w "$f" || $(mkdir -p "$f") ]] &&
        sudo $(which rsync) $OPTS \
                   "${EXCLUDE[@]}" \
                   "${INCLUDE[@]}" \
                   "${BACKUP[@]}" "$f" && ran=true
done

# flush fs cache to disk
[[ $ran ]] && sync &
