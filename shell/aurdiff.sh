#!/usr/bin/env bash

# diff an AUR pkgbuild based on your local copy

[[ ! -f PKGBUILD ]] && {
  echo "error: No PKGBUILD found in working directory."
  exit 1
}

eval $(grep '^pkgname=' PKGBUILD)
colordiff ${@:--Naur} \
    <(curl -sk "https://aur.archlinux.org/packages/${pkgname:0:2}/$pkgname/PKGBUILD") PKGBUILD
