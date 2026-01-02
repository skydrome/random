# bind pub - !p unscamble
bind pub - !rot rot13
bind pub - !rot13 rot13
bind pub - !morse morse
# bind pub - !atbash atbash
bind pub - !base64 b64decode

proc morse {nick host hand chan arg} {
    set _morse {
        A ._ B _... C _._. D _.. E . F .._.
        G __. H .... I .. J .___ K _._ L ._.. M __
        N _. O ___ P .__. Q __._ R ._. S ...
        T _ U .._ V ..._ W .__ X _.._ Y _.__ Z __..
        0 _____ 1 .____ 2 ..___ 3 ...__ 4 ...._ 5 .....
        6 _.... 7 __... 8 ___.. 9 ____.
        . ._._._ , __..__ ? ..__.. / _.._. ( _.__. ) _.__._
        + ._._. : ___... ; ...___ - _...._ = _..._
        ~ ._... # ..._._ $ _..._._
    }
    set res ""
    set s $arg
    if [regexp {^[._/\- ]+$} $s] {
        regsub -all {  +} $s " B " s
        regsub -all {\-} $s "_" s
        regsub -all {/} $s " " s
        foreach i [split $s] {
            if {$i eq ""}  continue
            if {$i eq "B"} {append res " "; continue}
            set ix [lsearch $_morse $i]
            if {$ix>=0} {
                append res [lindex $_morse [expr {$ix-1}]]
            } else {append res ?}
        }
    } else {
        foreach i [split [string toupper $s] ""] {
            if {$i eq " "} {append res "  "; continue}
            set ix [lsearch -exact $_morse $i]
            if {$ix>=0 && $ix%2==0} {
                append res "[lindex $_morse [expr {$ix+1}]] "
            }
        }
    }
    putquick "PRIVMSG $chan :$res"
}


proc rot13 {nick host hand chan text} {
    set res [string map -nocase {a n b o c p d q e r f s g t h u i v j w k x l y m z n a o b p c q d r e s f t g u h v i w j x k y l z m} $text]
    putquick "PRIVMSG $chan :$res"
}


proc unscamble {nick host hand chan arg} {
    global owner

    if {[lindex $arg 0] eq ""} {
        putquick "PRIVMSG $chan :no input"
        return
    }

    if {[lindex $arg 0] eq "Enter"} {
        regexp {Enter the number (.*) in digits} $arg -> num
        bgexec "python -c \"from word2number import w2n; print(w2n.word_to_num('$num'))\"" [list bgexec:cb_quick $nick $host $hand $chan]
        return 0
    } elseif {[lindex $arg 0] eq "What"} {
        regexp {What is (.*) as} $arg -> num
        bgexec "python -c \"from word2number import w2n; print(w2n.word_to_num('$num'))\"" [list bgexec:cb_quick $nick $host $hand $chan]
        return 0
    } elseif {[lindex $arg 0] eq "Atbaš"} {
        putquick "PRIVMSG $chan :sail to [_atbash::decode [lindex $arg 1]]"
        return 0
    }


    set min_size 5
    set header ""
    set nuke ""
    set counters {}
    set bad_nicks {}

    # TODO - special case for -o- ?
    # -anowr-ma -> man-o-war

    # strip colors
    set arg [stripcodes * $arg]

    # lockpickin' -> ing
    #set word [regsub {'} [lindex $arg end] "g"]
    set word [lindex $arg end]
    #putserv "PRIVMSG $chan :1 $word"

    # strip non alpha
    set word [string trim [regsub -all {[^a-zA-Z'\-]} $word ""]]
    #putserv "PRIVMSG $chan :2 $word"

    # count occurances of each letter
    set list [split $word ""]
    foreach item $list {
        dict incr counters $item
    }
    # find the letter that repeats the most and strip it
    dict for {item count} $counters {
        if {$count >= $min_size} {
            set nuke $item
            set min_size $count
        }
    }

    #putserv "PRIVMSG $chan :3 $nuke"
    set word [regsub -all -- $nuke $word ""]

    # save a copy of original word
    set orig $word

    proc doit {goog} {
        #putlog $goog
        set tmp [split [exec unscramble $goog] \n]
        return $tmp
    }


    # get output from unscrambler (https://github.com/WKHAllen/Unscramble)
    # put each line into a list and loop over it
    ## if {![catch {set word [split [exec unscramble $word] \n]} error] }
    if {![catch {set word [doit $word]} error]} {
        if {$word eq ""} {
            # TODO try adding one letter from $nuke
            putquick "PRIVMSG $chan :0 results for $orig"

            if {$nuke ne "" && [lsearch -nocase $bad_nicks $nick] == -1} {
                putquick "PRIVMSG $chan :try with $orig$nuke"
            }
            # try removing ing suffix
            if {[regexp {g} $orig] && [regexp {n} $orig] && [lsearch -nocase $bad_nicks $nick] == -1} {
                set orig [regsub i $orig ""]
                set orig [regsub n $orig ""]
                set orig [regsub g $orig ""]
                putquick "PRIVMSG $chan :try with [doit $orig] + ing"
            }

        } else {
            if {[lindex $arg 0] eq "P"} {
                set header "[lindex $arg 0] [lindex $arg 1] "
            }

            if {[lsearch -nocase $bad_nicks $nick] != -1} {
                foreach line $word {
                    putserv "PRIVMSG $chan :$header [p_randline]"
                }
            } else {
                foreach line $word {
                    putquick "PRIVMSG $chan :$header$line"
                }
            }
        }

    } else {
        putquick "NOTICE $nick :$owner: fix me"
        putlog "unscramble: $error:  $orig/$word"
    }
}

proc p_randline {} {
    set f [open "dict/american-english"]
    set list [split [read $f] "\n"]
    close $f
    set random [expr int(rand()*[llength $list])]
    return [lindex $list $random]
}

namespace eval _atbash {
    namespace export encode decode
    namespace ensemble create
    proc encode {input} {
        groups [decode $input] 5
    }
    proc decode {input} {
        set mapping {
            a z   b y   c x   d w   e v   f u   g t   h s   i r
            j q   k p   l o   m n   n m   o l   p k   q j   r i
            s h   t g   u f   v e   w d   x c   y b   z a   0 0
            1 1   2 2   3 3   4 4   5 5   6 6   7 7   8 8   9 9
        }
        set chars [regexp -all -inline -- {[[:alnum:]]} $input]
        string map -nocase $mapping [join $chars ""]
    }
    proc groups {s length} {
        set result {}
        for {set i 0} {$i < [string length $s]} {incr i $length} {
            lappend result [string range $s $i [expr {$i+$length-1}]]
        }
        return $result
    }
}

proc atbash {nick host hand chan arg} {
    putquick "PRIVMSG $chan :[_atbash::decode [lindex $arg 0]]"
}

proc b64decode {nick host hand chan arg} {
    set nstr [string trimright $arg =]
    set dstr [string map {
        A 000000 B 000001 C 000010 D 000011 E 000100 F 000101
        G 000110 H 000111 I 001000 J 001001 K 001010 L 001011
        M 001100 N 001101 O 001110 P 001111 Q 010000 R 010001
        S 010010 T 010011 U 010100 V 010101 W 010110 X 010111
        Y 011000 Z 011001 a 011010 b 011011 c 011100 d 011101
        e 011110 f 011111 g 100000 h 100001 i 100010 j 100011
        k 100100 l 100101 m 100110 n 100111 o 101000 p 101001
        q 101010 r 101011 s 101100 t 101101 u 101110 v 101111
        w 110000 x 110001 y 110010 z 110011 0 110100 1 110101
        2 110110 3 110111 4 111000 5 111001 6 111010 7 111011
        8 111100 9 111101 + 111110 / 111111
    } $nstr]
    switch [expr {[string length $arg]-[string length $nstr]}] {
        0 {#nothing to do}
        1 {set dstr [string range $dstr 0 {end-2}]}
        2 {set dstr [string range $dstr 0 {end-4}]}
    }
    putquick "PRIVMSG $chan :[binary format B* $dstr]"
}

putlog "Uncrambler loaded."

