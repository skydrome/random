"""X-Chat 2.0 plugin to show changes made to the topic.

Place in your .hexchat2 directory and either reload X-Chat or
/PY LOAD topicdiff.py

0.1     14jan04 initial version
0.2     15jan04 removed UTF-8 (C) that Python didn't like
                don't return changes list when everything changes
0.3     17jan04 fix bug when no initial topic
                fix bug when entire list of words get changed
"""

__author__ = "Scott James Remnant <scott@netsplit.com>"
__copyright__ = "Copyright (C) 2004 Scott James Remnant <scott@netsplit.com>."
__licence__ = "MIT"

__module_name__ = "topicdiff"
__module_version__ = "0.3"
__module_description__ = "Shows changes made to the topic"

import re
import hexchat


def strdiff(old_str, new_str):
    changes = []
    unchanged = 0
    last_hanging = 0

    if old_str is None or new_str is None:
        return []

    old_words = re.sub(r"\s+", " ", old_str).strip().split(" ")
    new_words = re.sub(r"\s+", " ", new_str).strip().split(" ")

    while len(old_words) and len(new_words):
        if new_words[0] == old_words[0]:
            # Both words match, carry on to the next
            new_words = new_words[1:]
            old_words = old_words[1:]
            last_hanging = 0
            unchanged += 1
        else:
            try:
                # Are the first two new words later in old_words?
                # If so, we've got deletions
                idx = old_words.index(new_words[0])
                if idx > 0 and old_words[idx + 1] == new_words[1]:
                    changes.append(["-", " ".join(old_words[0:idx])])
                    old_words = old_words[idx:]
                    last_hanging = 0
                    continue
            except ValueError:
                pass
            except IndexError:
                pass

            try:
                # Are the first two old words later in new_words?
                # If so, we've got additions
                idx = new_words.index(old_words[0])
                if idx > 0 and new_words[idx + 1] == old_words[1]:
                    changes.append(["03+", " ".join(new_words[0:idx])])
                    new_words = new_words[idx:]
                    last_hanging = 0
                    continue
            except ValueError:
                pass
            except IndexError:
                pass

            # Swapped words, just kill the old one
            # If we did this last time, just append to it (for when an entire
            # section of the string is swapped with another)
            if last_hanging:
                changes[-1][1] += " " + old_words[0]
            else:
                changes.append(["04-", old_words[0]])
            old_words = old_words[1:]
            last_hanging = 1

    if len(old_words):
        changes.append(["04-", " ".join(old_words)])
    if len(new_words):
        changes.append(["03+", " ".join(new_words)])

    if unchanged:
        return changes
    else:
        return []


def topic_change_cb(word, word_eol, userdata):
    ctx = hexchat.get_context()
    channel = ctx.get_info("channel")

    old_topic = ctx.get_info("topic")
    new_topic = word_eol[3][1:]

    changes = strdiff(old_topic, new_topic)
    for mod, change in changes:
        print(f"Topic: {mod} {change}")

    return hexchat.EAT_NONE


hexchat.hook_server("TOPIC", topic_change_cb)
