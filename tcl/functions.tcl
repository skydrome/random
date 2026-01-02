if {[catch {source scripts/.local.vars} err]} {
    putlog "-<< ERROR >>- .local.vars: $err"
}

package require http
package require tls

::http::register https 443 [list ::tls::socket -autoservername 1]
::http::config -useragent $web(user_agent)

array set colors {
    white      \00300
    black      \00301
    blue       \00302
    green      \00303
    red        \00304
    brown      \00305
    purple     \00306
    orange     \00307
    yellow     \00308
    lightgreen \00309
    cyan       \00310
    lightcyan  \00311
    lightblue  \00312
    pink       \00313
    grey       \00314
    lightgrey  \00315
    underline  \037
    italic     \035
    reverse    \026
    r          \003
    b          \002
}

foreach {color code} [array get colors] {
    proc $color {} "return $code"
}

bind pub n .rehash pub:rehash
proc pub:rehash {nick host hand chann arg} {
    global botnick
    if {[matchattr $hand +n] && [lindex $arg 0] eq $botnick} {
        save
        rehash
        putserv "NOTICE $nick :rehash->$botnick \[ok\]"
    }
}

bind pub n .restart pub:restart
proc pub:restart {nick host hand chan arg} {
    global botnick
    if {[matchattr $handle +n] && [lindex $arg 0] eq $botnick} {
        save
        putserv "NOTICE $nick :restarting->$botnick \[...\]"
        restart
    }
}

bind pub n .die pub:die
proc pub:die {nick host hand chan arg} {
    global botnick
    if {[matchattr $handle +n] && [lindex $arg 0] eq $botnick} {
        save
        putserv "NOTICE $nick :die->$botnick \[goodbye\]"
        die
    }
}

bind pub n .join pub:join
proc pub:join {nick host hand chan arg} {
    global botnick
    if {[lindex $arg 0] eq $botnick} {
        set tochan [lindex $arg 1]
        if {$tochan eq ""} {
            putserv "NOTICE $nick :Usage: $::lastbind <botnick> <#channel>"
            return 1
        }
        if {![validchan $tochan]} {
            channel add $tochan
            savechan
            #chattr [nick2hand $nick $chan] |+amno $to
            putserv "PRIVMSG $tochan :Hi!"
        } else {
            putserv "NOTICE $nick :$tochan already in chan list"
        }
    }
}

bind pub n .part pub:part
proc pub:part {nick host hand chan arg} {
    global botnick
    if {[lindex $arg 0] eq $botnick} {
        set tochan [lindex $arg 1]
        if {$tochan eq ""} {
            putserv "NOTICE $nick :Usage: $::lastbind <botnick> <#channel>"
            return 1
        }
        if {[onchan $botnick $tochan]} {
            putserv "PRIVMSG $tochan :Bye!"
            channel remove $tochan
            savechan
        } else {
            putserv "NOTICE $nick :not in $tochan"
        }
    }
}

# bind pub - .invite pub:invite
proc pub:invite {nick host hand chan arg} {
    set person [lindex $arg 0]
    if {$person eq ""} {
        putserv "NOTICE $nick :Usage: $::lastbind <nick>"
        return 1
    }
    if {[onchan $person $chan]} {
        putserv "NOTICE $nick :$peron is already here"
        return 1
    }

    if { (([matchattr $hand o|o $chan] || [isop $nick $chan]) && $person ne "") } {
        putserv "INVITE $person $chan"
        putserv "PRIVMSG $chan :Invited $arg"
        return
    }
    putserv "NOTICE $nick :Im sorry Dave, Im afraid I cannot do that"
}

if {$onkick(enabled) == 1} {
bind kick - * pub:kicked
proc pub:kicked {nick host hand chan target reason} {
    global botnick onkick

    if {[string tolower $nick] eq [string tolower $botnick]} {set nick "I"}
    set msg [lindex $onkick(msgs) [rand [llength $onkick(msgs)]]]
    set msg [string map [list \$nick $nick \$target $target] $msg]
    puthelp "PRIVMSG $chan :$msg"
}
} else {catch "unbind kick - * pub:kicked"}

# bind join - * pub:join
# setudef flag voiceall
# proc pub:join {nick host hand chan} {
#     if {[channel get $chan voiceall]} {
#         putserv "mode $chan +v $nick"
#     }
# }

# this does the same as [stripcodes] but much slower
# proc trimcolors {nostring} {
#     regsub -all -- {[0-9][0-9],[0-9][0-9]} $nostring "" nostring
#     regsub -all -- {[0-9][0-9],[0-9]}      $nostring "" nostring
#     regsub -all -- {[0-9][0-9]}            $nostring "" nostring
#     regsub -all -- {[0-9]}                 $nostring "" nostring
#     regsub -all -- {}                      $nostring "" nostring
#     regsub -all -- {}                      $nostring "" nostring
#     regsub -all -- {}                      $nostring "" nostring
#     regsub -all -- {}                      $nostring "" nostring
#     regsub -all -- {}                      $nostring "" nostring
#     regsub -all -- {}                      $nostring "" nostring
#     regsub -all -- {\002|\003([0-9]{1,2}(,[0-9]{1,2})?)?|\017|\026|\037|\022} $nostring "" nostring
#     return [string trim $nostring]
# }

proc flood {host} {
    global flood

    set a [lindex [split $flood(time) :] 0]
    set b [lindex [split $flood(time) :] 1]

    if {[info exists flood($host)]} {
        incr flood($host) 1
        if {$flood($host) > $a} {
            putlog "IGNORE: \[$host\] flooding with $::lastbind"
            newignore *!*@$host BOXINFO "flooding with: ($::lastbind)" $flood(ignore)
            return 1
        }
    } else {set flood($host) 1}
    if {![string match "*unset flood($host)*" [utimers]]} {
        utimer $b "catch {unset flood($host)}"
    }
    return 0
}

proc formatbytesize {value} {
    set test $value
    set unit 0
    while {[set test [expr {$test / 1024}]] > 0} {
        incr unit
    }
    return [format "%.2f %s" \
        [expr {$value / pow(1024,$unit)}] [lindex [list B KB MB GB TB PB EB ZB YB] $unit]]
}

bind pub - !random pub:random
proc pub:random {nick host hand chan arg} {
    if {[flood [string range $host [expr [string last @ $host]+1] end]]} {
        return 0
    }

    set length [lindex $arg 0]
    if {$arg < -1 || ![string is integer $length] || [expr $length > 100] } {
        set length 14
        putserv "NOTICE $nick :length either too small or large, setting to $length"
    }
    putserv "PRIVMSG $chan :[randstring [lindex $length]]"
}
proc randstring {length} {
    set s "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~!?@#$%^&*_+-=/"
    for {set i 1} {$i <= $length} {incr i} {
        append p [string index $s [expr {int([string length $s]*rand())}]]
    }
    return $p
}

putlog "functions.tcl loaded"
