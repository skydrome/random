namespace eval reminder {
    package require textutil

    variable reminderfile "scripts/remind.dat"

    bind pub - ".in" [namespace current]::add_reminder
    # every minute
    bind cron - {* * * * *} [namespace current]::check_time

    proc convert_to {time} {
        return [clock format $time -format "%D %R"]
    }
    proc epoch {formatted_t} {
        return [clock scan $formatted_t -format "%D %R"]
    }
    proc add_time {time amount period} {
        return [convert_to [clock add [epoch $time] $amount $period]]
    }

    proc check_time {minute hour day month weekday} {
        if {![info exists ::reminder::data]} {
            #putlog "reminder: check_time: no data - prob empty file its ok"
            return
        }
        variable data

        if {[string length $data] > 0} {
            foreach line $data {
                #putlog "check: line: $line"
                set crap [split $line "|"]
                set time [lindex $crap 2]
                # check if time to remind is now
                if {$time eq [convert_to [clock seconds]]} {
                    if {[botonchan [lindex $crap 1]]} {
                        puthelp "PRIVMSG [lindex $crap 1] :[lindex $crap 0]: [lindex $crap 3]"
                    }
                    # delete line
                    variable reminderfile
                    exec sed -i "/[regsub -all {/} $line "\\/"]/d" $reminderfile
                    read_data
                }
            }
        }
    }

    # read file into memory
    proc read_data {{arg ""}} {
        variable reminderfile
        if {![file exists $reminderfile]} {
            putlog "reminder: file $reminderfile doesnt exist"
            return
        }
        set fp [open $reminderfile r]
        variable data {}

        while {[gets $fp line] != -1} {
                #set line [regsub -all {\r} $line ""]            # remove CR
                # no need to chomp, gets removes the newline
                #set line [regsub {//.*} $line ""]               # remove // comments
                #set line [regsub {#.*} $line ""]                # remove # comments
                if {[string trim $line] eq ""} {
                    continue
                }
                # remove blank lines
                # expand variables in the line
                # executing in the calling scope, presumably the variables are in scope there
                #set line [uplevel 1 [list subst -nocommands -nobackslashes $line]]
                lappend data $line
        }
        close $fp
        #putlog "read_data(): $data [string length $data]"
    }

    proc write_data {nick chan time text} {
        variable reminderfile
        set fp [open $reminderfile a]
        puts $fp "$nick|$chan|$time|$text"
        close $fp
        read_data
    }

    proc add_reminder {nick host hand chan arg} {
        if {[llength $arg] < 2} {
            puthelp "NOTICE $nick :invalid syntax: \[number\]\[m|h|d|w|mo|y\] \[some msg\]"
            puthelp "NOTICE $nick :example: 1h30m go to bed"
            return 0
        }
        set at [lindex $arg 0]
        set text [lrange $arg 1 end]
        set time_added [convert_to [clock seconds]]
        set time_new $time_added

        foreach i [textutil::split::splitx $at {(\d+(?:\d+)? ?(?:m|m(ins?|inutes?)|h(r?s?|ours?)|d(ays?)|wk?|weeks?|mo|months?|yr?s?|years?)) ?}] {
            #putlog "test: $i"
            if {$i eq ""} {continue}
            switch -regexp -matchvar amount -- $i {
                (^[1-9]([0-9]?)+)m(ins?|inutes?)?$ {
                    set time_new [add_time $time_new [lindex $amount 1] minutes]
                }
                (^[1-9]([0-9]?)+)h(r?s?|ours?)?$ {
                    set time_new [add_time $time_new [lindex $amount 1] hours]
                }
                (^[1-9]([0-9]?)+)d(ays?)?$ {
                    set time_new [add_time $time_new [lindex $amount 1] days]
                }
                (^[1-9]([0-9]?)+)w(k|eeks?)?$ {
                    set time_new [add_time $time_new [lindex $amount 1] weeks]
                }
                (^[1-9]([0-9]?)+)mo(nths?)?$ {
                    set time_new [add_time $time_new [lindex $amount 1] months]
                }
                (^[1-9]([0-9]?)+)y(rs?|ears?)?$ {
                    set time_new [add_time $time_new [lindex $amount 1] years]
                }
                default {
                    puthelp "NOTICE $nick :invalid syntax: \[number\]\[m|h|d|w|mo|y\] \[some msg\]"
                    puthelp "NOTICE $nick :example: 1h30m go to bed"
                    return 0
                }
            }
        }
        write_data $nick $chan $time_new [lrange $arg 1 end]
        puthelp "PRIVMSG $chan :will remind you on $time_new"
    }

    bind evnt - rehash [namespace current]::read_data
    putlog "remind.tcl loaded"
}
