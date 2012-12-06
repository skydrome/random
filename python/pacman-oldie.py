#! /usr/bin/env python3

import stat
import os
import subprocess
import datetime

# bytes to unicode, for convenience
def b2u(l):
    return map(lambda x: x.decode('utf-8'), l)

# holds 'pkgname': latest_access_time
latest_pkg_access = {}

# iterate per package
for pkg in b2u(subprocess.check_output(["pacman", "-Qq"]).strip().split(b'\n')):
    access_times = []
    # iterate per file in that package
    for pkg_file in b2u(subprocess.check_output(["pacman", "-Qql", pkg]).strip().split(b'\n')):
        try:
            file_stat = os.stat(pkg_file)
        except OSError as e:
            #print(e)
            # symlinks or non existing files..
            continue

        if stat.S_ISREG(file_stat.st_mode):
            access_times.append(file_stat[stat.ST_ATIME])

    # needed check because xorg-font-utils has 0 files...
    if len(access_times):
        latest_pkg_access[pkg] = max(access_times)

# get the length of the longest pkgname used later for pretty formatting
max_name_len = max(map(len, latest_pkg_access.keys()))

# show pkgs with the oldest "latest access" time first
for pkg in sorted(latest_pkg_access, key=latest_pkg_access.get):
    date = datetime.datetime.fromtimestamp(latest_pkg_access[pkg])
    print('{0:{width}}'.format(pkg, width=max_name_len), date)
