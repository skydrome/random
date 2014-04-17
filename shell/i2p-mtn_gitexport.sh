#!/usr/bin/env bash
# if you wanna touch the sky you must be prepared to die

WORKING="$HOME/src/github"
GITHUB_URL="git@github.com:skydrome/i2p.i2p.git"
MTN_URL="mtn.i2p-projekt.de?i2p.i2p"
MTN_KEY=""
DEV_KEYS="$HOME/.monotone/dev_keys"


if [[ $1 = bootstrap ]]; then
    mkdir -p "$WORKING" && cd $_ || exit 1
    mtn db init --db=i2p.mtn
    mtn --db=i2p.mtn read < "$DEV_KEYS"
    mtn --db=i2p.mtn au pull "$MTN_URL"
    mkdir i2p.git && cd $_
    git init
    git remote add origin "$GITHUB_URL"
fi

cd "$WORKING"
md5sum i2p.mtn > MD5SUM
mtn --db=i2p.mtn au pull "$MTN_URL"
[[ $1 = bootstrap ]] && echo 'forcing' >MD5SUM
md5sum --check --status MD5SUM ||
{
    cd "i2p.git"
    mtn --db "${WORKING}/i2p.mtn" git_export |git fast-import
    [[ $1 = bootstrap ]] && git checkout i2p.i2p
    git push origin HEAD:master --force
}

rm MD5SUM
