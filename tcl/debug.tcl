#!/usr/bin/env tclsh
# this simulates/replaces by nops eggdrop functions for debugging purposes

set eggtcl {
    putlog
    putserv
    puthelp
    putquick
    bind
    utimer
    timers
    setudef
    dnslookup
    timer
    killtimer
}

proc _output {args} {
    puts stderr "$args"
    flush stderr
    return {}
}

foreach func $eggtcl {
    interp alias {} $func {} _output $func
}
