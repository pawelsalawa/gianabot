on {PING :*} {
    quote "PONG $S"
}
on {:%!%@% JOIN :[^&]%} {
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 [string range $0 1 [expr [string first ! $0] - 1]]
    set 2 [string tolower [string range $2 1 end]]
    lappend temp(onchannel:$2) "$0"
    set temp(chars:$2:$0) ""
    if {$N == $0} {
        lappend temp(mychans) "$2"
        set temp(users:$2) 1
        foreach x "topic topicby topicat" {
            upStatus $x $2 {}
        }
        lecho "[botspeak] %c[ts {I've joined channel %0} $2]"
        quote "mode $2"
        quote "who $2"
        getop $N $2
    } else {
        set temp(host:$0) "$1"
        set user [isuser2 $0!$1]
        if {"$user" != "" && [shellIdo $2]} {
            if {[isbot $user]} {
                botop $2 $0
            } elseif {[ahaveflags $user "o a" $2]} {
                op $2 $0
            } elseif {[ahaveflags $user "h a" $2]} {
                hop $2 $0
            } elseif {[ahaveflags $user "v a" $2]} {
                vop $2 $0
            } elseif {[haveflag $user b $2]} {
                queue "mode $2 +b [mask $0!$1 5]"
                kick $2 $0 $temp(kickreason)
            }
        }
        incr temp(users:$2)
    }
    checkFlood $0 $1 join $2
    switch -- $temp(logmode) {
        giana {
            log $2 "[ts {%0 (%1) has joined channel %2.} $0 $1 $2]"
        }
        eggdrop {
            log $2 " $0 ($1) joined $2."
        }
        epic {
            log $2 "*** $0 ($1) has joined channel $2"
        }
    }
}
on {:%!%@% PART % :*} {
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 [string range $0 1 [expr [string first ! $0] - 1]]
    set 2 [string tolower $2]
    if {$N == $0} {
        set temp(mychans) [lremove "$temp(mychans)" [lsearch "$temp(mychans)" $2]]
        catch {unset temp(users:$2)}
        catch {unset temp(scanned:$2)}
        foreach u "$temp(onchannel:$2)" {
            set ison 0
            foreach chan "$temp(mychans)" {
                if {[ison $u $chan]} {
                    set ison 1
                }
            }
            if {!$ison} {
                catch {unset temp(host:$u)}
            }
            catch {unset temp(chars:$2:$u)}
        }
        catch {unset temp(onchannel:$2)}
        lecho "[botspeak] %c[ts {I've left channel %0} $2]"
    } else {
        set ison 0
        foreach chan "$temp(mychans)" {
            if {[ison $0 $chan]} {
                set ison 1
            }
        }
        if {!$ison} {
            catch {unset temp(host:$0)}
        }
        catch {unset temp(chars:$2:$0)}
        set temp(onchannel:$2) "[lremove $temp(onchannel:$2) [lsearch $temp(onchannel:$2) $0]]"
        incr temp(users:$2) -1
        checkOP $2
    }
    set reason [string range [lrange $data 3 end] 1 end]
    switch -- $temp(logmode) {
        giana {
            log $2 "[ts {%0 (%1) has left channel %2 %3} $0 $1 $2 [split \"$reason\"]]"
        }
        eggdrop {
            log $2 " $0 ($1) left $2 ($reason)."
        }
        epic {
            log $2 "*** $0 has left channel $2 because ($reason)"
        }
    }
}
on {:%!%@% KICK % % :*} {
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 [string range $0 1 [expr [string first ! $0] - 1]]
    set 2 [string tolower $2]
    set reason [string range [lrange $data 4 end] 1 end]
    switch -- $temp(logmode) {
        giana {
            log $2 "[ts {%0 (%1) has been kicked from %2 by %3 (%4) :%5} $3 [Host $3] $2 $0 $1 [split \"$reason\"]]"
        }
        eggdrop {
            log $2 " $3 kicked from $2 by $0: $reason"
        }
        epic {
            log $2 "*** $3 has been kicked off channel $2 by $0 ($reason)"
        }
    }
    if {$N == $3} {
        set temp(mychans) "[lremove $temp(mychans) [lsearch $temp(mychans) $2]]"
        catch {unset temp(users:$2)}
        catch {unset temp(scanned:$2)}
        foreach u "$temp(onchannel:$2)" {
            set ison 0
            foreach chan "$temp(mychans)" {
                if {[ison $u $chan]} {
                    set ison 1
                }
            }
            if {!$ison} {
                catch {unset temp(host:$u)}
            }
            catch {unset temp(chars:$2:$u)}
        }
        mkick $2 $0
        catch {unset temp(onchannel:$2)}
        lecho "[botspeak] %c[ts {I've been kicked from channel %0 by %1} $2 $0]"
        join $2
    } else {
        if {[amon $2]} {
            set user0 [isuser2 $0!$1]
            set user [isuser2 $3![host $3]]
            if {"$user" != ""} {
                # here is no [shellIdo $2] becouse while 4x kick it doesn't work correctly.
                if {[haveflag $user x] && ![haveflag $user0 f]} {
                    mkick $2 $0
                }
            }
        }
        incr temp(users:$2) -1
        set ison 0
        foreach chan "$temp(mychans)" {
            if {[ison $0 $chan]} {
                set ison 1
            }
        }
        if {!$ison} {
            catch {unset temp(host:$3)}
        }
        catch {unset temp(chars:$2:$3)}
        set temp(onchannel:$2) "[lremove $temp(onchannel:$2) [lsearch $temp(onchannel:$2) $3]]"
        checkOP $2
    }
}
on {:%!%@% NICK :*} {
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 "[string range $0 1 [expr [string first ! $0] - 1]]"
    set 2 [string range $2 1 end]
    foreach chan "$temp(mychans)" {
        if {[ison $0 $chan]} {
            set temp(onchannel:$chan) "[lremove $temp(onchannel:$chan) [lsearch $temp(onchannel:$chan) $0]]"
            lappend temp(onchannel:$chan) "$2"
            set temp(chars:$chan:$2) "$temp(chars:$chan:$0)"
            set temp(host:$2) [host $0]
            catch {unset temp(host:$0)}
            catch {unset temp(chars:$chan:$0)}
            if {"$0" == "$N"} {
                set N "$2"
                lecho "[botspeak] %c[ts {I've changed my nick to %C%0%c.} $N]"
            }
            checkFlood $2 $1 nick $chan
        }
        switch -- $temp(logmode) {
            giana {
                log $chan "[ts {%0 (%1) has changed nick to %2.} $0 $1 $2]"
            }
            eggdrop {
                log $2 " Nick change: $0 -> $2"
            }
            epic {
                log $2 "*** $0 is now known as $2"
            }
        }
    }
}
on {:%!%@% KILL % :*} {
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 [string range $0 1 [expr [string first ! $0] - 1]]
    set reason [lrange $data 4 end]
    echo "[botspeak] %R[ts {I've been killed by %0 (%1).} $0 $reason]"
    set temp(mychans) ""
    set temp(server) ""
    set temp(serversock) ""
    LOG "[ts {I've been killd by %0 (%1)!} $0 $reason]"
}
on {:%!%@% QUIT :*} {
  set 1 [string range $0 [expr [string first ! $0] + 1] end]
  set 0 [string range $0 1 [expr [string first ! $0] - 1]]
  set reason [string range [lrange $data 2 end] 1 end]
  foreach ch "$temp(mychans)" {
        if {[ison $0 $ch]} {
            set temp(onchannel:$ch) "[lremove $temp(onchannel:$ch) [lsearch $temp(onchannel:$ch) $0]]"
            catch {unset temp(host:$0)}
            catch {unset temp(chars:$ch:$0)}
        }
        switch -- $temp(logmode) {
            giana {
                log $ch "[ts {%0 (%1) has left irc :%2} $0 $1 [split \"$reason\"]]"
            }
            eggdrop {
                log $2 " $0 ($1) left irc: $reason"
            }
            epic {
                log $2 "*** Signoff: $0 ($reason)"
            }
        }
        checkOP $ch
  }
}
on {:%!%@% PRIVMSG % :*} {
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 [string range $0 1 [expr [string first ! $0] - 1]]
    set 2 [string tolower $2]
    if {[string index [lindex $data 3] 1] == "\x01" && [string index [lindex $data end] end] == "\x01"} {
        switch "[string range [lindex $data 3] 2 end]" {
            DCC {
                switch "[strip \x01 [lindex $data 4]]" {
                    CHAT {
                        if {![info exists temp(dccchat_connection)]} {
                            # DCC CHAT FLOOD protection
                            set temp(dccchat_connection) 1
                            after 2000 unset temp(dccchat_connection)
                            set port "[strip \x01 [lindex $data 7]]"
                            set host [lindex [split $1 @] 1]
                            catch {socket $host $port} sock
                            if {[llength $sock] == 1} {
                                lecho "[botspeak] %c[ts {Incomming connection from %C%0%c on users port.} $host]"
                                set temp(dcctype:$sock) 1
                                fconfigure $sock -blocking 0 -buffering line
                                puts $sock "$temp(loginstring)"
                                fileevent $sock readable "getUserData $sock $host $port"
                            }
                        }
                    }
                }
            }
            ACTION {
                if {[ischan $2]} {
                    set string "[eval concat [lrange $data 4 end]]"
                    set string "[string range $string 0 end-1]"
                    switch -- $temp(logmode) {
                        giana {
                            log $2 "* $0 $string"
                        }
                        eggdrop {
                            log $2 " Action: $0 $string"
                        }
                        epic {
                            log $2 "* $0 $string"
                        }
                    }
                }
            }
        }
    } else {
        if {[ischan $2]} {
            if {[havechar [getchannel $2 mode] c]} {
                if {"[string index $3 1]" == "$temp(pubchar)"} {
                    set user "[isuser2 $0!$1]"
                    set cmd "[string tolower [string range $3 2 end]]"
                    if {"$user" != ""} {
                        if {[haveflags $user "u m n r c" $2]} {
                            if {"[info commands PUB:$cmd]" == "PUB:$cmd"} {
                                PUB:$cmd $0 $1 $user $2 "[lrange $data 4 end]"
                            } elseif {"[info commands pub:$cmd]" == "pub:$cmd"} {
                                pub:$cmd $0 $1 $user $2 "[lrange $data 4 end]"
                            }
                        }
                    } elseif {"[info commands pub:$cmd]" == "pub:$cmd"} {
                        pub:$cmd $0 $1 "" $2 "[lrange $data 4 end]"
                    }
                }
            }
            checkFlood $0 $1 public $2
            set string [string range [lrange $data 3 end] 1 end]
            switch -- $temp(logmode) {
                giana {
                    log $2 "<[pad 9 $temp(nickchar) $0]> $string"
                }
                eggdrop {
                    log $2 " <$0> $string"
                }
                epic {
                    log $2 "<$0> $string"
                }
            }
        } else {
            switch -- [string range $3 1 end] {
                op {
                    if {"[isuser2 $0!$1]" != ""} {
                        global password
                        if {[ischan $4] && "$5" == "$password([isuser2 $0!$1])"} {
                            if {[haveflag [isuser2 $0!$1] o] && [isop $N $4]} {
                                op $4 $0
                            }
                        }
                    }
                }
                dump {
                    if {"[string tolower $temp(dumpcmd)]" == "on"} {
                        set user "[isuser2 $0!$1]"
                        if {"$user" != ""} {
                            set sock $temp(null)
                            set temp(user:$sock) "$user"
                            set temp(sock:$user) "$sock"
                            cmd $4 [lrange $data 5 end]
                            unset temp(user:$sock)
                            unset temp(sock:$user)
                            unset sock
                        }
                    }
                }
                default {
                    set user "[isuser2 $0!$1]"
                    set cmd [string tolower [string range $3 1 end]]
                    if {"$user" != ""} {
                        if {[haveflags $user "u m n r" $2]} {
                            if {"[info commands MSG:$cmd]" == "MSG:$cmd"} {
                                MSG:$cmd $0 $1 $user "[lrange $data 4 end]"
                            } elseif {"[info commands msg:$cmd]" == "msg:$cmd"} {
                                msg:$cmd $0 $1 $user "[lrange $data 4 end]"
                            }
                        }
                    } elseif {"[info commands msg:$cmd]" == "msg:$cmd"} {
                        msg:$cmd $0 $1 "" "[lrange $data 4 end]"
                    }
                }
            }
        }
    }
}
on {:%!%@% NOTICE [^&]% :*} {
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 [string range $0 1 [expr [string first ! $0] - 1]]
    set 2 [string tolower $2]
    if {[string index [lindex $data 3] 1] == "\x01" && [string index [lindex $data end] end] == "\x01"} {
        switch "[string range [lindex $data 3] 2 end]" {
            DCC {
                # DCC and other ctcp to hook for version 2.1
            }
        }
    } else {
        if {[ischan $2]} {
            checkFlood $0 $1 public $2
            set string [string range [lrange $data 3 end] 1 end]
            switch -- $temp(logmode) {
                giana {
                    log $2 "-[pad 9 $temp(nickchar) $0]- $string"
                }
                eggdrop {
                    log $2 " -$0:$2- $string"
                }
                epic {
                    log $2 "-$0:$2- $string"
                }
            }
        } else {
            # private notice to hook for version 2.1
        }
    }
}
on {:%!%@% MODE % [^:]*} {
    set nick [string range $0 1 [expr [string first ! $0] - 1]]
    set host [string range $0 [expr [string first ! $0] + 1] end]
    set 2 [string tolower $2]
    set sgn ""
    set arg 4
    set chg 0
    set changelist ""
    set usch ""
    set usarg ""
    set tmp(chg) ""
    set tmp(arg) ""
    set tmp(kick) ""
    set tmp(test) 0
    set tmp(init) "$nick"
    set tmp(getop:$2:list) ""
    for {set fe 0} {[string index $3 $fe] != ""} {incr fe} {
        set ch [string index $3 $fe]
        if {$ch == "+" || $ch == "-"} {
            set sgn "$ch"
        } else {
            if {[lsearch -exact {o b e I v k} $ch] > -1} {
                set changelist "\[ $sgn$ch [lindex $data $arg] \] $changelist"
                check_$ch $sgn [lindex $data $arg] $2
                if {$ch == "k"} {
                    append usch "$sgn$ch"
                    lappend usarg [lindex $data $arg]
                }
                incr arg
                incr chg
            }
            if {[lsearch -exact l $ch] > -1} {
                if {$sgn == "+"} {
                    set changelist "\[ $sgn$ch [lindex $data $arg] \] $changelist"
                    check_$ch + [lindex $data $arg] $2
                    lappend usarg [lindex $data $arg]
                    incr arg
                } else {
                    set changelist "\[ $sgn$ch \] $changelist"
                    check_$ch - - $2
                }
                append usch "$sgn$ch"
                incr chg
            }
            if {[lsearch -exact {i m n s p t} $ch] > -1} {
                set changelist "\[ $sgn$ch \] $changelist"
                append usch "$sgn$ch"
                check_$ch $sgn $2
                incr chg
            }
        }
    }
    if {$usarg != ""} {
        set usarg [lsort $usarg]
    }
    upStatus chmode $2 $usch $usarg
    if {[isop $N $2]} {
        onMode $2
    } else {
#        getop $N $2
    }
    switch -- $temp(logmode) {
        giana {
            log $2 "* [ts {%0 (%1) has changed mode on channel %2 to:} $nick $host $2] $changelist"
        }
        eggdrop {
            log $2 " $2: mode change '[lrange $data 3 end]' by [string range $0 1 end]"
        }
        epic {
            log $2 "*** Mode change \"[lrange $data 3 end]\" on channel $2 by $nick"
        }
    }
    unset tmp(chg)
    unset tmp(arg)
    unset tmp(kick)
    unset tmp(test)
}
on {:% MODE % :*} {
    lecho "[botspeak] %c[ts {My user mode has been changed:}] %C[string range [lindex $data 3] 1 end]"
    for {set ucnt 1} {[string index [lindex $data 3] $ucnt] != ""} {incr ucnt} {
        set ch [string index [lindex $data 3] $ucnt]
        if {$ch == "+"} {
            set char 1
        }
        if {$ch == "-"} {
            set char 0
        }
        if {[lsearch {i w O o r s} $ch] > -1} {
            if {$char} {
                append temp(mymode) "$ch"
            } else {
                set temp(mymode) "[strip $ch $temp(mymode)]"
            }
        }
    }
}
on {:%!%@% TOPIC % :*} {
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 [string range $0 1 [expr [string first ! $0] - 1]]
    set 2 [string tolower $2]
    set t "[string range [lrange $data 3 end] 1 end]"
    upStatus topic $2 "$t"
    upStatus topicby $2 $0!$1
    upStatus topicat $2 [clock seconds]
    switch -- $temp(logmode) {
        giana {
            log $2 "[ts {%0 (%1) has changed topic for channel %2 to:} $0 $1 $2] $t"
        }
        eggdrop {
            log $2 " Topic changed on $2 by $0!$1: $t"
        }
        epic {
            log $2 "*** $0 has changed the topic on channel $2 to $t"
        }
    }
}
on {:%!%@% INVITE % :*} {
    set 3 [string tolower $3]
    set 1 [string range $0 [expr [string first ! $0] + 1] end]
    set 0 [string range $0 1 [expr [string first ! $0] - 1]]
    set 3 [string range $3 1 end]
    if {[mychan $3] && ![amon $3]} {
        join $3
    }
}
on {:% 001 * :*} {
    set N $2
    set temp(connected) 1
    lecho "[botspeak] %c[ts {Successful registered on server %C%0%c with nick %C%1%c.} [string range $0 1 end] $N]"
    set temp(onchannels) ""
    if {"[lindex [split $temp(server) :] 0]" != "[string range $0 1 end]"} {
        set temp(server) "[string range $0 1 end]:6667"
    }
    set S "[lindex [split $temp(server) :] 0]"
    quote "USERHOST $N"
    if {[llength "$temp(chanlist)"] > 0} {
        join $temp(chanlist)
    }
    after 90000 autoaway $temp(server)
}
on {:% 302 * :*} {
    if {[string first = $data] > -1} {
        set 0 [string range $data [expr [string first : $data 1] + 1] [expr [string first = $data 1] - 1]]
        set 1 [string range $data [expr [string first = $data] + 2] [expr [string first @ $data] - 1]]
        set 2 [string range $data [expr [string first @ $data] + 1] end]
        if {"$0" == "$N"} {
            set temp(myhost) "$1@$2"
            set X "$1@$2"
        } else {
            foreach2 ac switch userhost:[string tolower $0]:* {
                eval $switch($ac)
                unset switch($ac)
            }
        }
    }
}
on {:% 315 * :*} {
    set 3 [string tolower $3]
    lecho "[botspeak] %c[ts {Channel %0 scanned.} $3]"
    set temp(scanned:$3) 1
    catch {unset temp(scanning:$3)}
}
on {:% 324 *} {
    set 3 [string tolower $3]
    upStatus modes $3 [lrange $data 4 end]
}
on {:% 331 * :*} {
    set 3 [string tolower $3]
    foreach t {topic topicby topicat} {
        upStatus $t $3 ""
    }
}
on {:% 332 * :*} {
    set 3 [string tolower $3]
    upStatus topic $3 "[string range [lrange $data 4 end] 1 end]"
}
on {:% 333 *} {
    set 3 [string tolower $3]
    upStatus topicby $3 $4
    upStatus topicat $3 $5
}
on {:% 346 % % *} {
    set 3 [string tolower $3]
    if {![info exists temp(invsscan:$3)]} {
        set temp($3:invs) ""
        set temp(invsscan:$3) 1
    }
    if {[info exists switch($3:invs)]} {
        lappend temp($3:invs) "$4"
    }
}
on {:% 347 % % :*} {
    set 3 [string tolower $3]
    if {[info exists switch($3:invs)]} {
        if {![info exists temp($3:invs)]} {
            set temp($3:invs) ""
        }
        eval $switch($3:invs)
        unset switch($3:invs)
        unset temp($3:invs)
        catch {unset temp(invsscan:$3)}
    }
}
on {:% 348 % % *} {
    set 3 [string tolower $3]
    if {![info exists temp(excsscan:$3)]} {
        set temp($3:excs) ""
        set temp(excsscan:$3) 1
    }
    if {[info exists switch($3:excs)]} {
        lappend temp($3:excs) "$4"
    }
}
on {:% 349 % % :*} {
    set 3 [string tolower $3]
    if {[info exists switch($3:excs)]} {
        if {![info exists temp($3:excs)]} {
            set temp($3:excs) ""
        }
        eval $switch($3:excs)
        unset switch($3:excs)
        unset temp($3:excs)
        catch {unset temp(excsscan:$3)}
    }
}
on {:% 352 * :*} {
    set 3 [string tolower $3]
    if {![info exists temp(scanning:$3)]} {
        set temp(onchannel:$3) ""
        set temp(scanning:$3) 1
    }
    lappend temp(onchannel:$3) "$7"
    set temp(chars:$3:$7) "[strip HG $8]"
    set temp(host:$7) "$4@$5"
}
on {:% 367 % % *} {
    set 3 [string tolower $3]
    if {![info exists temp(bansscan:$3)]} {
        set temp($3:bans) ""
        set temp(bansscan:$3) 1
    }
    if {[info exists switch($3:bans)]} {
        lappend temp($3:bans) "$4"
    }
}
on {:% 368 % % :*} {
    set 3 [string tolower $3]
    if {[info exists switch($3:bans)]} {
        if {![info exists temp($3:bans)]} {
            set temp($3:bans) ""
        }
        eval $switch($3:bans)
        unset switch($3:bans)
        unset temp($3:bans)
        catch {unset temp(bansscan:$3)}
    }
}
on {:% 432 * :*} {
    if {!$temp(connected)} {
        set temp(nick) "[getStuff2 othernicks]"
        if {"$temp(nick)" == ""} {
            set temp(nick) "[randcrap 9]"
        }
        quote "NICK $temp(nick)"
    } else {
        lecho "[botspeak] %c[ts {I can't change nick, because it contains not allowed chars.}]"
    }
}
on {:% 433 * :*} {
    if {!$temp(connected)} {
        set temp(nick) "[getStuff2 othernicks]"
        if {"$temp(nick)" == ""} {
            set temp(nick) "[randcrap 9]"
        }
        quote "NICK $temp(nick)"
    } else {
        lecho "[botspeak] [ts {I can't change nick, because it is already in use.}]"
    }
}
on {:% 442 * :*} {
    set 3 [string tolower $3]
    if {$2 == $N} {
        lecho "[botspeak] %c[ts {I'm not on channel %C%0%c.} $3]"
    } else {
        lecho "[botspeak] %R[ts {%C%0%c is not on channel %C%1%c.} $2 $3]."
    }
}
on {:% 461 % MODE +l :*} {
    lecho "[botspeak] %c[ts {I've received message from server:}] %C[lrange $data 4 end]"
}
on {:% 473 *} {
    set 3 [string tolower $3]
    if {[isBotNet]} {
        bots2 "chanAccess $3 $N i"
    }
}
on {:% 474 *} {
    set 3 [string tolower $3]
    if {[isBotNet]} {
        bots2 "chanAccess $3 $temp(botname)#$N!$temp(myhost)#$N!$temp(myIP) e"
    }
}
on {:% 475 *} {
    set 3 [string tolower $3]
    if {[info exists temp(key:$3)]} {
        join $3 $temp(key:$3)
    } elseif {[isBotNet]} {
        bots2 "chanAccess $3 $temp(botname)#$temp(botname) k"
    }
}
on {:% 477 *} {
    set 3 [string tolower $3]
    upStatus modes $3 ""
}
on {:% 478 *} {
    set 3 [string tolower $3]
    lecho "[botspeak] %c[ts {There is maximum number of bans on %C%0%c.} $3]"
}
on {:% 482 % % :*} {
#    set 3 [string tolower $3]
#    getop $N $3
}
on {:% 484 * :*} {
    if {"$interactive" == "yes"} {
        lecho "[botspeak] %R[ts {My connection is restricted!}]"
    } else {
        if {![info exists temp(allow_restrict)]} {
            puts "(!) [ts {Bot connection is restricted! Shutting down...}]"
            exit 1
        }
    }
    set temp(am_restricted) 1
}
on {ERROR :Closing Link:*} {
    catch {close $channel}
    lecho "[botspeak] %c[ts {Connection with server %0 lost.} $temp(server)]"
    set temp(servtemp) $temp(server)
    set temp(connected) 0
    set temp(server) {}
    set temp(mychans) {}
    set temp(serversock) {}
    if {[llength [array names switch ondisc:$temp(servtemp):*]] > 0} {
        foreach od "[array names switch ondisc:$temp(servtemp):*]" {
            eval $switch($od)
            unset switch($od)
        }
    } else {
        after 5000 randserver
    }
}


### ON MODE Commands Section
proc check_o {sgn arg chan} {
    global N temp
    chUserStatus $chan $arg $sgn @
    upvar tmp tmp
    if {"$arg" == "$N"} {
        set tmp(getop:$chan) 1
    }
    if {$sgn == "+"} {
        if {"[isuser2 $arg![host $arg] bot]" != ""} {
            lappend tmp(getop:$chan:list) $arg
        }
        if {[haveflags [isuser2 $arg![host $arg]] "d b" $chan] || ![haveflag [isuser2 $arg![host $arg]] o $chan] && [havechar [getchannel $chan mode] b] || ![haveflag [isuser2 $arg![host $arg]] o $chan] && $temp(server_op_protect) && [string match *.* $tmp(init)]} {
            if {"$arg" != "$N"} {
                lappend tmp(kick) $arg
                set tmp(test) 1
            }
        }
    } else {
        if {[haveflags [isuser2 $arg![host $arg]] "x o" $chan] && $tmp(init) != $arg} {
            append tmp(chg) "+o"
            lappend tmp(arg) "$arg"
            set tmp(test) 1
        }
    }
}
proc check_h {sgn arg chan} {
    global N temp
    chUserStatus $chan $arg $sgn %
    upvar tmp tmp
    if {$sgn == "+"} {
        if {[haveflags [isuser2 $arg![host $arg]] "d b" $chan] || ![haveflag [isuser2 $arg![host $arg]] h $chan] && [havechar [getchannel $chan mode] b]} {
            if {"$arg" != "$N"} {
                lappend tmp(kick) $arg
                set tmp(test) 1
            }
        }
    } else {
        if {[haveflags [isuser2 $arg![host $arg]] "x h" $chan] && $tmp(init) != $arg} {
            append tmp(chg) "+h"
            lappend tmp(arg) "$arg"
            set tmp(test) 1
        }
    }
    chUserStatus $chan $arg $sgn %
}
proc check_v {sgn arg chan} {
    upvar tmp tmp
    chUserStatus $chan $arg $sgn +
    if {$sgn == "+"} {
        if {[haveflags [isuser2 $arg![host $arg]] "s b" $chan]} {
            append tmp(chg) "-v"
            lappend tmp(arg) "$arg"
        }
    } else {
        if {[haveflag [isuser2 $arg![host $arg]] x $chan] && $tmp(init) != $arg} {
            append tmp(chg) "+v"
            lappend tmp(arg) "$arg"
        }
    }
}
proc check_b {sgn arg chan} {
    global temp N
    upvar tmp tmp
    if {$sgn == "+"} {
        if {[haveflag [isuser2 $arg] x $chan] || [rmatch $N!$temp(myhost) $arg] || \
        [rmatch $N![string range $temp(myhost) 0 [expr {[string first @ $temp(myhost)] - 1}]]@$temp(myIP) $arg]} {
            append tmp(chg) "-b"
            lappend tmp(arg) "$arg"
            set tmp(test) 1
        }
        if {[haveflags [isuser2 $tmp(init)![host $tmp(init)]] "u m n r"] && $temp(bankick)} {
            foreach nk "$temp(onchannel:$chan)" {
                if {[string match $arg $nk![host $nk]] && ![haveflags [isuser2 $nk![host $nk]] f] && "$nk" != "$N"} {
                    lappend tmp(kick) "$nk"
                }
            }
        }
    }
}
proc check_I {sgn arg chan} {
    upvar tmp tmp
    if {$sgn == "+"} {
        if {[haveflag [isuser2 $arg] b]} {
            append tmp(chg) "-I"
            lappend tmp(arg) "$arg"
            set tmp(test) 1
        }
    }
}
proc check_e {sgn arg chan} {
    upvar tmp tmp
    if {$sgn == "+"} {
        if {[haveflag [isuser2 $arg] b]} {
            append tmp(chg) "-e"
            lappend tmp(arg) "$arg"
            set tmp(test) 1
        }
    }
}
proc check_k {sgn arg chan} {
    upvar tmp tmp
    global temp
    if {![nhavechar [getchannel $chan mode] f]} {
        if {$sgn == "+"} {
            set temp(ckey:$chan) "$arg"
            if {[havechar [getchannel $chan mode] k]} {
                if {[info exists temp(key:$chan)]} {
                    if {"$arg" != "$temp(key:$chan)"} {
                        append tmp(chg) "-k"
                        append tmp(arg) "$arg"
                        set tmp(mode2) "+k $temp(key:$chan)"
                    }
                }
            } else {
                append tmp(chg) "-k"
                append tmp(arg) "$arg"
            }
        } else {
            catch {unset temp(ckey:$chan)}
            if {[havechar [getchannel $chan mode] k]} {
                if {[info exists temp(key:$chan)]} {
                    append tmp(chg) "+k"
                    append tmp(arg) "$temp(key:$chan)"
                }
            }
        }
    }
}
proc check_n {sgn chan} {
    global temp
    upvar tmp tmp
    if {![nhavechar [getchannel $chan mode] f]} {
        if {$sgn == "+"} {
            if {![havechar [getchannel $chan mode] n]} {
                append tmp(chg) "-n"
            }
        } else {
            if {[havechar [getchannel $chan mode] n]} {
                append tmp(chg) "+n"
            }
        }
    }
}
proc check_t {sgn chan} {
    global temp
    upvar tmp tmp
    if {![nhavechar [getchannel $chan mode] f]} {
        if {$sgn == "+"} {
            if {![havechar [getchannel $chan mode] t]} {
                append tmp(chg) "-t"
            }
        } else {
            if {[havechar [getchannel $chan mode] t]} {
                append tmp(chg) "+t"
            }
        }
    }
}
proc check_s {sgn chan} {
    global temp
    upvar tmp tmp
    if {![nhavechar [getchannel $chan mode] f]} {
        if {$sgn == "+"} {
            if {![havechar [getchannel $chan mode] s]} {
                append tmp(chg) "-s"
            }
        } else {
            if {[havechar [getchannel $chan mode] s]} {
                append tmp(chg) "+s"
            }
        }
    }
}
proc check_p {sgn chan} {
    global temp
    upvar tmp tmp
    if {![nhavechar [getchannel $chan mode] f]} {
        if {$sgn == "+"} {
            if {![havechar [getchannel $chan mode] p]} {
                append tmp(chg) "-p"
            }
        } else {
            if {[havechar [getchannel $chan mode] p]} {
                append tmp(chg) "+p"
            }
        }
    }
}
proc check_m {sgn chan} {
    global temp
    upvar tmp tmp
    if {![nhavechar [getchannel $chan mode] f]} {
        if {$sgn == "+"} {
            if {![havechar [getchannel $chan mode] m]} {
                append tmp(chg) "-m"
            }
        } else {
            if {[havechar [getchannel $chan mode] m]} {
                append tmp(chg) "+m"
            }
        }
    }
}
proc check_l {sgn arg chan} {
    global temp
    upvar tmp tmp
    if {![nhavechar [getchannel $chan mode] f]} {
        if {$sgn == "+"} {
            set temp(climit:$chan) "$arg"
            if {![havechar [getchannel $chan mode] l]} {
                append tmp(chg) "-l"
            }
        } else {
            unset temp(climit:$chan)
            if {[havechar [getchannel $chan mode] l]} {
                global temp
                append tmp(chg) "+l"
                append tmp(arg) "[expr {$temp(users:$chan) + 5}]"
            }
        }
    }
}
proc check_i {sgn chan} {
    global temp
    upvar tmp tmp
    if {![nhavechar [getchannel $chan mode] f]} {
        if {$sgn == "+"} {
            if {![havechar [getchannel $chan mode] i]} {
                append tmp(chg) "-i"
            }
        } else {
            if {[havechar [getchannel $chan mode] i]} {
                append tmp(chg) "+i"
            }
        }
    }
}
proc onMode {chan} {
    global temp N
    upvar tmp tmp
    if {[info exists tmp(getop:$chan)]} {
        set OPS [getchannel $chan ops]
        set BOTS [getchannel $chan bots]
        set NONOPS ""
        foreach n $BOTS {
            if {[lsearch "$OPS" $n] == -1} {
                lappend NONOPS $n
            }
        }
        set ops [lsort -command {string compare} $tmp(getop:$chan:list)]
        set nonops [lsort -command {string compare} $NONOPS]
        set Iam [lsearch $ops $N]
        set myliststart [expr {$Iam * 3}]
        botop $chan [lrange $nonops $myliststart [expr {$myliststart + 2}]]
    }
    if {![haveflag [isuser2 $tmp(init)![host $tmp(init)]] q $chan] && "$tmp(init)" != "$N"} {
            if {$tmp(test) && ![haveflag [isuser2 $tmp(init)![host $tmp(init)]] f $chan] && [string first . $tmp(init)] == -1 && [string first : $tmp(init)] == -1} {
                lappend tmp(kick) $tmp(init)
            }
            if {[llength $tmp(kick)]} {
                mkick $chan $tmp(kick)
            }
            if {"$tmp(chg)" != ""} {
                mode $chan $tmp(chg) $tmp(arg)
            }
            if {[info exists tmp(mode2)]} {
                mode $chan [lindex $tmp(mode2) 0] [lindex $tmp(mode2) 1]
            }
    } elseif {[havechar [getchannel $chan mode] F] && [haveflags [isuser2 $tmp(init)![host $tmp(init)]] "r m n"]} {
        set virt "[strip $temp(chanflags_real) [getchannel $chan mode]]"
        set temp(chanmode:$chan) [sort $temp(mode:$chan)$virt]
        if {[info exists temp(ckey:$chan)]} {
            set temp(key:$chan) $temp(ckey:$chan)
        } else {
            catch {unset temp(key:$chan)}
        }
    }
}

