namespace eval reddit {
    package require http
    package require tls
    package require json

    http::register https 443 [list ::tls::socket -autoservername 1]
    http::config -useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0"

    bind pubm - "*https://*r?ddit*.com/r/*" reddit::title

    setudef flag reddit

    proc title {nick host hand chan arg} {
        array set headers {Cookie "reddit_session=36945213%2C2023-12-26T15%3A30%3A45%2C2f5b299cca71548542602fb51604ed813962d6cc"}
        set re {(?:http(?:s|).{3}|)(?:www.|)(?:r[xe]ddit(?:-viewer|).com\/r\/(\w+)\/(?:comments|)\/(\w+)\/(.*?))}

        if {[channel get $chan reddit] && [regexp -nocase -- $re $arg url sub id]} {
            regsub {\/\/(?:www.|)r[xe]ddit(?:-viewer|)} $url "//www.reddit" url
            #putlog "${url}.json"

            if {[catch {set data [::http::data [::http::geturl "${url}.json" -timeout 3000 -headers [array get headers]]]} err]} {
                putlog "reddit http error: $err"
                return
            }

            if {[catch {set data [dict get [lindex [dict get [lindex [json::json2dict $data] 0] data children] 0] data]}]} {
                if {[string match "*You've been blocked by network security.*" $data]} {
                    putlog "reddit: blocked: update session cookie "
                    return
                }
                putlog "reddit: problem with returned json"
                return
            }

            set title [regsub -all {\s+} [dict get $data title] " "]
            #set sub   [dict get $data subreddit]
            #set ratio [dict get $data upvote_ratio]
            #set url   [dict get $data url]

            putquick "PRIVMSG $chan :\002\00307🔴\002\003 $title"
        }
    }
}
putlog "reddit.tcl loaded"
