proc setDefVals {} {
    global CF CF2
    set CF(botname) "giana"
    set CF(uport) "7777"
    set CF(bport) "7778"
    set CF(loginstring) "Login:"
    set CF(passstring) "Password:"
    set CF(nick) ""
    set CF(othernicks) ""
    set CF(netflag) "2"
    set CF(netpass) "nopass"
    set CF(pubchar) "!"
    set CF(bankick) "ON"
    set CF(dumpcmd) "ON"
    set CF2(scripts) ""
    set CF2(servers) ""
}
proc setDefValsOptional {} {
    global CF env trans temp
    set CF(checktime) "80"
    set CF(logo) "logo1.txt"
    set CF(kickreason) "?"
    set CF(public:sensor) "ON"
    set CF(nick:sensor) "ON"
    set CF(join:sensor) "ON"
    set CF(pubflood_sensor) 8
    set CF(nickflood_sensor) 2
    set CF(joinflood_sensor) 2
    set CF(vhost) "[info hostname]"
    set CF(makelog) "ON"
    set CF(nickchar) .
    set CF(loadhelp) "YES"
    set CF(username) $env(USER)
    set CF(server_op_protect) "ON"
    set CF(logmode) "giana"
    set CF(locale) "$temp(locale)"
    set CF(encoding) "iso8859-1"
}
proc getConfData {} {
    global CF CF2
    set cr 1
    puts -nonewline "$cr) [ts {Choose name of bot (it's not nickname) [%0]:} $CF(botname)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(botname) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Users port [%0]:} $CF(uport)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(uport) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Bots port [%0]:} $CF(bport)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(bport) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Login question [%0]:} $CF(loginstring)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(loginstring) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Password question [%0]:} $CF(passstring)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(passstring) $tmp
    }
    incr cr
    set CF(nick) "[string totitle $CF(botname)]"
    puts -nonewline "$cr) [ts {Main nickname [%0]:} $CF(nick)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(nick) $tmp
    }
    incr cr
    set CF(othernicks) "[string totitle $CF(botname)]- [string totitle $CF(botname)]` _$CF(botname)_"
    puts -nonewline "$cr) [ts {Secondary nicknames (ex. nick1 nick2 nick3) [%0]:} \"$CF(othernicks)\"] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(othernicks) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Bots network flag status [%0]:} $CF(netflag)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(netflag) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Bots network password [%0]:} $CF(netpass)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(netpass) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Public commands char [%0]:} $CF(pubchar)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(pubchar) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Kick vitcim when friend has set ban (ON/OFF) [%0]:} $CF(bankick)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(bankick) [string toupper $tmp]
    }
    incr cr
    puts -nonewline "$cr) [ts {Allow to execute commands via private and channel messages by dump public command? (ON/OFF) [%0]:} $CF(dumpcmd)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(dumpcmd) [string toupper $tmp]
    }
    incr cr
    set tmp "X"
    puts "[ts {Enter servers names (with optional port - server.name:port). For each name, push an enter. When you finish, just push the enter without any server name.}]"
    while {[llength "$tmp"] > 0} {
        puts -nonewline "$cr) [ts {Server:}] "
        gets stdin tmp
        if {[llength "$tmp"] > 0} {
            lappend CF2(servers) $tmp
        }
    }
    incr cr
    set tmp "X"
    puts "[ts {Similarly do with TCL additional scripts now. There is a list of available scripts below. You can ommit .tcl extension in file name.}]"
    puts "[glob -nocomplain -tails -directory scripts *.tcl]"
    while {[llength "$tmp"] > 0} {
        puts -nonewline "$cr) [ts {Script:}] "
        gets stdin tmp
        if {[llength "$tmp"] > 0} {
            lappend CF2(scripts) $tmp
        }
    }
    incr cr
    puts -nonewline "*** [ts {Do you want to enter optional config values? (n/y) [N]:}] "
    gets stdin tmp
    set tmp [string tolower $tmp]
    if {[lsearch "y n" $tmp] > -1} {
        set yn $tmp
    } else {
        set yn n
    }
    if {"$yn" == "y"} {
        setDefValsOptional
        getConfDataOptional $cr
    }
    puts -nonewline "*** [ts {Would you like to create first user? (n/y) [Y]:}] "
    gets stdin tmp
    set tmp [string tolower $tmp]
    if {[lsearch "y n" $tmp] > -1} {
        set yn $tmp
    } else {
        set yn y
    }
    if {"$yn" == "y"} {
        createFirstUser
    }
}
proc getConfDataOptional {cr} {
    global CF temp
    puts -nonewline "$cr) [ts {Modes checking loop delay [%0]:} $CF(checktime)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(checktime) $tmp
    }
    incr cr
    puts "[ts {List of available logos:}] [glob -nocomplain -tails -directory logos *]"
    puts -nonewline "$cr) [ts {Login logo [%0]:} $CF(logo)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(logo) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Reason for 'kick queue' kicks [%0]:} $CF(kickreason)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(kickreason) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Public messages flood sensor (OFF/ON) [%0]:} $CF(public:sensor)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(public:sensor) [string toupper $tmp]
    }
    if {"$CF(public:sensor)" == "ON"} {
        incr cr
        puts -nonewline "$cr) [ts {Value of this sensor (how many messages per 10 secs are permitted) [%0]:} $CF(pubflood_sensor)] "
        gets stdin tmp
        if {[llength "$tmp"] > 0} {
            set CF(pubflood_sensor) $tmp
        }
    }
    incr cr
    puts -nonewline "$cr) [ts {Nick changing flood sensor (OFF/ON) [%0]:} $CF(nick:sensor)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(nick:sensor) [string toupper $tmp]
    }
    if {"$CF(nick:sensor)" == "ON"} {
        incr cr
        puts -nonewline "$cr) [ts {Value of this sensor (how many changes per 10 secs are permitted) [%0]:} $CF(nickflood_sensor)] "
        gets stdin tmp
        if {[llength "$tmp"] > 0} {
            set CF(nickflood_sensor) $tmp
        }
    }
    incr cr
    puts -nonewline "$cr) [ts {Channel joining flood sensor (OFF/ON) [%0]:} $CF(join:sensor)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(join:sensor) [string toupper $tmp]
    }
    if {"$CF(join:sensor)" == "ON"} {
        incr cr
        puts -nonewline "$cr) [ts {Value of this sensor (how many joins per 10 secs are permitted) [%0]:} $CF(joinflood_sensor)] "
        gets stdin tmp
        if {[llength "$tmp"] > 0} {
            set CF(joinflood_sensor) $tmp
        }
    }
    incr cr
    puts -nonewline "$cr) [ts {Virtual host, which should be used while connecting to server [%0]:} $CF(vhost)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(vhost) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Should bot log all important events? (OFF/ON) [%0]:} $CF(makelog)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(makelog) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Which logging mode use to log from channels? (supported: %1) [%0]:} $CF(logmode) {giana, eggdrop, epic}] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(logmode) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Which char use to pad nicknames in logs up to 9 chars long? (only 'giana' logging mode) [%0]:} $CF(nickchar)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(nickchar) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Shell we load help module? (yes/no) [%0]:} $CF(loadhelp)] "
    gets stdin tmp
    set tmp [string toupper $tmp]
    if {[llength "$tmp"] > 0} {
        set CF(loadhelp) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Username for bot [%0]:} $CF(username)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(username) $tmp
    }
    incr cr
    puts -nonewline "$cr) [ts {Protect from server op mode? (ON/OFF) [%0]:} $CF(server_op_protect)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(server_op_protect) $tmp
    }
    incr cr
    set str [sjoin "en $temp(supported_translations)" ,\ ]
    puts -nonewline "$cr) [ts {Language (%1) [%0]:} $CF(locale) $str] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(locale) $tmp
    }
    incr cr
    puts "-----"
    puts "[ts {SUPPORTED ENCODING SYSTEMS:}] [sjoin [lsort -ascii [encoding names]] ,\ ]"
    puts -nonewline "$cr) [ts {Encoding system [%0]:} $CF(encoding)] "
    gets stdin tmp
    if {[llength "$tmp"] > 0} {
        set CF(locale) [string tolower $tmp]
    }
}
proc createFirstUser {} {
    set name ""
    set pass1 ""
    set pass2 ""
    while {[llength $name] == 0} {
        puts -nonewline "# [ts {Type name for first user:}] "
        gets stdin tmp
        set name $tmp
    }
    while {[llength $pass1] == 0} {
        puts -nonewline "# [ts {Type password:}] "
        gets stdin tmp
        set pass1 $tmp
    }
    while {[llength $pass2] == 0} {
        puts -nonewline "# [ts {Retype password:}] "
        gets stdin tmp
        set pass2 $tmp
    }
    if {"$pass1" == "$pass2"} {
        global CF
        if {![info exists [file join lists $CF(botname)]]} {
            file mkdir [file join lists $CF(botname)]
        } else {
            file delete -force [file join lists $CF(botname) users.list]
        }
        source [file join lib md5pure.tcl]
        set fd [open [file join lists $CF(botname) users.list] w]
        puts $fd "{$name} {[::md5pure::hmac $name $pass1]} {Aafopqrx} {}"
        close $fd
    } else {
        puts "### [ts {Passwords mismatch!}]"
        createFirstUser
    }
}
proc wrConfig {file} {
    global CF CF2
    file delete -force [file join config $file]
    set fd [open [file join config $file] w]
    foreach v "[array names CF]" {
        puts $fd "set $v $CF($v)"
    }
    foreach s "$CF2(servers)" {
        puts $fd "server $s"
    }
    foreach s "$CF2(scripts)" {
        puts $fd "script $s"
    }
    close $fd
}
proc makeConfig {} {
    global CF CF2 temp config_file
    fconfigure stdout -buffering none
    if {[info exists config_file]} {
        setDefVals
        wrConfig $config_file.conf
        puts "[ts {Writting config done...}]"
    } else {
        setDefVals
        getConfData
        wrConfig $CF(botname).conf
        puts "[ts {Writting config done...}]"
    }
}
