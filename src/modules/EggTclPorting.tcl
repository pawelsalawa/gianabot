proc putserv {cmd} [info body quote]
proc putquick {cmd} [info body quote]
proc putkick {chan nick {reason {}}} [info body kick]
proc putdcc {who arg {full {}}} [info body mecho]
proc putlog {str} [info body LOG]
proc validuser {user} [info body isuser3]
proc nick2hand {nick {chan {}}} {
    return [isuser2 $nick![host $nick]]
}
proc dccbroadcast {args} [info body echo]
proc boot {arg} {
    if {[isLoggedOn $arg]} {
        if {![haveflags $arg "n r"]} {
            logout $arg
        }
    }
}
proc unixtime {} {
    return [clock seconds]
}
