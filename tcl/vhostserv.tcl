set vhost_chan "#help"

bind pub - !vhost vhost:set
bind pub - .vhost vhost:set
#bind join - "$vhost_chan *" vhost:join

setudef flag vhost

proc vhost:join {nick host handle chan} {
    puthelp "NOTICE $nick :To change your host type !vhost <the.host.you.want>"
    puthelp "NOTICE $nick : you will be kicked automatically after it is set"
    puthelp "NOTICE $nick :For other questions feel free to highlight anyone with voice for help"
}

proc vhost:set {nick host hand chan arg} {
    if {![channel get $chan vhost]} {
        return
    }

    if {![isidentified $nick]} {
        puthelp "NOTICE $nick :Your nickname must be registered first"
        return
    }

    set vhost [lindex $arg 0]

    set badwords {
        "*ircop*"
        "*admin*"
        "*oper*"
        "*root*"
        "*staff*"
        "*globop*"
        "*localop*"
        "*globalop*"
        "*services*"
    }

    if {[regexp {^[\.\-]} $vhost] || [regexp {[\.\-]$} $vhost]} {
        puthelp "NOTICE $nick :cannot contain .- at begging or end of hostname"
        return
    }
    for {set i 0} {$i < [string length $vhost]} {incr i} {
        set j [string index $vhost $i]
        if {![regexp -all {[a-zA-Z0-9\.\-]} $j]} {
            puthelp "NOTICE $nick :invalid character in hostname -> $j"
            return
        }
    }

    foreach i $badwords {
        if {[string match -nocase *$i* $vhost]} {
            puthelp "NOTICE $nick :invalid word in hostname -> [string map {* ""} $i]"
            return
        }
    }

    if {![string match "*.*" $vhost]} {
        puthelp "NOTICE $nick :invalid syntax !vhost <host.name.tld>"
        return
    }

    puthelp "PRIVMSG HOSTSERV :SET $nick $vhost"
    #puthelp "NOTICE $nick :Your vhost has been set"

    if {![isvoice $nick $chan] && [botisop $chan]} {
        puthelp "PRIVMSG CHANSERV :BAN $::vhost_chan +1m $nick"
    }
}

#bind raw - NOTICE oper:notc

proc bgexec:quick {nick host hand chan input} {
    putlog "bgexec: $input"
    foreach line [split $input "\n"] {
        putquick "PRIVMSG $chan :$line"
    }
}

proc oper:notc {from cmd text} {
    if {[regexp -nocase {\[Blacklist\] IP (.*) matches blacklist} $text - ip]} {
        #putlog "sending $ip"

        if {[catch {exec python scripts/maxmind.py $ip} network]} {
            putlog "maxmind: failed to get network"
            return
        }

        if {[catch {exec -- sudo firewall-cmd --permanent --zone=drop --add-source="$network"} err]} {
            putlog "firewall-cmd: failed to add rule: $err"
            return
        } else {
            putquick "PRIVMSG #opers :[firewall] added $network to DROP table"
        }

        #bgexec "python scripts/maxmind.py $ip" [list bgexec:quick 0 0 0 "#opers"]
    }
}
