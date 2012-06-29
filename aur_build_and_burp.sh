#!/usr/bin/env bash

for d in $*; do 
(   cd $d
        echo -en "\nBuilding source... "
            namcap PKGBUILD
            source PKGBUILD
            makepkg --source -f &>/dev/null
            if (( $? != 0 )); then
                echo "FAIL | $pkgname $pkgver-$pkgrel"
                break
            fi
        echo "done | $pkgname $pkgver-$pkgrel"
        echo "${pkgname}-${pkgver}-${pkgrel}.src.tar.gz has been successfully uploaded (fake)"
        #burp "${pkgname}-${pkgver}-${pkgrel}.src.tar.gz"
    cd ..
)
done
