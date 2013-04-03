import xchat

__module_name__ = "Freenode Hammer"
__module_version__ = "1.1"
__module_description__ = "Provides the /o and /hammer commands for use in FreeNode"
  
def isop():
    _isop = False
    mynick = xchat.get_info('nick')
    for user in xchat.get_list('users'):
        if xchat.nickcmp(user.nick, mynick) == 0:
            if user.prefix == "@":
                _isop = True
    return _isop
  
def o_command(word, word_eol, userdata):
    if isop():
        xchat.command("mode %s -o %s" % (xchat.get_info('channel'), xchat.get_info('nick')))
    else:
        xchat.command("msg ChanServ OP %s %s" % (xchat.get_info('channel'), xchat.get_info('nick')))
    return xchat.EAT_ALL
xchat.hook_command("O", o_command, help="/o Toggles +o on or off in the current channel quickly.")
  
def weapon_continue(ctx):
    context = ctx['context']
    channel = context.get_info('channel')
    for user in context.get_list('users'):
        for nick in ctx['nicks']:
            if xchat.nickcmp(user.nick, nick) == 0:
                username, hostname = user.host.split("@")
                if hostname.startswith("gateway/"):
                    mask = "*!*%s@gateway/*" % username.lstrip("~")
                else:
                    mask = "*!*@%s" % hostname
                context.command("mode %s +%s %s" % (channel, ctx["banmode"], mask))
                if ctx["kick"]:
                    context.command("kick %s" % user.nick)
    if not ctx["wasop"] and isop():
        xchat.command("mode %s -o %s" % (xchat.get_info('channel'), xchat.get_info('nick')))
def weapon_timer(ctx):
    ctx['times'] = ctx['times'] + 1
    if isop():
        weapon_continue(ctx)
    else:
        if ctx['times'] > 10:
            print "Failed to OP within 5 seconds, giving up"
        else:
            xchat.hook_timer(500, weapon_timer, userdata=ctx)       
def weapon_context(word, word_eol, userdata):
    nicks = []
    for nick in word:
        nicks.append(nick.strip(','))
    _isop = isop()
    ctx = dict(context=xchat.get_context(), times=0, nicks=nicks, wasop=_isop)
    return ctx
def weapon_activate(ctx):
    context = ctx['context']
    if ctx["wasop"]:
        weapon_continue(ctx)
    else:
        xchat.command("msg ChanServ OP %s %s" % (context.get_info('channel'), context.get_info('nick')))
        xchat.hook_timer(500, weapon_timer, userdata=ctx)
def hammer_command(word, word_eol, userdata):
    ctx = weapon_context(word, word_eol, userdata)
    ctx["banmode"] = "b"
    ctx["kick"] = True
    weapon_activate(ctx)
    return xchat.EAT_ALL
def silence_command(word, word_eol, userdata):
    ctx = weapon_context(word, word_eol, userdata)
    ctx["banmode"] = "q"
    ctx["kick"] = False
    weapon_activate(ctx)
    return xchat.EAT_ALL

xchat.hook_command("HAMMER", hammer_command, help="/hammer <nicks> Quickly ops, kicks and intelligently bans a list of users, then returns to the original state.")
xchat.hook_command("SILENCE", silence_command, help="/silence <nicks> Quickly ops and intelligently quiets a list of users, then returns to the original state.")
xchat.prnt(__module_name__+' Loaded') 
