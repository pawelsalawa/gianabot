alias +user {
    if {[is 0]} {
        if {"[isuser3 $0]" == ""} {
            lappend userlist "$0"
            set flags($0) ""
            set userhost($0) ""
            set password($0) "[randcrap 10]"
            mecho $_ "[ts {%C%0%c has been added to userlist.} [string totitle $0]]"
            mecho $_ "%c[ts {Change password for %C%0%c by command passwd or chpass.} $0]"
            if {[is 1]} {
                if {[string index $1 0] == "+"} {
                    flags $0 $1
                } else {
                    flags $0 =$1
                }
                if {[is 2]} {
                    cmd +host $0 [lrange $args 2 end]
                }
            } else {
                mecho $_ "%c[ts {Add flags for %C%0%c by command flags.} $0]"
            }
        } else {
            mecho $_ "[ts {%Y%0%y is already in userlist.} [string totitle $0]]"
        }
    } else {
        syntax $_ {+user <user> [<flags> [<host> <host> ...] ]}
    }
} n
alias adduser +user n
alias -user {
    if {[is 0]} {
        if {[isuser3 $0 user] != ""} {
            if {![haveflag $0 !] || "[bestflag $_]" == "r"} {
                mecho $_ "[ts {%C%0%c has been removed form userlist.} $0]"
                unset userhost($0)
                unset flags($0)
                unset password($0)
                foreach2 ar flags $0:* {
                    unset flags($ar)
                }
                set userlist "[npattern $userlist $0]"
            } else {
                mecho $_ "%y[ts {User %Y%0%y is immune (+!).} $0]"
            }
        }
    } else {
        syntax $_ "-user <user>"
    }
} n
alias remuser -user n
alias +host {
    if {[is 1]} {
        if {"[isuser3 $0]" != ""} {
            for {set a 1} {[is $a]} {incr a} {
                eval set c $$a
                if {"[isuser2 $c]" != ""} {
                    mecho $_ "[ts {%Y%0%y matches this mask, so %Y%1%y can't get it.} [string totitle [isuser2 $c]] $0]"
                } else {
                    if {[haveflag $0 !] && [bestflag $_] != "r"} {
                        mecho $_ "%y[ts {User %Y%0%y is immune (+!).} $0]"
                    } else {
                        if {![rmatch $c $userhost($0)]} {
                            lappend userhost($0) "$c"
                            mecho $_ "%c[ts {Host %C%0%c added for %C%1%c.} $c $0]"
                        } else {
                            mecho $_ "%y[ts {This host matches (or is matched by) another host of %Y%0%y.} $0]"
                        }
                    }
                }
            }
        } else {
            mecho $_ "%C[ts {No such user/bot.}]"
        }
    } else {
        syntax $_ {+host <user/bot> <host> [<host> <host> ...]}
    }
} m
alias addhost +host m
alias -host {
    if {[is 1]} {
        if {"[isuser3 $0]" != ""} {
            if {[haveflag $0 !] && [$bestflag $_] != "r"} {
                mecho $_ "%y[ts {User %Y%0%y is immune (+!).} $0]"
            } else {
                if {[match $userhost($0) $1]} {
                    set userhost($0) "[npattern $userhost($0) $1]"
                    set userhost($0) "[eval concat $userhost($0)]"
                    mecho $_ "%c[ts {Hosts matched by %C%0%c removed from %C%1%c.} $1 $0]"
                } else {
                    mecho $_ "[ts {%Y%0%y hasn't got host like this.} [string totitle $0]]"
                }
            }
        } else {
            mecho $_ "%y[ts {No such user/bot.}]"
        }
    } else {
        syntax $_ "-host <user/bot> <mask>"
    }
} m
alias remhost -host m
alias users {
  if {[is 0]} {
        switch -- $0 {
            -f {
                set whofor "flags"
                if {[is 1]} {
                    set whomask "[split $1 \"\"]"
                } else {
                    set whomask "*"
                }
            }
            -h {
                set whofor "host"
                if {[is 1]} {
                    set whomask "$1"
                } else {
                    set whomask "*"
                }
            }
            -n {
                set whofor "nick"
                if {[is 1]} {
                    set whomask "$1"
                } else {
                    set whomask "*"
                }
            }
            default {
                    set whofor "nick"
                    set whomask "$0"
            }
        }
  } else {
        set whofor "nick"
        set whomask "*"
  }
  set userscnt 1
  mecho $_ "%c[ts {~~~~~~~~%CUSER NICK%c~~~~~~~%CGLOBAL FLAGS%c~~~~}]"
  foreach2 usnick password * {
        if {[lmatch $usnick $whomask] && "$whofor" == "nick"} {
                mecho $_ "%c[rpad 3 \  $userscnt]%K> %W[center 20 $usnick] %K+%C$flags($usnick)"
                mecho $_ "     %c%u[ts {LOCAL FLAGS:}]" 1
                foreach2 f flags $usnick:* {
                    mecho $_ "%B       [lindex [split $f :] 1] %K+%C$flags($f)"
                }
                mecho $_ "     %c%u[ts {HOSTS:}]" 1
                foreach uh "$userhost($usnick)" {
                        mecho $_ "%B       $uh"
                }
                incr userscnt
        }
        if {"$whofor" == "host"} {
            if {[lmatch [strip * $userhost($usnick)] $whomask]} {
                mecho $_ "%c[rpad 3 \  $userscnt]%K> %W[center 20 $usnick] %K+%C$flags($usnick)"
                mecho $_ "     %c%u[ts {LOCAL FLAGS:}]" 1
                foreach2 f flags $usnick:* {
                    mecho $_ "%B       [lindex [split $f :] 1] %K+%C$flags($f)"
                }
                mecho $_ "     %c%u[ts {HOSTS:}]" 1
                foreach uh "$userhost($usnick)" {
                        mecho $_ "%B       $uh"
                }
                incr userscnt
            }
        }
        if {"$whofor" == "flags"} {
                if {"$whomask" == "*"} {
                    mecho $_ "%c[rpad 3 \  $userscnt]%K> %W[center 20 $usnick] %K+%C$flags($usnick)"
                    mecho $_ "     %c%u[ts {LOCAL FLAGS:}]" 1
                    foreach2 f flags $usnick:* {
                        mecho $_ "%B       [lindex [split $f :] 1] %K+%C$flags($f)"
                    }
                    mecho $_ "     %c%u[ts {HOSTS:}]" 1
                    foreach uh "$userhost($usnick)" {
                            mecho $_ "%B       $uh"
                    }
                    incr userscnt
                } else {
                        if {[havechars $flags($usnick) $whomask]} {
                            mecho $_ "%c[rpad 3 \  $userscnt]%K> %W[center 20 $usnick] %K+%C$flags($usnick)"
                            mecho $_ "     %c%u[ts {LOCAL FLAGS:}]" 1
                            foreach2 f flags $usnick:* {
                                mecho $_ "%B       [lindex [split $f :] 1] %K+%C$flags($f)"
                            }
                            mecho $_ "     %c%u[ts {HOSTS:}]" 1
                            foreach uh "$userhost($usnick)" {
                                mecho $_ "%B       $uh"
                            }
                            incr userscnt
                        }
                }
        }
  }
  mecho $_ "%c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
} u
alias userlist users
alias chattr {
    flags [lindex $args 0] [lindex $args 1] [lindex $args 2]
} m
alias flags chattr m
alias passwd {
    if {[is 0]} {
        if {[is 1]} {
            if {[lsearch "r n" [bestflag $_]] > -1 || "$_" == "$0"} {
                set password($0) [::md5pure::hmac $0 $1]
                mecho $_ "%c[ts {Password for %C%0%c changed.} $0]"
            } else {
                mecho $_ "%y[ts {You have to be owner if you want to change not your password.}]"
            }
        } else {
            set password($_) [::md5pure::hmac $_ $0]
            mecho $_ "%c[ts {Password for %C%0%c changed.} $_]"
        }
    } else {
        syntax $_ {passwd [<user>] <password>}
    }
}
alias chpass passwd
alias pass chpass
alias addbot {
    if {[is 1]} {
        if {"[isuser3 $0]" == ""} {
            if {"$0" != "$temp(botname)"} {
                lappend botlist "$0"
                set botflags($0) ""
                set flags($0) "ofqxna"
                set temp(botport:$0) [lindex [split $1 :] end]
                set temp(botaddress:$0) [sjoin [lrange [split $1 :] 0 end-1] :]
                set userhost($0) ""
                mecho $_ "[ts {%C%0%c has been added to my botlist} $0] ($1)."
                if {[is 2]} {
                    if {"[string index $2 0]" == "+"} {
                        botattr $0 $2
                    } else {
                        botattr $0 =$2
                    }
                    if {[is 3]} {
                          set userhost($0) "[lrange $args 3 end]"
                          mecho $_ "%c[ts {Hosts added for %C%0%c:} $0] %G[lrange $args 3 end]"
                    }
                } else {
                        mecho $_ "%c[ts {Add flags for %C%0%c by command botattr.} $0]"
                }
            } else {
                mecho $_ "%y[ts {I am}] %Y$0!"
            }
        } else {
            mecho $_ "[ts {%Y%0%y already exists on botlist.}]"
        }
    } else {
        syntax $_ {addbot <bot> <bot address>[:<bots port>[/<users port>]] [<flags> [<host> <host> ...] ]}
    }
} n
alias +bot addbot n
alias rembot {
    if {[is 0]} {
        if {[isuser3 $0 bot] != ""} {
            mecho $_ "[ts {%C%0%c has been removed from botlist.} $0]"
            unset userhost($0)
            unset botflags($0)
            unset temp(botport:$0)
            unset temp(botaddress:$0)
            set botlist "[npattern $botlist $0]"
        }
    } else {
        syntax $_ "rembot <bot nick>"
    }
} n
alias -bot rembot n
alias botport {
    if {[is 0]} {
        if {[is 1]} {
            if {[isuser3 $0 bot] != ""} {
                if {[string is digit $1]} {
                    set temp(botport:$0) "$1"
                    mecho $_ "%c[ts {Port(s) for bot %C%0%c changed to %C%1%c.} $0 $1]"
                } else {
                    mecho $_ "%y[ts {Port should be in number format.}]"
                }
            } else {
                mecho $_ "%y[ts {No such bot}] %Y$0%y."
            }
        } else {
            mecho $_ "%c[ts {Port(s) for bot %C%0%c:} $0] %C$temp(botport:$0)"
        }
    } else {
        syntax $_ {botport <bot> [<new bots port>[/<new users port>]]}
    }
} n
alias botaddress {
    if {[is 0]} {
        if {[is 1]} {
            if {[isuser3 $0 bot]} {
                set temp(botaddress:$0) "$1"
                mecho $_ "%c[ts {Address for bot %C%0%c changed to %C%1%c.} $0 $1]"
            } else {
                mecho $_ "%y[ts {No such bot}] %Y$0%y."
            }
        } else {
            mecho $_ "%C[ts {Address for bot %C%0%c:} $0] $temp(botaddress:$0)"
        }
    } else {
        syntax $_ {botaddress <bot> [<new address>]}
    }
} n
alias netpass botpass
alias botpass {
    if {[is 0]} {
        mecho $_ "%c[ts {Password for botnet has been changed.}]"
        if {"$0" == "rand"} {
            set temp(codekkey) [randcrap 20]
            set temp(netpass) "$codekkey"
        } else {
            set temp(codekkey) "$args"
            set temp(netpass) "$args"
        }
        unset temp(codekey)
        set temp(codekey) "[ascii encode $temp(codekkey)]"
    } else {
        syntax $_ "netpass <new password>"
    }
} n
alias botattr {
    botattr [lindex $args 0] [lindex $args 1]
} n
alias botflags botattr n
alias botlist {
    mecho $_ "%c[ts {Botlist:}]"
    set c 1
    foreach bot "$botlist" {
        mecho $_ "%c$c%K> %W$bot"
        mecho $_ "     %c[ts {Bot flags:}] %K+%C$botflags($bot)"
        mecho $_ "     %c[ts {Address:}] %C$temp(botaddress:$bot)"
        mecho $_ "     %c[ts {Users port:}] %C[lindex [split $temp(botport:$bot) /] 1]"
        mecho $_ "     %c[ts {Bots port:}] %C[lindex [split $temp(botport:$bot) /] 0]"
        mecho $_ "     %c[ts {Hosts:}]"
        foreach bh "$userhost($bot)" {
            mecho $_ "       %B$bh"
        }
        incr c
    }
    mecho $_ "%c~~~~~~~~~~~~~~~~~~~~~~~~~"
} n
alias bots botlist
alias whois {
    if {[is 0]} {
        if {"[isuser3 $0 user]" != ""} {
            mecho $_ "%W.---%Y---%G----%g----%K- --  -"
            mecho $_ "%W| %C%u$0" 1
            mecho $_ "%W| %c[ts {Flags:}] +%C$flags($0)"
            foreach2 cf flags $0:* {
                mecho $_ "%Y| %B[lindex [split $cf :] 1] %c+%C$flags($cf)"
            }
            mecho $_ "%Y| %c[ts {Hosts:}]"
            foreach uh "$userhost($0)" {
                mecho $_ "%G| %C$uh"
            }
            mecho $_ "%G`------%g------%K--- --  -"
            #`
        } elseif {"[isuser3 $0 bot]" != ""} {
            mecho $_ "%W.---%Y---%G----%g----%K- --  -"
            mecho $_ "%W| %C%u$0" 1
            mecho $_ "%W| %c[ts {Bot flags:}] +%C$botflags($0)"
            mecho $_ "%Y| %c[ts {Address:}] %C$temp(botaddress:$0)"
            mecho $_ "%Y| %c[ts {Users port:}] %C[lindex [split $temp(botport:$0) /] 1]"
            mecho $_ "%Y| %c[ts {Bots port:}] %C[lindex [split $temp(botport:$0) /] 0]"
            mecho $_ "%Y| %c[ts {Hosts:}]"
            foreach bh "$userhost($0)" {
                mecho $_ "%G| %C$bh"
            }
            mecho $_ "%G`----%g-------%K---- --  -"
            #`
        } elseif {[lsearch "$temp(chanlist)" $0] > -1} {
            mecho $_ "%W.---%Y---%G----%g----%K- --  -"
            mecho $_ "%W| %C%u$0" 1
            mecho $_ "%W| %c[ts {Constans modes:}] +%C$temp(chanmode:$0)"
            if {[info exists temp(key:$0)]} {
                mecho $_ "%W| %c[ts {Constans key:}] $temp(key:$0)"
            }
            mecho $_ "%Y| %c[ts {Current modes:}] +%C$temp(mode:$0)"
            if {[amon $0]} {
                mecho $_ "%Y| %c[ts {I'm already on this channel.}]"
            } else {
                mecho $_ "%Y| %c[ts {I'm NOT already on this channel.}]"
            }
            mecho $_ "%Y`--%G-----%g------%K-- --  -"
            #`
        } else {
            mecho $_ "%y[ts {No such user, channel or bot.}]"
        }
    } else {
        syntax $_ "whois <user/bot/channel>"
    }
}
alias wi whois
alias cmdlist {
    if {[is 0]} {
        if {"$0" == "-all" || "$0" == "-a"} {
            mecho $_ "%c[ts {~~~%COWNERS COMMANDS%c~~~~}]"
            foreach {c1 c2 c3 c4 c5} "$temp(n-cmds)" {
                mecho $_ "%B\[%C[center 14 $c1]%B\]%K#%B\[%C[center 14 $c2]%B\]%K#%B\[%C[center 14 $c3]%B\]%K#%B\[%C[center 14 $c4]%B\]%K#%B\[%C[center 14 $c5]%B\]"
            }
            mecho $_ "%c[ts {~~~%CMASTERS COMMANDS%c~~~}]"
            foreach {c1 c2 c3 c4 c5} "$temp(m-cmds)" {
                mecho $_ "%B\[%C[center 14 $c1]%B\]%K#%B\[%C[center 14 $c2]%B\]%K#%B\[%C[center 14 $c3]%B\]%K#%B\[%C[center 14 $c4]%B\]%K#%B\[%C[center 14 $c5]%B\]"
            }
            mecho $_ "%c[ts {~~~~%CUSERS COMMANDS%c~~~~}]"
            foreach {c1 c2 c3 c4 c5} "$temp(u-cmds)" {
                mecho $_ "%B\[%C[center 14 $c1]%B\]%K#%B\[%C[center 14 $c2]%B\]%K#%B\[%C[center 14 $c3]%B\]%K#%B\[%C[center 14 $c4]%B\]%K#%B\[%C[center 14 $c5]%B\]"
            }
        } else {
            syntax $_ {cmdlist [-all/-a]}
        }
    } else {
        mecho $_ "%c[ts {Commands list for you:}]"
        foreach {c1 c2 c3 c4 c5} "$temp([bestflag $_]-cmds)" {
            mecho $_ "%B\[%C[center 14 $c1]%B\]%K#%B\[%C[center 14 $c2]%B\]%K#%B\[%C[center 14 $c3]%B\]%K#%B\[%C[center 14 $c4]%B\]%K#%B\[%C[center 14 $c5]%B\]"
        }
    }
}
alias exit {
    mecho $_ "%W[ts {Bye.}]"
    logout $_
    close $sock
}
alias quit exit
alias bye exit
alias lo exit
alias . {
    echo "<%B$_@$temp(botname)%K> %w$args"
}
alias , {
    echo "%w* %B$_ $args"
}
alias server {
    if {[is 0]} {
        if {[string first : $0] > -1} {
            set tmp "[split $0 :]"
            set servtoconn "[lindex $tmp 0]"
            set porttoconn "[lindex $tmp 1]"
        } else {
            set servtoconn "$0"
            set porttoconn 6667
        }
        if {[is 1]} {
            lecho "[botspeak] %c[ts {Connecting to %C%0%c with VHost: %G%1%c.} $servtoconn $1]"
            connect $servtoconn $porttoconn $1
        } else {
            lecho "[botspeak] %c[ts {Connecting to %C%0%c.} $servtoconn]"
            connect $servtoconn $porttoconn
        }
    } else {
        syntax $_ {server <server[:port]> [<vhost>]}
    }
} m
alias jump {
    if {[is 0]} {
        if {[string first : $0] > -1} {
            set tmp "[split $0 :]"
            set servtoconn "[lindex $tmp 0]"
            set porttoconn "[lindex $tmp 1]"
        } else {
            set servtoconn "$0"
            set porttoconn 6667
        }
        if {[is 1]} {
            lecho "[botspeak] %c[ts {Connecting to %C%0%c with VHost: %G%1%c.} $servtoconn $1]"
            connect $servtoconn $porttoconn $1
        } else {
            lecho "[botspeak] %c[ts {Connecting to %C%0%c.} $servtoconn]"
            connect $servtoconn $porttoconn
        }
    } else {
        randserver
    }
} m
alias mode {
    if {[is 0]} {
        if {[is 1]} {
            if {[ischan $0]} {
                if {[isop $N $0]} {
                    mecho $_ "%c[ts {Changing mode for channel %C%0%c:} $0] %C[lrange $args 1 end]"
                    mode $0 $1 [lrange $args 2 end]
                } else {
                    mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
                }
            } else {
                syntax $_ {mode <channel> [<modes> [<arguments>]]}
            }
        } else {
            mecho $_ "%c[ts {Mode for channel %C%0%c is:} $1] +%C$temp(mode:$1)"
        }
    } else {
        syntax $_ {mode <channel> [<modes> [<arguments>]]}
    }
}
alias join {
    if {[is 0]} {
        if {[ischan $0]} {
            if {![amon $0]} {
                join $args
            } else {
                mecho $_ "%y[ts {I'm already on that channel.}]"
            }
        } else {
            mecho $_ "[ts {%Y%0%y is not valid channel name!} $0]"
        }
    } else {
        syntax $_ {join <channel> [<channel> ... ]}
    }
} m
alias part {
    if {[is 0]} {
        if {[ischan $0]} {
            if {[amon $0]} {
                part $args
            } else {
                mecho $_ "%c[ts {I'm not on channel %C%0%c.} $0]"
            }
        } else {
            mecho $_ "[ts {%Y%0%y is not valid channel name!} $0]"
        }
    } else {
        syntax $_ {part <channel> [<channel> ... ]}
    }
} m
alias cycle {
    if {[is 0]} {
        if {[ischan $0]} {
            if {[amon $0]} {
                part $0
                on ":$N!%@% PART $0 :*" "
                    on - \":$N!%@% PART $0 :*\"
                    join $0
                " cycle
            } else {
                mecho $_ "%c[ts {I'm not on channel %C%0%c.} $0]"
            }
        } else {
            mecho $_ "[ts {%Y%0%y is not valid channel name!} $0]"
        }
    } else {
        syntax $_ {cycle <channel>}
    }
}
alias die {
    lecho "%C[ts {Shutting down (by %0)} $_]"
    if {[amconn]} {
        if {[is 0]} {
            quote "quit :$args"
        } else {
            quote "quit :?"
        }
    }
    exit
} n
alias say {
    if {[is 1]} {
        if {[ischan $0]} {
            msg $0 [lrange $args 1 end]
        } else {
            syntax $_ {say <channel> <text>}
        }
    } else {
        syntax $_ {say <channel> <text>}
    }
}
alias msg {
    if {[is 1]} {
        if {![ischan $0]} {
            msg $0 [lrange $args 1 end]
        } else {
            syntax $_ {msg <nick> <text>}
        }
    } else {
        syntax $_ {say <nick> <text>}
    }
}
alias me {
    if {[is 1]} {
        if {[ischan $0]} {
            ctcp $0 action [lrange $args 1 end]
        } else {
            syntax $_ {me <channel> <text>}
        }
    } else {
        syntax $_ {me <channel> <text>}
    }
}
alias d13 die
alias link {
    if {[is 0]} {
        link2bot $0
    } else {
        syntax $_ "link <bot>"
    } 
}
alias unlink {
    if {[is 0]} {
        if {[isbot $0]} {
            if {[islink $0]} {
                disconnBot $0
            } else {
                mecho $_ "[botspeak] %y[ts {I'm not connected to bot %Y%0%y.} $0]"
            }
        } else {
            mecho $_ "[ts {%Y%0%y is not bot.} $0]"
        }
    } else {
        syntax $_ "unlink <bot>"
    }
}
alias +link {
    if {[is 0]} {
        addlink "$args"
    } else {
        syntax {+link <bot> [<bot> [...]]}
    }
}
alias addlink +link
alias -link {
    if {[is 0]} {
        remlink "$args"
    } else {
        syntax {-link <bot> [<bot> [...]]}
    }
}
alias remlink -link
alias links {
    mecho $_ "%c[ts {Current link list:}] %C$temp(linklist)"
}
alias linklist links
alias clearlinks {
    set temp(linklist) ""
    mecho $_ "%c[ts {Link list has been erased.}]"
}
alias setlinks {
    setlinks
    bots2 setlinks
}
alias net {
    if {[is 0]} {
        if {[eval lsearch {$temp([bestflag $_]-cmds)} $0] > -1} {
            bots "$0 [lrange $args 1 end]"
            cmd $0 [lrange $args 1 end]
        } else {
            mecho $_ "%y[ts {Unknown command '%0'. Type 'help' for get some help.} $0]"
        }
    } else {
        syntax $_ {net <command> [<arguments>]}
    }
}
alias m net
alias r {
    if {[is 1]} {
        if {[eval lsearch {$temp([bestflag $_]-cmds)} $1] > -1} {
            if {[isbot $0]} {
                bot $0 "$1 [lrange $args 1 end]"
            } else {
                mecho $_ "[ts {%Y%0%y is not bot.} $0]"
            }
        } else {
            mecho $_ "%y[ts {Unknown command '%0'. Type 'help' for get some help.} $1]"
        }
    } else {
        syntax $_ {r <bot> <command> [<arguments>]}
    }
}
alias bottree {
    if {[llength "$temp(botsonline)"] > 0} {
        if {![info exists temp(botnetchecking)]} {
            set temp(botnetchecking) 1
            set temp(tree4user) "$_"
            foreach b "$temp(botsonline)" {
                puts $temp(sock:$b) "bottree_request"
                lappend temp(bottree_bots) "$b"
            }
        } else {
            mecho $_ "%y[ts {I'm already waiting for this answer.}]"
        }
    } else {
        mecho $_ "%c[ts {BotNet doesn't exist!}]"
    }
}
alias tree bottree
alias whom {
    if {[llength "$temp(botsonline)"] > 0} {
        if {![info exists temp(whomchecking)]} {
            set temp(whomchecking) 1
            set temp(whom4user) "$_"
            foreach b "$temp(botsonline)" {
                puts $temp(sock:$b) "whom_request"
                lappend temp(whom_bots) "$b"
            }
        } else {
            mecho $_ "%y[ts {I'm already waiting for this answer.}]"
        }
    } else {
        mecho $_ "%c[ts {Users logged on:}]"
        foreach user "$temp(loggedon)" {
            mecho $_ "%m(%B[bestflag $user]%m)%C$user %c[ts {(at %C%0%c)} $temp(botname)] %m\[%c[ts {idle time:}] %C[convTime [expr [clock seconds] - $temp(idle:$user)]]%m\]"
        }
    }
}
alias save {
    if {"[bestflag $_]" == "u"} {
        save.users
        mecho $_ "%c[ts {Userlist has been saved.}]"
    } else {
        if {[is 0]} {
            switch -- $0 {
                -u {
                    save.users
                    mecho $_ "%c[ts {Userlist has been saved.}]"
                }
                -b {
                    save.bots
                    mecho $_ "%c[ts {Botlist has been saved.}]"
                }
                -c {
                    save.chans
                    mecho $_ "%c[ts {Chanlist has been saved.}]"
                }
                -s {
                    save.config
                    mecho $_ "%c[ts {Bot configuration has been saved.}]"
                }
                -a {
                    save.users
                    save.bots
                    save.chans
                    mecho $_ "%c[ts {All lists has been saved.}]"
                }
            }
        } else {
            syntax $_ {save [-u] [-b] [-c] [-a] [-s]}
        }
    }
} u
alias savenet {
    save.users
    save.bots
    save.chans
    mecho $_ "%c[ts {All lists has been saved.}]"
    sendlists
    mecho $_ "%c[ts {All lists has been sent.}]"
} m
alias sendlists {
    sendlists
    mecho $_ "%c[ts {All lists has been sent.}]"
} m
alias rehash {
    sendlists
    mecho $_ "%c[ts {All lists has been sent.}]"
} m
alias +chan {
    if {[is 0]} {
        if {[ischan $0]} {
            set 0 [string tolower $0]
            if {[is 1]} {
                set badflags "[strip $temp(chanflags) $1]"
                set mds "[sort [strip $badflags $1]]"
            } else {
                set badflags ""
                set mds "$temp(default_chan_flags)"
            }
            lappend temp(chanlist) "$0"
            set temp(chanmode:$0) "$mds"
            if {"$badflags" != ""} {
                mecho $_ "%y[ts {Flags %Y%0%y are not valid.} $badflags]"
            }
            mecho $_ "%c[ts {Channel %C%0%c added with modes +%C%1%c.} $0 $mds]"
            if {[amconn] && ![amon $0]} {
                join $0
            }
        } else {
            syntax $_ {+chan <channel> [<modes>]}
        }
    } else {
        syntax $_ {+chan <channel> [<modes>]}
    }
} m
alias addchan +chan m
alias -chan {
    if {[is 0]} {
        set 0 [string tolower $0]
        if {[lsearch -glob "$temp(chanlist)" $0] > -1} {
            unset temp(chanmode:[lsearch -glob -inline "$temp(chanlist)" $0])
            set temp(chanlist) "[lremove $temp(chanlist) [lsearch -glob "$temp(chanlist)" $0]]"
            if {[info exists temp(key:$0)]} {
                unset temp(key:$0)
            }
            mecho $_ "%c[ts {Channel %C%0%c removed from list.} $0]"
            if {[amconn] && [amon $0]} {
                part $0
            }
        } else {
            mecho $_ "%y[ts {There is no channel matching %Y%0%y on list.} $0]"
        }
    } else {
        syntax $_ {-chan <channel>}
    }
} m
alias remchan -chan m
alias chanmode {
    if {[is 0]} {
        set 0 [string tolower $0]
        if {[mychan $0]} {
            if {[is 1]} {
                if {[lsearch {= + -} [string index $1 0]] > -1} {
                    if {"[string index $1 0]" == "="} {
                        set badflags "[strip \"$temp(chanflags)=\" $1]"
                        set 1 "[strip $badflags $1]"
                        if {"$badflags" != ""} {
                            mecho $_ "%C[ts {Flags %0 are not valid.} $badflags]"
                        }
                        set temp(chanmode:$0) "[sort [string range $1 1 end]]"
                        mecho $_ "%c[ts {Now channel %C%0%c has got following modes:} $0] +%C$temp(chanmode:$0)"
                    } else {
                        set addflags ""
                        set remflags ""
                        set badflags "[strip \"$temp(chanflags)+-\" $1]"
                        if {"$badflags" != ""} {
                            set 1 "[strip $badflags $1]"
                        }
                        for {set cf 0} {"[string index $1 $cf]" != ""} {incr cf} {
                            switch -- [string index $1 $cf] {
                                + {
                                    set fchar +
                                }
                                - {
                                    set fchar -
                                }
                                default {
                                    if {"$fchar" == "+"} {
                                        if {"$cf" == "k"} {
                                            mecho $_ "%C[ts {Please set key for channel %C%0%c by command: key.} $0]"
                                        }
                                        append addflags "[string index $1 $cf]"
                                    } else {
                                        if {"$cf" == "k" && [info exists temp(key:$0)]} {
                                            unset temp(key:$0)
                                        }
                                        append remflags "[string index $1 $cf]"
                                    }
                                }
                            }
                        }
                        append temp(chanmode:$0) "$addflags"
                        set temp(chanmode:$0) "[sort -unique [strip $remflags $temp(chanmode:$0)]]"
                        mecho $_ "%c[ts {Now channel %C%0%c has got following modes:} $0] +%C$temp(chanmode:$0)"
                    }
                } else {
                    syntax $_ {chanmode <channel> [+/-/=<modes>]}
                }
            } else {
                mecho $_ "%c[ts {Channel %C%0%c has got following modes:} $0] +%C$temp(chanmode:$0)"
            }
        } else {
            mecho $_ "%y[ts {There is no such channel.}]"
        }
    } else {
        syntax $_ {chanmode <channel> [+/-/=<modes>]}
    }
} m
alias chanflags chanmode m
alias key {
    if {[is 0]} {
        set 0 [string tolower $0]
        if {[mychan $0]} {
            if {[is 1]} {
                set temp(key:$0) "$1"
                cmd chanmode $0 +k
                mecho $_ "%c[ts {Now key for channel %C%0%c is:} $0] %C$1"
            } else {
                if {[info exists temp(key:$0)]} {
                    mecho $_ "%c[ts {Channel key for %C%0%c is:} $0] %C$temp(key:$0)"
                } else {
                    mecho $_ "%c[ts {There is no key set on that channel.}]"
                }
            }
        } else {
            mecho $_ "%y[ts {There is no such channel.}]"
        }
    } else {
        syntax $_ {key <channel> [<new key>]}
    }
} m
alias chankey key
alias nokey {
    if {[is 0]} {
        set 0 [string tolower $0]
        if {[info exists temp(key:$0)]} {
            unset temp(key:$0)
            cmd chanmode $0 -k
            mecho $_ "%c[ts {Key for channel %C%0%c removed.} $0]"
        } else {
            mecho $_ "%c[ts {There is no key for channel %C%0%c.} $0]"
        }
    } else {
        syntax $_ {nokey <channel>}
    }
} m
alias limit {
    if {[is 0]} {
        set 0 [string tolower $0]
        if {[mychan $0]} {
            cmd chanmode $0 +l
        } else {
            mecho $_ "%y[ts {There is no such channel.}]"
        }
    } else {
        syntax $_ {limit <channel>}
    }
} m
alias lim limit m
alias nolimit {
    if {[is 0]} {
        set 0 [string tolower $0]
        if {[mychan $0]} {
            cmd chanmode $0 -l
        } else {
            mecho $_ "%y[ts {There is no such channel.}]"
        }
    } else {
        syntax $_ {nolimit <channel>}
    }
} m
alias nolim nolimit m
alias chanlist {
    if {[llength $temp(chanlist)] > 0} {
        mecho $_ "%c[ts {Channels list:}]"
        foreach ch "$temp(chanlist)" {
            mecho $_ "  %W%u$ch" 1
            mecho $_ "%c[ts {Constans modes:}] +%C$temp(chanmode:$ch)"
            if {[info exists temp(key:$ch)]} {
                mecho $_ "%c[ts {Constans key:}] %C$temp(key:$ch)"
            }
            if {[info exists temp(mode:$ch)]} {
                mecho $_ "%c[ts {Current modes:}] +%C$temp(mode:$ch)"
                if {[info exists temp(climit:$ch)]} {
                    mecho $_ "%c[ts {Current limit:}] %C$temp(climit:$ch)"
                }
                if {[info exists temp(ckey:$ch)]} {
                    mecho $_ "%c[ts {Current key:}] %C$temp(ckey:$ch)"
                }
            } else {
                mecho $_ "%c[ts {I'm NOT already on this channel.}]"
            }
        }
        mecho $_ "%c~~~~~~~~~~~~~~~~~~"
    } else {
        mecho $_ "%c[ts {There is no channels on list.}]"
    }
} u
alias chans chanlist
alias +ban {
    if {[is 1]} {
        set 0 [string tolower $0]
        if {[ischan $0]} {
            if {[mychan $0]} {
                lappend temp(ban:$0) [lrange $args 1 end]
                set temp(ban:$0) "[eval concat $temp(ban:$0)]"
                mecho $_ "%c[ts {Added following ban mask(s) for channel %C%0%c:} $0] %B[lrange $args 1 end]"
            } else {
                mecho $_ "%y[ts {I can't apply constans modes for channel, which is not on my channels list.}]"
            }
        } else {
            mecho $_ "%Y[ts {%0%y is not valid channel name.} $0]"
        }
    } else {
        syntax $_ {+ban <channel> <mask> [<mask> <mask> ...]}
    }
} m
alias addban +ban m
alias -ban {
    if {[is 1]} {
        set 0 [string tolower $0]
        if {[ischan $0]} {
            if {[info exists temp(ban:$0)]} {
                set temp(ban:$0) [npattern "$temp(ban:$0)" $1]
                mecho $_ "%c[ts {Removed ban masks matching '%B%0%c' for channel %C%1%c.} $1 $0] %B[lrange $args 1 end]"
            } else {
                mecho $_ "%c[ts {There is no ban masks for channel %C%0%c.} $0]"
            }
        } else {
            mecho $_ "%Y[ts {%0%y is not valid channel name.} $0]"
        }
    } else {
        syntax $_ {-ban <channel> <mask>}
    }
} m
alias remban -ban m
alias bans {
    if {[is 0]} {
        if {[is 1] && "$0" == "-r"} {
            set 1 [string tolower $1]
            onBans $1 "
                foreach ban \"\$temp($1:bans)\" {
                    mecho $_ \"%cBAN $1%K> %B\$ban\"
                }
            "
        } else {
            set 0 [string tolower $0]
            if {[info exists temp(ban:$0)]} {
                set cr 1
                foreach ban "$temp(ban:$0)" {
                    mecho $_ "%C[pad 2 \  $cr]%K> %B$ban"
                    incr cr
                }
            } else {
                mecho $_ "%c[ts {There is no ban masks for channel %C%0%c.} $0]"
            }
        }
    } else {
        syntax $_ {bans [-r] <channel>}
    }
}
alias banlist bans
alias +ex {
    if {[is 1]} {
        set 0 [string tolower $0]
        if {[ischan $0]} {
            if {[mychan $0]} {
                lappend temp(ex:$0) [lrange $args 1 end]
                set temp(ex:$0) "[eval concat $temp(ex:$0)]"
                mecho $_ "%c[ts {Added following exempt mask(s) for channel %C%0%c:} $0] %B[lrange $args 1 end]"
            } else {
                mecho $_ "%y[ts {I can't apply constans modes for channel, which is not on my channels list.}]"
            }
        } else {
            mecho $_ "%Y[ts {%0%y is not valid channel name.} $0]"
        }
    } else {
        syntax $_ {+ex <channel> <mask> [<mask> <mask> ...]}
    }
} m
alias addex +ex m
alias -ex {
    if {[is 1]} {
        set 0 [string tolower $0]
        if {[ischan $0]} {
            if {[info exists temp(inv:$0)]} {
                set temp(inv:$0) [npattern "$temp(inv:$0)" $1]
                mecho $_ "%c[ts {Removed exempt masks matching '%B%0%c' for channel %C%1%c.} $1 $0] %B[lrange $args 1 end]"
            } else {
                mecho $_ "%c[ts {There is no ban masks for channel %C%0%c.} $0]"
            }
        } else {
            mecho $_ "%Y[ts {%0%y is not valid channel name.} $0]"
        }
    } else {
        syntax $_ {-ex <channel> <mask>}
    }
} m
alias remex -ex m
alias exempts {
    if {[is 0]} {
        if {[is 1] && "$0" == "-r"} {
            set 1 [string tolower $1]
            onExempts $1 "
                foreach ex \"\$temp($1:excs)\" {
                    mecho $_ \"%cEXEMPT $1%K> %B\$ex\"
                }
            "
        } else {
            set 0 [string tolower $0]
            if {[info exists temp(ex:$0)]} {
                set cr 1
                foreach ex "$temp(ex:$0)" {
                    mecho $_ "%C[pad 2 \  $cr]%K> %B$ex"
                    incr cr
                }
            } else {
                mecho $_ "%c[ts {There is no exempt masks for channel %C%0%c.} $0]"
            }
        }
    } else {
        syntax $_ {exempts [-r] <channel>}
    }
}
alias exemptlist exempts
alias +inv {
    if {[is 1]} {
        set 0 [string tolower $0]
        if {[ischan $0]} {
            if {[mychan $0]} {
                lappend temp(inv:$0) [lrange $args 1 end]
                set temp(inv:$0) "[eval concat $temp(inv:$0)]"
                mecho $_ "%c[ts {Added following invite mask(s) for channel %C%0%c:} $0] %B[lrange $args 1 end]"
            } else {
                mecho $_ "%y[ts {I can't apply constans modes for channel, which is not on my channels list.}]"
            }
        } else {
            mecho $_ "%Y[ts {%0%y is not valid channel name.} $0]"
        }
    } else {
        syntax $_ {+inv <channel> <mask> [<mask> <mask> ...]}
    }
} m
alias addinv +inv m
alias -inv {
    if {[is 1]} {
        set 0 [string tolower $0]
        if {[ischan $0]} {
            if {[info exists temp(inv:$0)]} {
                set temp(inv:$0) [npattern "$temp(inv:$0)" $1]
                mecho $_ "%c[ts {Removed invite masks matching '%B%0%c' for channel %C%1%c.} $1 $0] %B[lrange $args 1 end]"
            } else {
                mecho $_ "%c[ts {There is no ban masks for channel %C%0%c.} $0]"
            }
        } else {
            mecho $_ "%Y[ts {%0%y is not valid channel name.} $0]"
        }
    } else {
        syntax $_ {-inv <channel> <mask>}
    }
} m
alias reminv -inv m
alias invites {
    if {[is 0]} {
        if {[is 1] && "$0" == "-r"} {
            set 1 [string tolower $1]
            onInvites $1 "
                foreach inv \"\$temp($1:invs)\" {
                    mecho $_ \"%cINVITE $1%K> %B\$inv\"
                }
            "
        } else {
            set 0 [string tolower $0]
            if {[info exists temp(inv:$0)]} {
                set cr 1
                foreach inv "$temp(inv:$0)" {
                    mecho $_ "%C[pad 2 \  $cr]%K> %B$inv"
                    incr cr
                }
            } else {
                mecho $_ "%c[ts {There is no invite masks for channel %C%0%c.} $0]"
            }
        }
    } else {
        syntax $_ {invites [-r] <channel>}
    }
}
alias invitelist invites
alias help {
    if {[is 0]} {
        help $_ $0
    } else {
        help $_
    }
}
alias relay {
    if {[is 0]} {
        if {[isbot $0]} {
            if {[info exists temp(botaddress:$0)]} {
                if {[info exists temp(botport:$0)]} {
                    catch {socket $temp(botaddress:$0) [lindex [split $temp(botport:$0) /] 1]} tempsock
                    if {[llength $tempsock] == 1} {
                        mecho $_ "%c[ts {Connected to bot %C%0%c.} $0]"
                        set temp(loggedon) "[lremove $temp(loggedon) [lsearch $temp(loggedon) $_]]"
                        fconfigure $tempsock -blocking 0 -buffering line
                        set temp(relay:$_) "$tempsock"
                        set temp(relaylev:$_) 0
                        set temp(relaybot:$_) "$0"
                        set temp(relayuser:$tempsock) "$_"
                        puts $tempsock "RELAY $_ $password($_)"
                        fileevent $tempsock readable "relayUser $_ $tempsock"
                    } else {
                        mecho $_ "%c[ts {I can't connect to bot %C%0%c (%C%1%c:%C%2%c).} $0 $temp(botaddress:$0) $temp(botport:$0)]"
                    }
                } else {
                    mecho $_ "%y[ts {There is no port for bot %Y%0%y.} $0]"
                }
            } else {
                mecho $_ "%y[ts {There is no address for bot %Y%0%y.} $0]"
            }
        } else {
            mecho $_ "[ts {%Y%0%y is not bot.} $0]"
        }
    } else {
        syntax $_ {relay <bot>}
    }
}
alias kickuser {
    if {[is 0]} {
        if {[isLoggedOn $0]} {
            if {![haveflags $0 "n r"]} {
                logout $0
            } else {
                mecho $_ "%y[ts {User %Y%0%y is unkickable.} $0]"
            }
        } else {
            mecho $_ "%Y[ts {%0%y isn't logged on me.}]"
        }
    } else {
        suntax $_ {kickuser <user>}
    }
} n
alias kuser kickuser
alias channel {
    if {[is 0]} {
        if {[ischan $0]} {
            if {[amconn]} {
                if {[amon $0]} {
                    mecho $_ "%c[ts {Users on channel %C%0%c:} $0]"
                    foreach {u1 u2 u3 u4 u5} "[lsort -dictionary $temp(onchannel:$0)]" {
                        mecho $_ "%K\[%M[nickchar $u1 $0]%B[pad 9 \  $u1]%K\] \[%M[nickchar $u2 $0]%B[pad 9 \  $u2]%K\] \[%M[nickchar $u3 $0]%B[pad 9 \  $u3]%K\] \[%M[nickchar $u4 $0]%B[pad 9 \  $u4]%K\] \[%M[nickchar $u5 $0]%B[pad 9 \  $u5]%K\]"
                    }
                    mecho $_ "%c[ts {Total users:}] %C[llength $temp(onchannel:$0)]"
                    mecho $_ "%c[ts {Topic:}] %C$temp(topic:$0)"
                    if {[llength $temp(topic_set_at:$0)] > 0} {
                        mecho $_ "%c[ts {Topic set by %C%0%c at %C%1%c.} $temp(topic_set_by:$0) [clock format $temp(topic_set_at:$0) -format %C]]"
                    } else {
                        mecho $_ "%c[ts {Topic set by %C%0%c at %C%1%c.} * *]"
                    }
                } else {
                    mecho $_ "%c[ts {I'm not on channel %C%0%c.} $0]"
                }
            } else {
                mecho $_ "%y[ts {I'm not connected to any IRC server.}]"
            }
        } else {
            mecho $_ "[ts {%Y%0%y is not valid channel name!} $0]"
        }
    } else {
        syntax $_ {channel <channel>}
    }
}
alias status {
    mecho $_ "%c[ts {My name is:}] %C$temp(botname)"
    mecho $_ "%c[ts {My current nick:}] %C$N"
    mecho $_ "%c[ts {My current server:}] %C$S"
    mecho $_ "%c[ts {Main nick:}] %C$temp(nick)"
    mecho $_ "%c[ts {Other nicks:}] %C$temp(othernicks)"
    mecho $_ "%c[ts {Opened ports: %C%0%c (users) %C%1%c (bots)} $temp(uport) $temp(bport)]"
    mecho $_ "%c[ts {My host:}] %C$temp(myHOST) %K(%C$temp(myIP)%K)"
    mecho $_ "%c[ts {Botnet flag:}] %C$temp(netflag)"
    mecho $_ "%c[ts {Botnet password:}] %C$temp(netpass)"
    mecho $_ "%c[ts {Writing main log:}] %C$temp(makelog)"
    mecho $_ "%c[ts {Server op protect:}] %C$temp(server_op_protect)"
}
alias op {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I give OP status to %C%0%c on %C%1%c.} $1 $0]"
            op $0 [lrange $args 1 end]
        } else {
            mecho $_ "[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {op <channel> <nick> [<nick> ...]}
    }
}
alias deop {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I take OP status from %C%0%c on %C%1%c.} $1 $0]"
            deop $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {deop <channel> <nick> [<nick> ...]}
    }
}
alias vop {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I give voice to %C%0%c on %C%1%c.} $1 $0]"
            vop $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {vop <channel> <nick> [<nick> ...]}
    }
}
alias devop {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I take voice from %C%0%c on %C%1%c.} $1 $0]"
            devop $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {devop <channel> <nick> [<nick> ...]}
    }
}
alias kick {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I kick %C%0%c from %C%1%c.} [lrange $args 1 end] $0]"
            mkick $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax _ {kick <channel> <nick> [<nick> ...]}
    }
}
alias ban {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I set ban for %C%0%c on %C%1%c.} $1 $0]"
            ban $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {ban <channel> [<nick> ...] / [<host> ...]}
    }
}
alias timeban {
    if {[is 2]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I set ban for %C%0%c on %C%1%c for time %C%2%c.} $1 $0 [lrange $args 2 end]]"
            timeban $0 $1 [lrange $args 2 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {timeban <channel> <nick>/<host> <time: *d *h *m *s>}
    }
}
alias unban {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I unset ban for %C%0%c on %C%1%c.} $1 $0]"
            unban $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {unban <channel> <nick> [<nick> ...] / <host> [<host> ...]}
    }
}
alias exempt {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I set ban-exempt for %C%0%c on %C%1%c.} $1 $0]"
            exempt $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {exempt <channel> [<nick> ...] / [<host> ...]}
    }
}
alias ex exempt
alias unexempt {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I unset ban-exempt for %C%0%c on %C%1%c.} $1 $0]"
            unexempt $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {unexempt <channel> <nick> [<nick> ...] / <host> [<host> ...]}
    }
}
alias unex unexempt
alias invite {
    if {[is 1]} {
        if {"$0" == "-i"} {
            if {[is 2]} {
                if {[isop $N $1]} {
                    mecho $_ "%c[ts {I invite %C%0%c to channel %C%1%c.} $2 $1]"
                    invite $1 $2
                } else {
                    mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $1]"
                }
            } else {
                syntax $_ {invite [-i <channel> <nick>] / <channel> [<nick> ...]/[<host> ...]}
            }
        } else {
            if {[isop $N $1]} {
                mecho $_ "%c[ts {I set invite-exempt for %C%0%c on %C%1%c.} $1 $0]"
                invite $0 [lrange $args 1 end]
            } else {
                mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
            }
        }
    } else {
        syntax $_ {invite [-i <channel> <nick>] / <channel> [<nick> ...]/[<host> ...]}
    }
}
alias inv invite
alias uninvite {
    if {[is 1]} {
        if {[isop $N $0]} {
            mecho $_ "%c[ts {I unset invite-exempt for %C%0%c on %C%1%c.} $1 $0]"
            uninvite $0 [lrange $args 1 end]
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {uninvite <channel> <nick> [<nick> ...] / <host> [<host> ...]}
    }
}
alias uninv uninvite
alias lsmod {
    if {[is 0]} {
        if {"$0" == "-r"} {
            mecho $_ "%c[ts {List of available scripts:}]"
            foreach scr "[glob -nocomplain -tails -directory scripts *.tcl]" {
                mecho $_ "%B> %C$scr"
            }
            mecho $_ "%c~~~~~~~~~~~~~~~~~~~~~~~"
        } else {
            syntax $_ {lsmod [-r]}
        }
    }
    mecho $_ "%c[ts {Scripts list:}]"
    foreach sc "$temp(scripts-inside)" {
        mecho $_ "%B> %C$sc"
    }
    mecho $_ "%c[ts {Libraries list:}]"
    foreach sc "$temp(libs)" {
        mecho $_ "%B> %C$sc"
    }
    mecho $_ "%c~~~~~~~~~~~~~~~~~~~~~~~"
}
alias insmod {
    if {[is 0]} {
        if {"[string range $0 end-3 end]" != ".tcl"} {
            append 0 .tcl
        }
        if {[file readable scripts/$0]} {
            set scriptfile $0
            source scripts/$0
            lappend temp(scripts-inside) "$0"
            mecho $_ "%c[ts {Script %C%0%c loaded.} $0]"
        } else {
            mecho $_ "%y[ts {Script %Y%0%y not found.} $0]"
        }
    } else {
        syntax $_ {insmod <script name>[.tcl]}
    }
}
alias modprobe insmod
alias addmod insmod
alias script insmod
alias ident {
    if {[is 0]} {
        set host $0![host $0]
        set user [isuser2 $host]
        if {"$user" != ""} {
            mecho $_ "%c[ts {User %C%0%c (%B%1%c) matched as %C%2%c.} $0 $host $user]"
        } else {
            mecho $_ "%c[ts {I can't ident %C%0%c (%B%1%c).} $0 $host]"
        }
    } else {
        syntax $_ {ident <nick>}
    }
}
alias sensors {
    if {[is 1]} {
        set 1 [string tolower $1]
        switch -- $0 {
            public {
                if {"$1" == "on"} {
                    set temp(public:sensor) ON
                    mecho $_ "[ts {%C%0%c flood sensor is now %C%1%c.} [string totitle $0] ON]"
                } elseif {"$1" == "off"} {
                    set temp(public:sensor) OFF
                    mecho $_ "[ts {%C%0%c flood sensor is now %C%1%c.} [string totitle $0] OFF]"
                } elseif {[string is digit $1]} {
                    set temp(pubflood_sensor) $1
                    mecho $_ "%c[ts {Value for %C%0%c flood sensor is now:} [string totitle $0]] %C$1"
                } else {
                    syntax $_ {sensor [<public/nick/join> ON/OFF/<value>]}
                }
            }
            nick {
                if {"$1" == "on"} {
                    set temp(nick:sensor) ON
                    mecho $_ "[ts {%C%0%c flood sensor is now %C%1%c.} [string totitle $0] ON]"
                } elseif {"$1" == "off"} {
                    set temp(nick:sensor) OFF
                    mecho $_ "[ts {%C%0%c flood sensor is now %C%1%c.} [string totitle $0] OFF]"
                } elseif {[string is digit $1]} {
                    set temp(nickflood_sensor) $1
                    mecho $_ "%c[ts {Value for %C%0%c flood sensor is now:} [string totitle $0]] %C$1"
                } else {
                    syntax $_ {sensor [<public/nick/join> ON/OFF/<value>]}
                }
            }
            join {
                if {"$1" == "on"} {
                    set temp(join:sensor) ON
                    mecho $_ "[ts {%C%0%c flood sensor is now %C%1%c.} [string totitle $0] ON]"
                } elseif {"$1" == "off"} {
                    set temp(join:sensor) OFF
                    mecho $_ "[ts {%C%0%c flood sensor is now %C%1%c.} [string totitle $0] OFF]"
                } elseif {[string is digit $1]} {
                    set temp(joinflood_sensor) $1
                    mecho $_ "%c[ts {Value for %C%0%c flood sensor is now:} [string totitle $0]] %C$1"
                } else {
                    syntax $_ {sensor [<public/nick/join> ON/OFF/<value>]}
                }
            }
            default {
                syntax $_ {sensor [<public/nick/join> ON/OFF/<value>]}
            }
        }
    } else {
        mecho $_ "%c[ts {Flood sensors:}]"
        mecho $_ "%c[pad 20 \  [ts {Public}]] %C[pad 3 \  $temp(public:sensor)] $temp(pubflood_sensor)"
        mecho $_ "%c[pad 20 \  [ts {Nick change}]] %C[pad 3 \  $temp(nick:sensor)] $temp(nickflood_sensor)"
        mecho $_ "%c[pad 20 \  [ts {Join}]] %C[pad 3 \  $temp(join:sensor)] $temp(joinflood_sensor)"
        mecho $_ "%c[ts {Values means allowed number of actions for each 10 seconds. To change any value:}]"
        syntax $_ {sensors <public/nick/join> ON/OFF/<value>}
    }
}
alias uptime {
    mecho $_ "%c[ts {I started %C%0%c ago.} \"[convTime [expr [clock seconds] - $temp(uptime)]]\"]"
}
alias nick {
    if {[is 0]} {
        if {[amconn] && ![info exists temp(am_restricted)]} {
            quote "nick $0"
        }
    } else {
        syntax $_ {nick <nick>}
    }
}
alias +server {
    if {[is 0]} {
        if {[string match *:* $0]} {
            set serv2add $0
        } else {
            set serv2add $0:6667
        }
        lappend temp(servlist) $serv2add
    } else {
        syntax $_ {+server <server[:port]>}
    }
} m
alias addserver +server m
alias -server {
    if {[is 0]} {
        if {[string match *:* $0]} {
            set serv2rem $0
        } else {
            set serv2rem $0:6667
        }
        set temp(servlist) [npattern $temp(servlist) $serv4rem]
    } else {
        syntax $_ {-server <server[:port]>}
    }
} m
alias remserver -server m
alias servlist {
    mecho $_ "%c[ts {Servers list:}]"
    foreach server "$temp(servlist)" {
        if {"$temp(server)" == "$server"} {
            mecho $_ "%B> $server    <== [ts {I'm on that server.}]"
        } else {
            mecho $_ "%B> $server"
        }
    }
    mecho $_ "%c~~~~~~~~~~~~~~~~~~~~~~~"
}
alias servers servlist
alias topic {
    if {[is 1]} {
        if {[isop $N $0]} {
            quote "topic $0 [lrange $args 1 end]"
        } else {
            mecho $_ "%c[ts {I'm not channel operator on %C%0%c.} $0]"
        }
    } else {
        syntax $_ {topic <channel> <new topic>}
    }
}
alias pwd {
    mecho $_ "%c[ts {I'm %C%0%c.} $temp(botname)]"
}
alias ! {
    if {[info exists temp(lastcmd:$_)]} {
        if {[lsearch "! (A" $temp(lastcmd:$_)] == -1} {
            cmd [lindex $temp(lastcmd:$_) 0] [lrange $temp(lastcmd:$_) 1 end]
        } else {
            mecho $_ "%y[ts {No command executed so far.}]"
        }
    } else {
        mecho $_ "%y[ts {No command executed so far.}]"
    }
}
alias log {
    if {[is 0]} {
        set 0 [string tolower $0]
        if {"[string index $0 0]" != "-"} {
            if {[mychan $0]} {
                cmd chanmode $0 +L
            } else {
                mecho $_ "%y[ts {There is no such channel.}]"
            }
        } else {
            set 0 [string range $0 1 end]
            if {[mychan $0]} {
                cmd chanmode $0 -L
            } else {
                mecho $_ "%y[ts {There is no such channel.}]"
            }
        }
    } else {
        syntax $_ {log [-]<channel>}
    }
}
alias nolog {
    if {[is 0]} {
        set 0 [string tolower $0]
        if {[mychan $0]} {
            cmd chanmode $0 -L
        } else {
            mecho $_ "%y[ts {There is no such channel.}]"
        }
    } else {
        syntax $_ {nolog <channel>}
    }
}
alias unlog nolog
alias quote {
    if {[is 0]} {
        quote $args
    } else {
        syntax $_ {quote <data>}
    }
}

alias env {
    mecho $_ "%c[ts {Bot evirnoment:}]"
    foreach v "$temp(vars_to_save)" {
        mecho $_ "%w[string toupper $v]=$temp($v)"
    }
    mecho $_ "%c~~~~~~~~~~~~~~~~~"
}
alias var {
    if {[is 0]} {
        if {[is 1]} {
            if {[lsearch "loginstring passstring nick othernicks botname netflag logo checktime bankick pubchar nickchar makelog kickreason encoding locale logmode netpass" [string tolower $0]] > -1} {
                if {[string tolower $0] == "encoding"} {
                    catch {encoding system [string tolower $1]} err
                    if {[llength $err] > 0} {
                        mecho $_ "%y[ts {This is unknown encoding system.}]"
                    } else {
                        set temp([string tolower $0]) $1
                        mecho $_ "%c[ts {Now variable %C%0%c evaluates:} [string toupper $0]] %C$1"
                    }
                } else {
                    set temp([string tolower $0]) $1
                    mecho $_ "%c[ts {Now variable %C%0%c evaluates:} [string toupper $0]] %C$1"
                }
            } else {
                mecho $_ "%y[ts {This variable can't be changed by command var.}]"
            }
        } else {
            if {[info exists temp([string tolower $0])]} {
                mecho $_ "%w[string toupper $0]=$temp([string tolower $0])"
            } elseif {[info exists trans([string tolower $0])]} {
                mecho $_ "%w[string toupper $0]=$trans([string tolower $0])"
            } else {
                mecho $_ "%y[ts {No such variable.}]"
            }
        }
    } else {
        syntax $_ {var <variable> [<new value>]}
    }
}

# Public commands
proc PUB:op {nick uhost handle channel arg} {
    if {[haveflag $handle o]} {
        op $channel $arg
    }
}
proc PUB:deop {nick uhost handle channel arg} {
    set todeop ""
    foreach a $arg {
        if {![haveflag [isuser2 $a![host $a]] f]} {
            lappend todeop $a
        }
    }
    if {"$todeop" != ""} {
        deop $channel $todeop
    }
}
proc PUB:vop {nick uhost handle channel arg} {
    vop $channel $arg
}
proc PUB:devop {nick uhost handle channel arg} {
    set todevop ""
    foreach a $arg {
        if {![haveflag [isuser2 $a![host $a]] f]} {
            lappend todevop $a
        }
    }
    if {"$todevop" != ""} {
        devop $channel $todevop
    }
}
proc PUB:ban {nick uhost handle channel arg} {
    set toban ""
    foreach a $arg {
        if {![haveflag [isuser2 $a![host $a]] f]} {
            lappend toban $a
        }
    }
    if {"$toban" != ""} {
        ban $channel $toban
    }
}
proc PUB:unban {nick uhost handle channel arg} {
    unban $channel $arg
}
proc PUB:kick {nick uhost handle channel arg} {
    set tokick ""
    foreach a $arg {
        if {![haveflag [isuser2 $a![host $a]] f]} {
            lappend tokick $a
        }
    }
    if {"$tokick" != ""} {
        mkick $channel $tokick
    }
}
proc PUB:dump {nick uhost handle channel arg} {
    global temp
    if {"[string tolower $temp(dumpcmd)]" == "on"} {
        set sock $temp(null)
        set temp(user:$sock) "$handle"
        set temp(sock:$handle) "$sock"
        cmd [lindex $arg 0] [lrange $arg 1 end]
        unset temp(user:$sock)
        unset temp(sock:$handle)
        unset sock

    }
}
