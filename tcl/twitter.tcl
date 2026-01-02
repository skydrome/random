namespace eval twitter {
    package require http
    package require tls
    package require json

    http::register https 443 [list ::tls::socket -autoservername 1]
    http::config -useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0) Gecko/20100101 Firefox/98.0"

    bind pubm - "*https://x.com/*/status/*"        twitter::title
    bind pubm - "*https://*twitter.com/*/status/*" twitter::title
    bind pubm - "*https://fixupx.com/*/status/*"   twitter::title

    setudef flag twitter

    proc title {nick host hand chan text} {
        set re {(?:https.{3}|)(?:www.|)(?:(?:x|twitter).com\/)(\w+)\/status\/(\d+)}

        if {[channel get $chan twitter] && [regexp -nocase -- $re $text url account id]} {
            if {[catch {set data [::http::data [::http::geturl "https://api.fxtwitter.com/status/$id/en" -timeout 3000]]} err]} {
                putlog "fxtwitter http error: $err"
                return
            }
            set data [::json::json2dict [encoding convertfrom utf-8 $data]]

            if {[dict get $data code] != 200} {
                putlog "fxtwitter api error: [dict get $data message]"
                return
            }

            if {[dict exists $data tweet translation]} {
                set text [dict get $data tweet translation text]
                #set language [dict get $data tweet translation source_lang_en]
            } else {
                set text [dict get $data tweet text]
            }

            # remove emojis while keeping asian characters
            regsub -all {([\U0001F1E0-\U0001F1FF]|[\U0001F300-\U0001F5FF]|[\U0001F600-\U0001F64F]|[\U0001F680-\U0001F6FF]|[\U0001F700-\U0001F77F]|[\U0001F780-\U0001F7FF]|[\U0001F800-\U0001F8FF]|[\U0001F900-\U0001F9FF]|[\U0001FA00-\U0001FA6F]|[\U0001FA70-\U0001FAFF]|[\U00002702-\U000027B0])} $text "" text
            regsub -all {(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])} $text "" text
            # remove urls and hashtags
            regsub -all {https?://\S+} $text "" text
            regsub -all {\#\w+[:\s]?} $text "" text
            regsub -all {\s+} [string trim $text] " " text

            if {[string length $text] < 2} {
                return
            }

            if {[string length $text] > 250} {
                set text [string range $text 0 [string last " " [string range $text 0 250]]-1]
                append text "…"
            }
            putquick "PRIVMSG $chan :\00302🐦\017 $text"
        }
    }
}

putlog "twitter.tcl loaded"
