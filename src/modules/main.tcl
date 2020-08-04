### Load rest of modules:
source modules/scripting.tcl
source modules/commands.tcl
source modules/on.tcl
if {"$temp(loadhelp)" == "YES"} {
    source modules/help.tcl
} else {
    proc help {} {}
}
lib md5pure

### Server connection
proc connect {server port {host {}}} {
    global temp switch
    if {"$temp(server)" != ""} {
        # If bot is already connected to some server,
        # disconnect form it.
        puts $temp(serversock) "QUIT :?"
        
        # Now sets switch for action, which will be
        # executed just after disconnect from current
        # server = connect to new server.
        set switch(ondisc:$temp(server):0) "
            if {\"$host\" != \"\"} {
                catch {socket -myaddr $host $server $port} tempsock
            } else {
                catch {socket $server $port} tempsock
            }
            if {\[llength \$tempsock\] == 1} {
                set temp(serversock) \"\$tempsock\"
                set temp(server) \"$server:$port\"
                fconfigure \$tempsock -blocking 0 -buffering line
                fileevent  \$tempsock readable \"collectServer \$tempsock\"
                lecho \"\[botspeak\] %c[ts {Registering connection on %0.} $server]\"
                puts \$tempsock \"NICK $temp(nick)\"
                puts \$tempsock \"USER $temp(username) 001 $server :[randcrap 5]\"
            } else {
                lecho \"\[botspeak\] %c[ts {I can't connect to server %0 (%1)} $server $port.]\"
            }
        "
    } else {
        # Bot isn't connected to any server, so connect to new.
        if {"$host" != ""} {
            catch {socket -myaddr $host $server $port} tempsock
        } else {
            catch {socket $server $port} tempsock
        }
        if {[llength $tempsock] == 1} {
            set temp(serversock) "$tempsock"
            set temp(server) "$server:$port"
            fconfigure $tempsock -blocking 0 -buffering line

            # Here we tells bot to redirect any data received form
            # server to command collectServer.
            fileevent  $tempsock readable "collectServer $tempsock"

            # Puts registering strings.
            lecho "[botspeak] %c[ts {Registering connection on %0.} $server]"
            puts $tempsock "NICK $temp(nick)"
            puts $tempsock "USER $temp(username) 001 $server :[randcrap 5]"
        } else {
            lecho "[botspeak] %c[ts {I can't connect to server}] $server ($port)."
        }
    }
}
proc collectServer {channel} {
    global temp
    set bl 1
    while {$bl > 0 && "$temp(server)" != ""} {
        catch {gets $channel data}
#        set data "[string map {\{ \x101 \} \x102 \[ \x103 \] \x104 \" \x105} $data]"
        # Editor syntax higlighting: "
        set bl [string bytelength $data]
        if {$bl > 0 && "$temp(server)" != ""} {

            # SockSpy:
            if {[info exists temp(enable_sockspy)]} {
                lecho "%c\[SockSpy input\]: %w$data"
            }

            # Send each line of data to datain.
            datain "$data" "$channel"
        }
    }

    # Check if channel has been closed, or sth.
    catch {eof $channel} err
    if {"$err" != "0"} {
        catch {close $channel}
        if {"$temp(server)" != ""} {
            lecho "[botspeak] %c[ts {Connection with server %C%0%c lost.} $temp(server)]"
            set temp(connected) 0
            set temp(server) ""
            set temp(serversock) ""
        }
    }
}

proc datain {data channel} {
    # First get all glob variables.
    global globals
    eval global $globals
    set data [split $data]
    
    # Make 0, 1, 2, 3... positional variables from data arguments.
    set ii 0
    while {[lindex [split $data] $ii] != ""} {
        set $ii [lindex [split $data] $ii]
        incr ii
    }
    
    # For each indexed 'onswitch' execute code.
    foreach2 ON onswitch * {
        switch -regexp -- $data "
            $onswitch($ON)
        "
    }
}
proc first_randserver {} {
    if {![amconn]} {
        randserver
    }
}
proc randserver {} {
    global temp
    set servcnt [llength $temp(servlist)]
    if {$servcnt > 0} {
        set serv "[split [getStuff servlist] :]"
        set port "[lindex $serv 1]"
        set serv "[lindex $serv 0]"
        if {"$port" == ""} {
            set port 6667
        }
        if {"$temp(vhost)" != ""} {
            lecho "[botspeak] %c[ts {Connecting to %C%0%c with VHost: %G%1%c.} $serv $temp(vhost)]"
            connect $serv $port $temp(vhost)
        } else {
            lecho "[botspeak] %c[ts {Connecting to %C%0%c.} $serv]"
            connect $serv $port
        }
    } else {
        puts "(!) [ts {No server found on list. Please correct bot configuration file.}]"
    }
}

# User & bot connection.
proc cmd {cmd args} {
    upvar sock sock
    getglob
    set _ "$temp(user:$sock)"
    set temp(idle:$_) "[clock seconds]"
    # Remove ^] chars:
    set cmd "[strip \033 $cmd]"
    
    # If command is not empty, then execute it.
    if {[eval lsearch {$temp([bestflag $_]-cmds)} $cmd] > -1} {
        set c 0
        set args [eval concat $args]
        while {[lindex $args $c] != ""} {
            set $c [lindex $args $c]
            incr c
        }
        if {[lsearch "--help -h /? /h" "$args"] == -1} {
            if {"$cmd" != "." && "$cmd" != "," && ![haveflag $_ i] && [info exists temp(log:$sock)]} {
                echo "#%c$_@$temp(botname)%K# %c$cmd"
            }
            switch -glob -- $cmd "
                $cmdswitch
            "
        } else {
            help $_ $cmd
        }
    } else {
        mecho $_ "%y[ts {Unknown command '%0'. Type 'help' for get some help.} $cmd]"
    }
}
proc listen {port type {host {}}} {
    global temp
    set arg "-server"
    switch -- $type {
        users {
            lappend arg "userConn"
        }
        bots {
            lappend arg "botConn"
        }
        default {
            lappend arg "$type"
        }
    }
    if {"$host" != ""} {
        lappend arg "-myaddr $host $port"
    } else {
        lappend arg "$port"
    }
    catch {eval socket $arg} tempsock
    if {[llength $tempsock] == 1} {
        puts "[ts {Port opened:      %0} $port]"
    } else {
        force_error "[ts {Can't open port %0!} $port]"
    }
}
proc userConn {sock host port} {
    global temp
    if {![info exists temp(telnet_connection)]} {
        set temp(telnet_connection) 1
        after 1500 unset temp(telnet_connection)
        lecho "[botspeak] %c[ts {Incomming connection from %C%0%c on users port.} $host]"
        fconfigure $sock -blocking 0 -buffering line
        puts $sock "$temp(loginstring)"
        fileevent $sock readable "getUserData $sock $host $port"
    } else {
        catch {close $sock}
    }
}
proc getUserData {sock host port} {
    global temp userlist password
    set bl 1
    while {$bl > 0} {
        # Remove dangerous chars :)
        set data [string map {\{ "" \} "" \" "" \; : \[ ( \] )} [gets $sock]]
        #"

        set bl [string bytelength $data]
        if {$bl > 0} {

            # Correct data after changing telnet echo.
            if {![string is ascii [string index "$data" 0]]} {set data "[ASCIIfilter [ALNUMfilter $data 1]]"}

            if {[info exists temp(log:$sock)]} {
                if {[llength $data] > 0} {
                    if {[info exists temp(relay:$temp(user:$sock))]} {
                        puts $temp(relay:$temp(user:$sock)) $data
                    } else {
                        cmd [lindex $data 0] [lrange $data 1 end]
                        if {"[lindex $data 0]" != "!" && [info exists temp(user:$sock)]} {
                            set temp(lastcmd:$temp(user:$sock)) "$data"
                        }
                    }
                }
            } else {
                if {[info exists temp(login:$sock)]} {

                    # Second data is password. If correct, then user is logged on.
                    if {"[crypt $temp(login:$sock) $data]" == "$password($temp(login:$sock))"} {
                        set temp(user:$sock) "$temp(login:$sock)"
                        set temp(sock:$temp(user:$sock)) "$sock"
                        set temp(log:$sock) 1
                        lappend temp(loggedon) "$temp(user:$sock)"
                        unset temp(login:$sock)
                        if {![info exists temp(dcctype:$sock)]} {
                            ECHO $sock on
                        }
                        put_welcome $temp(user:$sock)
                        set temp(lastloggedon) "$temp(user:$sock) [clock seconds]"
                        set temp(idle:$temp(user:$sock)) "[clock seconds]"
                        LOG "[ts {%0 has logged on.} $temp(user:$sock)]"
                    } else {
                        unset temp(login:$sock)
                        catch {close $sock}
                        set bl 0
                    }
                } else {
                
                    # First data is login name. It could be relay.
                    if {"[lindex $data 0]" == "RELAY"} {
                        if {"[lindex $data 2]" == "$password([lindex $data 1])"} {
                            set temp(user:$sock) "[lindex $data 1]"
                            set temp(sock:$temp(user:$sock)) "$sock"
                            set temp(log:$sock) 1
                            lappend temp(loggedon) "$temp(user:$sock)"
                            put_welcome $temp(user:$sock)
                            set temp(lastloggedon) "$temp(user:$sock) [clock seconds]"
                            set temp(idle:$temp(user:$sock)) "[clock seconds]"
                            LOG "[ts {%0 has logged on.} $temp(user:$sock)]"
                        } else {
                            catch {close $sock}
                            set bl 0
                        }
                    } else {
                        if {[lsearch "$userlist" $data] > -1} {
                            if {[haveflag $data p]} {
                                set temp(login:$sock) "$data"
                                puts $sock "$temp(passstring)"
                                if {![info exists temp(dcctype:$sock)]} {
                                    ECHO $sock off
                                }
                            } else {
                                catch {close $sock}
                                set bl 0
                            }
                        } elseif {[llength $userlist] == 0 && "$data" == "$temp(botname)" || [info exists temp(create_user_lev)]} {
                            if {[info exists temp(create_user_lev)]} {
                                switch -- $temp(create_user_lev) {
                                    0 {
                                        set temp(newuser:login) "[lindex $data 0]"
                                        incr temp(create_user_lev)
                                        puts $sock "[ts {Type password:}]"
                                        if {![info exists temp(dcctype:$sock)]} {
                                            ECHO $sock off
                                        }
                                    }
                                    1 {
                                        set temp(newuser:pass) "$data"
                                        incr temp(create_user_lev)
                                        puts $sock "[ts {Retype password:}]"
                                    }
                                    2 {
                                        if {"$data" == "$temp(newuser:pass)"} {
                                            global flags userhost
                                            lappend userlist "$temp(newuser:login)"
                                            set flags($temp(newuser:login)) "!@Aacfoqprx"
                                            set userhost($temp(newuser:login)) ""
                                            set password($temp(newuser:login)) "$data"
                                            set temp(log:$sock) 1
                                            set temp(user:$sock) "$temp(newuser:login)"
                                            set temp(sock:$temp(user:$sock)) "$sock"
                                            unset temp(newuser:login)
                                            unset temp(newuser:pass)
                                            lappend temp(loggedon) "$temp(user:$sock)"
                                            put_welcome $temp(user:$sock)
                                            set temp(lastloggedon) "$temp(user:$sock) [clock seconds]"
                                            set temp(idle:$temp(user:$sock)) "[clock seconds]"
                                            LOG "[ts {%0 has logged on.} $temp(user:$sock)]"
                                        } else {
                                            set temp(create_user_lev) 0
                                            puts $sock "[ts {Type name for first user:}]"
                                        }
                                        if {![info exists temp(dcctype:$sock)]} {
                                            ECHO $sock on
                                        }
                                    }
                                }
                            } else {
                                set temp(create_user_lev) 0
                                puts $sock "[ts {Type name for first user:}]"
                            }
                        } else {
                            catch {close $sock}
                            set bl 0
                        }
                    }
                }
            }
        }
        # Check if channel has been closed.
        catch {eof $sock} err
        if {"$err" != "0"} {
            catch {close $sock}
            if {[info exists temp(user:$sock)]} {
                logout $temp(user:$sock)
            }
        }
    }
}
proc put_welcome {user} {
    global version temp
    if {[file readable [file join logos $temp(logo)]]} {
        set fd [open [file join logos $temp(logo)] r]
        set host [info hostname]
        set time "[clock format [clock seconds] -format %c]"
        while {![eof $fd]} {
            mecho $user [eval string map {"&v {$version} &h {$host} &b {$temp(botname)} &t {$time}"} {[gets $fd]}]
        }
        close $fd
    }
    if {[info exists temp(lastloggedon)]} {
        mecho $user "%c[ts {Last logged on user:}] %C[string totitle [lindex $temp(lastloggedon) 0]] %c([clock format [lindex $temp(lastloggedon) 1] -format %c])."
    }
    echo "[botspeak] [ts {%C%0%c has logged on.} [string totitle $user]]"
}
proc relayUser {user channel} {
    global temp
    set bl 1
    while {$bl > 0} {
        catch {gets $channel data}
        set bl [string bytelength $data]
        if {$bl > 0} {
            if {$temp(relaylev:$user) == 1} {
                puts $temp(sock:$user) "$data"
            } else {
                incr temp(relaylev:$user)
            }
        }
    }

    catch {eof $channel} closed
    # Check if channel has been closed, or sth.
    if {$closed} {
        catch {close $channel}
        lappend temp(loggedon) "$user"
        mecho $user "        %C$temp(relaybot:$user)"
        mecho $user "          %c|"
        mecho $user "          %c|"
        mecho $user "          %c`-> %C$temp(botname)"
        catch {unset temp(relayuser:$temp(relay:$user))}
        catch {unset temp(relay:$user)}
        catch {unset temp(relaylev:$user)}
        catch {unset temp(relaybot:$user)}
    }
}
proc logout {user} {
    global temp
    catch {set temp(loggedon) "[lremove $temp(loggedon) [lsearch $temp(loggedon) $user]]"}
    catch {unset temp(user:$temp(sock:$user))}
    catch {unset temp(log:$temp(sock:$user))}
    catch {unset temp(dcctype:$temp(sock:$user))}
    catch {unset temp(sock:$user)}
    catch {unset temp(idle:$user)}
    catch {unset temp(chat:$user)}
    catch {unset temp(lastcmd:$user)}
    catch {unset temp(create_user_lev)}
    catch {unset temp(newuser:login)}
    catch {unset temp(newuser:pass)}
    echo "[botspeak] [ts {%C%0%c has logged off.} [string totitle $user]]"
    LOG "[ts {%0 has logged off.} [string totitle $user]]"
    catch {
        upvar #1 bl bl
        set bl 0
    }
}
proc read_stdin {} {
    # It's for interactive mode
    set sock stdin
    set data [string map {\{ "" \} "" \" "" \; : \[ ( \] )} [gets stdin]]
    #"
    if {[llength $data] > 0} {
        global temp
        cmd [lindex $data 0] [lrange $data 1 end]
        if {"[lindex $data 0]" != "!" && [info exists temp(user:CONSOLE)]} {
            set temp(lastcmd:CONSOLE) "$data"
        }
    }
}
proc connToBot {bot host port} {
    global temp
    lecho "[botspeak] %c[ts {I'm connecting to bot %C%0%c.} $bot]"
    
    # Make connectin to remote bot.
    catch {socket $host $port} tempsock
    if {[llength $tempsock] == 1} {
        set temp(connection:$tempsock) "active"
        set temp(boton:$tempsock) "$bot"
        fconfigure $tempsock -blocking 0 -buffering line
        fileevent  $tempsock readable "getBotData $tempsock $host $port"
    } else {
        lecho "[botspeak] %c[ts {I can't connect to bot %C%0%c (%C%1%c:%C%2%c).} $bot $host $port]"
    }
}
proc disconnBot {bot} {
    global temp
    catch {close $temp(sock:$bot)}
    botlogout $bot
}
proc botConn {sock host port} {
    global temp
    fconfigure $sock -blocking 0 -buffering line
    lecho "[botspeak] %c[ts {Incomming connection from %C%0%c on bots port.} $host]"
    puts $sock "\x01.\x01"
    set temp(connection:$sock) "passive"
    fileevent $sock readable "getBotData $sock $host $port"
}
proc getBotData {sock host port} {
    global temp botlist env userhost
    set bl 1
    while {$bl > 0} {
        gets $sock data
        set bl [string bytelength $data]
        if {$bl > 0} {
            if {[info exists temp(log:$sock)]} {
                raw.bot $temp(bot:$sock) [lindex $data 0] [lrange $data 1 end]
            } else {
                # Check if connection with bot is passive or active,
                # then wait for valid strings or send them.
                if {"$temp(connection:$sock)" == "passive"} {
                    set data0 "[decodepass [lindex $data 0]]"
                    if {"$data0" == "$temp(botname)"} {
                        if {"[lindex $data 2]" != "$temp(netflag)"} {
                            set temp(bot:$sock) "[lindex $data 1]"
                            set temp(sock:$temp(bot:$sock)) "$sock"
                            set temp(log:$sock) 1
                            set temp(botflag:$temp(bot:$sock)) "[lindex $data 2]"
                            lappend temp(botsonline) "$temp(bot:$sock)"
                            puts $sock "LOGIN_OK $temp(botname) $temp(netflag) *!$env(USER)@$temp(myHOST)"
                            lecho "[botspeak] %c[ts {Connection with bot %C%0%c established.} $temp(bot:$sock)]"
                            if {[llength "$userhost($temp(bot:$sock))"] == 0} {
                                set userhost($temp(bot:$sock)) "[lindex $data 3]"
                            }
                            if {$temp(netflag) < $temp(botflag:$temp(bot:$sock))} {
                                sendlists $temp(bot:$sock)
                            }
                        } else {
                            lecho "[botspeak] [ts {%C%0%c has got same flag. It is not allowed.} [string totitle [lindex $data 1]]]"
                            catch {close $sock}
                            set bl 0
                        }
                    } else {
                        lecho "[botspeak] [ts {%C%0%c gave wrong network password or my bot name.} [string totitle [lindex $data 1]]]"
                        catch {close $sock}
                        set bl 0
                    }
                } else {
                    if {"$data" == "\x01.\x01"} {
                        lecho "[botspeak] %c[ts {I'm sending login and password to %C%0%c:%C%1%c.} $host $port]"
                        puts $sock "{[encodepass $temp(boton:$sock)]} $temp(botname) $temp(netflag)  *!$env(USER)@$temp(myHOST)"
                    } elseif {"[lindex $data 0]" == "LOGIN_OK"} {
                        if {"[lindex $data 1]" == "$temp(boton:$sock)"} {
                            set temp(bot:$sock) "$temp(boton:$sock)"
                            unset temp(boton:$sock)
                            set temp(sock:$temp(bot:$sock)) "$sock"
                            set temp(log:$sock) 1
                            lappend temp(botsonline) "$temp(bot:$sock)"
                            set temp(botflag:$temp(bot:$sock)) "[lindex $data 2]"
                            lecho "[botspeak] %c[ts {Connection with bot %C%0%c established.} $temp(bot:$sock)]"
                            if {[llength "$userhost($temp(bot:$sock))"] == 0} {
                                set userhost($temp(bot:$sock)) "[lindex $data 3]"
                            }
                            if {$temp(netflag) < $temp(botflag:$temp(bot:$sock))} {
                                sendlists $temp(bot:$sock)
                            }
                        } else {
                            lecho "[botspeak] [ts {%C%0%c is not bot, which I want connect to.} [string totitle [lindex $data 1]]]"
                            catch {close $sock}
                            set bl 0
                        }
                    } else {
                        lecho "[botspeak] %c[ts {Host %C%0%c on port %C%1%c is not Giana bot.} $host $port]"
                        catch {close $sock}
                        set bl 0
                    }
                }
            }
        }
        # Check if channel has been closed.
        catch {eof $sock} err
        if {"$err" != "0"} {
            catch {close $sock}
            if {![info exists temp(bot:$sock)]} {
                lecho "[botspeak] %c[ts {Connection with %C%0%c lost.} $host]"
            } else {
                botlogout $temp(bot:$sock)
            }
        }
    }
}
proc botlogout {bot} {
    global temp
    lecho "[botspeak] %c[ts {Connection with bot %C%0%c lost.} $bot]"
    catch {set temp(botsonline) "[lremove $temp(botsonline) [lsearch $temp(botsonline) $bot]]"}
    catch {unset temp(connection:$temp(sock:$bot))}
    catch {unset temp(user:$temp(sock:$bot))}
    catch {unset temp(log:$temp(sock:$bot))}
    catch {unset temp(botflag:$temp(sock:$bot))}
    catch {unset temp(sock:$bot)}
    catch {
        upvar #1 bl bl
        set bl 0
    }
}
proc raw.bot {bot cmd args} {
    # There is main part of bots connection protocol.
    switch -- $cmd {
        bottree_request {
            global temp
            if {[isOtherBot $bot]} {
                set temp(botnetchecking) 1
                set temp(botnet_replyto) "$bot"
                foreach b "$temp(botsonline)" {
                    if {"$b" != "$bot"} {
                        puts $temp(sock:$b) "bottree_request"
                        lappend temp(bottree_bots) "$b"
                    }
                }
            } else {
                puts $temp(sock:$bot) "bottree_answer $temp(netflag)^$temp(botname)#[getOtherBots]"
            }
        }
        bottree_answer {
            global temp
            set temp(bottree_bots) "[lremove $temp(bottree_bots) [lsearch $temp(bottree_bots) $bot]]"
            set args [lindex $args 0]
            if {"$args" != ""} {
                lappend temp(bottree_answer) "$args"
            }
            if {[llength $temp(bottree_bots)] == 0} {
                if {[info exists temp(botnet_replyto)]} {
                    if {[info exists temp(bottree_answer)]} {
                        puts $temp(sock:$temp(botnet_replyto)) "bottree_answer $temp(netflag)^$temp(botname)#[getOtherBots] $temp(bottree_answer)"
                    } else {
                        puts $temp(sock:$temp(botnet_replyto)) "bottree_answer $temp(netflag)^$temp(botname)#[getOtherBots]"
                    }
                    unset temp(botnet_replyto)
                } else {
                    if {[info exists temp(bottree_answer)]} {
                        createLinks "$temp(netflag)^$temp(botname)#[getOtherBots] $temp(bottree_answer)"
                    } else {
                        createLinks "$temp(netflag)^$temp(botname)#[getOtherBots]"
                    }
                }
                catch {unset temp(bottree_answer)}
                unset temp(botnetchecking)
            }
        }
        whom_request {
            global temp
            if {[isOtherBot $bot]} {
                set temp(whomchecking) 1
                set temp(whom_replyto) "$bot"
                foreach b "$temp(botsonline)" {
                    if {"$b" != "$bot"} {
                        puts $temp(sock:$b) "whom_request"
                        lappend temp(whom_bots) "$b"
                    }
                }
            } else {
                puts $temp(sock:$bot) "whom_answer $temp(botname)#[getLoggedOn]"
            }
        }
        whom_answer {
            global temp
            set temp(whom_bots) "[lremove $temp(whom_bots) [lsearch $temp(whom_bots) $bot]]"
            set args [lindex $args 0]
            if {"$args" != ""} {
                lappend temp(whom_answer) "$args"
            }
            if {[llength $temp(whom_bots)] == 0} {
                if {[info exists temp(whom_replyto)]} {
                    if {[info exists temp(whom_answer)]} {
                        puts $temp(sock:$temp(whom_replyto)) "[eval concat whom_answer $temp(botname)#[getLoggedOn] $temp(whom_answer)]"
                    } else {
                        puts $temp(sock:$temp(whom_replyto)) "whom_answer $temp(botname)#[getLoggedOn]"
                    }
                    unset temp(whom_replyto)
                } else {
                    if {[info exists temp(whom_answer)]} {
                        createWhom "[eval concat $temp(botname)#[getLoggedOn] $temp(whom_answer)]"
                    } else {
                        createWhom "$temp(botname)#[getLoggedOn]"
                    }
                }
                catch {unset temp(whom_answer)}
                unset temp(whomchecking)
            }
        }
        do {
            getglob
            set _ "$bot"
            set args [lindex $args 0]
            set cmd [lindex $args 0]
            set args "[lrange $args 1 end]"
            set c 0
            set args [eval concat $args]
            while {[lindex $args $c] != ""} {
                set $c [lindex $args $c]
                incr c
            }
            switch -glob -- $cmd "
                $cmdswitch
            "
        }
        do2 {
            set _ "$bot"
            eval [eval lindex $args 0] [eval lrange "$args" 1 end]
        }
        netdo {
            getglob
            set args [lindex $args 0]
            bots $args $bot
            set _ "$bot"
            set cmd [lindex $args 0]
            set args "[lrange $args 1 end]"
            set c 0
            set args [eval concat $args]
            while {[lindex $args $c] != ""} {
                set $c [lindex $args $c]
                incr c
            }
            switch -glob -- $cmd "
                $cmdswitch
            "
        }
        netdo2 {
            set _ "$bot"
            bots2 $args $bot
            eval [eval lindex $args 0] [eval lrange "$args" 1 end]
        }
        rdo {
            set args [lindex $args 0]
            global temp
            if {"[lindex $args 0]" == "$temp(botname)"} {
                getglob
                set _ "$bot"
                set cmd [lindex $args 1]
                set args "[lrange $args 2 end]"
                set c 0
                set args [eval concat $args]
                while {[lindex $args $c] != ""} {
                    set $c [lindex $args $c]
                    incr c
                }
                switch -glob -- $cmd "
                    $cmdswitch
                "
            } else {
                bot [lindex $args 0] [lrange $args 1 end] $temp(botname)
            }
        }
        rdo2 {
            set args [lindex $args 0]
            global temp
            if {"[lindex $args 0]" == "$temp(botname)"} {
                eval [lindex $args 1] [lrange $args 2 end]
            } else {
                bot2 [lindex $args 0] [lrange $args 1 end] $temp(botname)
            }
        }
        myhost {
            set args [lindex $args 0]
            global userhost
            set userhost([lindex $args 0]) "[lindex $args 1]"
        }
        list {
            set args [lindex $args 0]
            switch [lindex $args 0] {
                start {
                    if {"[lindex $args 2]" == "erase"} {
                        switch [lindex $args 1] {
                            user {
                                global userlist flags userhost password
                                foreach user "$userlist" {
                                    unset flags($user)
                                    unset userhost($user)
                                    unset password($user)
                                }
                                set userlist ""
                            }
                            bot {
                                global botlist flags userhost password
                                foreach b "$botlist" {
                                    if {"$bot" != "$b"} {
                                        catch {unset flags($b)}
                                        catch {unset botflags($b)}
                                        catch {unset userhost($b)}
                                        catch {unset botaddress($b)}
                                        catch {unset botport($b)}
                                    }
                                }
                                set botlist "$bot"
                            }
                            chan {
                                global temp
                                foreach chan "$temp(chanlist)" {
                                    unset temp(chanmode:$chan)
                                }
                                set temp(chanlist) ""
                            }
                        }
                    }
                }
                data {
                    switch [lindex $args 1] {
                        user {
                            global userlist flags userhost password
                            lappend userlist "[lindex $args 2]"
                            set password([lindex $args 2]) "[lindex $args 3]"
                            set flags([lindex $args 2]) "[lindex $args 4]"
                            foreach cf "[split [lindex $args 5] ,]" {
                                set flags([lindex $args 2]:[lindex [split $cf .] 0]) "[lindex [split $cf .] 1]"
                            }
                            set userhost([lindex $args 2]) "[lrange $args 6 end]"
                        }
                        bot {
                            global botlist flags userhost password botflags temp
                            lappend botlist "[lindex $args 2]"
                            set botflags([lindex $args 2]) "[lindex $args 3]"
                            set flags([lindex $args 2]) "[lindex $args 4]"
                            set temp(botaddress:[lindex $args 2]) "[lindex $args 5]"
                            set temp(botport:[lindex $args 2]) "[lindex $args 6]"
                            set userhost([lindex $args 2]) "[lrange $args 7 end]"
                        }
                        chan {
                            global temp
                            lappend temp(chanlist) "[lindex $args 2]"
                            set temp(chanmode:[lindex $args 2]) "[lindex $args 3]"
                        }
                    }
                }
                end {
                    save.[lindex $args 1]s
                }
            }
        }
        default {
            global temp
            set args [lindex $args 0]
            if {"[info commands bot:$cmd]" == "bot:$cmd"} {
                bot:$cmd $bot $args
            }
        }
    }
}
proc sendlists {{bot {}}} {
    if {"$bot" != ""} {
        sendLists $bot
    } else {
        global temp
        foreach bot "$temp(botsonline)" {
            sendlists $bot
        }
    }
}
proc sendLists {bot} {
    getglob
    foreach list "user bot chan" {
        if {[bhaveflags $bot [string tolower [string index $list 0]] [string toupper [string index $list 0]]]} {
            if {[bhaveflag $bot [string tolower [string index $list 0]]]} {
                puts $temp(sock:$bot) "list start $list erase"
            } else {
                puts $temp(sock:$bot) "list start $list noerase"
            }
            switch $list {
                user {
                    foreach user "$userlist" {
                        set localflags ""
                        foreach2 cf flags $user:* {
                            lappend localflags [lindex [split $cf :] 1].$flags($cf)
                        }
                        puts $temp(sock:$bot) "list data $list {$user} {$password($user)} {$flags($user)} {[sjoin $localflags ,]} $userhost($user)"
                    }
                }
                bot {
                    foreach b "$botlist" {
                        if {"$b" != "$bot"} {
                            puts $temp(sock:$bot) "list data $list {$b} {$botflags($b)} {$flags($b)} {$temp(botaddress:$b)} {$temp(botport:$b)} $userhost($b)"
                        }
                    }
                }
                chan {
                    foreach chan "$temp(chanlist)" {
                        puts $temp(sock:$bot) "list data $list {$chan} {$temp(chanmode:$chan)}"
                    }
                }
            }
            puts $temp(sock:$bot) "list end $list"
        }
    }
}
proc isOtherBot {bot} {
    global temp
    set is 0
    foreach b "$temp(botsonline)" {
        if {"$b" != "$bot"} {
            set is 1
        }
    }
    return $is
}
proc getOtherBots {} {
    global temp
    set list ""
    foreach b "$temp(botsonline)" {
        if {"$temp(botflag:$b)" > "$temp(netflag)"} {
            lappend list "$temp(botflag:$b)^$b"
        }
    }
    return [sjoin $list :]
}
proc createLinks {data} {
    global temp botlist
    set bestflag "$temp(netflag)"
    set hub "$temp(botname)"
    
    # Convert data to more readable form and searching for hub.
    # It remembers all bots connected to hub and all bots connected
    # to bots, which are connected to hub and so on...
    foreach arg "[eval concat $data]" {
        set main "[lindex [split $arg #] 0]"
        set flag([lindex [split $main ^] 1]) "[lindex [split $main ^] 0]"
        set others "[lindex [split $arg #] 1]"
        if {[lindex [split $main ^] 0] < $bestflag} {
            set bestflag "[lindex [split $main ^] 0]"
            set hub "[lindex [split $main ^] 1]"
        }
        foreach oth "[split $others :]" {
            lappend link([lindex [split $main ^] 1]) "[lindex [split $oth ^] 1]"
            set flag([lindex [split $oth ^] 1]) "[lindex [split $oth ^] 0]"
        }
    }
    
    # Start to draw botnet tree. First set sure values.
    set botsleft "$botlist"
    set line 1
    set level "    "
    set tree(0) "%m(%B$bestflag%m)%C$hub"
    if {"$hub" == "$temp(botname)"} {
        append tree(0) "    %c<=== %C[ts {That's me!}]"
    } else {
        set botsleft "[lremove $botsleft [lsearch $botsleft $hub]]"
    }
    
    # Now use command drawTree to draw tree for rest of bots.
    drawTree $hub
    
    # Display ready tree.
    mecho $temp(tree4user) "%c[ts {BotNet tree:}]"
    for {set line 0} {[info exists tree($line)]} {incr line} {
        mecho $temp(tree4user) "$tree($line)"
    }
    mecho $temp(tree4user) "%c[ts {End of BotNet tree. Total bots:}] %C$line%c."
    mecho $temp(tree4user) "%c[ts {Missing bots:}] %C$botsleft"
    unset temp(tree4user)
}
proc drawTree {root} {
    # This function is execuded recursive.
    # It draws tree for all bots connected
    # to main bot - 'root' and checks for each bot,
    # if some bots are connected to him, then execute
    # drawTree with this bot as 'root'.
    upvar level level line line flag flag link link tree tree temp temp botsleft botsleft
    for {set i 0} {"[lindex $link($root) $i]" != ""} {incr i} {
        set bot "[lindex $link($root) $i]"
        set tree($line) "%c$level[botTreeChar1 $link($root) $i]-%m(%B$flag($bot)%m)%C$bot"
        if {"$bot" == "$temp(botname)"} {
            append tree($line) "    %c<=== %C[ts {That's me!}]"
        } else {
            set botsleft "[lremove $botsleft [lsearch $botsleft $bot]]"
        }
        incr line
        if {[info exists link($bot)]} {
            if {[llength $link($bot)] > 0} {
                set cnt [expr {$i + 1}]
                if {"[lindex $list $cnt]" != ""} {
                    append level "|   "
                } else {
                    append level "    "
                }
                drawTree $bot
                set level "[string range $level 0 end-4]"
            }
        }
    }
}
proc botTreeChar1 {list cnt} {
    incr cnt
    if {"[lindex $list $cnt]" != ""} {
        return "|"
    } else {
        return "`"
    }
}
# This is only for editor highlighting :) -> `
proc getLoggedOn {} {
    global temp
    set list ""
    foreach b "$temp(loggedon)" {
        lappend list "[bestflag $b]^[expr {[clock seconds] - $temp(idle:$b)}]^$b"
    }
    return [sjoin $list :]
}
proc createWhom {data} {
    global temp
    mecho $temp(whom4user) "%c[ts {Users logged on:}]"
    foreach arg "$data" {
        set main "[lindex [split $arg #] 0]"
        set others "[lindex [split $arg #] 1]"
        foreach oth "[split $others :]" {
            mecho $temp(whom4user) "%m(%B[lindex [split $oth ^] 0]%m)%C[lindex [split $oth ^] 2] %c[ts {(at %C%0%c)} $main] %c[ts {idle time:}] %C[convTime [lindex [split $oth ^] 1]]"
        }
    }
    unset temp(whom4user)
}
proc invIfOp {nick chan} {
    global N
    if {[isop $N $chan]} {
        invite $chan $nick
    } else {
        upvar bot bot
        bots2 "invIfOp $nick $chan" $bot
    }
}

# Other stuff...
proc canChange {user1 user2} {
    # Check if user1 can change anything for user2.
    switch [bestflag $user1] {
        r {
            return 1
        }
        n {
            if {[lsearch "n m u" [bestflag $user2]] > -1} {
                return 1
            } else {
                return 0
            }
        }
        m {
            if {"[bestflag $user2]" == "u"} {
                return 1
            } else {
                return 0
            }
        }
        u {
            return 0
        }
    }
}

# Checking channel modes, bans, etc.
proc timeCheckModes {} {
    global temp N
    foreach chan "$temp(chanlist)" {
        if {[amon $chan]} {
            if {[isop $N $chan]} {
                if {![nhavechar $temp(chanmode:$chan) f] && [shellIdo $chan]} {
                    checkModes $chan
                }
                if {[shellIdo $chan]} {
                    checkMasks $chan
                }
            } else {
                getop $N $chan
            }
        } else {
            join $chan
        }
    }
    after [expr {$temp(checktime) * 1000}] timeCheckModes
}
proc checkModes {chan} {
    global temp N
    set modestoadd "[strip $temp(chanflags_virtual) [strip [lindex $temp(mode:$chan) 0] $temp(chanmode:$chan)] ]"
    set modestorem "[strip $temp(chanmode:$chan) [lindex $temp(mode:$chan) 0]]"
    set keymode 0
    if {[havechar $modestoadd k]} {
        if {![info exists temp(key:$chan)]} {
            set modestoadd "[strip k $modestoadd]"
        } else {
            lappend modestoadd "$temp(key:$chan)"
        }
    }
    if {[havechar $modestorem k]} {
        if {![info exists temp(ckey:$chan)]} {
            set modestorem "[strip k $modestorem]"
        } else {
            lappend modestorem "$temp(ckey:$chan)"
        }
    }
    if {[havechar $modestorem l]} {
        lappend modestoadd [expr {$temp(users:$chan) + 5}]
    }
    if {[havechar $temp(mode:$chan) k] && [havechar $temp(chanmode:$chan) k]} {
        if {[info exists temp(key:$chan)] && [info exists temp(ckey:$chan)]} {
            if {"$temp(key:$chan)" != "$temp(ckey:$chan)"} {
                append modestorem "k"
                lappend modestorem "$temp(ckey:$chan)"
                set keymode 1
            }
        }
    }
    if {[llength $modestoadd] > 0 || [llength $modestorem] > 0} {
        quote "mode $chan +[lindex $modestoadd 0]-[lindex $modestorem 0] [lrange $modestoadd 1 end] [lrange $modestorem 1 end]"
        if {$keymode} {
            mode $chan +k $temp(key:$chan)
        }
    }
}
proc checkMasks {chan} {
    global N temp
    onBans $chan {
        if {![info exists temp(ban:$3)]} {
            set temp(ban:$3) ""
        }
        foreach md "b e I" {
            set temp(modestoset:$md) ""
            set temp(listtoset:$md) ""
            set temp(modestounset:$md) ""
            set temp(listtounset:$md) ""
        }
        if {![havechar $temp(chanmode:$3) u]} {
            foreach b "$temp(ban:$3)" {
                if {[lsearch -exact "$temp($3:bans)" $b] == -1} {
                    lappend temp(modestoset:b) "+b"
                    lappend temp(listtoset:b) "$b"
                }
            }
        }
        foreach b "$temp($3:bans)" {
            if {[haveflag [isuser2 $b] x] || [string match $b $N!$temp(myIP)] || [string match $b $N!$temp(myhost)]} {
                lappend temp(modestoset:b) "-b"
                lappend temp(listtoset:b) "$b"
            }
        }
        if {![havechar $temp(chanmode:$3) u]} {
            mode $3 +I
        } else {
            set clist 0
            foreach {ch1 ch2 ch3} "$temp(modestoset:b)" {
                set chg($clist) "$ch1$ch2$ch3 [lrange $temp(listtoset:b) 0 2]"
                set temp(listtoset:b) "[lrange $temp(listtoset:b) 3 end]"
                incr clist
            }
            foreach2 cl chg * {
                mode $3 $chg($cl)
                unset chg($cl)
            }
        }
    }
    if {![havechar $temp(chanmode:$chan) u]} {
        OnInvites $chan {
            if {![info exists temp(inv:$3)]} {
                set temp(inv:$3) ""
            }
            foreach i "$temp(inv:$3)" {
                if {[lsearch -exact "$temp($3:invs)" $i] == -1} {
                    lappend temp(modestoset:I) "+I"
                    lappend temp(listtoset:I) "$i"
                }
            }
            mode $3 +e
        }
        OnExempts $chan {
            if {![info exists temp(ex:$3)]} {
                set temp(ex:$3) ""
            }
            foreach e "$temp(ex:$3)" {
                if {[lsearch -exact "$temp($3:excs)" $e] == -1} {
                    lappend temp(modestoset:e) "+e"
                    lappend temp(listtoset:e) "$e"
                }
            }
            foreach md "b I e" {
                set clist 0
                foreach {ch1 ch2 ch3} "$temp(modestoset:$md)" {
                    set chg($clist) "$ch1$ch2$ch3 [lrange $temp(listtoset:$md) 0 2]"
                    set temp(listtoset:$md) "[lrange $temp(listtoset:$md) 3 end]"
                    incr clist
                }
                foreach2 cl chg * {
                    mode $3 $chg($cl)
                    unset chg($cl)
                }
            }
        }
    }
}
timeCheckModes

# Timer
proc 0if0 {arg} {
    if {"$arg" != ""} {
        return $arg
    } else {
        return 0
    }
}
proc TIMER {} {
    global temp
    set TIME [clock format [clock seconds] -format %H:%M]
    foreach2 act temp timer-* {
        if {[string match [lindex [split $act -] 1] $TIME]} {
            eval $temp($act)
        }
    }
    after [expr {1000 * [expr {60 - [0if0 [string trimleft [clock format [clock seconds] -format %S] 0]]}]}] TIMER
}
proc TIMER_init {} {
    after [expr {1000 * [expr {60 - [0if0 [string trimleft [clock format [clock seconds] -format %S] 0]]}]}] TIMER
}
after 500 TIMER_init

proc timer {time cmd} {
    global temp
    if {"$time" == "-"} {
        foreach2 ident temp timer-$cmd-* {
            unset temp($ident)
        }
    } else {
        set ident 0
        while {[info exists temp(timer-$time-$ident)]} {
            incr ident
        }
        set temp(timer-$time-$ident) $cmd
    }
}
### Built-in cron :)
timer ??:?? {
    if {[lsearch "0 2 4 6 8" [string index $TIME 4]] > -1} {
        if {[llength $temp(linklist)] > 0} {
            foreach bot "$temp(linklist)" {
                if {![islink $bot]} {
                    link2bot $bot
                }
            }
        }
    }
}
timer 00:01 {
    lecho "%c[ts {Daily saving lists and config...}]"
    save.users
    save.bots
    save.chans
    lecho "%c[ts {Bot configuration has been saved.}]"
    save.config
    lecho "%c[ts {All lists has been saved.}]"
}


# Chars which describes irc users.
set temp(status_hierarchy:*) 4
set temp(status_hierarchy:@) 3
set temp(status_hierarchy:%) 2
set temp(status_hierarchy:+) 1
set temp(status_hierarchy:\ ) -1
set temp(status_hierarchy:H) 0
set temp(status_hierarchy:G) 0
proc whochar {arg} {
    global temp
    set i 0
    set char " "
    while {[string index $arg $i] != ""} {
        if {$temp(status_hierarchy:[string index $arg $i]) > $temp(status_hierarchy:$char)} {
            set char "[string index $arg $i]"
        }
        incr i
    }
    return $char
}
proc chUserStatus {chan who sgn char} {
    global temp
    if {[info exists temp(chars:$chan:$who)]} {
        if {"$sgn" == "+"} {
            if {![havechar $temp(chars:$chan:$who) $char]} {
                append temp(chars:$chan:$who) $char
            }
        } else {
            if {[havechar $temp(chars:$chan:$who) $char]} {
                set temp(chars:$chan:$who) [strip $char $temp(chars:$chan:$who)]
            }
        }
    }
}
# Described in docs/scripting
proc getStuffReset {what} {
    global temp
    set temp($what:cnt) 0
}
proc getStuff {what} {
    global temp
    if {[info exists temp($what)]} {
        if {![info exists temp($what:cnt)]} {
            set temp($what:cnt) 0
        }
        if {[lindex "$temp($what)" $temp($what:cnt)] != ""} {
            set ret [lindex "$temp($what)" $temp($what:cnt)]
        } else {
            set temp($what:cnt) 0
            set ret [lindex "$temp($what)" $temp($what:cnt)]
        }
        incr temp($what:cnt)
        return "$ret"
    } else {
        return ""
    }
}
proc getStuff2 {what} {
    global temp
    if {[info exists temp($what)]} {
        if {![info exists temp($what:cnt)]} {
            set temp($what:cnt) 0
        }
        if {[lindex "$temp($what)" $temp($what:cnt)] != ""} {
            set ret [lindex "$temp($what)" $temp($what:cnt)]
        } else {
            set temp($what:cnt) -1
            set ret ""
        }
        incr temp($what:cnt)
        return "$ret"
    } else {
        return ""
    }
}
# When somthing is going really bad.
proc force_error {msg} {
    puts "(!) $msg"
    exit 1
}
# Bot knows mode for channel without asking about it, becouse of that:
proc upStatus {sw chan args} {
    global temp
    switch $sw {
        modes {
            set args "[eval concat $args]"
            set temp(mode:$chan) "[sort [string range [lindex $args 0] 1 end]]"
            if {[havechar $temp(mode:$chan) l]} {
                if {[havechar $temp(mode:$chan) k]} {
                    set temp(climit:$chan) [lindex $args 1]
                    set temp(ckey:$chan) [lindex $args 2]
                } else {
                    set temp(climit:$chan) [lindex $args 1]
                }
            } elseif {[havechar $temp(mode:$chan) k]} {
                set temp(ckey:$chan) [lindex $args 1]
            }
        }
        chmode {
            set modes [lindex $args 0]
            if {[info exists temp(mode:$chan)]} {
                set cmode $temp(mode:$chan)
            } else {
                set cmode ""
            }
            set modem ""
            set carg 0
            for {set m 0} {[string index $modes $m] != ""} {incr m} {
                set mm [string index $modes $m]
                switch -- $mm {
                    + {
                        set ch $mm
                    }
                    - {
                        set ch $mm
                    }
                    default {
                        if {$ch == "+"} {
                            append cmode $mm
                        } else {
                            append modem $mm
                        }
                    }
                }
            }
            if {$modem != ""} {
                set cmode [sort [strip $modem $cmode]]
            } else {
                set cmode [sort $cmode]
            }
            set temp(mode:$chan) "$cmode"
        }
        topic {
            set args "[eval concat $args]"
            set temp(topic:$chan) "$args"
        }
        topicby {
            set args "[eval concat $args]"
            set temp(topic_set_by:$chan) "$args"
        }
        topicat {
            set args "[eval concat $args]"
            set temp(topic_set_at:$chan) "$args"
        }
    }
}
# Checking for collide flags while changing attributes.
proc collideflags {flags} {
    global temp
    if {[havechar $temp(friendflags) [split [string index $flags 0] {}]]} {
        if {[havechars $flags [split $temp(enemyflags) {}]]} {
            return 1
        } else {
            return 0
        }
    } else {
        if {[havechars $flags [split $temp(friendflags) {}]]} {
            return 1
        } else {
            return 0
        }
    }
}
proc correctMainFlags {flags} {
    if {[havechar $flags r]} {
        return [strip nmu $flags]
    } elseif {[havechar $flags n]} {
        return [strip mu $flags]
    } elseif {[havechar $flags m]} {
        return [strip u $flags]
    } else {
        return $flags
    }
}
proc flags {{0 {}} {1 {}} {2 {}}} {
    getglob
    upvar _ _
    if {"$0" != ""} {
        if {"$2" != ""} {
            set user "$0"
            set chan "[string tolower $1]"
            set F "$2"
            set 0 "$user:$chan"
            if {[lsearch {# ! &} [string index $chan 0]] == -1} {
                mecho $_ "[ts {%Y%0%y is not valid channel name!} $chan]"
                set chan ""
            }
        } else {
            set user "$0"
            set chan ""
            set F "$1"
        }
        if {"[isuser3 $user user]" != ""} {
            if {"$F" != ""} {
                if {![haveflags $user !] || "[bestflag $_]" == "r"} {
                    if {[canChange $_ $user]} {
                        if {[lsearch {= + -} [string index $F 0]] > -1} {
                            if {"[string index $F 0]" == "="} {
                                set rights "$temp(allowflags:[bestflag $_])"
                                set badflags "[strip \"$rights\=\" $F]"
                                set F "[strip $badflags $F]"
                                if {"$badflags" != ""} {
                                    mecho $_ "%y[ts {Flags %Y%0%y are not valid.} $badflags]"
                                }
                                if {![collideflags [string range $F 1 end]]} {
                                    set flags($0) "[sort [correctMainFlags [string range $F 1 end]]]"
                                    if {"$chan" != ""} {
                                        mecho $_ "%c[ts {Now %C%0%c has got following flags on %C%1%c:} $user $chan] +%C$flags($0)"
                                    } else {
                                        mecho $_ "%c[ts {Now %C%0%c has got following flags:} $user] +%C$flags($user)"
                                    }
                                } else {
                                    mecho $_ "%y[ts {Flags %Y%0%y collides with itself. User can't got flags for enemy and friend at same time.} [string range $F 1 end]]"
                                }
                            } else {
                                set addflags ""
                                set remflags ""
                                set rights "$temp(allowflags:[bestflag $_])"
                                set badflags "[strip \"$rights\+-\" $F]"
                                if {"$badflags" != ""} {
                                    set F "[strip $badflags $F]"
                                }
                                for {set cf 0} {"[string index $F $cf]" != ""} {incr cf} {
                                    switch -- [string index $F $cf] {
                                        + {
                                            set fchar +
                                        }
                                        - {
                                            set fchar -
                                        }
                                        default {
                                            if {"$fchar" == "+"} {
                                                append addflags "[string index $F $cf]"
                                            } else {
                                                append remflags "[string index $F $cf]"
                                            }
                                        }
                                    }
                                }
                                if {![collideflags $addflags]} {
                                    if {![collideflags $addflags[strip $remflags $flags($0)]]} {
                                        append flags($0) "$addflags"
                                        set flags($0) "[sort -unique [correctMainFlags [strip $remflags $flags($0)]]]"
                                        if {"$chan" != ""} {
                                            mecho $_ "%c[ts {Now %C%0%c has got following flags on %C%1%c:} $user $chan] +%C$flags($0)"
                                            if {"$flags($0)" == ""} {
                                                unset flags($0)
                                            }
                                        } else {
                                            mecho $_ "%c[ts {Now %C%0%c has got following flags:} $user] +%C$flags($0)"
                                        }
                                    } else {
                                        mecho $_ "%y[ts {Flags %Y%0%y collides with %Y%1%y. User can't got flags for enemy and friend at same time.} $addflags $flags($0)]"
                                    }
                                } else {
                                    mecho $_ "%y[ts {Flags %Y%0%y collides with itself. User can't got flags for enemy and friend at same time.} $addflags]"
                                }
                            }
                        } else {
                            syntax $_ {flags <user> [<channel>] [+/-/=<flags>]}
                        }
                    } else {
                        mecho $_ "%y[ts {You can do no changes for %Y%0%y.} $0]"
                    }
                } else {
                    mecho $_ "%y[ts {User %Y%0%y is immune (+!).} $0]"
                }
            } else {
                if {"$chan" != ""} {
                    if {[info exists flags($0)]} {
                        mecho $_ "[ts {%C%0%c has got following flags on %C%1%c:} [string totitle $user] $chan] +%C$flags($0)"
                    } else {
                        mecho $_ "[ts {%C%0%c has got no flags on %C%1%c.} [string totitle $user] $chan]"
                    }
                } else {
                    mecho $_ "[ts {%C%0%c has got following flags:} [string totitle $user]] +%C$flags($user)"
                }
            }
        } else {
            mecho $_ "%y[ts {Unknown user}] %Y$0%y."
        }
    } else {
        syntax $_ {flags <user> [<channel>] [+/-/=<flags>]}
    }
}
proc botattr {{0 {}} {1 {}}} {
    getglob
    upvar _ _
    if {"$0" != ""} {
        if {"[isuser3 $0]" != ""} {
            if {"$1" != ""} {
                if {[lsearch {= + -} [string index $1 0]] > -1} {
                    if {"[string index $1 0]" == "="} {
                        set badflags "[strip \"$temp(botflags)=\" $1]"
                        set 1 "[strip $badflags $1]"
                        if {"$badflags" != ""} {
                            mecho $_ "%C[ts {Flags %0 are not valid.} $badflags]"
                        }
                        set botflags($0) "[sort [string range $1 1 end]]"
                        mecho $_ "%c[ts {Now %C%0%c has got following botflags:} $0] +%C$botflags($0)"
                    } else {
                        set addflags ""
                        set remflags ""
                        set badflags "[strip \"$temp(botflags)+-\" $1]"
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
                                        append addflags "[string index $1 $cf]"
                                    } else {
                                        append remflags "[string index $1 $cf]"
                                    }
                                }
                            }
                        }
                        append botflags($0) "$addflags"
                        set botflags($0) "[sort -unique [strip $remflags $botflags($0)]]"
                        mecho $_ "%c[ts {Now %C%0%c has got following botflags:} $0] +%C$botflags($0)"
                    }
                } else {
                    syntax $_ {botflags <bot> [+/-/=<flags>]}
                }
            } else {
                mecho $_ "[ts {%C%0%c has got following flags:} [string totitle $0]] +%C$flags($0)"
            }
        } else {
            mecho $_ "%y[ts {Unknown bot %Y%0%y.} $0]"
        }
    } else {
        syntax $_ {botflags <bot> [+/-/=<flags>]}
    }
}
proc chanAccess {chan who type} {
    upvar bot bot
    switch $type {
        i {
            global N
            if {[isop $N $chan] && [shellIdo $chan]} {
                invite $who $chan
            }
        }
        e {
            global N
            if {[isop $N $chan] && [shellIdo $chan]} {
                mode $chan +ee [lindex [split $who #] 1] [lindex [split $who #] 2]
                bot2 [lindex [split $who #] 0] "join $chan"
            }
        }
        k {
            global temp
            if {[info exists temp(ckey:$chan)]} {
                bot2 [lindex [split $who #] 0] "join $chan $temp(ckey:$chan)"
            }
        }
    }
}
proc link2bot {0} {
    upvar _ _ temp temp
    if {[isbot $0]} {
        if {[info exists temp(botaddress:$0)]} {
            if {[info exists temp(botport:$0)]} {
                if {![islink $0]} {
                    connToBot $0 $temp(botaddress:$0) [lindex [split $temp(botport:$0) /] 0]
                } else {
                    mecho $_ "[botspeak] %y[ts {I'm already linked with bot %Y%0%y.} $0]"
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
}
proc addlink {bots} {
    upvar _ _ temp temp
    set list ""
    foreach bot "$bots" {
        if {[isbot $bot]} {
            lappend list $bot
        } else {
            mecho $_ "[ts {%Y%0%y is not bot.} $bot]"
        }
    }
    if {[llength $list] > 0} {
        lappend temp(linklist) "$list"
    }
    mecho $_ "%c[ts {Adding following bots to link list:}] %C$list"
}
proc remlink {bots} {
    upvar _ _ temp temp
    foreach bot "$bots" {
        set temp(linklist) "[npattern $temp(linklist) $bot]"
    }
    mecho $_ "%c[ts {Removing following bots from link list:}] %C$bots"
}
proc setlinks {} {
    global temp
    foreach bt "$temp(botsonline)" {
        if {"$temp(botflag:$bt)" < "$temp(netflag)"} {
            set temp(linklist) "$bt"
        }
    }
    lecho "%c[ts {Link list has been rehashed.}]"
}
### Lists
proc c2s {args} {
    if {"$args" == ""} {
        return "{}"
    } else {
        return "$args"
    }
}
proc save.users {} {
    getglob
    file delete -force [file join lists $temp(botname) users.list]
    set fd [open [file join lists $temp(botname) users.list] a+]
    foreach user "$userlist" {
        puts $fd "{$user} {$password($user)} {$flags($user)} {$userhost($user)}"
        foreach2 cf flags $user:* {
            if {"$flags($cf)" != ""} {
                puts $fd "+ $cf $flags($cf)"
            }
        }
        foreach2 x temp extra:*:$user {
            if {"$temp($x)" != ""} {
                puts $fd "! $x $temp($x)"
            }
        }
    }
    close $fd
}
proc save.bots {} {
    getglob
    file delete -force [file join lists $temp(botname) bots.list]
    set fd [open [file join lists $temp(botname) bots.list] a+]
    puts $fd "$temp(linklist)"
    foreach bot "$botlist" {
        puts $fd "{$bot} {$botflags($bot)} {$flags($bot)} {$temp(botaddress:$bot)} {$temp(botport:$bot)} {$userhost($bot)}"
    }
    close $fd
}
proc save.chans {} {
    global temp
    file delete -force [file join lists $temp(botname) chans.list]
    set fd [open [file join lists $temp(botname) chans.list] a+]
    foreach chan "$temp(chanlist)" {
        puts $fd "{$chan} {$temp(chanmode:$chan)}"
    }
    close $fd
}
set temp(vars_to_save) "loginstring passstring nick othernicks botname netflag netpass uport bport logo checktime bankick pubchar nickchar makelog public:sensor nick:sensor join:sensor pubflood_sensor nickflood_sensor joinflood_sensor kickreason vhost loadhelp username logmode encoding locale"
proc save.config {} {
    getglob
    file delete -force [file join config $temp(botname).conf]
    set fd [open [file join config $temp(botname).conf] a+]
    foreach sett "$temp(vars_to_save)" {
        puts $fd "set $sett $temp($sett)"
    }
    foreach serv "$temp(servlist)" {
        puts $fd "server $serv"
    }
    foreach scr "$temp(scripts)" {
        puts $fd "script $scr"
    }
    close $fd
}
proc load.users {} {
    getglob
    if {[file exists [file join lists $temp(botname) users.list]]} {
        set fd [open [file join lists $temp(botname) users.list] r]
        while {![eof $fd]} {
            gets $fd data
            if {[llength "$data"] > 0} {
                if {"[lindex $data 0]" == "+"} {
                    set flags([lindex $data 1]) "[lindex $data 2]"
                } elseif {"[lindex $data 0]" == "!"} {
                    set temp([lindex $data 1]) "[lindex $data 2]"
                } else {
                    lappend userlist "[lindex $data 0]"
                    set password([lindex $data 0]) "[lindex $data 1]"
                    set flags([lindex $data 0]) "[lindex $data 2]"
                    set userhost([lindex $data 0]) "[eval concat [lrange $data 3 end]]"
                }
            }
        }
        close $fd
    }
}
proc load.bots {} {
    getglob
    if {[file exists [file join lists $temp(botname) bots.list]]} {
        set fd [open [file join lists $temp(botname) bots.list] r]
        gets $fd temp(linklist)
        while {![eof $fd]} {
            gets $fd data
            if {[llength "$data"] > 0} {
                    lappend botlist "[lindex $data 0]"
                    set botflags([lindex $data 0]) "[lindex $data 1]"
                    set flags([lindex $data 0]) "[lindex $data 2]"
                    set temp(botaddress:[lindex $data 0]) "[lindex $data 3]"
                    set temp(botport:[lindex $data 0]) "[lindex $data 4]"
                    set userhost([lindex $data 0]) "[eval concat [lrange $data 5 end]]"
            }
        }
        close $fd
    }
}
proc load.chans {} {
    getglob
    if {[file exists [file join lists $temp(botname) chans.list]]} {
        set fd [open [file join lists $temp(botname) chans.list] r]
        while {![eof $fd]} {
            gets $fd data
            if {[llength "$data"] > 0} {
                lappend temp(chanlist) "[lindex $data 0]"
                set temp(chanmode:[lindex $data 0]) "[lindex $data 1]"
            }
        }
        close $fd
    }
}
### IRC Protocol commands
proc op {chan args} {
    global N
    set args "[eval concat $args]"
    if {[isop $N $chan]} {
        queue -friendop $chan [lrange $args 0 2]
        if {"[lindex $args 3]" != ""} {
            op $chan [lrange $args 3 end]
        }
    }
}
proc deop {chan args} {
    global N
    if {[isop $N $chan]} {
        queue -fast "mode $chan -ooo [lrange $args 0 2]"
        if {"[lindex $args 3]" != ""} {
            deop $chan [lrange $args 3 end]
        }
    }
}
proc mkick {chan args} {
    global N temp
    set args "[eval concat $args]"
    if {[isop $N $chan]} {
        queue -kick $chan $args
    }
}
proc kick {chan nick {reason {}}} {
    global N
    if {[isop $N $chan]} {
        if {"$reason" != ""} {
            queue -fast "kick $chan $nick :$reason"
        } else {
            queue -fast "kick $chan $nick :$temp(kickreason)"
        }
    }
}
proc vop {chan args} {
    global N
    set args "[eval concat $args]"
    if {[isop $N $chan]} {
        queue "mode $chan +vvv [lrange $args 0 2]"
        if {"[lindex $args 2]" != ""} {
            vop $chan [lrange $args 3 end]
        }
    }
}
proc devop {chan args} {
    global N
    if {[isop $N $chan]} {
        queue "mode $chan -vvv [lrange $args 0 2]"
        if {"[lindex $args 2]" != ""} {
            devop $chan [lrange $args 3 end]
        }
    }
}
proc hop {chan arg} {
    global N
    if {[isop $N $chan]} {
        queue -fast "mode $chan +hhh [lrange $args 0 2]"
        if {"[lindex $args 3]" != ""} {
            deop $chan [lrange $args 3 end]
        }
    }
}
proc dehop {chan args} {
    global N
    if {[isop $N $chan]} {
        queue -fast "mode $chan -hhh [lrange $args 0 2]"
        if {"[lindex $args 3]" != ""} {
            deop $chan [lrange $args 3 end]
        }
    }
}

proc join {chanlist {key {}}} {
    queue "join [sjoin $chanlist ,] $key"
}
proc part {chanlist {reason {}}} {
    queue "part [sjoin $chanlist ,] :$reason"
}
proc leave {chanlist {reason {}}} {
    queue "part [sjoin $chanlist ,] :$reason"
}
proc msg {nick msg} {
    queue "privmsg $nick :$msg"
}
proc say {nick msg} {
    queue "privmsg $nick :$msg"
}
proc notice {nick msg} {
    queue "notice $nick :$msg"
}
proc ctcp {nick type {msg {}}} {
    queue "privmsg $nick :\x01$type $msg\x01"
}
proc rctcp {nick type {msg {}}} {
    queue "notice $nick :\x01$type $msg\x01"
}
proc mode {chan chg args} {
    global N
    if {[isop $N $chan]} {
        queue -fast "[eval concat mode $chan $chg $args]"
    }
}
proc topic {chan {topic {}}} {
    if {$topic != ""} {
        if {[isop $N $chan]} {
            queue "topic $chan $topic"
        }
    } else {
        return $temp(topic:$chan)
    }
}
proc Invite {chan nick} {
    queue -fast "invite $nick $chan"
}
proc nick {newnick} {
    global N
    if {[amconn] && "$N" != "$newnick"} {
        queue "nick $newnick"
    }
}
proc massmode {chan sgn char args} {
    global N
    set args "[eval concat $args]"
    if {[isop $N $chan]} {
        queue -fast "mode $chan $sgn$char$char$char [lrange $args 0 3]"
        if {"[lindex $args 4]" != ""} {
            massmode $chan $sgn $char [lrange $args 4 end]
        }
    }
}
proc away {{reason {}}} {
    if {[amconn]} {
        queue "away $reason"
    }
}
proc seta {reason} {
    away $reason
}
proc una {} {
    away
}
proc autoaway {server} {
    global temp
    if {"$temp(server)" == "$server"} {
        away [randcrap 5]
    }
}
proc ban {chan list} {
    if {[string match *!*@* [lindex $list 0]]} {
        massmode $chan + b $list
    } else {
        set maskstoban ""
        foreach nick "$list" {
            lappend maskstoban *![host $nick]
        }
        if {"$maskstoban" != ""} {
            massmode $chan + b $maskstoban
            mkick $chan $list
        }
    }
}
proc unban {chan list} {
    if {[string match *!*@* [lindex $list 0]]} {
        massmode $chan - b $list
    } else {
        set maskstounban ""
        foreach nick "$list" {
            lappend maskstounban $nick![host $nick]
        }
        if {"$maskstounban" != ""} {
            onBans $0 "
                set maskstounban2 \"\"
                foreach mask \"\$temp($0:bans)\" {
                    if {\[lmatch $maskstounban \$mask\]} {
                        lappend maskstounban2 \$mask
                    }
                }
                if {\"\$maskstounban2\" != \"\"} {
                    massmode $chan - b \$maskstounban2
                }
            "
        }
    }
}
proc timeban {chan trg time} {
    if {[string match *!*@* $trg]} {
        mode $chan +b $trg
        after [expr {[reconvTime $time] * 1000}] mode $chan -b $trg
    } else {
        set mask *![host $trg]
        mode $chan +b $mask
        kick $chan $trg
        after [expr {[reconvTime $time] * 1000}] mode $chan -b $mask
    }
}
proc exempt {chan list} {
    if {[string match *!*@* [lindex $list 0]]} {
        massmode $chan + e $list
    } else {
        set maskstoban ""
        foreach nick "$list" {
            lappend maskstoban *![host $nick]
        }
        if {"$maskstoban" != ""} {
            massmode $chan + e $maskstoban
            mkick $chan $list
        }
    }
}
proc unexempt {chan list} {
    if {[string match *!*@* [lindex $list 0]]} {
        massmode $chan - e $list
    } else {
        set maskstounban ""
        foreach nick "$list" {
            lappend maskstounban $nick![host $nick]
        }
        if {"$maskstounban" != ""} {
            onExempts $0 "
                set maskstounban2 \"\"
                foreach mask \"\$temp($0:excs)\" {
                    if {\[lmatch $maskstounban \$mask\]} {
                        lappend maskstounban2 \$mask
                    }
                }
                if {\"\$maskstounban2\" != \"\"} {
                    massmode $chan - e \$maskstounban2
                }
            "
        }
    }
}
proc invite {chan list} {
    if {[string match *!*@* [lindex $list 0]]} {
        massmode $chan + I $list
    } else {
        set maskstoban ""
        foreach nick "$list" {
            lappend maskstoban *![host $nick]
        }
        if {"$maskstoban" != ""} {
            massmode $chan + I $maskstoban
        }
    }
}
proc uninvite {chan list} {
    if {[string match *!*@* [lindex $list 0]]} {
        massmode $chan - I $list
    } else {
        set maskstounban ""
        foreach nick "$list" {
            lappend maskstounban $nick![host $nick]
        }
        if {"$maskstounban" != ""} {
            onInvites $0 "
                set maskstounban2 \"\"
                foreach mask \"\$temp($0:invs)\" {
                    if {\[lmatch $maskstounban \$mask\]} {
                        lappend maskstounban2 \$mask
                    }
                }
                if {\"\$maskstounban2\" != \"\"} {
                    massmode $chan - I \$maskstounban2
                }
            "
        }
    }
}
proc botop {chan list} {
    queue -botop $chan "$list"
}
### Flood protection
proc checkFlood {nick host type chan} {
    global flood temp N
    if {"[string tolower $temp($type:sensor)]" == "on" && "$nick" != "$N" && ![haveflag [isuser2 $nick!$host] f]} {
        if {"$type" == "nick"} {
            set patt "$host:nick:$chan"
        } else {
            set patt "$nick:$host:$type:$chan"
        }
        if {[info exists flood($patt)]} {
            incr flood($patt)
        } else {
            set flood($patt) 1
        }
        after 10000 remFlood $patt
        switch $type {
            public {
                if {$flood($patt) > $temp(pubflood_sensor)} {
                    kick $chan $nick "*Public flood*"
                }
            }
            nick {
                if {$flood($patt) > $temp(nickflood_sensor)} {
                    kick $chan $nick "*Nick flood*"
                }
            }
            join {
                if {$flood($patt) > $temp(joinflood_sensor)} {
                    mode $chan +b *!$host
                    after 15000 mode $chan -b *!$host
                    kick $chan $nick "*Join flood*"
                }
            }
        }
    }
}
proc remFlood {patt} {
    global flood
    incr flood($patt) -1
    if {$flood($patt) == 0} {
        unset flood($patt)
    }
}

### Loging engine
proc log {target str} {
    global temp
    if {[info exists temp(chanmode:$target)]} {
        if {[havechar $temp(chanmode:$target) L]} {
            set date "[clock format [clock seconds] -format %m.%d.%y]"
            set fd [open [file join log $temp(botname) ${target}_$date.log] a+]
            switch $temp(logmode) {
                giana {
                    puts -nonewline $fd "\[[clock format [clock seconds] -format %T]\] "
                    puts $fd [sjoin $str]
                }
                eggdrop {
                    puts $fd [sjoin $str]
                }
                epic {
                    puts $fd [sjoin $str]
                }
            }
            close $fd
        }
    }
}
proc LOG {str} {
    global  temp
    if {"[string tolower $temp(makelog)]" == "on"} {
        set fd [open [file join log $temp(botname) main.log] a+]
        puts $fd "\[[clock format [clock seconds] -format (%m.%d.%y)\ %T]\] $str"
        close $fd
    }
}
# If personal log directory doesn't exists, then create it.
if {![file isdirectory [file join log $temp(botname)]]} {
    file mkdir [file join log $temp(botname)]
}


### GETOP
proc getop {nick chan} {
    global temp
    if {[isBotNet] && !$temp(getop_in_progress)} {
        Bots2 "getOp $nick $chan"
        set temp(getop_in_progress) 1
        after 3000 set temp(getop_in_progress) 0
    }
}
proc getOp {nick chan} {
    global N
    upvar bot bot
    if {[isop $N $chan]} {
#        botop $chan $nick
    } else {
        Bots2 "getOp $nick $chan" $bot
    }
}

### ReOp
proc checkOP {chan} {
    global temp botlist N
    if {[llength [getchannel $chan ops]] == 0 && [getchannel $chan known]} {
        set ok 1
        foreach nick "[npattern $temp(onchannel:$chan) $N]" {
            if {[lsearch $botlist [isuser2 $nick![host $nick]]] == -1} {
                set ok 0
            }
        }
        if {$ok} {
            part $chan
            after 5000 "join $chan"
        }
    }
}

### Queuing engine
set temp(queue) 0
set temp(queue-time) 1200
proc execQueue {} {
    global temp
    if {$temp(queue) < 5} {
        if {[info exists temp(queue:opbots)]} {
            set list 0
            foreach l "$temp(queue:opbots)" {
                if {![info exists chan]} {
                    set chan [lindex $l 0]
                }
                if {[lindex $l 0] == $chan} {
                    eval lappend nicks [lrange $l 1 end]
                    set temp(queue:opbots) [lremove $temp(queue:opbots) $list]
                } else {
                    incr list
                }
            }
            set nicks [uniq $nicks]
            set toop [eval concat [lrange $nicks 0 2]]
            if {[llength $toop] > 0} {
                quote "mode $chan +ooo $toop"
                incr temp(queue)
                after $temp(queue-time) incr temp(queue) -1
            }
            set rest [lrange $nicks 3 end]
            if {[llength $rest] > 0} {
                lappend temp(queue:opbots) "$chan $rest"
            }
            if {[llength $temp(queue:opbots)] == 0} {
                unset temp(queue:opbots)
            }
        } elseif {[info exists temp(queue:kicks)]} {
            set list 0
            foreach l "$temp(queue:kicks)" {
                if {![info exists chan]} {
                    set chan [lindex $l 0]
                }
                if {[lindex $l 0] == $chan} {
                    eval lappend nicks [lrange $l 1 end]
                    set temp(queue:kicks) [lremove $temp(queue:kicks) $list]
                } else {
                    incr list
                }
            }
            set nicks [uniq $nicks]
            set tokick [sjoin [eval concat [lrange $nicks 0 3]] ,]
            if {[llength $tokick] > 0} {
                quote "kick $chan $tokick :$temp(kickreason)"
                incr temp(queue)
                after $temp(queue-time) incr temp(queue) -1
            }
            set rest [lrange $nicks 3 end]
            if {[llength $rest] > 0} {
                lappend temp(queue:kicks) "$chan $rest"
            }
            if {[llength $temp(queue:kicks)] == 0} {
                unset temp(queue:kicks)
            }
        } elseif {[info exists temp(queue:opfriends)]} {
            set list 0
            foreach l "$temp(queue:opfriends)" {
                if {![info exists chan]} {
                    set chan [lindex $l 0]
                }
                if {[lindex $l 0] == $chan} {
                    eval lappend nicks [lrange $l 1 end]
                    set temp(queue:opfriends) [lremove $temp(queue:opfriends) $list]
                } else {
                    incr list
                }
            }
            set nicks [uniq $nicks]
            set toop [eval concat [lrange $nicks 0 2]]
            if {[llength $toop] > 0} {
                quote "mode $chan +ooo $toop"
                after $temp(queue-time) incr temp(queue) -1
                incr temp(queue)
            }
            set rest [lrange $nicks 3 end]
            if {[llength $rest] > 0} {
                lappend temp(queue:opfriends) "$chan $rest"
            }
            if {[llength $temp(queue:opfriends)] == 0} {
                unset temp(queue:opfriends)
            }
        } elseif {[info exists temp(queue:msgs-fast)]} {
            quote [lindex $temp(queue:msgs-fast) 0]
            incr temp(queue)
            after $temp(queue-time) incr temp(queue) -1
            if {[lindex $temp(queue:msgs-fast) 1] != ""} {
                set temp(queue:msgs-fast) [lrange $temp(queue:msgs-fast) 1 end]
            } else {
                unset temp(queue:msgs-fast)
            }
        } elseif {[info exists temp(queue:msgs)]} {
            quote [lindex $temp(queue:msgs) 0]
            incr temp(queue)
            after $temp(queue-time) incr temp(queue) -1
            if {[lindex $temp(queue:msgs) 1] != ""} {
                set temp(queue:msgs) [lrange $temp(queue:msgs) 1 end]
            } else {
                unset temp(queue:msgs)
            }
        }
    }
    after $temp(queue_delay) execQueue
}
after 1000 execQueue
proc queue {args} {
    global temp
    switch -- [llength $args] {
        1 {
            lappend temp(queue:msgs) "[lindex $args 0]"
        }
        2 {
            switch -- [lindex $args 0] {
                -fast {
                    lappend temp(queue:msgs-fast) "[lindex $args 1]"
                }
            }
        }
        3 {
            switch -- [lindex $args 0] {
                -kick {
                    lappend temp(queue:kicks) "[lrange $args 1 2]"
                }
                -botop {
                    lappend temp(queue:opbots) "[lrange $args 1 2]"
                }
                -friendop {
                    lappend temp(queue:opfriends) "[lrange $args 1 2]"
                }
            }
        }
        default {
            error "wrong # args: queue ?-kick channel? ?-botop channel? ?-friendop channel? data"
        }
    }
}

### Finishing
set temp(links:$temp(botname)) ""
# Getting local IP
if {"$temp(vhost)" != ""} {
    set iphost $temp(vhost)
} else {
    set iphost [info hostname]
}
set ipsock ""
while {[llength "$ipsock"] != 1} {
    catch {socket -server false -myaddr $iphost [rand 3000 50000]} ipsock
    if {"$ipsock" == "couldn't open socket: can't assign requested address"} {
        catch {socket -server flase [rand 3000 50000]} ipsock
    }
    if {[llength "$ipsock"] != 1} {
        switch -- [lrange $ipsock 3 end] {
            "host is unreachable" {
                # VHost doesn't exists
                if {"$iphost" == "$temp(vhost)"} {
                    puts "[ts {Given VHost doesn't work. Bot will use defaul hostname (%0).} [info hostname]]"
                    set iphost [info hostname]
                } else {
                    puts "[ts {Bot can't set up his socket with default hostname. Perahps network on this machine doesn't work.}]"
                }
            }
            "address already in use" {
                # Sock in use
            }
        }
    }
}
set temp(myIP) "[lindex [fconfigure $ipsock -sockname] 0]"
close $ipsock
unset ipsock
set temp(myHOST) $iphost
unset iphost
# Link to bots from links list
after 1000 {
    if {[llength $temp(linklist)] > 0} {
        foreach bot "$temp(linklist)" {
            link2bot $bot
        }
    }
}
# [404] Command not found :)
set cmdswitch "
    $cmdswitch
    default {mecho \$_ \"%y[ts {Unknown command '%0'. Type 'help' for get some help.} \$cmd]\"}
"

puts "\n[ts {Giana v%0 by Googie} $version]"
listen $temp(uport) users
listen $temp(bport) bots
puts "[ts {Hostname:         %0 (%1)} $temp(myHOST) $temp(myIP)]"
# Loads lists and refresh pid
foreach listprefix "users bots chans" {
    load.$listprefix
}
file delete -force [file join .run $temp(botname).pid]
proc PID {} {
    global temp
    if {![file exists [file join .run $temp(botname).pid]]} {
        set pid [open [file join .run $temp(botname).pid] a+]
        puts $pid "[pid]"
        close $pid
    }
    after 10000 PID
}
PID
puts "Bot:              $temp(botname)"
if {$temp(server_auto_connect)} {
    after 1000 first_randserver
}

### Load optional scripts:
set scriptfile ""
foreach file "$temp(scripts)" {
    if {"[string range $file end-3 end]" != ".tcl"} {
        append file .tcl
    }
    if {[file readable [file join scripts $file]]} {
        set scriptfile $file
        source [file join scripts $file]
        lappend temp(scripts-inside) "$file"
    } else {
        puts "[ts {File %0 doesn't exist. Remove this line from config.} $file]"
    }
}
unset scriptfile

# Now we can load eggdrop compatybility module.
if {"$temp(scripts-inside)" != ""} {
    source modules/EggTclPorting.tcl
}

# Set command rights for users
lappend temp(m-cmds) "$temp(u-cmds)"
lappend temp(n-cmds) "[eval concat $temp(m-cmds)]"
set temp(r-cmds) "$temp(n-cmds)"
foreach xx "m n r" {
    set temp($xx-cmds) "[eval concat $temp($xx-cmds)]"
}
foreach xx "u m n r" {
    set temp($xx-cmds) "[lsort $temp($xx-cmds)]"
}
### Channel real flags and users common flags:
set temp(chanflags_real) [strip $temp(chanflags_virtual) $temp(chanflags)]
set tmp [strip $temp(enemyflags) $temp(friendflags)]
set temp(users_common_flags) [strip $tmp $temp(friendflags)]

# Interactive mode
if {"$interactive" == "yes"} {
    mecho CONSOLE "%B[ts {Interactive Mode.}]"
}

### Thats all :)
vwait forever

