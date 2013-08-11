#!/bin/bash

MAX=50000
echo bash-$BASH_VERSION

echo
echo '((..))'

f() {
    local i
    for (( i=MAX; i > 0; i-- )); do
        ((3 > 5))
    done
}
time f

echo
echo '[[..]]'

f() {
    local i
    for (( i=MAX; i > 0; i-- )); do
        [[ 3 -gt 5 ]]
    done
}
time f

echo
echo '[..]'

f() {
    local i
    for (( i=MAX; i > 0; i-- )); do
        [ 3 -gt 5 ]
    done
}
time f

exit 0
