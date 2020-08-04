# Terminal Library 1.0 for Tcl.
# Version modified for Giana2.
#############################################

proc ansi_replace {string} {
    set idx [string first % "$string"]
    set startidx 0
    set sw 0
    while {$idx > -1} {
        if {"[string index "$string" [expr {$idx + 1}]]" == "%"} {
            append string2 "[string range $string $startidx [expr {$idx - 1}]]%"
            incr idx
        } else {
            append string2 "[string range $string $startidx [expr {$idx - 1}]]\033\[\0"
            while {[string index "$string" $idx] == "%"} {
                incr idx
                set char [string index "$string" $idx]
                if {"$char" == "#"} {
                    incr idx
                    set char [string index "$string" $idx]
                    set sw 1
                }
                append string2 "\;"
                if {$sw} {
                    append string2 "[string map {b 44 r 41 g 42 y 43 m 45 w 47 k 40 c 46 n 0 \
                        K 100 R 101 G 102 Y 103 B 104 M 105 C 106 W 107 d 1 u 4 l 5} $char]"
                    set sw 0
                } else {
                    append string2 "[string map {b 34 r 31 g 32 y 33 m 35 w 37 k 30 c 36 n 0 \
                        K 90 R 91 G 92 Y 93 B 94 M 95 C 96 W 97 d 1 u 4 l 5} $char]"
                }
                incr idx
            }
            append string2 m
            set startidx $idx
            set idx [string first % "$string" $startidx]
        }
    }
    append string2 "[string range $string $startidx end]"
    return "$string2"
}
proc ansi_remove {string} {
    set idx [string first % "$string"]
    set startidx 0
    set sw 0
    while {$idx > -1} {
        if {"[string index "$string" [expr {$idx + 1}]]" == "%"} {
            append string2 "[string range $string $startidx [expr {$idx - 1}]]%"
            incr idx
        } else {
            append string2 "[string range $string $startidx [expr {$idx - 1}]]\033\[\0"
            while {[string index "$string" $idx] == "%"} {
                incr idx
                set char [string index "$string" $idx]
                if {"$char" == "#"} {
                    incr idx
                    set char [string index "$string" $idx]
                    set sw 1
                }
                append string2 "\;"
                if {$sw} {
                    append string2 "[string map {b {} r {} g {} y {} m {} w {} k {} c {} n {} \
                        K {} R {} G {} Y {} B {} M {} C {} W {} d {} u {} l {}} $char]"
                    set sw 0
                } else {
                    append string2 "[string map {b {} r {} g {} y {} m {} w {} k {} c {} n {} \
                        K {} R {} G {} Y {} B {} M {} C {} W {} d {} u {} l {}} $char]"
                }
                incr idx
            }
            append string2 m
            set startidx $idx
            set idx [string first % "$string" $startidx]
        }
    }
    append string2 "[string range $string $startidx end]"
    return "$string2"
}
proc fcputs {arg ansi {nnl {}} {channelID {}}} {
    append arg "%n"
    if {$ansi} {
        set output "[string map {%% % %b \033\[0\;34m %r \033\[0\;31m \
                %g \033\[0\;32m %y \033\[0\;33m %m \033\[0\;35m %w \033\[0\;37m %k \033\[0\;30m \
                %c \033\[0\;36m %n \033\[0\;0\;m %K \033\[0\;90m %R \033\[0\;91m %G \033\[0\;92m \
                %Y \033\[0\;93m %B \033\[0\;94m %M \033\[0\;95m %C \033\[0\;96m %W \033\[0\;97m \
                %#r \033\[0\;40m %#k \033\[0\;41m %#g \033\[0\;42m %#y \033\[0\;43m %#b \033\[0\;44m \
                %#m \033\[0\;45m %#c \033\[0\;46m %#K \033\[0\;100m %#R \033\[0\;101m \
                %#G \033\[0\;102 %#Y \033\[0\;103 %#B \033\[0\;104m %#M \033\[0\;105m %#C \033\[0\;106 \
                %#W \033\[0\;107m %#w \033\[0\;47m %d \033\[0\;1m %u \033\[0\;4m %l \033\[0\;5m %v \033\[0\;7m} $arg]"
    } else {
        set output [string map {%% % %b "" %r "" \
                %g "" %y "" %m "" %w "" %k "" \
                %c "" %n "" %K "" %R "" %G "" \
                %Y "" %B "" %M "" %C "" %W "" \
                %#r "" %#k "" %#g "" %#y "" %#b "" \
                %#m "" %#c "" %#K "" %#R "" \
                %#G "" %#Y "" %#B "" %#M "" %#C "" \
                %#W "" %#w "" %d "" %u "" %l "" %v ""} $arg]
    }
    if {"$nnl" == "-nonewline"} {
        if {"$channelID" != ""} {
             puts -nonewline $channelID "$output"
        } else {
            puts -nonewline "$output"
        }
    } else {
        if {"$nnl" != ""} {
            puts $nnl "$output"
        } else {
            puts "$output"
        }
    }
}
proc cputs {arg ansi {nnl {}} {channelID {}}} {
    append arg "%n"
    if {$ansi} {
        set arg "[ansi_replace $arg]"
    } else {
        set arg "[ansi_remove $arg]"
    }
    if {"$nnl" == "-nonewline"} {
        if {"$channelID" != ""} {
            puts -nonewline $channelID "$arg"
        } else {
            puts -nonewline "$arg"
        }
    } else {
        if {"$nnl" != ""} {
            puts $nnl "$arg"
        } else {
            puts "$arg"
        }
    }
}
proc mv {args} {
    if {"$args" != ""} {
        foreach arg "$args" {
            switch -- [string index $arg 0] {
                u {
                    if {"[string range $arg 1 end]" != ""} {
                        if {[string is digit [string range $arg 1 end]]} {
                            puts "\033\[[string range $arg 1 end]A"
                        }
                    }
                }
                d {
                    if {"[string range $arg 1 end]" != ""} {
                        if {[string is digit [string range $arg 1 end]]} {
                            puts "\033\[[string range $arg 1 end]B"
                        }
                    }
                }
                l {
                    if {"[string range $arg 1 end]" != ""} {
                        if {[string is digit [string range $arg 1 end]]} {
                            puts "\033\[[string range $arg 1 end]D"
                        }
                    }
                }
                r {
                    if {"[string range $arg 1 end]" != ""} {
                        if {[string is digit [string range $arg 1 end]]} {
                            puts "\033\[[string range $arg 1 end]C"
                        }
                    }
                }
                default {
                    if {[string match "$arg" *,*]} {
                        if {[string is digit [lindex [split $arg ,] 0]] && [string is digit [lindex [split $arg ,] 1]]} {
                            puts "\033\[[string map {, \;} $arg]H"
                        }
                    } else {
                        if {[string is digit $arg]} {
                            puts "\033\[$arg\;0H"
                        }
                    }
                }
            }
        }
    }
}
proc curpos {sl} {
    if {"$sl" == "save"} {
        puts "\033\[s"
    } elseif {"$sl" == "load"} {
        puts "\033\[u"
    }
}
