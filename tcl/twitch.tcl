#bind rmst - "* *" roomstate
#bind usst - "* *" userstate
#bind usrntc - "* *" usernotice
bind htgt - "* *" hosttarget

bind part - * twpart
bind join - * twjoin

set twitch_header "\00314\[\002\00300,06TWiTCH\003\002\00314\]\003"

proc twpart {nick host hand chan arg} {
    if {"#$nick" == "$chan"} {
        global twitch_header
        putlog ""
        putlog "STREAM ENDED! $chan"
        putlog ""
        putbot F ">pub twitch $twitch_header \002$nick\002: parted"
    }
    #putlog "PART: c|$chan  n|$nick"
    #putbot F ">pub" "Twitch: part test"
}
proc twjoin {nick host hand chan} {
    #putlog ""
    #putlog "JOIN: c|$chan  n|$nick"
    #putbot F ">pub $chan Twitch: join test"
    #putlog ""
    if {"#$nick" == "$chan"} {
        global twitch_header
        putlog ""
        putlog "GOING LIVE! $chan"
        putlog ""
        putbot F ">pub twitch $twitch_header \002$nick\002: joined \00314https://www.twitch.tv/$nick"
    }
}

proc roomstate {chan tags} {
    putlog ""
    putlog "ROOM STATE: $chan"
    putlog "tags: $tags"
    putlog ""
}

proc hosttarget {target chan viewers} {
    #putlog ""
    #putlog "HOST TARGET: $chan -> $target"
    #putlog "tags: $viewers"
    #putlog ""
    if {$target == "-"} {return 0}
    global twitch_header
    putbot F ">pub twitch $twitch_header \002[string trim $chan "#"]\002 is now hosting \002$target\002 with [string map {- 0} $viewers] viewers"
}

proc userstate {chan tags} {
    putlog ""
    putlog "USER STATE: $chan"
    putlog "tags: $tags"
    putlog ""
}

proc usernotice {chan tags} {
    putlog ""
    putlog "USER NOTICE: $chan"
    putlog "tags: $tags"
    putlog ""
}

putlog "Twitch.tcl loaded."
