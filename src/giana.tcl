#!/bin/sh
# If you have 2 or more tcl distributions in your system
# and this script selects older, then you have to type
# a path to tclsh you want to use instead #!/usr/sh
# and remove 2 following lines:
# \
exec tclsh "$0" "$@"

### Variables section
# These variables will be accessed by getglob command:
set globals "cmdlist cmdswitch onswitch temp version tokick version N S H switch flags password userhost botlist userlist interactive botflags vw flood"

# Init some variables:
foreach x "cmdswitch cmdlist N S H userlist botlist flags()" {
    # Init some variables
    set $x ""
}
foreach x "botsonline loggedon chanlist myhost onchannel mymode server serversock scripts libs logo servlist linklist scripts-inside ON_bot utimers timers" {
    # ...and some arrays
    set temp($x) ""
}
set onswitch(0) ""
set version 2.0.0-beta3
set interactive no
set temp(connected) 0
set temp(getop_in_progress) 0
set temp(debug) 0
set temp(server_auto_connect) 1
set temp(uptime) [clock seconds]
set temp(queue_delay) 100

# Variables which can (but hasn't to) be changed in bot config
set temp(kickreason) "?"
set temp(kicktime) 750
set temp(optime) 1000
set temp(voptime) 3000
set temp(public:sensor) ON
set temp(nick:sensor) ON
set temp(join:sensor) ON
set temp(pubflood_sensor) 8
set temp(nickflood_sensor) 2
set temp(joinflood_sensor) 2
set temp(vhost) ""
set temp(makelog) ON
set temp(nickchar) .
set temp(checktime) 80
set temp(logo) logo1.txt
set temp(username) $env(USER)
set temp(server_op_protect) ON
set temp(loadhelp) "YES"
set temp(encoding) iso8859-2
set temp(logmode) giana

### Allowed users flags:
set temp(friendflags) Aaopfqumnri@!vcx
set temp(enemyflags) bds
# Rights for flags managing:
set temp(allowflags:u) ""
set temp(allowflags:m) $temp(allowflags:u)Aaopfu@vcxbds
set temp(allowflags:n) $temp(allowflags:m)Aaopfqumni@vcxbds
set temp(allowflags:r) $temp(friendflags)$temp(enemyflags)
# End of rights.
# Channel flags:
set temp(chanflags) ntimpsklbcfuFL
# Channel virtual flags:
set temp(chanflags_virtual) cbfuFL
# Default flags for new channel:
set temp(default_chan_flags) cFnt
# Bots flags:
set temp(botflags) 123456789ucbUCB

### Open null channel
set temp(null) [open /dev/null w]

### Fix current path
if {[info exists tcl_platform(isWrapped)]} {
    set argv0 ./giana
} else {
    cd [join [lrange [split $argv0 /] 0 end-1] /]
}

# Renaming join procedure, to define it as irc join command.
rename join sjoin

### Load first needed modules:
source [file join modules libterm.tcl]
source [file join modules locale.tcl]

### Locale
set temp(supported_translations) ""
foreach file "[glob -nocomplain -tails -directory po *.po]" {
    lappend temp(supported_translations) [lindex [split $file .] 0]
}
loadLocale po

# Help message
set globhelp "
[ts {Syntax: %0 [options] <bot>} $argv0]

[ts Options:]
    --kill, -k  - [ts {Kills given bot.}]
    -i          - [ts {Interactive mode. Console from standart input (keyboard).}]
    -c          - [ts {Connects with given bot.}]
    -m          - [ts {Displays memory usage for given bot.}]
    -l          - [ts {Lists bots found in config directory and notices if they are up or down.}]
    -f          - [ts {Interactive generating configuration file.}]
    -cf         - [ts {Runs editor and opens configuration file for given bot.}]
                  [ts {If pico is found, then it's used to edit, otherwise vi is used.}]
    --del       - [ts {Removes all files of given bot.}]
    -u          - [ts {Runs bot with given username.}]
    -H          - [ts {Runs bot with given virtual host.}]
    -C          - [ts {Installs given bot in crontab.}]
    -s          - [ts {Bot will not connect to a server upon startup.}]
    -d          - [ts {Debugging mode. Given debug level could be 0-2.}]
    --sockspy   - [ts {You will be able to see outgoing and incoming data from server.}]
    -r          - [ts {If you know that bot will got restriction, but you still want to run it.}]
    -L          - [ts {Runs bot with given translation. This version supports following translations:}] en, [sjoin $temp(supported_translations) ,\ ]
    -rd
    --readdebug - [ts {Shows debug log file of given bot.}]
    --checkhelp - [ts {Optional arguments are: file, locale. Script reads given (or default - commands.tcl) file}]
                  [ts {and checks if all aliases has got readable (for help.tcl module) help introductions}]
                  [ts {for given (or default - en) locale. If not, then reports them.}]
    --help, -h  - [ts {You're just reading this.}]
    -v          - [ts {Shows version.}]
"
if {$tcl_version < 8.4} {
    puts "[ts {TCL version is %0. It's too old. Giana requires at least 8.4.} $tcl_version]"
    if {"$tcl_platform(platform)" == "unix"} {
        puts "[ts {Used this tclsh:}] [exec which tclsh]"
    }
    puts "[ts {If you have 2 or more tcl distributions in system, you have to\nedit this file and read header for help.}]"
    puts ""
    puts "* [ts {Don't try to remove this from code. If TCL is too old\n  then there will be a lot of errors. Application will crash.}]"
    exit
}
# Interprete command line arguments
set bg 0
set config ""
if {$argc > 0} {
    for {set i 0} {[lindex $argv $i] != ""} {incr i} {
        switch -- "[lindex $argv $i]" {
            -i {
                set interactive yes
            }
            --run_in_background {
                set bg 1
            }
            --help - -h {
                puts "$globhelp"
                exit
            }
            -f {
                if {"[lindex $argv [expr {$i + 1}]]" != ""} {
                    incr i
                    set config_file [lindex $argv $i]
                }
                source [file join modules config.tcl]
                makeConfig
                exit
            }
            -d {
                incr i
                set temp(debug) [lindex $argv $i]
            }
            -k - --kill {
                incr i
                if {[file exists [file join .run [lindex $argv $i].pid]]} {
                    set fd [open [file join .run [lindex $argv $i].pid] r]
                    gets $fd pid
                    close $fd
                    catch {exec kill $pid} killresult
                    if {[llength $killresult] == 0} {
                        puts "[ts {Bot killed.}]"
                    } else {
                        puts "[ts {Bot %0 wasn't up.} [lindex $argv $i]]"
                    }
                } else {
                    puts "(!) [ts {Bot PID file not found. Looked for %0.} [file join .run [lindex $argv $i].pid]]"
                }
                exit
            }
            -c {
                incr i
                if {[file exists [file join config [lindex $argv $i].conf]]} {
                    set fd [open [file join config [lindex $argv $i].conf] r]
                    while {![eof $fd] && ![info exists usersport]} {
                        gets $fd data
                        if {"[lrange $data 0 1]" == "set uport"} {
                            set usersport [lindex $data 2]
                        }
                    }
                    close $fd
                    catch {exec telnet localhost $usersport >@ stdout}
                } else {
                    puts "(!) [ts {File %0 doesn't exists or it's not readable.} [file join config [lindex $argv $i].conf]]"
                }
                exit
            }
            -m {
                incr i
                if {[file exists [file join .run [lindex $argv $i].pid]]} {
                    set fd [open [file join .run [lindex $argv $i].pid] r]
                    gets $fd pid
                    close $fd
                    catch {exec ps aux | grep tclsh | grep $pid} result
                    if {[llength $result] > 4} {
                        puts "[ts {Bot %0 use %1 KB of memory.} [lindex $argv $i] [lindex $result 5]]"
                    } else {
                        puts "(!) [ts {Can't find bot process. Perhaps it isn't up.}]"
                    }
                } else {
                    puts "(!) [ts {Bot PID file not found. Looked for %0.} [file join .run [lindex $argv $i].pid]]"
                }
                exit
            }
            -l {
                set configs "[glob -tails -directory config -nocomplain *]"
                source [file join modules scripting.tcl]
                puts "[ts {Bot name         [+ = up, X = down]}]"
                foreach cfg "$configs" {
                    set cfg "[lindex [split $cfg .] 0]"
                    if {[file exists [file join .run $cfg.pid]]} {
                        set fd [open [file join .run $cfg.pid] r]
                        gets $fd pid
                        close $fd
                        catch {exec ps aux | grep tclsh | grep $pid} result
                        if {[llength $result] > 4} {
                            puts "[pad 24 \  $cfg] +"
                        } else {
                            puts "[pad 24 \  $cfg] X"
                        }
                    } else {
                        puts "[pad 24 \  $cfg] X"
                    }
                }
                exit
            }
            -C {
                incr i
                if {"[lindex $argv $i]" == ""} {
                    puts "$argv0 -C <bot>"
                    exit 0
                }
                file delete -force [file join [pwd] cron-giana]
                set fd [open [file join [pwd] cron-giana] w]
                puts $fd "0,10,20,30,40,50 * * * * [file join [pwd] giana] --crontab [lindex $argv $i] >/dev/null 2>&1"
                close $fd
                catch {exec crontab [file join [pwd] cron-giana]} res
                file delete -force [file join [pwd] cron-giana]
                if {[llength $res] == 0} {
                    puts "[ts {Giana has been installed in crontab.}]"
                } else {
                    puts "[ts {Error while installing giana in crontab: %0} \"$res\"]"
                }
                exit
            }
            --crontab {
                incr i
                if {[file exists [file join .run [lindex $argv $i].pid]]} {
                    set fd [open [file join .run [lindex $argv $i].pid] r]
                    gets $fd pid
                    close $fd
                    catch {exec ps aux | grep tclsh | grep $pid} result
                    if {[llength $result] > 4} {
                        exit 0
                    } else {
                        set config "[lindex $argv $i]"
                    }
                } else {
                    set config "[lindex $argv $i]"
                }
            }
            -r {
                set temp(allow_restrict) 1
            }
            -u {
                incr i
                set temp(set_username) [lindex $argv $i]
            }
            -H {
                incr i
                set temp(set_vhost) [lindex $argv $i]
            }
            -L {
                incr i
                set temp(set_locale) [lindex $argv $i]
            }
            -cf {
                incr i
                set cfg_to_edit [file join config [lindex $argv $i].conf]
                set editor "vi"
                catch {exec which pico} new_editor
                if {[llength $new_editor] == 1} {
                    set editor $new_editor
                }
                exec $editor $cfg_to_edit >@ stdout
                exit
            }
            -v {
                puts "Giana Bot: $version"
                puts "TCL:       $tcl_patchLevel"
                puts "OS:        $tcl_platform(os) $tcl_platform(osVersion)"
                exit
            }
            -s {
                set temp(server_auto_connect) 0
            }
            --del {
                incr i
                set bot "[lindex $argv $i]"
                file delete -force [file join lists $bot] [file join config $bot.conf] [file join .run $bot.pid] [file join log $bot]
                puts "[ts {Bot files has been removed.}]"
                exit
            }
            --sockspy {
                set temp(enable_sockspy) 1
            }
            --checkhelp {
                source [file join modules help.tcl]
                incr i
                if {[lindex $argv $i] != ""} {
                    checkhelp [lindex $argv $i] [lindex $argv [expr {$i + 1}]]
                } else {
                    checkhelp
                }
                exit
            }
            -rd - --readdebug {
                incr i
                set config [lindex $argv $i]
                if {[file exists log/$config/debug.log]} {
                    set fd [open log/$config/debug.log r]
                    set debug [read $fd]
                    close $fd
                    puts -nonewline $debug
                }
                exit
            }
            default {
                set config "[lindex $argv $i]"
            }
        }
    }
}

# Prepare to read config.
proc read.config {data} {
    global temp var
    switch -- [lindex $data 0] {
        set {
            set temp([lindex $data 1]) "[lrange $data 2 end]"
        }
        source {
            lappend temp(scripts) "[lindex $data 1]"
        }
        file {
            lappend temp(scripts) "[lindex $data 1]"
        }
        script {
            lappend temp(scripts) "[lindex $data 1]"
        }
        server {
            lappend temp(servlist) "[lindex $data 1]"
        }
    }
}
# Load config
if {"$config" != ""} {
    if {[file readable [file join config $config.conf]]} {
        if {[file exists [file join .run $config.pid]]} {
            set fd [open [file join .run $config.pid] r]
            gets $fd pid
            close $fd
            catch {exec ps aux | grep tclsh | grep $pid} result
            if {[llength $result] > 4} {
                puts "(!) [ts {Bot %0 is already up with PID %1.} $config $pid]"
                exit 1
            }
        }
        set fd [open [file join config $config.conf] r]
        while {![eof $fd]} {
            gets $fd data
            if {"$data" != ""} {
                read.config "$data"
            }
        }
        close $fd
    } else {
        puts "(!) [ts {File %0 doesn't exists or it's not readable.} [file join config $config.conf]]"
        puts "(!) [ts {Giana hasn't started.}]"
        exit 1
    }
} else {
    puts "$globhelp"
    exit 1
}
foreach val "set_username set_vhost" {
    if {[info exists temp($val)]} {
        set val2 [lindex [split $val _] 1]
        set temp($val2) "$val"
    }
}
if {[info exists temp(set_locale)]} {
    set temp(locale) $temp(set_locale)
}
encoding system $temp(encoding)

# Check directory structure
if {![file exists [file join lists $temp(botname)]]} {
    file mkdir [file join lists $temp(botname)]
}
if {![file exists [file join log $temp(botname)]]} {
    file mkdir [file join log $temp(botname)]
}
if {![file exists .run]} {
    file mkdir .run
}

# Going to interactive mode or to background.
if {"$interactive" == "yes"} {
    set temp(user:stdin) "CONSOLE"
    set temp(idle:CONSOLE) "[clock seconds]"
    set temp(sock:CONSOLE) "stdout"
#    set password(CONSOLE) "$temp(netpass)"
    set flags(CONSOLE) "!Apr"
    lappend temp(loggedon) "CONSOLE"
    fileevent stdin readable read_stdin
    source [file join modules main.tcl]
} else {
    if {!$bg} {
        eval set execcmd $argv0
        eval lappend execcmd --run_in_background
        if {"$argv" != ""} {
            eval lappend execcmd "$argv"
        }
        if {$temp(debug) > 0} {
            file delete -force [file join log $temp(botname) debug.log]
            lappend execcmd "2>>[file join log $temp(botname) debug.log]"
            set cmd "$argv0 -rd $temp(botname)"
            puts "[ts {Run bot in debug mode. Error messages will be logged in %0.} [file join log $temp(botname) debug.log]]"
            puts "[ts {You can read them by %0.} $cmd]"
        }
        lappend execcmd &
        eval exec $execcmd
        exit 0
    } else {
        puts "\n[ts {Process successful sent to background.}]"
        puts "[ts {Process PID:}] [pid]"
        source [file join modules main.tcl]
    }
}
