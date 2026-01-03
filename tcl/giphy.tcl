namespace eval giphy {
    package require http
    package require tls
    package require json

    ::http::register https 443 [list ::tls::socket -autoservername 1]
    ::http::config -useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0) Gecko/20100101 Firefox/98.0"

    bind pub - ".gif" giphy::search

    setudef flag giphy

    # tenor v2
    variable key "AIzaSyAasU-aIgVh0aYVwuaCckEaDF3XD2bp-yw"
    # giphy
    #variable key "VgbsADdtjsi8lQXVz0ZMrUDO3Xie0kUc"

    proc search {nick host hand chan text} {
        if {![channel get $chan giphy] } { return }

        set text [::http::quoteString $text]

        set query [::http::formatQuery q $text key $::giphy::key media_filter gif limit 5 contentfilter off]
        set url "https://tenor.googleapis.com/v2/search?$query"
        #set query [::http::formatQuery q $text api_key $::giphy::key limit 5]
        #set url "http://api.giphy.com/v1/gifs/search?q=$text&api_key=$::giphy::key&limit=5"

        if {[catch {set data [::http::data [::http::geturl $url -timeout 3000]]} err]} {
            putlog "giphy http error: $err"
            return
        }
        set data [json::json2dict $data]

        if {[dict exists $data error]} {
            putlog "giphy error ([dict get $data error code]): [dict get $data error message]"
            return
        }

        set data [dict get $data results]
        set num_res [llength $data]
        set gif [dict get [lindex $data [expr {int(rand() * $num_res)}]] media_formats gif url]

        putquick "PRIVMSG $chan :$gif"
    }
}
putlog "giphy.tcl loaded"
