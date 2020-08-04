proc on {match cmd {osnum {0}}} {
    getglob
    if {![info exists onswitch($osnum)]} {
        set onswitch($osnum) ""
    }
    if {"$match" == "-"} {
        set i 0
        set cmd [eval concat $cmd]
        while {[lindex $onswitch($osnum) $i] != ""} {
            if {[lindex $onswitch($osnum) $i] == $cmd} {
                set ii $i
                incr i
                break
            }
            incr i
        }
        if {[info exists ii]} {
            set onswitch($osnum) [lreplace $onswitch($osnum) $ii $i]
        }
    } else {
        set patt "^[string map {? . * .* % \\S+ %% % \? ?} $match]$"
        set onswitch($osnum) "
            $onswitch($osnum)
            {$patt} {
                $cmd
            }
        "
    }
}
#proc ON {type cmd {osnum {}}} {
#    switch -- [string tolower $type] {
#        action {
#        }
#        channel_nick {
#        }
#        channel_signoff {
#        }
#        channel_sync {
#        }
#        ctcp {
#        }
#        ctcp_reply {
#        }
#        
#        join {
#        }
#        part {
#        }
#    }
#}
proc alias {name cmd {rights {u}}} {
    global cmdswitch cmdlist temp
    lappend cmdlist $name
    if {[llength $cmd] == 1} {
        set i 0
        set args cmd
        while {[lindex $cmdswitch $i] != ""} {
            if {[lindex $cmdswitch $i] == $cmd} {
                incr i
                break
            }
            incr i
        }
        set cmdswitch "
            $cmdswitch
            $name {
                [lindex $cmdswitch $i]
            }
        "
    } else {
        set cmdswitch "
            $cmdswitch
            $name {
                $cmd
            }
        "
    }
    lappend temp($rights-cmds) "$name"
}
proc lremove {list index} {
    return [lreplace $list $index $index]
}
proc lreverse {list} {
    set list2 ""
    foreach word "$list" {
        set list2 "[linsert $list2 0 $word]"
    }
    return "$list2"
}
proc rand args {
    switch -exact -- [llength $args] {
        0 {
            set lower 0
            set upper 2
        }
        1 {
            set lower 0
            set upper $args
        }
        2 {
            set lower [lindex $args 0]
            set upper [lindex $args 1]
        }
        default {
            error {wrong # args: rand ??minimum? maximum?}
        }
    }
    expr { int((rand() * ($upper - $lower)) + $lower) }
}

global randchars
set randchars "abcdefghijklmnopqrstuvwxyz1234567890"
proc randcrap {length {sw {0}}} {
    global randchars
    set crap ""
    if {$sw} {
        while {$length > 0} {
            append crap [binary format c* [rand 255]]
            incr length -1
        }
    } else {
        while {$length > 0} {
            append crap [string index $randchars [rand 36]]
            incr length -1
        }
    }
    return $crap
}
proc sort {args} {
    switch [llength $args] {
        0 {
            error "wrong # args: sort ?options? string"
        }
        1 {
            set str [lindex $args 0]
        }
        2 {
            set str [lindex $args end]
            set opts [lrange $args 0 end-1]
        }
    }
    if {[info exists opts]} {
        return "[sjoin [eval lsort $opts \"[split $str {}]\"] {}]"
    } else {
        return "[sjoin [lsort [split $str {}]] {}]"
    }
}
proc center {cnt str} {
    set lgt [string length $str]
    if {$lgt >= $cnt} {
        return [string range $str 0 $cnt]
    } else {
        set spcs [expr {$cnt - $lgt}]
        set spcs [expr $spcs.0 / 2]
        if {[string index $spcs 2] == 5} {
            set lsp [string index $spcs 0]
            set rsp [expr {[string index $spcs 0] + 1}]
        } else {
            set lsp [string index $spcs 0]
            set rsp [string index $spcs 0]
        }
        return "[string repeat \  $lsp]$str[string repeat \  $rsp]"
    }
}
proc pad {cnt char str} {
    set lgt [string length $str]
    if {$lgt < $cnt} {
        set addlgt [expr {$cnt - $lgt}]
        append str [string repeat $char $addlgt]
        return $str
    } else {
        return $str
    }
}
proc rpad {cnt char str} {
    set lgt [string length $str]
    if {$lgt < $cnt} {
        set addlgt [expr {$cnt - $lgt}]
        set str "[string repeat $char $addlgt]$str"
        return $str
    } else {
        return $str
    }
}
proc strip {chars str} {
    set str2 ""
    for {set s 0} {[string index $str $s] != ""} {incr s} {
        if {![havechar $chars [string index $str $s]]} {
            append str2 [string index $str $s]
        }
    }
    return $str2
}
proc ASCIIfilter {string} {
    set str2 ""
    for {set s 0} {[string index $string $s] != ""} {incr s} {
        if {[string is ascii [string index $string $s]]} {
            append str2 [string index $string $s]
        }
    }
    return $str2
}
proc ALNUMfilter {string {space {0}}} {
    set str2 ""
    if {$space} {
        for {set s 0} {[string index $string $s] != ""} {incr s} {
            if {[string is alnum [string index $string $s]] || "[string index $string $s]" == " "} {
                append str2 [string index $string $s]
            }
        }
    } else {
        for {set s 0} {[string index $string $s] != ""} {incr s} {
            if {[string is alnum [string index $string $s]]} {
                append str2 [string index $string $s]
            }
        }
    }
    return $str2
}
proc safecode {string {code {+}} {type {0}}} {
    if {$type} {
        if {"$code" == "+"} {
            return "[string map {\{ \001\001 \} \001\002} $string]"
        } else {
            return "[string map {\001\001 \{ \001\002 \}} $string]"
        }
    } else {
        if {"$code" == "+"} {
            return "[string map {\" \001\003} $string]"
        } else {
            return "[string map {\001\003 \"} $string]"
        }
    }
}
proc match {list patt} {
    set matched 0
    foreach pt "$list" {
        if {[string match -nocase $patt $pt] || [string match -nocase $pt $patt]} {
            set matched 1
        }
    }
    return $matched
}
proc lmatch {list patt} {
    set matched [lsearch -glob $list $patt]
    incr matched
    return $matched
}
proc rmatch {patts word} {
    set matched 0
    foreach pt "$patts" {
        if {[string match -nocase $pt $word]} {
            set matched 1
        }
    }
    return $matched
}
proc pattern {list patt} {
    set matched "[lsearch -all -inline -glob $list $patt]"
    return $matched
}
proc rpattern {patts word} {
    foreach p "$patts" {
        lappend matched "[lsearch -inline -glob $word $p]"
    }
    return $matched
}
proc npattern {list patt} {
    set matched "[lsearch -all -inline -glob -not $list $patt]"
    return $matched
}
proc rnpattern {patts word} {
    foreach p "$patts" {
        lappend matched "[lsearch -inline -glob -not $word $p]"
    }
    return $matched
}
proc nhavechar {string char} {
    set ch 0
    set string "[string tolower $string]"
    set char "[string tolower $char]"
    if {[string first $char "$string"] > -1} {
        set ch 1
    }
    return $ch
}
proc havechar {string char} {
    set ch 0
    if {[string first $char "$string"] > -1} {
        set ch 1
    }
    return $ch
}
proc nhavechars {string chars} {
    set ch 0
    set string "[string tolower $string]"
    set chars "[string tolower $chars]"
    foreach char "$chars" {
        if {[string first $char "$string"] > -1} {
            set ch 1
            break
        }
    }
    return $ch
}
proc havechars {string chars} {
    set ch 0
    foreach char "$chars" {
        if {[string first $char "$string"] > -1} {
            set ch 1
            break
        }
    }
    return $ch
}
proc nahavechars {string chars} {
    set ch 1
    set string "[string tolower $string]"
    set chars "[string tolower $chars]"
    foreach char "$chars" {
        if {[string first $char "$string"] > -1} {
            set ch 0
            break
        }
    }
    return $ch
}
proc ahavechars {string chars} {
    set ch 1
    foreach char "$chars" {
        if {[string first $char "$string"] > -1} {
            set ch 0
            break
        }
    }
    return $ch
}
proc is {varname} {
    uplevel "
        return \[info exists $varname\]
    "
}
proc syntax {who args} {
    global temp trans
    set args [string map {\{ "" \} ""} $args]
    set cmd "[lindex $args 0]"
    set Args "[string map {\{ "" \} ""} [lrange $args 1 end]]"
    set str [string map {\\ ""} [string map {< %K<%w > %K> [ %K[%w ] %K]%w} $Args]]
    fcputs "%K\[%B*%K\] %c[ts {Syntax is:}] %W$cmd %w$str" 1 $temp(sock:$who)
}
proc mecho {who arg {full {}}} {
    global temp
    if {"[isuser3 $who]" != "" || "$who" == "CONSOLE"} {
        set args [string map {\{ "" \} ""} $arg]
        if {"$full" != ""} {
            cputs "%K\[%bG%K\] $arg" [expr {[haveflag $who A] && ![info exists temp(dcctype:$temp(sock:$who))]}] $temp(sock:$who)
        } else {
            fcputs "%K\[%bG%K\] $arg" [expr {[haveflag $who A] && ![info exists temp(dcctype:$temp(sock:$who))]}] $temp(sock:$who)
        }
    }
}
proc lecho {args} {
    global temp
    set args [string map {\{ "" \} ""} $args]
    foreach user "$temp(loggedon)" {
        fcputs "%K\[%bG%K\] $args" [expr {[haveflag $user A] && ![info exists temp(dcctype:$temp(sock:$user))]}] $temp(sock:$user)
    }
}
proc echo {args} {
    global temp
    set args2 [string map {\{ "" \} ""} $args]
    foreach user "$temp(loggedon)" {
        fcputs "%K\[%bG%K\] $args2" [expr {[haveflag $user A] && ![info exists temp(dcctype:$temp(sock:$user))]}] $temp(sock:$user)
    }
    bots2 "lecho $args"
}
proc botspeak {} {
    global temp
    return "%K%%%C$temp(botname)%K%%"
}
proc quote {cmd} {
    global temp
    if {"$temp(serversock)" != "" && "[fconfigure $temp(serversock) -error]" == ""} {
#        catch {puts $temp(serversock) "[string map {\101 \{ \102 \} \103 \[ \104 \] \105 \"} $cmd]"}
        catch {puts $temp(serversock) $cmd}
        if {[info exists temp(enable_sockspy)]} {
            lecho "%c\[SockSpy output\]: %w$cmd"
        }
    }
}
proc bot {bot cmd {without {}}} {
    global temp
    if {"$without" != ""} {
        foreach b "$temp(botsonline)" {
            if {"$b" != "$without"} {
                puts $temp(sock:$bot) "rdo $bot $cmd"
            }
        }
    } else {
        foreach b "$temp(botsonline)" {
            puts $temp(sock:$bot) "rdo $bot $cmd"
        }
    }
}
proc bot2 {bot cmd {without {}}} {
    global temp
    if {"$without" != ""} {
        foreach b "$temp(botsonline)" {
            if {"$b" != "$without"} {
                puts $temp(sock:$b) "rdo2 $bot $cmd"
            }
        }
    } else {
        foreach b "$temp(botsonline)" {
            puts $temp(sock:$b) "rdo2 $bot $cmd"
        }
    }
}
proc nickchar {nick chan} {
    global temp
    if {"$nick" != "" && "$chan" != ""} {
        if {[havechar $temp(chars:$chan:$nick) *]} {
            return *
        } elseif {[havechar $temp(chars:$chan:$nick) @]} {
            return @
        } elseif {[havechar $temp(chars:$chan:$nick) +]} {
            return +
        } else {
            return " "
        }
    } else {
        return " "
    }
}
proc amon {chan} {
    global temp
    if {[info exists temp(mychans)]} {
        if {[lsearch $temp(mychans) $chan] == -1} {
            return 0
        } else {
            return 1
        }
    } else {
        return 0
    }
}
proc ison {who chan} {
    global temp
    if {[amon $chan]} {
        if {[lsearch -glob "$temp(onchannel:$chan)" $who] > -1} {
            return 1
        } else {
            return 0
        }
    } else {
        return 0
    }
}
proc isop {who chan} {
    global temp N N
    set is 0
    
    if {[ison $who $chan]} {
        if {![info exists temp(chars:$chan:$who)]} {
            set temp(chars:$chan:$who) ""
        }
        if {![info exists temp(am_restricted)] && "$who" == "$N"} {
            if {[string first @ $temp(chars:$chan:$who)] > -1} {
                set is 1
            }
        } else {        
            if {[string first @ $temp(chars:$chan:$who)] > -1} {
                set is 1
            }
        }
    }
    return $is
}
proc ishop {who chan} {
    global temp
    set is 0
    if {[ison $who $chan]} {
        if {![info exists temp(chars:$chan:$who)]} {
            set temp(chars:$chan:$who) ""
        }
        if {[string first % $temp(chars:$chan:$who)] > -1} {
            set is 1
        }
    }
    return $is
}
proc isvop {who chan} {
    global temp
    set is 0
    if {[ison $who $chan]} {
        if {![info exists temp(chars:$chan:$who)]} {
            set temp(chars:$chan:$who) ""
        }
        if {[string first + $temp(chars:$chan:$who)] > -1} {
            set is 1
        }
    }
    return $is
}
proc amconn {} {
    global temp
    return $temp(connected)
}
proc getglob {} {
    uplevel {
        global globals
        eval global $globals
    }
}
proc host {nick} {
    global temp
    if {[info exists temp(host:$nick)]} {
        return "$temp(host:$nick)"
    } else {
        global switch vw
        set ret ""
        set switch(userhost:$nick:isuser1) "
            set vw(userhost:$nick) \"\$1@\$2\"
        "
        quote "USERHOST $nick"
        after 10000 "if {!\[info exists vw(userhost:$nick)\]} {set vw(userhost:$nick) *@*}"
        vwait vw(userhost:$nick)
        set ret $vw(userhost:$nick)
        return $ret
    }
}
proc Host {nick} {
    global temp
    if {[info exists temp(host:$nick)]} {
        return "$temp(host:$nick)"
    } else {
        return "*@*"
    }
}
proc isknown {nick} {
    global temp
    if {[info exists temp(host:$nick)]} {
        return 1
    } else {
        return 0
    }
}
proc mask {host {type {0}}} {
    if {[string first @ $host] > -1 && [string first ! $host] > -1} {
        switch -- $type {
            0 {
                return "*[string range "$host" [string first ! $host] end]"
            }
            1 {
                return "*!*[string range "$host" [expr {[string first ! $host] + 2}] end]"
            }
            2 {
                return "[string range $host 0 [string first ! $host]]*[string range "$host" [string first @ $host] end]"
            }
            3 {
                return "*!*[string range "$host" [string first @ $host] end]"
            }
            4 {
                return "*[string range "$host" [string first ! $host] [string first @ $host]]*[string range $host [string first . $host] end]"
            }
            5 {
                return "*!*[string range "$host" [expr {[string first ! $host] + 2}] [string first @ $host]]*[string range $host [string first . $host] end]"
            }
            6 {
                return "[string range $host 0 [string first ! $host]]*@*[string range "$host" [string first . $host] end]"
            }
            7 {
                return "*!*@*[string range "$host" [string first . $host] end]"
            }
            nick {
                return "[string range $host 0 [expr {[string first ! $host] - 1}]]"
            }
            user {
                return "[string range $host [expr {[string first ! $host] + 1}] [expr {[string first @ $host] - 1}]]"
            }
            host {
                return "[string range $host [expr {[string first @ $host] + 1}] end]"
            }
            default {
                return ""
            }
        }
    } else {
        return ""
    }
}
proc ischan {str} {
    if {[lsearch {# & !} [string index $str 0]] > -1} {
        return 1
    } else {
        return 0
    }
}
proc users {chan {flag {}}} {
    global temp
    foreach u "$temp(onchannel:$chan)" {
        if {[havechar $temp(chars:$u:$chan) $flag]} {
            lappend toret "$u"
        }
    }
    return $toret
}
proc isuser1 {nick} {
    global switch vw
    set ret ""
    set switch(userhost:$nick:isuser1) "
        set vw(isuser1:$nick) \[isuser2 \$0!\$1@\$2\]
    "
    quote "USERHOST $nick"
    vwait vw(isuser1:$nick)
    set ret $vw(isuser1:$nick)
    unset vw(isuser1:$nick)
    return $ret
}
proc isuser2 {host {type {}}} {
    if {[string first ! $host] > -1 && [string first @ $host] > -1} {
        set ret ""
        if {[llength $type] == 0} {
            global userlist botlist userhost
            foreach nick "$userlist $botlist" {
                if {[rmatch $userhost($nick) [strip * $host]] || [match [strip * $userhost($nick)] $host]} {
                    set ret "$nick"
                    break
                }
            }
        } elseif {"$type" == "bot"} {
            global botlist userhost
            foreach nick "$botlist" {
                if {[rmatch $userhost($nick) [strip * $host]] || [match [strip * $userhost($nick)] $host]} {
                    set ret "$nick"
                    break
                }
            }
        } else {
            global userlist userhost
            foreach nick "$userlist" {
                if {[rmatch $userhost($nick) [strip * $host]] || [match [strip * $userhost($nick)] $host]} {
                    set ret "$nick"
                    break
                }
            }
        }
        return $ret
    } else {
        error "$host should be valid IRC hostmask. It has to contain '!' and '@'."
    }
}
proc isuser3 {user {type {}}} {
    global userlist botlist
    if {"$type" == "bot"} {
        set us "[lsearch -inline $botlist $user]"
    } elseif {"$type" == "user"} {
        set us "[lsearch -inline $userlist $user]"
    } else {
        set us "[lsearch -inline [eval list $userlist $botlist] $user]"
    }
    if {"$us" != ""} {
        return $us
    } else {
        return ""
    }
}
proc haveflag {user flag {chan {}}} {
    global flags
    set ret 0
    if {[havechar $flags($user) $flag]} {
        set ret 1
    } else {
        if {"$chan" != ""} {
            if {[info exists flags($user:$chan)]} {
                if {[havechar $flags($user:$chan) $flag]} {
                    set ret 1
                }
            }
        }
    }
    return $ret
}
proc haveflags {user flgs {chan {}}} {
    global flags
    set ret 0
    if {[havechars $flags($user) $flgs]} {
        set ret 1
    } else {
        if {"$chan" != ""} {
            if {[info exists flags($user:$chan)]} {
                if {[havechars $flags($user:$chan) $flgs]} {
                    set ret 1
                }
            }
        }
    }
    return $ret
}
proc ahaveflags {user flags {chan {}}} {
    set ret 1
    foreach f "$flags" {
        if {![haveflag $user $f $chan]} {
            set ret 0
        }
    }
    return $ret
}
proc bhaveflag {bot flag {chan {}}} {
    global botflags
    set ret 0
    if {[havechar $botflags($bot) $flag]} {
        set ret 1
    }
    return $ret
}
proc bhaveflags {bot flags {chan {}}} {
    global botflags
    set ret 0
    if {[havechars $botflags($bot) $flags]} {
        set ret 1
    }
    return $ret
}
proc xbhaveflags {bot flags {chan {}}} {
    set ret 1
    foreach f "$flags" {
        if {![bhaveflag $bot $f]} {
            set ret 0
        }
    }
    return $ret
}
proc bestflag {user} {
    global flags
    set fg ""
    foreach flag "u m n r" {
        if {[string first $flag $flags($user)] > -1} {
            set fg "$flag"
        }
    }
    return $fg
}
proc jot {cnt1 cnt2} {
    for {set i $cnt1} {$i <= $cnt2} {incr i} {
        lappend ret "$i"
    }
    return "$ret"
}
proc ascii {action string} {
    if {"$action" == "encode"} {
        binary scan $string c* res
        return $res
    } elseif {"$action" == "decode"} {
        return [binary format c* $string]
    } else {
        return ""
    }
}
proc foreach2 {var array patt code} {
    uplevel "
        foreach $var \"\[lsort -dictionary \[array names $array $patt\]\]\" {
            $code
        }
    "
}
proc fec {var string code} {
    uplevel "
        for {set fec 0} {\"\[string index $string \$fec\]\" != \"\"} {incr fec} {
            set $var \"\[string index $string \$fec\]\"
            $code
        }
    "
}
proc bots {cmd {without {}}} {
    global temp
    if {"$without" != ""} {
        foreach bot "$temp(botsonline)" {
            if {"$bot" != "$without"} {
                puts $temp(sock:$bot) "netdo $cmd"
            }
        }
    } else {
        foreach bot "$temp(botsonline)" {
            puts $temp(sock:$bot) "netdo $cmd"
        }
    }
}
proc bots2 {cmd {without {}}} {
    global temp
    if {"$without" != ""} {
        foreach bot "$temp(botsonline)" {
            if {"$bot" != "$without"} {
                puts $temp(sock:$bot) "netdo2 $cmd"
            }
        }
    } else {
        foreach bot "$temp(botsonline)" {
            puts $temp(sock:$bot) "netdo2 $cmd"
        }
    }
}
proc Bots {cmd {without {}}} {
    global temp
    if {"$without" != ""} {
        foreach bot "$temp(botsonline)" {
            if {"$bot" != "$without"} {
                puts $temp(sock:$bot) "rdo $bot $cmd"
            }
        }
    } else {
        foreach bot "$temp(botsonline)" {
            puts $temp(sock:$bot) "rdo $bot $cmd"
        }
    }
}
proc Bots2 {cmd {without {}}} {
    global temp
    if {"$without" != ""} {
        foreach bot "$temp(botsonline)" {
            if {"$bot" != "$without"} {
                puts $temp(sock:$bot) "rdo2 $bot $cmd"
            }
        }
    } else {
        foreach bot "$temp(botsonline)" {
            puts $temp(sock:$bot) "rdo2 $bot $cmd"
        }
    }
}
proc islink {bot} {
    global temp
    if {[lsearch "$temp(botsonline)" $bot] > -1} {
        return 1
    } else {
        return 0
    }
}
proc isuser {user} {
    global userlist
    if {[lsearch "$userlist" $bot] > -1} {
        return 1
    } else {
        return 0
    }
}
proc isbot {bot} {
    global botlist
    if {[lsearch "$botlist" $bot] > -1} {
        return 1
    } else {
        return 0
    }
}
proc getword {var} {
    upvar $var $var
    global temp
    if {[info exists $var]} {
        if {![info exists temp($var:lcnt)]} {
            set temp($var:lcnt) 0
        }
        if {[eval lindex "$$var" $temp($var:lcnt)] != ""} {
            set ret [eval lindex "$$var" $temp($var:lcnt)]
        } else {
            set temp($var:lcnt) 0
            set ret [eval lindex "$$var" $temp($var:lcnt)]
        }
        incr temp($var:lcnt)
        return "$ret"
    } else {
        return ""
    }
}
proc getword2 {var} {
    upvar $var $var
    global temp
    if {[info exists $var]} {
        if {![info exists temp($var:lcnt)]} {
            set temp($var:lcnt) 0
        }
        if {[eval lindex "$$var" $temp($var:lcnt)] != ""} {
            set ret [eval lindex "$$var" $temp($var:lcnt)]
        } else {
            set temp($var:cnt) -1
            set ret ""
        }
        incr temp($var:lcnt)
        return "$ret"
    } else {
        return ""
    }
}
proc crypt {key string} {
    return [::md5pure::hmac "$key" "$string"]
}
proc encode {pass key} {
    global temp
    set enckey [ascii encode $key]
    set pass2 [ascii encode $pass]
    foreach cnt "$pass2" {
        lappend encodedpass "[expr {$cnt + [getword enckey]}]"
    }
    unset temp(enckey:lcnt); # Clears craps left from getword
    return $encodedpass
}
proc decode {pass key} {
    global temp
    set enckey [ascii encode $key]
    foreach cnt "$pass" {
        lappend decodedpass "[expr {$cnt - [getword enckey]}]"
    }
    unset temp(enckey:lcnt); # Clears craps left from getword
    return [ascii decode $decodedpass]
}
proc encodepass {pass} {
    global temp
    return [encode $pass $temp(netpass)]
}
proc decodepass {pass} {
    global temp
    return [decode $pass $temp(netpass)]
}
proc isBotNet {} {
    global temp
    if {[llength "$temp(botsonline)"] > 0} {
        return 1
    } else {
        return 0
    }
}
proc isLoggedOn {user} {
    global temp
    if {[lsearch "$temp(loggedon)" $user] > -1} {
        return 1
    } else {
        return 0
    }
}
proc require {script} {
    global temp
    if {"[file extension $script]" != ".tcl"} {
        append script .tcl
    }
    if {[lsearch "$temp(scripts)" $script] == -1} {
        if {[file readable [file join scripts $script]]} {
            lappend temp(scripts) "$script"
            source [file join scripts $script]
        } else {
            puts "[ts {Can't load script %0. It's required by %1 script.} $script $scriptfile]"
        }
    }
}
proc convTime {s} {
    set m 0
    set h 0
    set d 0
    while {$s > 59} {
        incr s -60
        incr m
    }
    while {$m > 59} {
        incr m -60
        incr h
    }
    while {$h > 23} {
        incr h -24
        incr d
    }
    if {$d} {
        append ans "$d\d "
    }
    if {$h} {
        append ans "$h\h "
    }
    if {$m} {
        append ans "$m\m "
    }
    append ans "$s\s"
}
proc reconvTime {s} {
    set secs [string range [pattern $s *s] 0 end-1]
    set mins [string range [pattern $s *m] 0 end-1]
    set hours [string range [pattern $s *h] 0 end-1]
    set days [string range [pattern $s *d] 0 end-1]
    if {"$mins" != ""} {
        set mins [expr {$mins * 60}]
    }
    if {"$hours" != ""} {
        set hours [expr {$hours * 3600}]
    }
    if {"$days" != ""} {
        set days [expr {$days * 86400}]
    }
    set time 0
    foreach t "secs mins hours days" {
        if {"[set $t]" != ""} {
            incr time [set $t]
        }
    }
    return $time
}
proc lib {file} {
    global temp
    if {"[file extension $file]" != ".tcl"} {
        append file .tcl
    }
    if {[lsearch "$temp(libs)" $file] == -1} {
        if {[file readable [file join lib $file]]} {
            source [file join lib $file]
            lappend temp(libs) "$file"
        } else {
            puts "(!) [ts {Can't read library:}] [file join lib $file]"
        }
    }
}
proc mychan {name} {
    global temp
    if {[lsearch $temp(chanlist) $name] > -1} {
        return 1
    } else {
        return 0
    }
}
proc onExempts {chan cmd} {
    global switch
    set switch($chan:excs) "$cmd"
    mode $chan +e
}
proc onBans {chan cmd} {
    global switch
    set switch($chan:bans) "$cmd"
    mode $chan +b
}
proc onInvites {chan cmd} {
    global switch
    set switch($chan:invs) "$cmd"
    mode $chan +I
}
proc OnExempts {chan cmd} {
    global switch
    set switch($chan:excs) "$cmd"
}
proc OnBans {chan cmd} {
    global switch
    set switch($chan:bans) "$cmd"
}
proc OnInvites {chan cmd} {
    global switch
    set switch($chan:invs) "$cmd"
}
proc ECHO {socket onoff} {
    global temp
    set encoding [fconfigure $socket -encoding]
    fconfigure $socket -encoding binary
    if {"[string tolower $onoff]" == "on"} {
        puts -nonewline $socket "\xFF\xFC\x01"
    } elseif {"[string tolower $onoff]" == "off"} {
        puts -nonewline $socket "\xFF\xFB\x01"
    } else {
        error {wrong # args: should be "ECHO on/off"}
    }
    flush $socket
    fconfigure $socket -encoding $encoding
}
proc debug {data} {
    global temp interactive
    if {$temp(debug) == 2} {
        if {"$interactive" == "yes"} {
            puts $data
        } else {
            set fd [open [file join log $temp(botname) debug.log] a+]
            puts -nonewline $fd "DEBUG: "
            puts $fd $data
            close $fd
        }
    }
}
proc ip_to_int {ip} {
    set ip_list [split $ip .]
    set ip32 0
    foreach xx "$ip_list" {
            set ip32 [expr {[expr {$ip32 << 8}] + $xx}]
    }
    return $ip32
}
proc common {list1 list2 {opt {}}} {
    set list3 ""
    if {"$opt" == ""} {
        foreach el "$list1" {
            if {[lsearch "$list2" $el] > -1} {
                lappend list3 $el
            }
        }
    } else {
        foreach el "$list1" {
            if {[eval lsearch $opt {$list2} $el] > -1} {
                lappend list3 $el
            }
        }
    }
    return $list3
}
proc ncommon {list1 list2 {opt {}}} {
    set list3 ""
    if {"$opt" == ""} {
        foreach el "$list1" {
            if {[lsearch "$list2" $el] == -1} {
                lappend list3 $el
            }
        }
        foreach el "$list2" {
            if {[lsearch "$list1" $el] == -1} {
                lappend list3 $el
            }
        }
    } else {
        foreach el "$list1" {
            if {[eval lsearch $opt {$list2} $el] == -1} {
                lappend list3 $el
            }
        }
        foreach el "$list2" {
            if {[eval lsearch $opt {$list1} $el] == -1} {
                lappend list3 $el
            }
        }
    }
    return $list3
}
proc uniq {list} {
    set LIST ""
    foreach l "$list" {
        if {[lsearch $LIST $l] == -1} {
            lappend LIST $l
        }
    }
    return $LIST
}
proc ldelete {listname arg} {
    upvar $listname $listname
    set list [set $listname]
    foreach a "$arg" {
        set idx [lsearch $list $arg]
        set list [lreplace $list $idx $idx]
    }
    set $listname $list
}
proc getuser {user type {info {}}} {
    switch -- [string toupper $type] {
        XTRA {
            global temp
            if {[info exists temp(extra:$type:$user)]} {
                return $temp(extra:$type:$user)
            } else {
                return ""
            }
        }
        BOTFL {
            global flags
            if {[info exists flags($user)]} {
                return $temp($user)
            } else {
                return ""
            }
        }
        FLAGS {
            global flags
            if {[info exists flags($user)]} {
                return $temp($user)
            } else {
                return ""
            }
        }
        CHANFLAGS {
            if {"$info" != ""} {
                global flags
                if {[info exists flags($user)]} {
                    return $temp($user:$info)
                } else {
                    return ""
                }
            } else {
                return ""
            }
        }
        HOSTS {
            global userhost
            if {[info exists userhost($user)]} {
                return $userhost($user)
            } else {
                return ""
            }
        }
        PASS {
            global password
            if {[info exists password($user)]} {
                return $password($user)
            } else {
                return ""
            }
        }
    }
}
proc setuser {user type {info {}}} {
    switch -- [string toupper $type] {
        XTRA {
            global temp
            set temp(extra:$type:$user) $info
        }
        BOTFL {
            global flags
            set temp($user) $info
        }
        FLAGS {
            global flags
            set temp($user) $info
        }
        CHANFLAGS {
            if {"$info" != ""} {
                global flags
                set temp($user:[lindex $info 0]) [lindex $info 1]
            }
        }
        HOSTS {
            global userhost
            set userhost($user) $info
        }
        PASS {
            global password
            set password($user) [::md5pure::hmac $user $info]
        }
    }
}
proc getchannel {channel type} {
    global temp
    switch -- [string toupper $type] {
        KNOWN {
            if {[info exists temp(scanned:$channel)]} {
                return 1
            } else {
                return 0
            }
        }
        NICKS {
            if {[info exists temp(onchannel:$channel)]} {
                return $temp(onchannel:$channel)
            } else {
                return ""
            }
        }
        OPS {
            if {[info exists temp(onchannel:$channel)]} {
                set list ""
                foreach x "$temp(onchannel:$channel)" {
                    if {[isop $x $channel]} {
                        lappend list $x
                    }
                }
                return $list
            } else {
                return ""
            }
        }
        VOPS {
            if {[info exists temp(onchannel:$channel)]} {
                set list ""
                foreach x "$temp(onchannel:$channel)" {
                    if {[isvop $x $channel]} {
                        lappend list $x
                    }
                }
                return $list
            } else {
                return ""
            }
        }
        HOPS {
            if {[info exists temp(onchannel:$channel)]} {
                set list ""
                foreach x "$temp(onchannel:$channel)" {
                    if {[ishop $x $channel]} {
                        lappend list $x
                    }
                }
                return $list
            } else {
                return ""
            }
        }
        BOTS {
            if {[info exists temp(onchannel:$channel)]} {
                set list ""
                foreach x "$temp(onchannel:$channel)" {
                    if {"[isuser2 $x![host $x] bot]" != ""} {
                        lappend list $x
                    }
                }
                return $list
            } else {
                return ""
            }
        }
        USERS {
            if {[info exists temp(onchannel:$channel)]} {
                set list ""
                foreach x "$temp(onchannel:$channel)" {
                    if {"[isuser2 $x![host $x] user]" != ""} {
                        lappend list $x
                    }
                }
                return $list
            } else {
                return ""
            }
        }
        BOTS&USERS {
            if {[info exists temp(onchannel:$channel)]} {
                set list ""
                foreach x "$temp(onchannel:$channel)" {
                    if {"[isuser2 $x![host $x]]" != ""} {
                        lappend list $x
                    }
                }
                return $list
            } else {
                return ""
            }
        }
        CMODE {
            if {[info exists temp(mode:$channel)]} {
                return $temp(mode:$channel)
            } else {
                return ""
            }
        }
        MODE {
            if {[info exists temp(chanmode:$channel)]} {
                return $temp(chanmode:$channel)
            } else {
                return ""
            }
        }
        CKEY {
            if {[info exists temp(ckey:$channel)]} {
                return $temp(ckey:$channel)
            } else {
                return ""
            }
        }
        KEY {
            if {[info exists temp(key:$channel)]} {
                return $temp(key:$channel)
            } else {
                return ""
            }
        }
        LIMIT {
            if {[info exists temp(climit:$channel)]} {
                return $temp(climit:$channel)
            } else {
                return ""
            }
        }
        TOPIC {
            if {[info exists temp(topic:$channel)]} {
                return $temp(topic:$channel)
            } else {
                return ""
            }
        }
    }
}
proc setchannel {channel type {val {}}} {
    switch -- [string toupper $type] {
        TOPIC {
            global N
            if {[isop $N $channel]} {
                topic $channel $val
            }
        }
        KEY {
            if {[mychan $channel] && "$val" != ""} {
                set temp(key:$channel) "$val"
                cmd chanmode $channel +k
            }
        }
        MODE {
            if {[mychan $channel]} {
                set temp(chanmode:$channel) "$val"
            }
        }
    }
}
proc channels {type} {
    switch -- [string toupper $type] {
        REAL {
            return $temp(mychans)
        }
        LIST {
            return $temp(chanlist)
        }
    }
}
proc getbot {bot type} {
    switch -- [string toupper $type] {
        FLASG {
            global botflags
            if {[info exists botflags($bot)]} {
                return $botflags($bot)
            } else {
                return ""
            }
        }
        HOSTS {
            global userhost
            if {[info exists userhost($bot)]} {
                return $userhost($bot)
            } else {
                return ""
            }
        }
        ADDRESS {
            global temp
            if {[info exists temp(botaddress:$bot)]} {
                return $temp(botaddress:$bot)
            } else {
                return ""
            }
        }
        PORT {
            global temp
            if {[info exists temp(botport:$bot)]} {
                return $temp(botport:$bot)
            } else {
                return ""
            }
        }
    }
}
proc setbot {bot type {val {}}} {
    switch -- [string toupper $type] {
        FLASG {
            global botflags
            set botflags($bot) "$val"
        }
        HOSTS {
            global userhost
            set userhost($bot) "$val"
        }
        ADDRESS {
            global temp
            set temp(botaddress:$bot) "$val"
        }
        PORT {
            global temp
            set temp(botport:$bot) "$val"
        }
    }
}
proc getnetpass {} {
    global temp
    return $temp(netpass)
}
proc cmdlist {type} {
    global temp
    return $temp($type-cmds)
}
proc getserver {type} {
    global temp
    switch -- [string toupper $type] {
        LIST {
            return $temp(servlist)
        }
        CURRENT {
            return $temp(server)
        }
        CSOCK {
            return $temp(serversock)
        }
        NICK {
            global N
            return $N
        }
    }
}
proc getconsole {type} {
    global temp
    switch -- [string toupper $type] {
        USERS {
            return $temp(loggedon)
        }
        BOTS {
            return $temp(botsonline)
        }
        UPTIME {
            return $temp(uptime)
        }
        BOTNAME {
            return $temp(botname)
        }
    }
}
proc convCount {cnt} {
    switch -- $cnt {
        1 {
            return ${cnt}st
        }
        2 {
            return ${cnt}nd
        }
        3 {
            return ${cnt}rd
        }
        default {
            return ${cnt}th
        }
    }
}
proc ctrl {char} {
    switch -- $char {
        a {
            return \001
        }
        b {
            return \002
        }
        c {
            return \003
        }
        g {
            return \007
        }
        i {
            return \009
        }
        u {
            return \021
        }
        deafult {
            return ""
        }
    }
}
proc scriptname {} {
    return [file tail [info script]]
}
proc botsonchan {chan} {
    set ret ""
    foreach n [getchannel $chan nicks] {
        if {[isuser2 [host $n] bot]} {
            lappend ret $n
        }
    }
    return $ret
}
proc uptime {} {
    global temp
    return $temp(uptime)
}
proc me {} {
    global N
    return $N
}
proc shellIdo {chan {sw {}}} {
    global N
    set ops [lsort -command {string compare} "[common [getchannel $chan bots] [getchannel $chan ops]] $N"]
    if {$sw == "-which"} {
        return [lsearch $ops $N]
    } else {
        if {[lsearch $ops $N] == 0} {
            return 1
        } else {
            return 0
        }
    }
}
proc k {mode} {
    set mode [string map {white 0 black 1 darkblue 2 darkgreen 3 red 4 darkred 5 brown 5 darkpink 6 darkmagenta 6 darkyellow 7 orange 7 \
yellow 8 green 9 darkcyan 10 cyan 11 blue 12 pink 13 magenta 13 lightblack 14 darkgrey 14  lightgrey 15 darkwhite 15} $mode]
    return "[format %c 3]$mode"
}
proc / {args} {
    return
}
