#!/usr/bin/env bash
# if you wanna touch the sky you must be prepared to die

MTN_SRC="/usr/src/i2p"
GIT_SRC="$HOME/github/i2p.i2p"
MTN_KEY=""

cd "$MTN_SRC"
md5sum i2p.mtn > MD5SUM

    cd i2p.i2p
    mtn pull -k "$KEY" && mtn up ||
        { echo "non zero exit status from mtn pull"; exit 1; }
    cd ..

md5sum --check --status MD5SUM || {

    cd "$GIT_SRC"
    mtn --db "${MTN_SRC}/i2p.mtn" git_export | git fast-import && git push ||
        { echo "non zero exit status from git-import/push"; exit 1; }
}
