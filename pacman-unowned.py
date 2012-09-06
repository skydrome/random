#!/usr/bin/env python3

import os
import subprocess

IGNORE = [
    '/boot',
    '/dev',
    '/etc/ssl/certs',
    '/etc/pacman.d/gnupg',
    '/usr/share/spacefm',
    '/usr/share/mime',
    '/home',
    '/media',
    '/mnt',
    '/proc',
    '/root',
    '/router_root_fs',
    '/run',
    '/srv',
    '/sys',
    '/tmp',
    '/usr/local',
    '/var/abs',
    '/var/cache',
    '/var/lib/oprofile',
    '/var/lib/pacman',
    '/var/lib/texmf',
    '/var/log',
    '/var/run',
    '/var/spool',
    '/var/tmp',
]

o = subprocess.getoutput('pacman -Ql')
files = {x.split()[1] for x in o.split('\n') if x[-1] != '/'}

for dirname, dirnames, filenames in os.walk('/'):
    for subdirname in dirnames[:]:
        sd = os.path.join(dirname, subdirname)
        if sd in IGNORE:
            dirnames.remove(subdirname)

    dirnames.sort()

    for filename in filenames:
        f = os.path.join(dirname, filename)
        if f not in files:
            print(f)
