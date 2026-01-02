namespace eval squire {
    bind pub - ".boobs"   squire::faces
    bind pub - ".bedtime" squire::faces
    bind pub - ".yuno"    squire::faces
    bind pub - ".cool"    squire::faces
    bind pub - ".smoke"   squire::faces
    bind pub - ".fail"    squire::faces
    bind pub - ".coffee"  squire::faces
    bind pub - ".pacman"  squire::faces
    bind pub - ".beerme"  squire::faces
    bind pub - ".pie"     squire::faces
    bind pub - ".cheese"  squire::faces
    bind pub - ".nut"     squire::faces
    bind pub - ".hello"   squire::faces
    bind pub - ".shrug"   squire::faces

    setudef flag squire

proc faces {nick host hand chan arg} {
    if {![channel get $chan squire]} {
        return 0
    }

    switch -glob [string trim $::lastbind "."] {
        boobs {
            putquick "PRIVMSG $chan :（。 ㅅ  。）"
        }
        bedtime {
            putquick "PRIVMSG $chan :［(－_－)］zzz"
        }
        yuno {
            putquick "PRIVMSG $chan :ლ(ಠ益ಠ)ლ"
        }
        cool {
            putquick "PRIVMSG $chan :( •_•)   ( •_•)>⌐■-■   (⌐■_■)"
        }
        smoke {
            putquick "PRIVMSG $chan :    ___"
            putquick "PRIVMSG $chan :   |   |   (("
            putquick "PRIVMSG $chan :   |   |    )"
            putquick "PRIVMSG $chan :   |   | __/"
            putquick "PRIVMSG $chan :   |   |/ /"
            putquick "PRIVMSG $chan :   |   | /"
            putquick "PRIVMSG $chan :  /------\\"
            putquick "PRIVMSG $chan : (________)"
            putquick "PRIVMSG $chan :  \\______/"
        }
        shrug {
            set faces [list \
                "¯\\_(ツ)_/¯" \
                "¯\\_(☼,☼)_/¯" \
                "¯\\_(°෴°)_/¯" \
                "¯\\(º_o)/¯" \
                "¯\\_(ȍ!ȍ)_/¯" \
                "¯\\_(ò‿ó)_/¯" \
                "( ☉_☉ )" \
                "¯\\_(◕◡◕)_/¯" \
                "⁀⊙ ﹏☉⁀" \
                "¯\\_(⊙_ʖ⊙)_/¯" \
                "¯\\_(⊙ω⊙)_/¯" \
                "¯\\_(⍜v⍜)_/¯" \
                "¯\\_(• ͟ʖ•)_/¯" \
                "ƪ(•̃͡ε•̃͡)∫" \
            ]
            putquick "PRIVMSG $chan :[lindex $faces [rand [llength $faces]]]"
        }
        fail {
            putquick "PRIVMSG $chan : ▄██████████████▄▐█▄▄▄▄█▌"
            putquick "PRIVMSG $chan : ██████▌▄▌▄▐▐▌███▌▀▀██▀▀"
            putquick "PRIVMSG $chan : ████▄█▌▄▌▄▐▐▌▀███▄▄█▌"
            putquick "PRIVMSG $chan : ▄▄▄▄▄██████████████▀"
        }
        coffee {
            putquick "PRIVMSG $chan :      (   ) )"
            putquick "PRIVMSG $chan :       ) ( ( "
            putquick "PRIVMSG $chan :      _)_____"
            putquick "PRIVMSG $chan :  .- '-------|"
            putquick "PRIVMSG $chan : ( (|        |"
            putquick "PRIVMSG $chan :  '-.        |"
            putquick "PRIVMSG $chan :     '_______'"
            putquick "PRIVMSG $chan :     '-------'"
        }
        pacman {
            putquick "PRIVMSG $chan :__________________|      |______________________________________"
            putquick "PRIVMSG $chan :     ,--.    ,--.          ,--.   ,--."
            putquick "PRIVMSG $chan :    |oo  | _  \\  `.       | oo | |  oo|"
            putquick "PRIVMSG $chan :o  o|~~  |(_) /   ;       | ~~ | |  ~~|o  o  o  o  o  o  o  o  o"
            putquick "PRIVMSG $chan :    |/\\/\\|   '._,'        |/\\/\\| |/\\/\\|"
            putquick "PRIVMSG $chan :__________________        _______________________________________"
            putquick "PRIVMSG $chan :                  |      |"
        }
        beerme {
            putquick "PRIVMSG $chan :         . ."
            putquick "PRIVMSG $chan :       .. . *."
            putquick "PRIVMSG $chan :- -_ _-__-0oOo"
            putquick "PRIVMSG $chan : _-_ -__ -||||)"
            putquick "PRIVMSG $chan :    ______||||______"
            putquick "PRIVMSG $chan :~~~~~~~~~~`\"\"'"
        }
        pie {
            putquick "PRIVMSG $chan :          ("
            putquick "PRIVMSG $chan :           )"
            putquick "PRIVMSG $chan :      __..---..__"
            putquick "PRIVMSG $chan :  ,-='  /  |  \\  `=-."
            putquick "PRIVMSG $chan : :--..___________..--;"
            putquick "PRIVMSG $chan :  \\.,_____________,./"
        }
        cheese {
            putquick "PRIVMSG $chan :     ___"
            putquick "PRIVMSG $chan :   .'o O'-._"
            putquick "PRIVMSG $chan :  / O o_.-`|"
            putquick "PRIVMSG $chan : /O_.-'  O |"
            putquick "PRIVMSG $chan : | o   o .-`"
            putquick "PRIVMSG $chan : |o O_.-'"
            putquick "PRIVMSG $chan : '--`"
        }
        nut {
            putquick "PRIVMSG $chan :       _"
            putquick "PRIVMSG $chan :     _/-\\_"
            putquick "PRIVMSG $chan :  .-`-:-:-`-."
            putquick "PRIVMSG $chan : /-:-:-:-:-:-\\"
            putquick "PRIVMSG $chan : \\:-:-:-:-:-:/"
            putquick "PRIVMSG $chan :  |`       `|"
            putquick "PRIVMSG $chan :  |         |"
            putquick "PRIVMSG $chan :  `\\       /'"
            putquick "PRIVMSG $chan :    `-._.-'"
        }
        hello {
            set faces [list "( ･ω･)ﾉ" \
                "( ^_^)／" \
                "(^o^)/" \
                "( ´ ▽ ` )ﾉ" \
                "(=ﾟωﾟ)ﾉ" \
                "( ・_・)ノ" \
                "(。･∀･)ﾉ" \
                "(*ﾟ͠ ∀ ͠)ﾉ" \
                "(♦亝д 亝)ﾉ" \
                "( *՞ਊ՞*)ﾉ" \
                "(｡Ő▽Ő｡)ﾉﾞ" \
                "(ஐ╹◡╹)ノ" \
                "(✧∇✧)╯" \
                "(^▽^)/ ʸᵉᔆᵎ" \
                "(。･д･)ﾉﾞ" \
                "(◍˃̶ᗜ˂̶◍)ﾉ”" \
                "(*´･д･)ﾉ" \
                "|。･ω･|ﾉ" \
                "(ه’́⌣’̀ه )／" \
                "ヽ(´･ω･`)､" \
                "ヘ(°￢°)ノ" \
                "＼(-_- )" \
                "(¬_¬)ﾉ" \
                "(;-_-)ノ" \
                "(^-^*)/" \
                "＼( ･_･)" \
                "ヾ(-_-;)" \
                "|ʘ‿ʘ)╯" \
            ]
            putquick "PRIVMSG $chan :[lindex $faces [rand [llength $faces]]]"
        }
    }
}

putlog "squire.tcl loaded"
}
