import xchat

__module_name__ = "Common Denominator"
__module_version__ = "1.0"
__module_description__ = "Finds common denominators with other users"

def scanChannels(word, word_eol, userdata):
  if xchat.get_info("server") is None:
    xchat.prnt("Connect before scanning for common denominators")

    return xchat.EAT_ALL

  my_users = getUsers()

  channels = []

  for channel in getChannels():
    users = list(set(my_users) & set(getUsers(channel.context)))

    if (len(users)):
      channels.append({"channel": channel, "users": users})

  xchat.prnt("--- Common Denominator Chart")

  if channels:
    for channel in sorted(channels, key=lambda c: len(c["users"]), reverse=True):
      xchat.prnt("")
      xchat.prnt(channel["channel"].channel + ": " + str(len(channel["users"])))
      xchat.prnt(" ".join(sorted(channel["users"])))
  else:
    xchat.prnt("")
    xchat.prnt("You have no common denominators here!")

  return xchat.EAT_ALL

def getChannels(context=None):
  if context is None:
    context = xchat.get_context()

  channels = context.get_list("channels")
  blacklist = [context.get_info("channel"), 1, 3]

  return [c for c in channels if c.channel not in blacklist and c.type not in blacklist]

def getUsers(context=None):
  if context is None:
    context = xchat.get_context()

  users = context.get_list("users")
  blacklist = [xchat.get_info("nick"), "ChanServ", "__main__", "__class__"]

  return [u.nick for u in users if u.nick not in blacklist]

xchat.hook_command("comden", scanChannels, False)
xchat.prnt("Common Denominator Loaded")
