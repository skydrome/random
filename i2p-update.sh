#!/usr/bin/env bash
trap 'echo " Interrupt detected... Exiting."; exit 1' SIGINT

#[ NOTES ]#
# Made for archlinux but should also work across different
# distros if you set the variables below correctly.

#[ VARIABLES ]#
I2P_PATH="/opt/i2p"
I2P_USER="i2p"

#I2P_URL="mtn.i2p2.de"
I2P_URL="mtn.i2p-projekt.de"
#I2P_URL="mtn.i2pproject.net"
#I2P_URL="127.0.0.1:8998"

KEY="" # Key for signatures using either the key name or the key hash

#[ FUNCTIONS ]#
usage() {
cat <<EOF

 Usage:
 ./$(basename $0) [options]

 options:
 -d, --dont-build    Download source ONLY, dont build
 -f, --force         Force compile even if source hasn't changed
 -j, --java-wrapper  Compile the java wrapper from source
 -r, --restart       Restart I2P after updating or installing wrapper

EOF
exit 1
}

msg() {
    echo -e "\e[1;31m--->\e[1;32m $1 \e[0m"
}

BASEDIR=$(pwd)
while [[ $# > 0 ]]; do
    case "$1" in
        -d|--dont-build) opt_no_build=1 ;;
        -f|--force) opt_force_compile=1 ;;
        -j|--java-wrapper) opt_compile_wrapper=1 ;;
        -r|--restart) opt_restart=1 ;;
        -h|--help) usage ;;
        *) echo " Unrecognized option"; usage ;;
    esac
    shift
done

[[ ! $(type -P "ant") ]] && {
    msg "You need apache-ant to compile the I2P sources\n"
    exit 1
}
[[ $opt_compile_wrapper = 0 && ! $(type -P "mtn") ]] && {
    msg "You need monotone to download the I2P sources\n"
    exit 1
}
[[ $UID = 0 ]] && {
    msg "\e[1;31mYOU ARE RUNNING AS ROOT USER!\e[1;32m You probably dont want to do this!"
    msg "Waiting 30 seconds and continuing anyways...\n"
    sleep 30
}

check_return() {
    if [[ "$_E" != 0 ]]; then
        msg "Non zero return code while executing \e[1;31m${1}\e[1;32m : ${_E}"
        exit 1
    fi
}

restart_router() {
    if [[ $opt_restart ]]; then
        msg "Restarting I2P Router..."
        sudo $I2P_PATH/i2prouter restart
    fi
}

build_i2p() {
    if [[ ! -f i2p.mtn ]]; then
        _new_install=true
        msg "No db found, initializing db i2p.mtn now..."
        mtn db init --db=i2p.mtn && md5sum i2p.mtn > MD5SUM
        mtn --db=i2p.mtn -k "$KEY" pull "$I2P_URL" i2p.i2p
        mtn --db=i2p.mtn checkout --branch=i2p.i2p
    else
        msg "Checking for updates..."
        md5sum i2p.mtn > MD5SUM
    fi

    cd i2p.i2p && mtn -k "$KEY" pull && mtn up
    md5sum --check --status MD5SUM || hash_fail=1

    if [[ $hash_fail || $opt_force_compile ]]; then
        [[ $opt_no_build ]] && exit 0
        msg "Starting compile..."
        cd i2p.i2p
        if [[ $_new_install ]]; then
            ant installer-linux
            sudo mkdir -p $I2P_PATH ; sudo mv -v i2pinstall*.jar $I2P_PATH ; cd $I2P_PATH
            msg "Starting interactive installer..."
            sudo java -jar i2pinstall*.jar -console
        else
            ant updater ; _E=$? ; check_return "ant updater"
            sudo mv -v i2pupdate.zip $I2P_PATH
        fi
        sed -i "s:#RUN_AS_USER=:RUN_AS_USER=${I2P_USER}:" $I2P_PATH/i2prouter
        sudo chown -R $I2P_USER:$I2P_USER $I2P_PATH
        [[ $opt_compile_wrapper ]] || restart_router
    else msg "I2P already up to date."
    fi
}

build_wrapper() {
_VER="3.5.15"
_CFLAGS="-march=native"
[[ $(uname -m) = "x86_64" ]] && _ARCH="64" || _ARCH="32"
cd $BASEDIR
    if [[ ! -d "wrapper_${_VER}_src" ]]; then
        msg "Fetching java wrapper v$_VER ..."
        curl https://wrapper.tanukisoftware.com/download/${_VER}/wrapper_${_VER}_src.tar.gz | tar xz
    fi
    cd wrapper_${_VER}_src
    msg "Starting compile..."
    sudo $I2P_PATH/i2prouter stop
    sed -i "s|gcc |gcc $_CFLAGS |" src/c/Makefile-linux-x86-${_ARCH}.make
    ./build${_ARCH}.sh ; _E=$? ; check_return "./build${_ARCH}.sh java wrapper"
    strip --strip-unneeded bin/wrapper lib/libwrapper.so
        sudo install -v -m 644 bin/wrapper       $I2P_PATH/i2psvc
        sudo install -v -m 644 lib/wrapper.jar   $I2P_PATH/lib
        sudo install -v -m 755 lib/libwrapper.so $I2P_PATH/lib
        sudo chown -R $I2P_USER:$I2P_USER $I2P_PATH
    restart_router
}

#[ MAIN ]#
[[ $opt_compile_wrapper ]] &&
    build_wrapper ||
    build_i2p
msg "Done!"
