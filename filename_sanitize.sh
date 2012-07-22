#!/usr/bin/env bash

for f in *; do
    file=$(echo $f | \
                tr A-Z a-z | \
                tr ' ' _   | \
                tr '(' _   | \
                tr ')' _   | \
                tr ',' _   | \
                tr '[' _   | \
                tr  \' _   | \
                tr ']' _
            )
    [[ ! -f $file ]] && mv "$f" $file
done
