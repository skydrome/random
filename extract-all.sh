#!/usr/bin/env bash

# find type of compression and extract accordingly
extract_dir="$( echo "$file_name" | sed "s/\.${1##*.}//g" )"
for i in "$@" ;do
    case "$1" in
      *.tar.gz|*.tgz        ) tar xzf "$1" ;;
      *.tar.bz2|*.tbz|*.tbz2) tar xjf "$1" ;;
      *.tar.xz|*.txz        ) tar --xz --help &> /dev/null &&
                              tar --xz -xf "$1" ||
                              xzcat "$1" | tar xf - ;;
      *.tar.zma|*.tlz       ) tar --lzma --help &> /dev/null &&
                              tar --lzma -xf "$1" ||
                              lzcat "$1" | tar xf - ;;
      *.tar.lrz) lrzuntar    "$1" ;;
      *.lrz    ) lrunzip     "$1" ;;
      *.tar    ) tar xf      "$1" ;;
      *.gz     ) gunzip      "$1" ;;
      *.bz2    ) bunzip2     "$1" ;;
      *.xz     ) unxz        "$1" ;;
      *.lzma   ) unlzma      "$1" ;;
      *.Z      ) uncompress  "$1" ;;
      *.zip    ) local extract_dir=$(echo $(basename "$1") | sed "s/\.${1##*.}//g")
                 unzip       "$1" -d $extract_dir ;;
      *.rar    ) unrar e -ad "$1" ;;
      *.7z     ) 7za x       "$1" ;;
      *.Z      ) uncompress  "$1" ;;
      *.exe    ) cabextract  "$1" ;;
      *) echo "extract: '$1' cannot be extracted" 1>&2
    esac
done
