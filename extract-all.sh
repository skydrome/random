#!/usr/bin/env bash

extract() {  # find type of compression and extract accordingly
    case "$1" in
        *.tar.bz2) tar xjf    "$1" ;;
        *.tbz2   ) tar xjf    "$1" ;;
        *.tar.gz ) tar xzf    "$1" ;;
        *.tgz    ) tar xzf    "$1" ;;
        *.tar    ) tar xf     "$1" ;;
        *.gz     ) gunzip -q  "$1" ;;
        *.bz2    ) bunzip2 -q "$1" ;;
        *.rar    ) unrar x    "$1" ;;
        *.zip    ) unzip      "$1" ;;
        *.Z      ) uncompress "$1" ;;
        *.7z     ) 7z x       "$1" ;;
    esac
}

for FILE in $(find . -type f); do
    extract "$FILE"
done
