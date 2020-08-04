lappend globals "trans"

proc localeSet {loc} {
    global temp
    set temp(locale) "$loc"
}
proc localeTrans {lc src trg} {
    global trans
    set trans($lc:[sjoin $src \001]) "$trg"
}
proc ts {src args} {
    global trans temp
    if {[info exists trans($temp(locale):[sjoin $src \001])]} {
        if {"$trans($temp(locale):[sjoin $src \001])" != ""} {
            set trg "$trans($temp(locale):[sjoin $src \001])"
        } else {
            set trg "$src"
        }
    } else {
        set trg "$src"
    }
    set c 0
    if {"$args" != ""} {
        foreach a "$args" {
            eval set trg {[string map "%$c {$a}" $trg]}
            incr c
        }
        set trg "[string map {%% %} $trg]"
    }
    return "$trg"
}
proc loadLocale {dir} {
    set files "[glob -nocomplain -directory $dir *.po]"
    foreach file "$files" {
        set lang "[lindex [split [lindex [split $file .] 0] /] end]"
        set src ""
        set trs ""
        set start 0
        set action ""
        set fd [open $file r]
        while {![eof $fd]} {
            gets $fd data
            if {"$data" != "" && "[string index $data 0]" != "#"} {
                if {"[lindex $data 0]" == "msgid"} {
                    set action "id"
                    if {"$src" != ""} {
                        localeTrans $lang $src $trs
                    }
                    set src "[eval concat [lrange $data 1 end]]"
                } elseif {"[lindex $data 0]" == "msgstr"} {
                    set action "str"
                    set trs "[eval concat [lrange $data 1 end]]"
                } else {
                    if {"$action" == "id"} {
                        append src "[eval concat $data]"
                    } else {
                        append trs "[eval concat $data]"
                    }
                }
            }
        }
        close $fd
        localeTrans $lang $src $trs
    }
}
set temp(locale) ""
foreach l "LC_ALL LC_MESSAGES LANG" {
    if {[info exists env($l)]} {
        if {"$env($l)" != ""} {
            set temp(locale) "$env($l)"
        }
    }
}
if {"$temp(locale)" == ""} {
    set temp(locale) "en"
}

