namespace eval site_announce {

    # echo "password ANNOUNCE test msg here" |nc 172.17.0.2 11111

    variable ip 0.0.0.0
    variable port 11111

    variable gpass "password"
    variable announceto "#something"
    variable logchan "#logs"

    proc disable {arg} {
        catch {listen $::site_announce::ip $::site_announce::port off}
    }

    proc connect {idx} {
        # putdcc $idx "READY"
        control $idx site_announce::incoming
    }

    proc incoming {idx arg} {
        # putlog "args -> $arg"

        set pass [lindex $arg 0]

        if {$pass != $::site_announce::gpass} {
            set hostname [lindex [split [lindex [split [lindex [dcclist script] 0]] 2] @] 1]

            # ignores dont work on telnet?
            #newignore $hostname site-announcer portscanner 1

            putlog "announcer: badpass ($pass) $arg from $hostname 2"
            #putserv "PRIVMSG $::site_announe::logchan :badpass \[$pass\] from \[$hostname\] data: \[[join [lrange [split $args] 1 end]]\]"
            killdcc $idx
            return 0
        }

        set type [lindex $arg 1]
        set msg  [join [lrange $arg 2 end]]

        if {$type == "INVITE"} {
            set nick [lindex [split $msg] 0]
            set chan [lindex [split $msg] 1]
            putserv "INVITE $nick $chan"

        } elseif {$type == "ANNOUNCE"} {
            putserv "PRIVMSG $::site_announce::announceto :$msg"
        }

        killdcc $idx
    }

    listen $::site_announce::ip $::site_announce::port script "site_announce::connect" pub

    bind evnt - prerehash  site_announce::disable
    bind evnt - prerestart site_announce::disable

    putlog "Site Announcer loaded"
}


# namespace eval punbb {}

# listen 12000 script ::punbb::accept
# setudef flag punbb

# proc ::punbb::accept {idx} {
#     control $idx ::punbb::incoming
# }

# proc ::punbb::incoming { idx args } {
#     putlog "$args"
#     set chans 0
#     foreach chan [channels] {
#         if { [channel get $chan punbb]} {
#                  incr chans
#         }
#     }

#     set line [join $args]
#     set line [split $line ";"]

#         set nick        [lindex $line 0]
#         set topic       [lindex $line 1]
#         set subj        [lindex $line 2]
#         set url         [lindex $line 3]
#         set type        [lindex $line 4]
#         if { $type == "1" } {
#                 set type "replied to"
#         } else {
#                 set type "posted"
#         }

#         foreach chan [channels] {

#                 if { [channel get $chan punbb]} {
#                     putserv "privmsg $chan :\002\00310 $nick \002\00306 $type:\002\00311 $topic \002\00312 $subj \00310(\00303$url\00310)"
#                 }
#         }
#     killdcc $idx
# }
# putlog "punbb2egg.tcl v1.1 support@codetheworld loaded."
