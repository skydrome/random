__module_name__ = "BetterKickban"
__module_author__ = "Wa (logicplace.com)"
__module_version__ = "0.5"
__module_description__ = "A better version of kicking and banning."

import xchat
import re
from time import time

hosts = {}
reNick = re.compile(r"^[a-zA-Z\[\]\\`_^{|}][a-zA-Z0-9\-\[\]\\`_^{|}]*$")
reMask = re.compile(r"^.+!.+@.+$")
reBanType = re.compile(r"^(?:([0-9]+)|(\*|\*?(?:n|nick)\*?)!(\*|\*?(?:u|user)\*?)@"
	+r"(\*|(?:\*\.?)?(?:h|host)\*?|\*\.tld))$"
)
reTime = re.compile(r"^(?:([0-9]+)w)?(?:([0-9]+)d)?(?:(?:([0-9]+)h)?(?:([0-9]+)m)?(?:([0-9]+)s)?|"
	+r"([0-9]+):([0-9]+)(?:([0-9]+))?)$"
)
banNums = map(reBanType.match,["*!*@*.host","*!*@host","*!*user@*.host","*!*user@host","*!*user@*","nick!*@*"])

bannedNicks = {}
banTimes = {}
banOpts = { "*": {
	"irc_kick_message": "Your behavior is not conducive to the desired environment."
}}
nextBanInfo = None
nextBanTime = None

pathToSettings = xchat.get_info("xchatdir")

try: os.mkdir(pathToSettings+"/settings")
except: pass

pathToSettings += "/settings/"

def LoadINIish(etc):
	global pathToSettings
	dic,fn,do = etc
	try:
		f=open(pathToSettings+fn,"r")
		setLines=f.readlines()
		f.close()
		head = ""
		for x in setLines:
			x = x.rstrip("\n\r")
			if x[0] == "[" and x[-1] == "]":
				head = x[1:-1]
				dic[head] = {}
			else:
				var,val = tuple(x.split('='))
				dic[head][var] = do(val)
			#endif
		#endfor
		return True
	except IOError: return False
#endif

def SaveINIish(etc):
	global pathToSettings,banTimes
	dic,fn = etc
	try:
		f=open(pathToSettings+fn,"w")
		for head in dic:
			f.write("[%s]\n" % head)
			for var in dic[head]:
				f.write("%s=%s\n" % (var,str(dic[head][var])))
			#endfor
		#endfor
		f.close()
		return True
	except IOError: return False
#endif

banTimer = None
def BanTimerGo(newInfo=None,newTime=None,onYouJoin=False):
	global banTimer,nextBanInfo,nextBanTime
	if onYouJoin:
		newInfo = None
		newTime = None
	#endif
	curTime = time()
	if not newTime:
		for servChan in banTimes:
			serv,chan = tuple(servChan.split("/",1))
			if xchat.find_context(serv,chan):
				remove = []
				for mask in banTimes[servChan]:
					thTime = banTimes[servChan][mask]
					if thTime <= curTime: remove.append((servChan,mask,thTime))
					elif not nextBanTime or thTime < nextBanTime:
						newInfo = (servChan,mask)
						newTime = thTime
					#endif
				#endfor
				for x in remove: BanTimerTick(x)
			#endif
		#endfor
	#endif
	if newInfo and newTime and (not nextBanTime or newTime < nextBanTime):
		nextBanInfo = newInfo
		nextBanTime = newTime
		if banTimer: xchat.unhook(banTimer)
		banTimer = xchat.hook_timer((newTime-int(time()))*1000, BanTimerTick)
	#endif
#enddef

def BanTimerTick(userdata=None):
	global banTimer,banTimes,nextBanInfo,nextBanTime
	if banTimer:
		xchat.unhook(banTimer)
		banTimer = None
	#endif
	banTime = nextBanTime
	if userdata: servChan,mask,banTime = userdata
	else: servChan,mask = nextBanInfo
	serv,chan = tuple(servChan.split("/",1))
	context = xchat.find_context(serv,chan)
	if context:
		context.command("mode %s -b %s" % (chan,mask))
		try: del banTimes[servChan][mask]
		except KeyError: pass
	#endif
	if not userdata: nextBanInfo = nextBanTime = None
	BanTimerGo()
#enddef

def CheckJoin(word,word_eol,userdata):
	global hosts
	servChan = xchat.get_info("host")+"/"+xchat.get_info("channel")
	nick = word[0]
	user,host = tuple(word[2].split("@"))
	if servChan not in hosts: hosts[servChan] = {}
	hosts[servChan][nick] = (user,host)
	return xchat.EAT_NONE
#enddef

def CheckWhoRet(word,word_eol,userdata):
	global hosts
	servChan = xchat.get_info("host")+"/"+xchat.get_info("channel")
	nick,user,host = (word[7],word[4],word[5])
	if servChan not in hosts: hosts[servChan] = {}
	hosts[servChan][nick] = (user,host)
	return xchat.EAT_NONE
#enddef

def BanNick(word,word_eol,kickAfter):
	global hosts,reNick,reMask,reBanType,reTime,banNums,banTimes,nextBanTime,bannedNicks
	if len(word) < 2: return xchat.EAT_NONE # Fixes complaining when I manually unban..
	context = xchat.get_context()
	servChan = context.get_info("host")+"/"+context.get_info("channel")
	ttime = None
	if word[1][0] == '-':
		i = 1
		while i < len(word[1]):
			if word[1][i] in 'kK': kickAfter = True
			elif word[1][i] in 'uU':
				try:
					ttime = int(word[1][i+1:])
				except ValueError:
					xchat.prnt("u argument should come last and be followed only by numbers.")
				#endtry
			#endif
			i += 1
		#endwhile
		nick = word[2]
		args = 3
		nickLoc = 2
	else:
		nick = word[1]
		args = 2
		nickLoc = 1
	#endif
	btype = reBanType.match(word[args]) if len(word) > args else None
	if btype: args += 1
	btime = reTime.match(word[args]) if len(word) > args else None
	if btime: args += 1
	if reNick.match(nick):
		if (btype and btype.group(1)) or btype is None:
			if btype is None: btype = xchat.get_prefs("irc_ban_type")
			else: btype = int(btype.group(1))
			try: btype = banNums[btype]
			except IndexError: xchat.prnt("Ban type numeric %s does not exist" % btype.group(1))
		#endif
		nmask,umask,hmask = btype.groups()[1:]
		if servChan in hosts and nick in hosts[servChan]:
			user,host = hosts[servChan][nick]

			mask = (nmask.replace("nick","n").replace("n",nick)+"!"
			+(lambda u: "*"+(user[1:] if user[0] == "~" else user)+u[2:] if umask[0:2] == "*u" else u.replace("u",user))(
				umask.replace("user","u")
			)+"@"
			+(lambda h: "*"+host[host.index("."):]+h[3:] if h[0:3] == "*.h" else (
				"*"+host[host.rindex("."):] if h == "*.tld" else (
				h.replace("h",host)
			)))(
				hmask.replace("host","h")
			))
			context.command("mode +b "+mask)
		else:
			xchat.prnt("Nick unknown.")
			return xchat.EAT_ALL
		#endif
	elif reMask.match(nick):
		context.command("mode +b "+nick)
		mask = nick
	else:
		xchat.prnt("No one to ban.")
		return xchat.EAT_ALL
	#endif

	if servChan not in bannedNicks: bannedNicks[servChan] = {}
	bannedNicks[servChan][nick] = mask

	if btime:
		if servChan not in banTimes: banTimes[servChan] = {}
		t = map(int,list(btime.groups("0")))
		# w,d,h,m,s,h,m,s
		ttime = (t[0]*604800 + t[1]*86400
		+ t[2]*3600 + t[3]*60 + t[4]
		+ t[5]*3600 + t[6]*60 + t[7])
	#endif
	if ttime:
		xchat.prnt("Banning %s for %i seconds." % (nick,ttime))
		ttime = banTimes[servChan][mask] = int(time()) + ttime
		BanTimerGo((servChan,mask),ttime)
	#endif

	if kickAfter: KickNick(word,word_eol,(nickLoc,args,btime.group(0) if btime else None))
	return xchat.EAT_ALL
#enddef

def UnbanNick(word,word_eol,userdata):
	context = xchat.get_context()
	servChan = context.get_info("host")+"/"+context.get_info("channel")
	nick = word[1]
	if reNick.match(nick):
		if nick in bannedNicks[servChan]:
			context.command("mode -b "+bannedNicks[servChan][nick])
		else:
			# TODO: Retrieve ban list, find all matches to a certain nick's mask,
			# unban all of those
			xchat.prnt("You didn't ban this nick. (Condition not supported yet)")
		#endif
	elif reMask.match(nick):
		context.command("mode -b "+nick)
		mask = nick
	else:
		xchat.prnt("No one to unban.")
		return xchat.EAT_ALL
	#endif
	return xchat.EAT_ALL
#enddef

nextkick = False
def KickNick(word,word_eol,userdata):
	global nextkick
	if nextkick:
		nextkick = False
		return xchat.EAT_NONE
	#endif
	nickLoc,messageIdx,btime = userdata
	try: irc_kick_message = banOpts["*"]["irc_kick_message"]
	except KeyError: irc_kick_message = None
	message = word_eol[messageIdx] if len(word_eol) > messageIdx else (
		irc_kick_message or "Your behavior is not conducive to the desired environment."
	)
	if btime: message += " (for "+btime+")"
	try: word_eol[2] = message
	except IndexError: word_eol.append(message)
	nextkick = True
	xchat.command("kick "+word[nickLoc]+" "+message)
	return xchat.EAT_ALL
#enddef

def SetMessage(word,word_eol,userdata):
	global banOpts
	if "*" not in banOpts: banOpts["*"] = {}
	if word[1] == "irc_kick_message":
		if len(word_eol) > 2: # Set
			banOpts["*"]["irc_kick_message"] = word_eol[2]
			xchat.prnt("%s set to: %s" % (word[1],word_eol[2]))
		else:
			dots = 29-len(word[1])
			try: irc_kick_message = banOpts["*"]["irc_kick_message"]
			except KeyError: irc_kick_message = None
			xchat.prnt(word[1]+"\00318"+("."*dots)+"\00319:\x0f "+irc_kick_message)
		#endif
		return xchat.EAT_XCHAT
	#endif

	return xchat.EAT_NONE
#enddef

xchat.hook_print("Join", CheckJoin)
xchat.hook_print("You Join", BanTimerGo, True)
xchat.hook_server("352", CheckWhoRet)
xchat.hook_command("set",SetMessage)
for x in ["b","ban"]: xchat.hook_command(x,BanNick,None,xchat.PRI_HIGHEST)
for x in ["ub","unban"]: xchat.hook_command(x,UnbanNick,None,xchat.PRI_HIGHEST)
for x in ["k","kick"]: xchat.hook_command(x,KickNick,(1,2,None),xchat.PRI_HIGHEST)
for x in ["kb","kickban"]: xchat.hook_command(x,BanNick,True,xchat.PRI_HIGHEST)

LoadINIish((banTimes,"bantimes",int))
xchat.hook_unload(SaveINIish,(banTimes,"bantimes"))
LoadINIish((bannedNicks,"bannednicks",str))
xchat.hook_unload(SaveINIish,(bannedNicks,"bannednicks"))
LoadINIish((banOpts,"banopts",str))
xchat.hook_unload(SaveINIish,(banOpts,"banopts"))
xchat.prnt("Loaded %s version %s." % (__module_name__,__module_version__))
