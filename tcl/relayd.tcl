#!/usr/bin/env tclsh
package require picoirc
package require tls


set config {
    steers {
        url "irc://127.0.0.1:6667/#potato"
        nick "v"
        password ""
        realname ""
        user_modes "+B"
        ignore_hostmasks {
            *!*@B5D2884F.68E5F1D1.7630B150.IP
        }
    }
    queers {
        url "ircs://127.0.0.1:6697/#tomato"
        nick "m"
        password ""
        realname ""
        user_modes "+BDTip-w"
        ignore_hostmasks {}
    }
}

set commandPrefix  .relay  ;# Prefix for IRC commands
set maxReconnectDelay 600  ;# Max reconnect delay (10 minutes)
set colorCacheTime     60  ;# Cache nick colors for 60 minutes
set spamThreshold       5  ;# Number of duplicate messages allowed before blocking (1 = block first duplicate)
set spamWindow         30  ;# Seconds to track duplicate messages


array set color {
    white   "\00300"   yellow  "\00308"   bold       "\002"
    black   "\00301"   lime    "\00309"   italic     "\035"
    navy    "\00302"   teal    "\00310"   underline  "\037"
    green   "\00303"   cyan    "\00311"   reverse    "\026"
    red     "\00304"   blue    "\00312"   reset      "\017"
    maroon  "\00305"   pink    "\00313"   clear      "\003"
    purple  "\00306"   grey    "\00314"
    olive   "\00307"   silver  "\00315"
}

set nickColorList {navy green red purple olive yellow lime teal cyan blue pink silver}

proc formatMsg {fromNick msg} {
    global color
    set nickColor [getNickColor $fromNick]
    return "${color(maroon)}₍${nickColor}${fromNick}${color(maroon)}⁾${color(reset)} $msg"
}

proc log {level msg} {
    set ms [clock milliseconds]
    puts [format "\[%s.%03d\] \[%-6s\] %s\033\[0m" \
         [clock format [expr {$ms / 1000}] -format "%H:%M:%S"] \
         [expr {$ms % 1000}] $level $msg]
}


# global state
array set connections {}
array set nickColors {}
array set userHostmasks {}
array set contextToName {}
array set msgDedup {}

proc getNickColor {nick} {
    global nickColors nickColorList color
    set now [clock milliseconds]

    # check if nick already has a color
    if {[info exists nickColors($nick)]} {
        lassign $nickColors($nick) colorName timestamp
        # update timestamp to keep it
        set nickColors($nick) [list $colorName $now]
        return $color($colorName)
    }

    # assign new color if not
    set usedColors {}
    foreach {n data} [array get nickColors] {
        lappend usedColors [lindex $data 0]
    }

    # pick unused color or if all are used, a random one
    set availableColors [lmap c $nickColorList {expr {$c in $usedColors ? [continue] : $c}}]
    set listToUse [expr {[llength $availableColors] > 0 ? $availableColors : $nickColorList}]
    set colorName [lindex $listToUse [expr {int(rand() * [llength $listToUse])}]]

    set nickColors($nick) [list $colorName $now]
    return $color($colorName)
}

proc colorCleanup {} {
    global nickColors colorCacheTime

    while {1} {
        if {[catch {
            # Wait 5 minutes before next cleanup
            after [expr {5 * 60000}] [info coroutine]
            yield

            set now [clock milliseconds]
            set cacheTimeMs [expr {$colorCacheTime * 60000}]
            set expired {}

            foreach {nick data} [array get nickColors] {
                lassign $data colorName timestamp
                if {($now - $timestamp) > $cacheTimeMs} {
                    lappend expired $nick
                }
            }
            foreach nick $expired {
                unset nickColors($nick)
            }
        } err]} {
            log "ERROR" "colorCleanup error: $err"
        }
    }
}

proc dedupCleanup {} {
    global msgDedup spamWindow

    while {1} {
        if {[catch {
            # Wait 1 minute before next cleanup
            after 60000 [info coroutine]
            yield

            set now [clock seconds]
            set expired {}

            foreach {hash data} [array get msgDedup] {
                lassign $data count timestamp
                if {($now - $timestamp) > $spamWindow} {
                    lappend expired $hash
                }
            }
            foreach hash $expired {
                unset msgDedup($hash)
            }
        } err]} {
            log "ERROR" "dedupCleanup error: $err"
        }
    }
}

proc isDuplicateMsg {nick msg} {
    global msgDedup spamThreshold spamWindow

    # hash: nick + first 80 chars of message
    set key "$nick:[string range $msg 0 79]"
    set now [clock seconds]

    if {[info exists msgDedup($key)]} {
        lassign $msgDedup($key) count timestamp
        set age [expr {$now - $timestamp}]

        # if within time window, increment count
        if {$age < $spamWindow} {
            incr count
            set msgDedup($key) [list $count $timestamp]
            # block if threshold exceeded
            if {$count > $spamThreshold} {
                return 1
            }
            return 0
        }
    }

    # new message
    set msgDedup($key) [list 1 $now]
    return 0
}

proc getConnInfo {ctx {key ""}} {
    global connections contextToName

    # first check the direct mapping
    if {[info exists contextToName($ctx)]} {
        set name $contextToName($ctx)
        if {$key eq ""} {
            return $name
        } elseif {[info exists connections($name)]} {
            return [dict get $connections($name) $key]
        }
    }

    # fallback to searching connections array
    foreach {name info} [array get connections] {
        if {[dict get $info context] eq $ctx} {
            return [expr {$key eq "" ? $name : [dict get $info $key]}]
        }
    }
    return ""
}

# get full connection info as dict for caching
proc getConnInfoFull {ctx} {
    global connections contextToName

    # try direct mapping first
    if {[info exists contextToName($ctx)]} {
        set name $contextToName($ctx)
        if {[info exists connections($name)]} {
            set info $connections($name)
            return [dict create \
                name $name \
                nick [dict get $info nick] \
                channel [dict get $info channel] \
                context $ctx \
                connected [dict get $info connected]]
        }
    }

    # fallback to searching
    foreach {name info} [array get connections] {
        if {[dict get $info context] eq $ctx} {
            return [dict create \
                name $name \
                nick [dict get $info nick] \
                channel [dict get $info channel] \
                context $ctx \
                connected [dict get $info connected]]
        }
    }
    # empty dict if not found
    return [dict create name "" nick "" channel "" context "" connected 0]
}

proc shouldIgnore {ctx hostmask} {
    global connections
    set connName [getConnInfo $ctx]
    if {$connName eq "" || ![info exists connections($connName)] ||
        ![dict exists $connections($connName) ignore_hostmasks]} {
        return 0
    }

    foreach pattern [dict get $connections($connName) ignore_hostmasks] {
        if {[string match -nocase $pattern $hostmask]} {return 1}
    }
    return 0
}

proc handleIrcCmd {ctx channel nick cmd connName args} {
    global connections color config commandPrefix

    switch -exact -- $cmd {
        help {
            set help_msg [list \
                "-Available Commands-" \
                " ${commandPrefix} status" \
                " ${commandPrefix} reconnect <server>"
            ]
            foreach line $help_msg {
                picoirc::post $ctx "" "NOTICE $nick :$line"
            }
        }
        reconnect {
            set targetConn [lindex $args 0]
            if {$targetConn ne "" && [info exists connections($targetConn)]} {
                log "CMD" "\033\[94m$nick requested reconnect $targetConn from $connName"
                startReconnection $targetConn 1
            } {
                picoirc::post $ctx "" "NOTICE $nick :server name empty or doesnt exist"
            }
        }
        status - "" {
            set statusLines {}
            foreach {name info} [array get connections] {
                if {[dict get $info context] eq $ctx} {continue}
                set status [expr {[dict get $info connected] ? "${color(lime)}Online" : "${color(red)}Offline"}]
                lappend statusLines "${name}: $status"
            }
            set response [join $statusLines " ${color(grey)}|${color(reset)} "]
            picoirc::post $ctx $channel $response
        }
    }
}

# all the magic
proc ircCallback {ctx state args} {
    global connections userHostmasks color commandPrefix

    # parse hostmasks from debug messages FIRST
    if {$state eq "debug"} {
        lassign $args direction line
        # match patterns :nick!user@host
        if {$direction eq "read" && [regexp {^:([^!]+)!([^@]+)@(\S+)} $line -> nick user host]} {
            set userHostmasks($ctx,$nick) "$nick!$user@$host"
        }
        #log "DEBUG" "$direction: $line"
        return
    }

    # cache connection info once for the entire event callback
    set connInfo [getConnInfoFull $ctx]
    set connName [dict get $connInfo name]
    set connNick [dict get $connInfo nick]
    set connChannel [dict get $connInfo channel]

    switch -exact -- $state {
        connect {
            if {$connName ne "" && [info exists connections($connName)]} {
                dict set connections($connName) reconnectDelay 5
                dict set connections($connName) connected 1
            }
            log "CONN" "\033\[32mConnected to \033\[32;1m$connName"
        }
        chat {
            lassign $args channel nick msg type
            if {$type ne ""} {return}

            # dont relay bot messages
            foreach {name info} [array get connections] {
                if {$nick eq [dict get $info nick]} {return}
            }

            # dont relay NOTICE or ACTION
            if {$type ne ""} {return}

            #log "MSG" "$nick in $channel: $msg"

            # check for dupe messages / spam
            if {[isDuplicateMsg $nick $msg]} {
                #log "DEBUG" "Blocking duplicate message from $nick"
                return
            }

            # check ignore list
            set hostmask [expr {[info exists userHostmasks($ctx,$nick)] ? $userHostmasks($ctx,$nick) : $nick}]
            if {[shouldIgnore $ctx $hostmask]} {return}

            # check for commandPrefix
            if {[string match "${commandPrefix}*" $msg]} {
                set cmdLine [string range $msg [string length $commandPrefix] end]
                set cmdLine [string trim $cmdLine]

                set cmdParts [split $cmdLine]
                set cmd [string tolower [lindex $cmdParts 0]]
                set cmdArgs [lrange $cmdParts 1 end]

                # Command name validation
                if {$cmd ne "" && (![regexp {^[a-z]+$} $cmd] || [string length $cmd] > 20)} {
                    log "WARN" "$nick sent invalid command format"
                    return
                }

                handleIrcCmd $ctx $channel $nick $cmd $connName {*}$cmdArgs
                return
            }

            # finally, relay to other channels
            set relayMsg [formatMsg $nick $msg]
            foreach {name info} [array get connections] {
                if {[dict get $info context] ne $ctx} {
                    if {[catch {picoirc::post [dict get $info context] [dict get $info channel] $relayMsg} err]} {
                        log "ERROR" "Failed to relay to $name: $err"
                    }
                    #log "RELAY" "Sent to $targetChannel: $relayMsg"
                }
            }
        }
        traffic {
            #lassign $args action channel nick
            #log "TRAFFIC" "$action: $nick in $channel"
        }
        userlist {
            lassign $args channel users
            log "INFO" "\033\[90mUsers in $channel: [expr {[llength $users] - 1}]"

            # announce connection to other servers
            set connMsg "\001ACTION now ${color(lime)}linked${color(reset)} with ${connName}\001"
            foreach {name info} [array get connections] {
                if {[dict get $info context] ne $ctx && [dict get $info connected]} {
                    if {[catch {picoirc::post [dict get $info context] [dict get $info channel] $connMsg} err]} {
                        log "ERROR" "Failed to announce connection to $name: $err"
                    }
                }
            }
        }
        system {
            lassign $args channel message
            if {$message ne "" || ![string match -nocase "*253*" $message]} {
                log "SYSTEM" "\033\[033m$message"
            }

            # set bot mode after registration (396 = RPL_HOSTHIDDEN)
            if {[string match "*396*" $message]} {
                picoirc::post $ctx "" "MODE $connNick +BDTip-w"
                # TODO: use config if u want
                # if {$connName ne ""} {
                #     if {[dict exists $connections($connName) user_modes]} {
                #         set userModes [dict get $connections($connName) user_modes]
                #         if {$userModes ne ""} {
                #             picoirc::post $ctx "" "MODE $connNick $userModes"
                #             #log "INFO" "Set user mode $userModes for $connNick"
                #         }
                #     }
                # }
            }

            # detect disconnections
            # 433 (nick in use handled by picoirc)
            # 465 (banned)
            # 464 (bad password)
            if {[string match -nocase "*error*" $message] ||
                [string match -nocase "*closing link*" $message] ||
                [string match "*465*" $message]} {

                if {$connName ne ""} {
                    set disconnMsg "\001ACTION ${connName} link ${color(red)}severed ${color(grey)}(connection lost)\001"
                    foreach {name info} [array get connections] {
                        if {[dict get $info context] ne $ctx && [dict get $info connected]} {
                            if {[catch {picoirc::post [dict get $info context] [dict get $info channel] $disconnMsg} err]} {
                                log "ERROR" "Failed to announce disconnection to $name: $err"
                            }
                        }
                    }
                }
            }
        }
        close {
            log "CLOSE" "\033\[91mConnection closed: $connName"
            if {[llength $args] > 0} {log "ERROR" "\033\[31mClose reason: [lindex $args 0]"}

            if {$connName ne "" && [info exists connections($connName)]} {
                set isCurrentContext [expr {[dict get $connections($connName) context] eq $ctx}]
                if {$isCurrentContext} {
                    # announce disconnection to other servers
                    set disconnMsg "\001ACTION attempting to reconnect..\001"
                    foreach {name info} [array get connections] {
                        if {[dict get $info context] ne $ctx && [dict get $info connected]} {
                            if {[catch {picoirc::post [dict get $info context] [dict get $info channel] $disconnMsg} err]} {
                                log "ERROR" "Failed to announce disconnection to $name: $err"
                            }
                        }
                    }
                    dict set connections($connName) connected 0
                    startReconnection $connName 0
                }

                # clean up context map
                global contextToName
                catch {unset contextToName($ctx)}
            }
        }
        debug {
            #lassign $args direction line
            #log "DEBUG" "$direction: $line"
        }
        default {
            #log "$state" "\033\[90m$args"
        }
    }
}

proc connectServer {name config} {
    global connections contextToName

    set url [dict get $config url]
    set nick [dict get $config nick]
    set realname [dict get $config realname]
    set password [dict get $config password]

    #log "INFO" "Connecting $name to $url as $nick"

    # get channel name from url
    regexp {/([#&][^/\s]+)} $url -> channel

    set ::tcl_platform(user) "FindUs"
    set ctx [picoirc::connect ircCallback "$nick" "$password" "$realname" "$url"]

    # store context-to-name mapping (persists even after reconnection)
    set contextToName($ctx) $name

    set reconnectDelay 5
    if {[info exists connections($name)] && [dict exists $connections($name) reconnectDelay]} {
        set reconnectDelay [dict get $connections($name) reconnectDelay]
    }

    # store connection info
    set connections($name) [dict create \
        context $ctx \
        nick $nick \
        channel $channel \
        realname $realname \
        ignore_hostmasks [dict get $config ignore_hostmasks] \
        reconnectDelay $reconnectDelay \
        connected 0 \
        reconnect ""]

    return $ctx
}

proc reconnection {name {triggered 0}} {
    global connections config maxReconnectDelay

    while {1} {
        # check if connection still exists (might have been cleaned up)
        if {![info exists connections($name)]} {
            log "INFO" "\033\[38;5;208mReconnection coroutine for $name stopping (connection removed)"
            return
        }

        # wait for delay period
        if {!$triggered} {
            set delay [dict get $connections($name) reconnectDelay]
            log "INFO" "\033\[38;5;208mScheduling reconnect for $name in $delay seconds"
            after [expr {$delay * 1000}] [info coroutine]
            yield
        }

        # check again after yield (connection might have been removed during wait)
        if {![info exists connections($name)]} {
            log "INFO" "\033\[38;5;208mReconnection coroutine for $name stopping (connection removed)"
            return
        }

        if {![dict exists $config $name]} {
            log "ERROR" "Cannot find config for: $name"
            return
        }

        if {[dict exists $connections($name) context]} {
            set oldCtx [dict get $connections($name) context]
            catch {picoirc::post $oldCtx "" "QUIT :221 Goodbye."}
        }

        # attempt reconnection
        if {[catch {connectServer $name [dict get $config $name]} err]} {
            log "ERROR" "Failed to reconnect $name: $err"
            # exponential backoff (only for automatic reconnects)
            if {!$triggered} {
                set delay [expr {min($delay * 2, $maxReconnectDelay)}]
                dict set connections($name) reconnectDelay $delay
                continue
            } else {
                dict set connections($name) reconnect ""
                return
            }
        }

        log "INFO" "\033\[38;5;214mReconnected to $name"

        # clear the coroutine reference since we're done
        dict set connections($name) reconnect ""
        # exit coroutine after successful reconnection
        return
    }
}

proc startReconnection {name {triggered 0}} {
    global connections

    if {![info exists connections($name)]} {
        log "ERROR" "Cannot start reconnection for unknown connection: $name"
        return
    }

    # check if reconnection coroutine already exists
    set existingCoro [dict get $connections($name) reconnect]
    if {$existingCoro ne "" && [info commands $existingCoro] ne ""} {
        log "INFO" "\033\[38;5;208mReconnection already in progress for $name"
        return
    }

    # create and store new reconnection coroutine
    set coroName "reconnect_${name}"
    coroutine $coroName reconnection $name $triggered
    dict set connections($name) reconnect $coroName
}

# trap handler
proc cleanup {} {
    global connections contextToName

    log "INFO" "\033\[31mShutting down..."

    catch {rename colorCleanupCoro ""}
    catch {rename dedupCleanupCoro ""}

    foreach {name info} [array get connections] {
        set coro [dict get $info reconnect]
        if {$coro ne "" && [info commands $coro] ne ""} {
            catch {rename $coro ""}
        }
        set ctx [dict get $info context]
        catch {picoirc::post $ctx "" "QUIT :221 Goodbye."}
        catch {unset contextToName($ctx)}
    }
    exit 0
}

# replacement for signal traps that would require tclx package
proc consoleInput {} {
    if {[gets stdin line] >= 0} {
        switch -exact -- [string trim $line] {
            "quit" - ".quit" - "exit" - ".exit" {
                cleanup
            }
            "status" - ".status" {
                global connections
                foreach {name info} [array get connections] {
                    log "STATUS" "$name: [expr {[dict get $info connected] ? "\033\[92mOnline" : "\033\[91mOffline"}] (Backoff: [dict get $info reconnectDelay]s)"
                }
            }
        }
    } elseif {[eof stdin]} {
        fileevent stdin readable {}
    }
}

proc main {} {
    global config

    coroutine colorCleanupCoro colorCleanup
    coroutine dedupCleanupCoro dedupCleanup

    dict for {name serverConfig} $config {
        if {[catch {connectServer $name $serverConfig} err]} {
            log "ERROR" "Failed to connect $name: $err"
            exit 1
        }
    }
    log "INFO" "\033\[32mAll connections initiated. Relay active."

    fconfigure stdin -blocking 0
    fileevent stdin readable consoleInput
    log "INFO" "\033\[38;5;214mType '.quit' to shutdown, '.status' for connections"

    vwait forever
}

main
