bind raw - QUIT detect:netsplit

set sl_mask "virtulus.*"
set sl_chan "#virt"

proc detect:netsplit {from key arg} {
    global netsplit_detected sl_mask sl_chan
    if {[info exists netsplit_detected]} {
        return 0
    }

    set arg [string trimleft [stripcodes bcruag $arg] :]

    if {[string equal "Quit:" [string range $arg 0 4]] || \
       ![regexp -- {^([[:alnum:][:punct:]]+)[[:space:]]([[:alnum:][:punct:]]+)$} $arg _arg server1 server2]} {
        return 0
    }

    if {[string match $sl_mask $server1] && [string match $sl_mask $server2]} {
        putlog "NETSPLIT: $server1 just split from $server2"
        putquick "PRIVMSG $sl_chan :-\002NETSPLiT\002- $server2 just split from $server1"
        set netsplit_detected 1
        utimer 20 [list do:netsplit:unlock]
    }
}

proc do:netsplit:unlock {} {
    global netsplit_detected
    if {[info exists netsplit_detected]} {
        unset netsplit_detected
    }
}

putlog "netsplit.tcl loaded"
