package require tdbc::sqlite3

namespace eval pre {
    # path to the database file
    variable dbFile "scripts/predb/pre.sqlite"

    variable addprechan "#addpre"
    variable sitechan   "#virt"
    variable search_limit 10

    # send commands to console
    variable debug 0

    # adds commas to number: 1000 -> 1,000
    proc commify {n {s ,} {g 3}} {
        return [regsub -all \\d(?=(\\d{$g})+([regexp -inline {\.\d*$} $n]$)) $n \\0$s]
    }

    proc getSectioncolor {arg} {
        set sec [lindex $arg 0]

        array set sectionColors {
                "0DAY"          "\0037\002\0020DAY\003"
                "ANIME"         "\00310ANiME\003"
                "APPS"          "\0037APPS\003"
                "AUDIOBOOK"     "\0036AUDiOBOOK\003"
                "BLURAY"        "\00310BLURAY\003"
                "BLURAY-FULL"   "\00310BLURAY-FULL\003"
                "COVERS"        "\00310COVERS\003"
                "DOX"           "\0036DOX\003"
                "DVDR"          "\0035DVDR\003"
                "EBOOK"         "\00312EBOOK\003"
                "FLAC"          "\0036FLAC\003"
                "GAMES"         "\0033GAMES\003"
                "GBA"           "\0036GBA\003"
                "MBLURAY"       "\00310MBLURAY\003"
                "MDVDR"         "\00310MDVDR\003"
                "MP3"           "\0036MP3\003"
                "MVID"          "\00310MViD\003"
                "NDS"           "\0036NDS\003"
                "NGC"           "\0036NGC\003"
                "PDA"           "\0037PDA\003"
                "PRE"           "\002PRE\002"
                "U"             "\002PRE\002"
                "PS2"           "\00314PS\0032\002\0022\003"
                "PS3"           "\00314PS\003\002\0023"
                "PSP"           "\00311P\00312S\0032P\003"
                "SCENENOTiCE"   "\0034SCENENOTiCE\003"
                "SUBPACK"       "\0035SUBPACK\003"
                "SVCD"          "\0036SVCD\003"
                "TV"            "\00311TV\003"
                "TV-DVDR"       "\00311TV-DVDR\003"
                "TV-DVDRIP"     "\00311TV-DVDRiP\003"
                "TV-HD"         "\00311TV-HD\003"
                "TV-HD-DE"      "\00311TV-HD-DE\003"
                "TV-HD-NL"      "\00311TV-HD-NL\003"
                "TV-HD-FR"      "\00311TV-HD-FR\003"
                "TV-HD-X264"    "\00311TV-HD-X264\003"
                "TV-HDRIP"      "\00311TV-HDRIP\003"
                "TV-SD-DE"      "\00311TV-SD-DE\003"
                "TV-SD-NL"      "\00311TV-SD-NL\003"
                "TV-SD-FR"      "\00311TV-SD-FR\003"
                "TV-SD-X264"    "\00311TV-SD-X264\003"
                "TV-SDR"        "\00311TV-SDR\003"
                "TV-SDRIP"      "\00311TV-SDRIP\003"
                "TV-X264"       "\00311TV-X264\003"
                "TV-XVID"       "\00311TV-XViD\003"
                "VCD"           "\0036VCD\003"
                "WII"           "\00314WII\003"
                "X264"          "\0032X264\003"
                "X264-HD"       "\0032X264-HD\003"
                "X264-SD-DE"    "\0032X264-SD-DE\003"
                "X264-SD-NL"    "\0032X264-SD-NL\003"
                "XBOX"          "\00312XBOX\003"
                "XBOX360"       "\00312XBOX\003\0033\002\002360\003"
                "XVID"          "\0032XViD\003"
                "XXX"           "\00313XXX\003"
                "XXX-0DAY"      "\00313XXX-0DAY\003"
                "XXX-DVDR"      "\00313XXX-DVDR\003"
                "XXX-IMGSET"    "\00313XXX-iMGSET\003"
                "XXX-X264"      "\00313XXX-X264\003"
        }

        foreach {section replace} [array get sectionColors] {
            if {[string equal -nocase $section $sec]} {
                return $replace
            }
        }
        return "${sec}(FIXCOLOR)"
    }

    bind pub - "!stats"     pre::dbstats
    bind pub - "!dupe"      pre::search
    bind pub - "!group"     pre::groupstats
    bind pub - "!grp"       pre::groupstats

    bind pub o "!addpre"    pre::pubaddpre
    bind pub o "!addimdb"   pre::pubimdb
    bind pub o "!addtvmaze" pre::pubtvmaze
    bind pub o "!info"      pre::pubaddinfo
    bind pub o "!addinfo"   pre::pubaddinfo
    bind pub o "!addgenre"  pre::pubgenre
    bind pub o "!genre"     pre::pubgenre
    bind pub o "!gn"        pre::pubgenre
    bind pub o "!nuke"      pre::pubnuke
    bind pub o "!modnuke"   pre::pubnuke
    bind pub o "!unnuke"    pre::pubunnuke

    bind bot - ADDPRE  pre::addpre
    bind bot - IMDB    pre::imdb
    bind bot - TVMAZE  pre::tvmaze
    bind bot - INFO    pre::addinfo
    bind bot - GENRE   pre::genre
    bind bot - NUKE    pre::nuke
    bind bot - UNNUKE  pre::unnuke

    # bind cron - "0 12 * * *" pre::topic
    bind cron - "0 12 * * *" pre::echostats

    # close the database connection on rehash/restart
    bind evnt - prerehash  pre::unload
    bind evnt - prerestart pre::unload
}

proc pre::count {} {
    [[db prepare {SELECT COUNT(id) FROM "predb"}] execute] nextdict res
    return [commify [dict get $res "COUNT(id)"]]
}

proc pre::dbstats {nick host hand chan arg} {
    # if {$chan ne $::pre::sitechan} {return 0}

    [[db prepare {SELECT COUNT(DISTINCT grp) FROM "predb"}] execute] nextdict res
    set groups [commify [dict get $res "COUNT(DISTINCT grp)"]]
    [[db prepare {SELECT COUNT(id) FROM "predb" WHERE status = 1}] execute] nextdict res
    set nukes [dict get $res "COUNT(id)"]
    [[db prepare {SELECT COUNT(id) FROM "predb" WHERE status = 2}] execute] nextdict res
    set unnukes [dict get $res "COUNT(id)"]

    putquick "PRIVMSG $chan :-\002PREdb\002- ([format "%.2f" [expr {[file size $::pre::dbFile] / 1024.0**2}]]\00314mB\003) \002[pre::count]\002 releases from \002$groups\002 groups, \002$nukes\002 nuked, \002$unnukes\002 unnuked"
}

proc pre::pubaddpre {nick host hand chan arg} {
    if {[llength $arg] < 2} {
        putlog ">> Error (addpre) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set grp     [lindex [split $rlsname "-"] end]
    set section [lindex $arg 1]
    set ctime   [clock seconds]

    if {$section eq "U"} {set section "PRE"}

    if {$::pre::debug == 1} {putlog "!addpre $rlsname $grp $section $ctime"}
    pre::addpre - ADDPRE "$rlsname $grp $section $ctime"
}

proc pre::addpre {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set grp     [lindex $arg 1]
    set section [lindex $arg 2]
    set ctime   [lindex $arg 3]

    if {$section eq "U"} {set section "PRE"}

    if {$::pre::debug == 1} {putlog "ADDPRE $rlsname $grp $section $ctime"}

    db allrows {
        INSERT OR IGNORE INTO "predb" (section, rlsname, grp, ctime)
        VALUES (:section, :rlsname, :grp, :ctime)
    }
}

proc pre::pubaddinfo {nick host hand chan arg} {
    if {[llength $arg] < 3} {
        putlog ">> Error (addinfo) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set files   [lindex $arg 1]
    set size    [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "!info $rlsname $files $size"}
    pre::addinfo - INFO "$rlsname $files $size"
}

proc pre::addinfo {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set files   [lindex $arg 1]
    set size    [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "INFO $rlsname $files $size"}

    db allrows {
        UPDATE "predb"
        SET files = :files, size = :size
        WHERE rlsname = :rlsname
    }
}

proc pre::pubtvmaze {nick host hand chan arg} {
    if {[llength $arg] < 2} {
        putlog ">> Error (tvmaze) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set url     [lindex $arg 1]

    if {$::pre::debug == 1} {putlog "!tvmaze $rlsname $url"}
    pre::tvmaze - TVMAZE "$rlsname $url"
}

proc pre::tvmaze {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set url     [lindex $arg 1]

    if {$::pre::debug == 1} {putlog "TVMAZE $rlsname $url"}

    db allrows {
        UPDATE "predb"
        SET tvmaze = :url
        WHERE rlsname = :rlsname
    }
}

proc pre::pubimdb {nick host hand chan arg} {
    if {[llength $arg] < 2} {
        putlog ">> Error (imdb) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set url     [lindex $arg 1]

    if {$::pre::debug == 1} {putlog "!imdb $rlsname $url"}
    pre::imdb - IMDB "$rlsname $url"
}

proc pre::imdb {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set url     [lindex $arg 1]

    if {$::pre::debug == 1} {putlog "IMDB $rlsname $url"}

    db allrows {
        UPDATE "predb"
        SET imdb = :url
        WHERE rlsname = :rlsname
    }
}

proc pre::pubgenre {nick host hand chan arg} {
    if {[llength $arg] < 2} {
        putlog ">> Error (genre) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set genre   [lindex $arg 1]

    if {$::pre::debug == 1} {putlog "!genre $rlsname $genre"}
    pre::genre - GENRE "$rlsname $genre"
}

proc pre::genre {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set genre   [lindex $arg 1]

    if {$::pre::debug == 1} {putlog "GENRE $rlsname $genre"}

    db allrows {
        UPDATE "predb"
        SET genre = :genre
        WHERE rlsname = :rlsname
    }
}

proc pre::pubnuke {nick host hand chan arg} {
    if {[llength $arg] < 3} {
        putlog ">> Error (nuke) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set reason  [lindex $arg 1]
    set nukenet [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "!nuke $rlsname $reason $nukenet"}
    pre::nuke - NUKE "$rlsname $reason $nukenet"
}

proc pre::nuke {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set reason  [lindex $arg 1]
    set nukenet [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "NUKE $rlsname $reason $nukenet"}

    db allrows {
        UPDATE "predb"
        SET reason = :reason, nukenet = :nukenet, status = 1
        WHERE rlsname = :rlsname
    }
}

proc pre::pubunnuke {nick host hand chan arg} {
    if {[llength $arg] < 3} {
        putlog ">> Error (unnuke) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set reason  [lindex $arg 1]
    set nukenet [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "!unnuke $rlsname $reason $nukenet"}
    pre::unnuke - UNNUKE "$rlsname $nukenet"
}

proc pre::unnuke {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set reason  [lindex $arg 1]
    set nukenet [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "UNNUKE $rlsname $reason $nukenet"}

    db allrows {
        UPDATE "predb"
        SET reason = :reason, nukenet = :nukenet, status = 2
        WHERE rlsname = :rlsname
    }
}

proc pre::pubdelpre {nick host hand chan arg} {
    if {[llength $arg] < 3} {
        putlog ">> Error (delpre) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set reason  [lindex $arg 1]
    set nukenet [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "!delpre $rlsname $reason $nukenet"}
    pre::delpre - DELPRE "$rlsname $reason $nukenet"
}

proc pre::delpre {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set reason  [lindex $arg 1]
    set nukenet [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "DELPRE $rlsname $reason $nukenet"}

    db allrows {
        UPDATE "predb"
        SET reason = :reason, nukenet = :nukenet, status = 3
        WHERE rlsname = :rlsname
    }
}

proc pre::pubundelpre {nick host hand chan arg} {
    if {[llength $arg] < 3} {
        putlog ">> Error (undelpre) missing args ($arg)"
        return 1
    }

    set rlsname [lindex $arg 0]
    set reason  [lindex $arg 1]
    set nukenet [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "!undelpre $rlsname $reason $nukenet"}
    pre::undelpre - UNDELPRE "$rlsname $reason $nukenet"
}

proc pre::undelpre {bot cmd arg} {
    set rlsname [lindex $arg 0]
    set reason  [lindex $arg 1]
    set nukenet [lindex $arg 2]

    if {$::pre::debug == 1} {putlog "UNDELPRE $rlsname $reason $nukenet"}

    db allrows {
        UPDATE "predb"
        SET reason = :reason, nukenet = :nukenet, status = 4
        WHERE rlsname = :rlsname
    }
}

proc pre::topic {args} {
    variable addprechan
    if {[botisop $addprechan]} {
        putserv "TOPIC $addprechan :[pre::count] releases [format "%.2f" [expr {[file size $::pre::dbFile] / 1024.0**2}]] MB"
    }
}

proc pre::echostats {args} {
    variable sitechan
    putquick "PRIVMSG $sitechan :-\002DAiLY STATS\002- ([format "%.2f" [expr {[file size $::pre::dbFile] / 1024.0**2}]]\00314mB\003) \002[pre::count]\002 releases"
}

proc pre::groupstats {nick host hand chan arg} {
    # if {$chan ne $::pre::sitechan} {return 0}

    set arg [string map {I i} [string toupper [string trim [lindex $arg 0]]]]

    [[db prepare {SELECT COUNT(id) FROM "predb" WHERE grp = :arg COLLATE NOCASE AND status != 3}] execute] nextdict res
    set releases [dict get $res "COUNT(id)"]

    if {$releases < 1} {
        putquick "PRIVMSG $chan :0 releases found"
        return 0
    }

    set regex "%NTERNAL%-$arg"
    [[db prepare {SELECT COUNT(id) FROM "predb" WHERE rlsname LIKE :regex}] execute] nextdict res
    set internals [dict get $res "COUNT(id)"]

    set regex "%DIRFIX%-$arg"
    [[db prepare {SELECT COUNT(id) FROM "predb" WHERE rlsname LIKE :regex}] execute] nextdict res
    set dirfixes [dict get $res "COUNT(id)"]

    set regex "%REPACK%-$arg"
    [[db prepare {SELECT COUNT(id) FROM "predb" WHERE rlsname LIKE :regex}] execute] nextdict res
    set repacks [dict get $res "COUNT(id)"]

    [[db prepare {SELECT COUNT(id) FROM "predb" WHERE grp = :arg COLLATE NOCASE AND status IN (1,3)}] execute] nextdict res
    set nukes [dict get $res "COUNT(id)"]

    set quality [expr $releases - $nukes - $dirfixes - $repacks]
    set percent [expr round([expr ($quality.00 / $releases) * 100])]

    set percentc "\00303$percent\003"
    if {$percent <= 65} {set percentc "\00307$percent\003"}
    if {$percent <= 35} {set percentc "\00304$percent\003"}

    putquick "PRIVMSG $chan :-\002$arg\002- Found \002$releases\002 \00314(\003INTERNALS: \00308$internals\003 NUKES: \00304$nukes\003 FIXES: \00312$dirfixes\003 REPACKS: \00307$repacks\00314)\003 we have \002${percentc}\00314%\003\002 quality releases"

    foreach sort {ASC DESC} {
        if {$sort eq "ASC"} {
            [[db prepare {SELECT rlsname, ctime FROM "predb" WHERE grp = :arg COLLATE NOCASE ORDER BY ctime ASC LIMIT 1}] execute] nextdict res
            set order "First \00314release was\003"
        } else {
            [[db prepare {SELECT rlsname, ctime FROM "predb" WHERE grp = :arg COLLATE NOCASE ORDER BY ctime DESC LIMIT 1}] execute] nextdict res
            set order "Latest \00314release is\003"
        }

        set rlsname [dict get $res "rlsname"]
        set ctime   [dict get $res "ctime"]
        set predate [clock format $ctime -format %d.%m.%Y]
        set pretime [clock format $ctime -format %H:%M:%S]

        putserv "PRIVMSG $chan :$order $rlsname \00314on\003 $predate \00314at\003 $pretime"
    }
}

proc pre::search {nick host hand chan arg} {
    # if {$chan ne $::pre::sitechan} {return 0}

    set arg "%[regsub -all { } [string trim $arg] {%}]%"
    set results_found 0

    set res [db prepare {
        SELECT * FROM "predb"
        WHERE rlsname LIKE :arg
        ORDER BY ctime DESC
        LIMIT :pre::search_limit
    }]

    set results_found 0

    $res foreach -as dicts d {
        incr results_found

        foreach key {size files tvmaze imdb} {
            if {[dict exists $d $key]} {set $key [dict get $d $key]} else {set $key 0}
        }

        set section [getSectioncolor [dict get $d section]]
        set rlsname [dict get $d rlsname]
        # set grp [dict get $d grp]
        # set time "\00314[clock format [dict get $d ctime] -format "%Y-%m-%d %H:%M:%S"]\003"
        set time "\00314(\017[string map [list \
            " years" \00314y\003 " weeks"   \00314w\003 " days"    \00314d\003 \
            " hours" \00314h\003 " minutes" \00314m\003 " seconds" \00314s\003 \
            " year"  \00314y\003 " week"    \00314w\003 " day"     \00314d\003 \
            " hour"  \00314h\003 " minute"  \00314m\003 " second"  \00314s\003 \
        ] [duration [expr {[clock seconds] - [dict get $d ctime]}]]]\00314)\003"

        set status [dict get $d status]

        append size  "\00308M\003 "
        append files "\00303F\003 "

        set nuked ""; set reason ""; set nukenet ""; set genre ""

        if {[dict exists $d genre]} {
            set genre "\00314([dict get $d genre])\003"
        }

        if {$status > 0} {
            switch $status {
                1 {set nuked "\002\00304NUKED\003\002 "}
                2 {set nuked "\002\00303UNNUKED\003\002 "}
                3 {set nuked "\002\00315DELPRE\002\003 "}
                4 {set nuked "\002\00307UNDELPRE\002\003 "}
            }
            set reason  "\00304[dict get $d reason]\003"
            set nukenet "\00314[dict get $d nukenet]\003"
        }
        putquick "PRIVMSG $chan :[string trim "$nuked$section$genre $rlsname $files$size$time $reason $nukenet"]"
    }

    if {$results_found == 0} {
        putquick "PRIVMSG $chan :Nothing found"
        return 0
    }

    if {$results_found == 1} {
        if {$tvmaze != 0} {putquick "PRIVMSG $chan :\002iNFO\002: https://tvmaze.com/shows/$tvmaze"}
        if {$imdb   != 0} {putquick "PRIVMSG $chan :\002iNFO\002: https://imdb.com/title/$imdb"}
    }
}

proc pre::db_init {database} {
    putlog "predb: creating $database"

    $database allrows {
        CREATE TABLE "predb" (
            "id"      INTEGER NOT NULL,
            "section" TEXT NOT NULL,
            "rlsname" TEXT NOT NULL UNIQUE,
            "grp"     TEXT NOT NULL,
            "ctime"   INTEGER NOT NULL,
            "size"    INTEGER,
            "files"   INTEGER,
            "status"  INTEGER NOT NULL DEFAULT 0,
            "reason"  TEXT,
            "nukenet" TEXT,
            "genre"   TEXT,
            "imdb"    TEXT,
            "tvmaze"  TEXT,
            PRIMARY KEY("id" AUTOINCREMENT)
        );
        CREATE INDEX "idx_predb_grp" ON "predb" (
            "grp"
        );
    }
}

proc pre::load {{arg 0}} {
    if {[catch {tdbc::sqlite3::connection create db $::pre::dbFile} err]} {
        putlog "predb: error: $err ($dbFile)"
        return 1
    }

    if {[lindex $arg 0] eq "create"} {
        pre::db_init db
    }

    putlog "predb: loaded [pre::count] entries"
}

proc pre::unload {arg} {
    db allrows {
        PRAGMA analysis_limit=1000;
        PRAGMA optimize;
    }
    db close
    putlog "predb: unloaded"
}

namespace eval pre {
    # trace die so that we can unload the database properly before the bot exist
    if {![info exists SetTraces]} {
        trace add execution die enter pre::unload
        variable SetTraces 1
    }

    # load the database if it's not already loaded
    if {![info object isa object db]} {
        # check if db needs to be created
        if {![file exists $dbFile]} {
            pre::load create
        } else {
            pre::load
        }
    }
}


proc bot:disc {frm_bot} {
    putquick "PRIVMSG $::pre::sitechan :*** \002$frm_bot\002 has \00304left\003 the botnet"
}
proc bot:link {frm_bot via} {
    putquick "PRIVMSG $::pre::sitechan :*** \002$frm_bot\002 has \00303joined\003 the botnet"
}

bind disc - * bot:disc
bind link - * bot:link
