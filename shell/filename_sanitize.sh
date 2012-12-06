#!/usr/bin/env bash

for f in $*; do
    file=$(echo "$f" \
        | tr A-Z a-z \
        | tr ' ' '_' \
        | tr -d '()[]{},?!' \
        | tr -d "'" \
        | tr -d '\' \
        | tr '[[:upper:]]' '[[:lower:]]' \
        | sed 's/__/_/g' \
        | sed 's/_-_/-/g' \
    )
    [[ ! -f "$file" ]] && mv -v "$f" "$file"
done
exit 0
