#!/usr/bin/python

import xchat

__module_name__ = "mvoice.py"
__module_version__ = "1.1"
__module_description__ = "Mass De/voice"
__module_author__ = "Ferus"

def voice(word, word_eol, userdata):
	list = xchat.get_list('users')
	if list:
		for i in list:
			xchat.command("VOICE {0}".format(i.nick))
	return xchat.EAT_ALL

def devoice(word, word_eol, userdata):
	list = xchat.get_list('users')
	if list:
		for i in list:
			xchat.command("DEVOICE {0}".format(i.nick))
	return xchat.EAT_ALL

xchat.hook_command("mvoice", voice, help="Mass voice all users")
xchat.hook_command("mdevoice", devoice, help="Mass devoice all users")
print("Loaded {0}, version {1}".format(__module_name__, __module_version__))

