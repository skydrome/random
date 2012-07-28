#!/usr/bin/env bash

build() {
    [[ -r "$1/PKGBUILD" ]] && (
        cd $1
        echo -en "\nBuilding source $1 ... "
            namcap PKGBUILD && source PKGBUILD || exit
            makepkg -Sf &>/dev/null
            if (( $? != 0 )); then
                echo "FAIL | $pkgname-$pkgver-$pkgrel"
                exit
            fi
        echo "done"
        #echo "$pkgname-$pkgver-$pkgrel.src.tar.gz has been successfully uploaded (dry run)"
        burp "$pkgname-$pkgver-$pkgrel.src.tar.gz"
    )
}

if [[ "$1" = 'all' ]]; then
    echo "--==--[ Building entire tree ]--==--"
    for d in $(find . -maxdepth 1 -type d)
        do build "$(basename $d)"
    done
else
    for d in $*
        do build "$d"
    done
fi

