namespace eval math {
    setudef flag calc

    bind pub - !calc math::calc
    bind pub - .calc math::calc

    proc is_op {arg} {
        return [expr [lsearch {{ } . + - * / ( ) %} $arg] != -1]
    }

    proc calc {nick host hand chan arg} {
        if {![channel get $chan calc] } {
            return
        }

        foreach char [split $arg {}] {
            if {![is_op $char] && ![string is integer $char]} {
                putquick "NOTICE $nick :Invalid expression"
                return
            }
        }

        # make all values floating point
        set arg [regsub -all -- {((?:\d+)?\.?\d+)} $arg {[expr {\1*1.0}]}]
        set arg [subst $arg]

        if {![catch {expr $arg} out]} {
            putquick "PRIVMSG $chan :$out"
            return
        }
        putquick "NOTICE $nick :Invalid equation"
    }
}
putlog "math.tcl loaded"
