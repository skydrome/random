#!/usr/bin/env bash
trap 'echo " Interrupt detected... Exiting."; exit 1' SIGINT

#[ NOTES ]#
# Made for archlinux but should also work across different
# distros if you set the variables below correctly.

#[ VARIABLES ]#
I2P_BIN_PATH="/opt/i2p"
I2P_USER="i2p"

#I2P_URL="mtn.i2p2.de"
I2P_URL="mtn.i2p-projekt.de"
#I2P_URL="mtn.i2pproject.net"
#I2P_URL="127.0.0.1:8998"

KEY="" # Key for signatures using either the key name or the key hash

# see install_archive()
I2P_VER="0.9"
I2P_AURL="http://mirror.i2p2.de"
SHA256="8a3654a13781a9aacf9db94081e057be73322f88db2931eba4f2cfa467ead429"

#[ FUNCTIONS ]#
usage() {
cat <<EOF

 Usage:
 ./$(basename $0) [options]

 options:
 -a, --archive       Download i2psource_${I2P_VER}.tar.bz2
     --archiveupdate   ^ but perform an update
 -d, --no-build      Download source ONLY, dont build
 -f, --force         Force compile even if source hasn't changed
 -j, --java-wrapper  Compile the java wrapper from source
 -r, --restart       Restart I2P after updating

EOF
exit 1
}

msg() {
    echo -e "\n\e[1;31m--->\e[1;32m $1 \e[0m"
}

BASEDIR=$(pwd)
while [[ $# > 0 ]]; do
    case "$1" in
        -a|--archive) opt_use_archive=1 ;;
        --archiveupdate) opt_use_archive=update ;;
        -d|--no-build) opt_no_build=1 ;;
        -f|--force) opt_force_compile=1 ;;
        -j|--java-wrapper) opt_compile_wrapper=1 ;;
        -r|--restart) opt_restart=1 ;;
        -h|--help) usage ;;
        *) echo " Unrecognized option"; usage ;;
    esac
    shift
done

[[ $(type -P "ant") ]] || { msg "You need apache-ant to compile the I2P sources\n"
                            exit 1; }
[[ $UID = 0 ]] && ( msg "\e[1;31mYOU ARE RUNNING AS ROOT USER!\e[1;32m You probably dont want to do this!"
                    msg "Waiting 30 seconds and continuing anyways...\n"; sleep 30 )

check_return() {
    if [[ "$_E" != 0 ]]; then
        msg "Non zero return code while executing \e[1;31m${1}\e[1;32m : ${_E}"
        exit 1
    fi
}
restart_router() {
    if [[ $opt_restart ]]; then
        msg "Restarting I2P Router..."
        sudo $I2P_BIN_PATH/i2prouter restart
    fi
}
install_archive() {
    [[ -f i2psource_${I2P_VER}.tar.bz2 ]] || wget "${I2P_AURL}/i2psource_${I2P_VER}.tar.bz2"
    [[ -f i2psource_${I2P_VER}.tar.bz2.sig ]] || wget "${I2P_AURL}/i2psource_${I2P_VER}.tar.bz2.sig"

    msg "Verifying checksum..."
    echo "$SHA256  i2psource_${I2P_VER}.tar.bz2" > SHA256SUM
    sha256sum --check SHA256SUM ; _E=$? ; check_return "sha256sum --check"
    msg "Verifying signing key..."
    gpg --verify i2psource_${I2P_VER}.tar.bz2.sig i2psource_${I2P_VER}.tar.bz2 ; _E=$?
    if [[ $_E = 2 ]]; then
        msg "You need to import zzz's GPG key to successfully validate this package!"
        msg "https://www.i2p2.de/release-signing-key.html"

    else check_return "gpg --verify"
    fi

    [[ $opt_no_build ]] && exit 0
    msg "Starting compile..."
    tar -xjf i2psource_${I2P_VER}.tar.bz2 && cd i2p-${I2P_VER}
    if [[ $opt_use_archive = 'update' ]]; then
        ant updater ; _E=$? ; check_return "ant updater"
        sudo mv -v i2pupdate.zip $I2P_BIN_PATH
    else
        ant installer-linux
        sudo mkdir -p $I2P_BIN_PATH ; sudo mv -v i2pinstall.jar $I2P_BIN_PATH ; cd $I2P_BIN_PATH
        msg "Starting interactive installer..."
        sudo java -jar i2pinstall*.jar -console
    fi
    sed -i "s:#RUN_AS_USER=:RUN_AS_USER=${I2P_USER}:" $I2P_BIN_PATH/i2prouter
    sudo chown -R $I2P_USER:$I2P_USER $I2P_BIN_PATH
    [[ $opt_compile_wrapper ]] || restart_router
}
install_mtn() {
    if [[ ! -f i2p.mtn ]]; then
        _new_install=true
        msg "No db found, initializing db i2p.mtn now..."
        [[ $(type -P "mtn") ]] || ( msg "Monotone is NOT installed!"; exit 1 )
        mtn db init --db=i2p.mtn && md5sum i2p.mtn > MD5SUM
        mtn --db=i2p.mtn -k "$KEY" pull "$I2P_URL" i2p.i2p
        mtn --db=i2p.mtn checkout --branch=i2p.i2p
    else
        msg "Checking for updates..."
        md5sum i2p.mtn > MD5SUM
    fi

    ( cd i2p.i2p && mtn -k "$KEY" pull && mtn up )
    md5sum --check --status MD5SUM || hash_fail=1

    if [[ $hash_fail || $opt_force_compile ]]; then
        [[ $opt_no_build ]] && exit 0
        msg "Starting compile..."
        cd i2p.i2p
        if [[ $_new_install ]]; then
            ant installer-linux
            sudo mkdir -p $I2P_BIN_PATH ; sudo mv -v i2pinstall*.jar $I2P_BIN_PATH ; cd $I2P_BIN_PATH
            msg "Starting interactive installer..."
            sudo java -jar i2pinstall*.jar -console
        else
            ant updater ; _E=$? ; check_return "ant updater"
            sudo mv -v i2pupdate.zip $I2P_BIN_PATH
        fi
        sed -i "s:#RUN_AS_USER=:RUN_AS_USER=${I2P_USER}:" $I2P_BIN_PATH/i2prouter
        sudo chown -R $I2P_USER:$I2P_USER $I2P_BIN_PATH
        [[ $opt_compile_wrapper ]] || restart_router
    else msg "I2P already up to date."
    fi
}
install_wrapper() {
_VER="3.5.14"
[[ $(uname -m) = "x86_64" ]] && _ARCH="64" || _ARCH="32"
cd $BASEDIR
    if [[ ! -d "wrapper_${_VER}_src" ]]; then
        msg "Fetching java wrapper v$_VER ..."
        curl https://wrapper.tanukisoftware.com/download/${_VER}/wrapper_${_VER}_src.tar.gz | tar xz
    fi
    cd wrapper_${_VER}_src
    msg "Starting compile..."
    sudo $I2P_BIN_PATH/i2prouter stop
    ./build${_ARCH}.sh ; _E=$? ; check_return "./build${_ARCH}.sh java wrapper"
    strip --strip-unneeded bin/wrapper lib/libwrapper.so
        sudo install -v -m 644 bin/wrapper       $I2P_BIN_PATH/i2psvc
        sudo install -v -m 644 lib/wrapper.jar   $I2P_BIN_PATH/lib
        sudo install -v -m 755 lib/libwrapper.so $I2P_BIN_PATH/lib
        sudo chown -R $I2P_USER:$I2P_USER $I2P_BIN_PATH
    restart_router
}

#[ MAIN ]#
if [[ $opt_use_archive ]]
    then install_archive
    else install_mtn
fi
if [[ $opt_compile_wrapper ]]
    then install_wrapper
fi
msg "Done!" ; exit 0
