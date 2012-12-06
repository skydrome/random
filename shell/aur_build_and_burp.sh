#!/usr/bin/env bash

build() {
    [[ -r "$1/PKGBUILD" ]] && (
        cd "$1"
        if [[ -f *.src.tar.gz ]]; then
            echo "Another source package exists..."
            exit
        fi
        echo -en "\nBuilding source $1 ... "
        namcap -i PKGBUILD
        if [[ ! "$_check" ]]; then
            source PKGBUILD
            makepkg -Sf &>/dev/null
            if (( $? != 0 )); then
                echo "FAIL | $pkgname-$pkgver-$pkgrel"
                exit
            fi
            echo "done"
            #echo "$pkgname-$pkgver-$pkgrel.src.tar.gz has been successfully uploaded (dry run)"
            burp "$pkgname-$pkgver-$pkgrel.src.tar.gz" &&
                rm "$pkgname-$pkgver-$pkgrel.src.tar.gz"
        fi
    )
}

[[ "$1" = 'check' ]] && { _check=1; shift; }

if [[ "$1" = 'all' ]]; then
    for dir in $(find . -maxdepth 1 -type d); do
        build "$(basename $dir)"
    done
else
    for dir in $*; do
        build "$dir"
    done
fi

