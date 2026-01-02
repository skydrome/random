package require http
package require tls
package require json

::http::register https 443 [list ::tls::socket -autoservername 1]
::http::config -useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0) Gecko/20100101 Firefox/98.0"

set bitly(url)  "https://api-ssl.bitly.com/v4/shorten"
set bitly(auth) "0d16ccb6a8f389150cdf69fdfa38acef49488f10"
set bitly(guid) "Bk8v1rJBRxZ"

proc bitly {link} {
    global bitly

    set auth [list Authorization "Bearer $bitly(auth)"]
    set query [list long_url \"$link\" domain \"bit.ly\" group_guid \"$bitly(guid)\"]

    if {[catch {::http::geturl $bitly(url) -headers $auth -type "application/json" \
                               -query [json::dict2json $query] } token]} {
        return -code 1 "fatal error (bitly) :$token"
    }
    if {![string equal -nocase [::http::status $token] "ok"]} {
        ::http::cleanup $token
        return -code 1 "http error (bitly) :[::http::ncode $token] [::http::status $token]"
    }
    set data [json::json2dict [::http::data $token]]
    ::http::cleanup $token

    return [lindex $data 5]
}

proc isgd {link} {
    set link [string map {"\\\\u003d" "="} $link]
    set query [::http::formatQuery format simple url $link]

    if {[catch {::http::geturl https://is.gd/create.php?${query}} token]} {
        return -code 1 "fatal error (is.gd) :$token"
    }

    if {![string equal -nocase [::http::status $token] "ok"]} {
        ::http::cleanup $token
        return -code 1 "http error (is.gd) :[::http::ncode $token] [::http::status $token]"
    }

    set data [::http::data $token]
    ::http::cleanup $token
    return $data
}

putlog "bitly/isgd.tcl loaded"
