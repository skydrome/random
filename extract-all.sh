#!/usr/bin/env bash

extract() {  # find type of compression and extract accordingly
    case "$1" in
        *.tar.bz2|*.tbz|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz ) tar xzf "$1" ;;
        *.tar.xz|*.txz ) tar --xz -xf "$1" || xzcat "$1" | tar xvf - ;;
        *.tar.zma|*.tlz) tar --lzma -xvf "$1" || lzcat "$1" | tar xvf - ;;
        *.tar ) tar xf      "$1" ;;
        *.gz  ) gunzip -q   "$1" ;;
        *.bz2 ) bunzip2 -q  "$1" ;;
        *.xz  ) unxz        "$1" ;;
        *.lzma) unlzma      "$1" ;;
        *.rar ) unrar e -ad "$1" ;;
        *.zip ) unzip       "$1" ;;
        *.Z   ) uncompress  "$1" ;;
        *.7z  ) 7za x       "$1" ;;
    esac
}

for FILE in $(find . -type f); do
    extract "$FILE"
done
