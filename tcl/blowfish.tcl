bind pub - +OK encryptedincominghandler
proc encryptedincominghandler {nick host hand chan arg} {
    global blowfish

    if {$blowfish(key) eq ""} {return}
    set tmp [string trim [decrypt $blowfish(key) $arg]]
    set tmp [stripcodes * $tmp]

    if {[regexp {^(\S+) ?(.*)$} $tmp "" trigger arguments]} {
    foreach item [binds pub] {
        if {[lindex $item 2] eq "+OK" || [lindex $item 2] eq "mcps"} {continue}
        if {[lindex $item 1] ne "-|-" && ![matchattr $hand [lindex $item 1] $chan]} {continue}

        if {[string equal -nocase [lindex $item 2] $trigger]} {
            set ::lastbind [lindex $item 2]
            eval [lindex $item 4] [list $nick $host $hand $chan $arguments]
        }
    }
    # foreach item [binds pubm] {
    #     if {[lindex $item 2] eq "+OK" || [lindex $item 2] eq "mcps"} {continue}
    #     if {[lindex $item 1] ne "-|-" && ![matchattr $hand [lindex $item 1] $chan]} {continue}
    #     if {[string match -nocase [lindex $item 2] "$chan $tmp"]} {
    #         set ::lastbind [lindex $item 2]
    #         eval [lindex $item 4] [list $nick $host $hand $chan $tmp]
    #     }
    # }
    }
}

# Usage: putblow "PRIVMSG $chan :$text"
proc putblow {text} {
    global blowfish

    if {![regexp -nocase {^(\S+) (\S+) :(.+)$} $text "" msgtype msgdest msgtext]} {
        if {![regexp -nocase {^(\S+) (\S+) (\S+)$} $text "" msgtype msgdest msgtext]} {
            putlog "putblow: BOGUS MESSAGE!"
            return
        }
    }

    if {$blowfish(key) eq ""} {return}
    putquick "PRIVMSG $msgdest :+OK [encrypt $blowfish(key) $msgtext]"
}

putlog "blowfish.tcl loaded"
