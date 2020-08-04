lappend globals "help"

proc help {user {cmd {}}} {
    global cmdlist help temp trans
    if {"$cmd" != ""} {
        if {[lsearch "$cmdlist" $cmd] > -1} {
            if {[info exists help($cmd)]} {
                if {[info exists help($cmd:$temp(locale))]} {
                    if {"[lindex $help($cmd:$temp(locale)) 2]" != ""} {
                        set str1 [string map {\\ ""} [string map {< %K<%w > %K> [ %K[%w ] %K]%w} [lindex $help($cmd:$temp(locale)) 0]]]
                        set str2 [lindex $help($cmd:$temp(locale)) 1]
                        set str3 [lindex $help($cmd:$temp(locale)) 2]
                    } else {
                        set cmd "$help($cmd)"
                        set str1 [string map {\\ ""} [string map {< %K<%w > %K> [ %K[%w ] %K]%w} [lindex $help($cmd:$temp(locale)) 0]]]
                        set str2 [lindex $help($cmd:$temp(locale)) 1]
                        set str3 [lindex $help($cmd:$temp(locale)) 2]
                    }
                } else {
                    if {"[lindex $help($cmd) 2]" != ""} {
                        set str1 [string map {\\ ""} [string map {< %K<%w > %K> [ %K[%w ] %K]%w} [lindex $help($cmd) 0]]]
                        set str2 [lindex $help($cmd) 1]
                        set str3 [lindex $help($cmd) 2]
                    } else {
                        set cmd "$help($cmd)"
                        set str1 [string map {\\ ""} [string map {< %K<%w > %K> [ %K[%w ] %K]%w} [lindex $help($cmd) 0]]]
                        set str2 [lindex $help($cmd) 1]
                        set str3 [lindex $help($cmd) 2]
                    }
                }
                mecho $user "%c[ts {Syntax is:}] %C$str1"
                mecho $user "%c[ts {Alias(es):}] %C$str2"
                mecho $user "%c[ts {Description:}] %C$str3"
            } else {
                mecho $user "%y[ts {No help available for command %Y%0%y.} $cmd]"
            }
        } else {
            mecho $user "%y[ts {Help: Unknown command.}]"
        }
    } else {
        mecho $user "%c[ts {Commands list for you:}]"
        foreach {c1 c2 c3 c4 c5} "$temp([bestflag $user]-cmds)" {
            mecho $user "%B\[%C[center 14 $c1]%B\]%K#%B\[%C[center 14 $c2]%B\]%K#%B\[%C[center 14 $c3]%B\]%K#%B\[%C[center 14 $c4]%B\]%K#%B\[%C[center 14 $c5]%B\]"
        }
    }
}
proc checkhelp {args} {
    switch [llength $args] {
        0 {
            set file "modules/commands.tcl"
            set locale "en"
        }
        1 {
            set file [lindex $args 0]
            set locale "en"
        }
        2 {
            set file [lindex $args 0]
            set locale [lindex $args 1]
        }
    }
    if {"$locale" == "en"} {
        set locale ""
    } else {
        set locale ":$locale"
    }
    set helps ""
    set fd [open $file r]
    while {![eof $fd]} {
        gets $fd data
        set data [string map {\{ ( \} ) \" '} $data]
        #"
        if {[string match {*set help(*)*} $data]} {
            lappend helps [string range [lindex $data 1] 5 end-1]
        }
    }
    close $fd
    
    global help
    set fd [open $file r]
    while {![eof $fd]} {
        gets $fd data
        set data [string map {\{ ( \} ) \" '} $data]
        #"
        if {[string match {*alias * (*} $data]} {
            if {[lsearch $helps [lindex $data 1]] == -1 && ![info exists help([lindex $data 1]$locale)]} {
                puts "[ts {Command %0 hasn't got help.} [lindex $data 1]]"
            }
        }
    }
    close $fd
}

# Default help messages
set help(+user) {
    {+user <user> [<flags> [<host> <host> ...] ]}
    {adduser}
    {Adds new user with flags and hosts. Flags and hosts can be ommited.}
}
set help(adduser) +user
set help(-user) {
    {-user <user>}
    {remuser}
    {Removes user from userlist.}
}
set help(remuser) -user
set help(userlist) {
    {userlist [-f/-h/-n <argument>]}
    {users}
    {Display user database. Switch -f enables filter for flags, where flag(s) should be types as argument. -h enables filter for host and argument is hostmask. -n enables filter for nicks, where argument can be mask for nickname. Default is: -n *}
}
set help(users) userlist
set help(+host) {
    {+host <user/bot> <host> [<host> <host> ...]}
    {addhost}
    {Adds new hostmask(s) for user or bot.}
}
set help(addhost) +host
set help(-host) {
    {-host <user/bot> <mask>}
    {remhost}
    {Removes hostmask(s) matched by given mask from user or bot.}
}
set help(remhost) -host
set help(flags) {
    {flags <user> [<channel>] [+/-/=<flags>]}
    {chattr}
    {Changes rights for user. Flags could be global (without channel) or local (with given channel). For flags describe read file docs/flags. = means that flags will be erased and set to given. + and - are known.}
}
set help(chattr) flags
set help(passwd) {
    {passwd [<user>] <password>}
    {chpass}
    {Changes password for given user (if is) or for executor.}
}
set help(chpass) {
    {chpass [<user>] <password>}
    {passwd pass}
    {Changes password for given user (if is) or for executor.}
}
set help(passwd) chpass
set help(pass) chpass
set help(+bot) {
    {+bot <bot> <bot address>[:<bots port>[/<users port>]] [<flags> [<host> <host> ...] ]}
    {addbot}
    {Adds new bot with address. You can also type bots, users port, bot flags ad hostmask(s). Ports and address can be changed by commands botaddress and botport.}
}
set help(addbot) +bot
set help(-bot) {
    {-bot <bot>}
    {rembot}
    {Simply removes bot from list.}
}
set help(rembot) -bot
set help(botport) {
    {botport <bot> [<new bots port>[/<new users port>]]}
    {}
    {Sets/changes ports for bot.}
}
set help(botaddress) {
    {botaddress <bot> [<new address>]}
    {}
    {Sets/changes address for bot.}
}
set help(netpass) {
    {netpass <new password>}
    {botpass}
    {Sets password for bots network.}
}
set help(botpass) netpass
set help(botflags) {
    {botflags <bot> [+/-/=<flags>]}
    {botattr}
    {Changes flags for bot. = means that flags will be erased and set to given. + and - are known.}
}
set help(botattr) botflags
set help(botlist) {
    {botlist}
    {bots}
    {Lists all bots from list.}
}
set help(bots) botlist
set help(whois) {
    {whois <user/bot/channel>}
    {wi}
    {Displays informations about given thing. It could be bot, user or channel.}
}
set help(wi) whois
set help(cmdlist) {
    {cmdlist [-a/-all]}
    {}
    {Lists commands for you. If switch -a or -all is given, then shows commands for all users.}
}
set help(exit) {
    {exit}
    {quit bye lo}
    {Logs you out from bot.}
}
set help(quit) exit
set help(bye) exit
set help(lo) exit
set help(.) {
    {. <text>}
    {}
    {Says text on bot partyline.}
}
set help(,) {
    {, <text>}
    {}
    {Does action on bot partyline.}
}
set help(server) {
    {server <server[:port]> [<vhost>]}
    {}
    {Connects bot to given server. Yuo may type vhost for this connection.}
}
set help(mode) {
    {mode <channel> [<modes> [<arguments>]]}
    {}
    {Displays/changes modes for channel.}
}
set help(join) {
    {join <channel> [<channel> ... ]}
    {}
    {Bot joins to given channel(s).}
}
set help(part) {
    {part <channel> [<channel> ... ]}
    {}
    {Bot leaves given channel(s).}
}
set help(die) {
    {die [<reason>]}
    {d13}
    {Bot dies. You may give reason.}
}
set help(d13) die
set help(say) {
    {say <channel> <text>}
    {}
    {Bot says text on channel.}
}
set help(msg) {
    {msg <nick> <message>}
    {}
    {Sends private message to nick.}
}
set help(link) {
    {link <bot>}
    {}
    {Links local bot with given bot.}
}
set help(unlink) {
    {unlink <bot>}
    {}
    {Breakes link betwean local bot and given bot.}
}
set help(+link) {
    {+link <bot> [<bot> [...]]}
    {addlink}
    {Adds bot(s) to links list.}
}
set help(addlink) +link
set help(-link) {
    {-link <bot> [<bot> [...]]}
    {remlink}
    {Removes bot(s) from links list.}
}
set help(remlink) -link
set help(links) {
    {links}
    {linklist}
    {Displays links list.}
}
set help(linklist) links
set help(clearlinks) {
    {clearlinks}
    {}
    {Clears links list.}
}
set help(setlinks) {
    {setlinks}
    {}
    {Bots will remember links betwean each other. Old links list is erased.}
}
set help(net) {
    {net <command> [<arguments>]}
    {}
    {Executes command with arguments on each bot from botnet.}
}
set help(r) {
    {r <bot> <command> [<arguments>]}
    {}
    {Executes command with arguments on given bot.}
}
set help(bottree) {
    {bottree}
    {tree}
    {Displays bots links tree.}
}
set help(tree) bottree
set help(whom) {
    {whom}
    {}
    {Shows users logged on any bot in botnet.}
}
set help(save) {
    {save [-u] [-b] [-c] [-a] [-s]}
    {}
    {Saves lists and settings. -u = users list, -b = bots list, -c = channels list, -a = all lists, -s = settings.}
}
set help(savenet) {
    {savenet}
    {}
    {Saves all lists and sent them to rest of bots. !!!This command has to be executed on hub!!!}
}
set help(sendlists) {
    {sendlists}
    {rehash}
    {Sends all lists to rest of bots. !!!This command has to be executed on hub!!!}
}
set help(rehash) sendlists
set help(+chan) {
    {+chan <channel> [<modes>]}
    {addchan}
    {Adds channel to list with default or given modes. If connected to server, joins to that channel.}
}
set help(addchan) +chan
set help(-chan) {
    {-chan <channel>}
    {remchan}
    {Removes channel from list. If connected to server, leaves that channel.}
}
set help(remchan) -chan
set help(chanmode) {
    {chanmode <channel> [=/-/+<modes>]}
    {chandlags}
    {Sets/changes modes for given channel, or just shows them.}
}
set help(chanflags) chanmode
set help(key) {
    {key <channel> [<new key>]}
    {}
    {Shows/sets channel key for channel.}
}
set help(chankey) key
set help(nokey) {
    {nokey <channel>}
    {}
    {Removes key from channel.}
}
set help(limit) {
    {limit <channel>}
    {lim}
    {Sets limit for channel. Limit is automaticaly calculated to be safe (2 users > limit > 6 users).}
}
set help(lim) limit
set help(nolimit) {
    {nolimit <channel>}
    {nolim}
    {Removes limit from channel.}
}
set help(nolim) nolimit
set help(chanlist) {
    {chanlist}
    {chans}
    {Shows list of channels with modes, keys, etc.}
}
set help(chans) chanlist
set help(+ban) {
    {+ban <channel> <mask>}
    {addban}
    {Adds ban to list for given channel.}
}
set help(addban) +ban
set help(-ban) {
    {-ban <channel> <mask>}
    {remban}
    {Removes ban from list for given channel.}
}
set help(remban) -ban
set help(bans) {
    {bans [-r] <channel>}
    {banlist}
    {Displays bans list for channel. With -r switch, shows real channel bans.}
}
set help(banlist) bans
set help(+ex) {
    {+ex <channel> <mask>}
    {addex}
    {Adds exempt to list for given channel.}
}
set help(addex) +ex
set help(-ex) {
    {-ex <channel> <mask>}
    {remex}
    {Removes exempt from list for given channel.}
}
set help(remex) -ex
set help(exempts) {
    {exempts [-r] <channel>}
    {exemptlist}
    {Displays exempts list for channel. With -r switch, shows real channel exempts.}
}
set help(exemptlist) exempts
set help(+inv) {
    {+inv <channel> <mask>}
    {addinv}
    {Adds invite to list for given channel.}
}
set help(addinv) +inv
set help(-inv) {
    {-inv <channel> <mask>}
    {reminv}
    {Removes invite from list for given channel.}
}
set help(reminv) -inv
set help(invites) {
    {invites [-r] <channel>}
    {invitelist}
    {Displays invites list for channel. With -r switch, shows real channel invites.}
}
set help(invitelist) invites
set help(help) {
    {help [<command>]}
    {}
    {Displays command list, or help for given command.}
}
set help(relay) {
    {relay <bot>}
    {}
    {Redirects user to given bot. User is logged on that bot automatically.}
}
set help(kickuser) {
    {kickuser <user>}
    {kuser}
    {Kicks off user from party line. You can't kick owners and roots.}
}
set help(kuser) kickuser
set help(channel) {
    {channel <channel>}
    {}
    {Displays list of users on given channel. Bot has to be on that channel.}
}
set help(status) {
    {status}
    {}
    {Displays general information about bot, like opened ports, current nick, etc.}
}
set help(op) {
    {op <channel> <nick> [<nick> ...]}
    {}
    {Gives op to given nick(s).}
}
set help(deop) {
    {deop <channel> <nick> [<nick> ...]}
    {}
    {Gets back op from given nick(s).}
}
set help(vop) {
    {vop <channel> <nick> [<nick> ...]}
    {}
    {Gives voice to given nick(s).}
}
set help(devop) {
    {devop <channel> <nick> [<nick> ...]}
    {}
    {Gets back voice from given nick(s).}
}
set help(kick) {
    {kick <channel> <nick> [<nick> ...]}
    {}
    {Kicks nick(s) from channel.}
}
set help(ban) {
    {ban <channel> [<nick> ...] / [<host> ...]}
    {}
    {Sets ban(s) for nick(s) / host(s) on channel.}
}
set help(unban) {
    {unban <channel> <nick> [<nick> ...] / <host> [<host> ...]}
    {}
    {Unsets ban(s) for nick(s) / host(s) on channel.}
}
set help(invite) {
    {invite [-i <channel> <nick>] / <channel> [<nick> ...]/[<host> ...]}
    {}
    {Sets invite(s) for nick(s) / host(s) on channel.}
}
set help(inv) invite
set help(uninvite) {
    {uninvite <channel> <nick> [<nick> ...] / <host> [<host> ...]}
    {}
    {Unsets invite(s) for nick(s) / host(s) on channel.}
}
set help(uninv) uninvite
set help(exempt) {
    {exempt <channel> [<nick> ...] / [<host> ...]}
    {}
    {Sets exempt(s) for nick(s) / host(s) on channel.}
}
set help(ex) exempt
set help(unexempt) {
    {unexempt <channel> <nick> [<nick> ...] / <host> [<host> ...]}
    {}
    {Unsets exempt(s) for nick(s) / host(s) on channel.}
}
set help(unex) exempt
set help(lsmod) {
    {lsmod}
    {}
    {Lists loaded additional scripts.}
}
set help(insmod) {
    {insmod <script name>[.tcl]}
    {modprobe addmod script}
    {Loads given script.}
}
set help(script) insmod
set help(modprobe) insmod
set help(addmod) insmod
set help(ident) {
    {ident <nick>}
    {}
    {Checks is nick is registered user and shows result.}
}
set help(sensors) {
    {sensors [<public/nick/join> ON/OFF/<value>]}
    {}
    {Without arguments shows current sensors settings. With both of arguments enables, disables, or sents value for given sensor.}
}
set help(uptime) {
    {uptime}
    {}
    {Shows how much time bot is alive.}
}
set help(nick) {
    {nick <nick>}
    {}
    {Changes bot nick.}
}
set help(+server) {
    {+server <server[:port]>}
    {}
    {Adds server to servers list.}
}
set help(addserver) +server
set help(-server) {
    {-server <server[:port]>}
    {}
    {Removes server from servers list.}
}
set help(remserver) -server
set help(servlist) {
    {servlist}
    {}
    {Shows servers list.}
}
set help(servers) servlist
set help(topic) {
    {topic <channel> <new topic>}
    {}
    {Changes topic on given channel.}
}
set help(pwd) {
    {pwd}
    {}
    {Tells You, on which bot you are already.}
}
set help(!) {
    {!}
    {}
    {Executes again last command.}
}
set help(log) {
    {log [-]<channel>}
    {}
    {Sets or unsets mode L for given channel. Simply starts or stops logging from that channel.}
}
set help(nolog) {
    {nolog <channel>}
    {unlog}
    {Stops logging from given channel (unsets L mode for that channel).}
}
set help(unlog) nolog
set help(jump) {
    {jump [<server[:port]>]}
    {}
    {Bot changes server to given, or to random if not given.}
}
set help(cycle) {
    {cycle <channel>}
    {}
    {Bot leaves and rejoins given channel.}
}
set help(me) {
    {me <channel> <text>}
    {}
    {Bot does an action with text on given channel.}
}
set help(timeban) {
    {timeban <channel> <nick>/<host> <time: *d *h *m *s>}
    {}
    {Similar ban command, but here you can specify how long ban should be keept. Time format is number with d, h, m, or s (day, hour, minute, second). All of them can be used but havn't to.}
}
set help(quote) {
    {quote <data>}
    {}
    {Sends data directly to server. No paring, interpreting, just sends it.}
}
set help(env) {
    {env}
    {}
    {Displays all variables from configuration.}
}
set help(var) {
    {var <variable> [<value>]}
    {}
    {Sets new value for given variable. You can manage only variables displayed by command env. You can't change all variables (not all makes effect while changing them on the fly). You'll be noticed if some variable can't be changed. Without value argument, shows current value of given variable.}
}

# Polish help messages (all languages should be done similar)
#set help(+user:pl) {
#    {+user <u¿ytkownik> [<flagi> [<host> <host> ...] ]}
#    {adduser}
#    {Dodaje nowego u¿ytkownika z flagami i hostami. Flagi i hosty mog± byæ pominiête.}
#}
