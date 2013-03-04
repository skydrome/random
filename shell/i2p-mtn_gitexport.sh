#!/usr/bin/env bash
# if you wanna touch the sky you must be prepared to die

WORKING="$HOME/src/github"
MTN_KEY=""

bootstrap() {
    mkdir -p "$WORKING" && cd $_ || exit 1
    mtn db init --db=i2p.mtn
    mtn --db=i2p.mtn read < $HOME/.monotone/dev_keys
    mtn --db=i2p.mtn au pull "mtn.i2p-projekt.de?i2p.i2p"
    mkdir i2p.git && cd $_
    git init
    git remote add origin git@github.com:skydrome/i2p.i2p.git
}
[[ $1 = bootstrap ]] && bootstrap

cd "$WORKING"
md5sum i2p.mtn > MD5SUM
mtn --db=i2p.mtn au pull "mtn.i2p-projekt.de?i2p.i2p"
md5sum --check --status MD5SUM &&
{
    cd "i2p.git"
    mtn --db "${WORKING}/i2p.mtn" git_export | git fast-import
    [[ $1 = bootstrap ]] && git checkout i2p.i2p
    git push origin HEAD:master
}
