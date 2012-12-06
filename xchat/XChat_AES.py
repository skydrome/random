#!/usr/bin/python
###
#
# Blowfish and AES FiSH like for X-Chat in 100% Python
#
# Requirements: PyCrypto, and Python 2.5+
#
# Copyright 2011 Emiliano Gonzalez http://www.ergio.com.ar
# Based in works of Nam T. Nguyen (FiSH clone) and Bjorn Edstrom (cryptographic methods for IRC)
# Released under the GPLV3 license
#
# Changelog:
#
#   * 1.0:
#      + Initial release AES256 from PyCrypto
###

from __future__ import with_statement

__author__ = "Emiliano Gonzalez <egonzalez@ergio.com.ar>"
__date__ = "2011-12-07"
__version__ = "1.0"

###################

__module_name__ = 'FiSH_AES'
__module_version__ = '2.0'
__module_description__ = 'FiSH with Blowfish/AES encryption for XChat in pure python'

import pickle
import os
import binascii
import hashlib
import struct

from math import log
try:
    import Crypto.Cipher.Blowfish
    import Crypto.Cipher.AES
except ImportError:
    print "This module requires PyCrypto / The Python Cryptographic Toolkit."
    print "Get it from http://www.dlitz.net/software/pycrypto/."
    raise
from os import urandom

##
## Preliminaries.
##

class MalformedError(Exception):
    pass


def sha256(s):
    """sha256"""
    return hashlib.sha256(s).digest()


def int2bytes(n):
    """Integer to variable length big endian."""
    if n == 0:
        return '\x00'
    b = ''
    while n:
        b = chr(n % 256) + b
        n /= 256
    return b


def bytes2int(b):
    """Variable length big endian to integer."""
    n = 0
    for p in b:
        n *= 256
        n += ord(p)
    return n


# FIXME! Only usable for really small a with b near 16^x.
#def randint(a, b):
#    """Random integer in [a,b]."""
#    bits = int(log(b, 2) + 1) / 8
##    candidate = 0
#    while True:
#        candidate = bytes2int(urandom(bits))
#        if a <= candidate <= b:
#            break
#    assert a <= candidate <= b
#    return candidate


def padto(msg, length):
    """Pads 'msg' with zeroes until it's length is divisible by 'length'.
    If the length of msg is already a multiple of 'length', does nothing."""
    L = len(msg)
    if L % length:
        msg += '\x00' * (length - L % length)
    assert len(msg) % length == 0
    return msg


def xorstring(a, b, blocksize): # Slow.
    """xor string a and b, both of length blocksize."""
    xored = ''
    for i in xrange(blocksize):
        xored += chr(ord(a[i]) ^ ord(b[i]))
    return xored


def cbc_encrypt(func, data, blocksize):
    """The CBC mode. The randomy generated IV is prefixed to the ciphertext.
    'func' is a function that encrypts data in ECB mode. 'data' is the
    plaintext. 'blocksize' is the block size of the cipher."""
    assert len(data) % blocksize == 0

    IV = urandom(blocksize)
    assert len(IV) == blocksize

    ciphertext = IV
    for block_index in xrange(len(data) / blocksize):
        xored = xorstring(data, IV, blocksize)
        enc = func(xored)

        ciphertext += enc
        IV = enc
        data = data[blocksize:]

    assert len(ciphertext) % blocksize == 0
    return ciphertext


def cbc_decrypt(func, data, blocksize):
    """See cbc_encrypt."""
    assert len(data) % blocksize == 0

    IV = data[0:blocksize]
    data = data[blocksize:]

    plaintext = ''
    for block_index in xrange(len(data) / blocksize):
        temp = func(data[0:blocksize])
        temp2 = xorstring(temp, IV, blocksize)
        plaintext += temp2
        IV = data[0:blocksize]
        data = data[blocksize:]

    assert len(plaintext) % blocksize == 0
    return plaintext

class Blowfish:

    def __init__(self, key=None):
        if key:
            self.blowfish = Crypto.Cipher.Blowfish.new(key)

    def decrypt(self, data):
        return self.blowfish.decrypt(data)

    def encrypt(self, data):
        return self.blowfish.encrypt(data)

class AESCBC:

    def __init__(self, key):
        self.aes = Crypto.Cipher.AES.new(key)

    def decrypt(self, data):
        return cbc_decrypt(self.aes.decrypt, data, 16)

    def encrypt(self, data):
        return cbc_encrypt(self.aes.encrypt, data, 16)

##
## blowcrypt, Fish etc.
##

# XXX: Unstable.
def blowcrypt_b64encode(s):
    """A non-standard base64-encode."""
    B64 = "./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    res = ''
    while s:
        left, right = struct.unpack('>LL', s[:8])
        for i in xrange(6):
            res += B64[right & 0x3f]
            right >>= 6
        for i in xrange(6):
            res += B64[left & 0x3f]
            left >>= 6
        s = s[8:]
    return res


def blowcrypt_b64decode(s):
    """A non-standard base64-decode."""
    B64 = "./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    res = ''
    while s:
        left, right = 0, 0
        for i, p in enumerate(s[0:6]):
            right |= B64.index(p) << (i * 6)
        for i, p in enumerate(s[6:12]):
            left |= B64.index(p) << (i * 6)
        res += struct.pack('>LL', left, right)
        s = s[12:]
    return res


def blowcrypt_pack(msg, cipher):
    """."""
    return '+OK ' + blowcrypt_b64encode(cipher.encrypt(padto(msg, 8)))


def blowcrypt_unpack(msg, cipher):
    """."""
    if not msg.startswith('+OK '):
        raise ValueError
    _, rest = msg.split(' ', 1)
    if len(rest) < 12:
        raise MalformedError

    try:
        raw = blowcrypt_b64decode(padto(rest, 12))
    except TypeError:
        raise MalformedError
    if not raw:
        raise MalformedError

    try:
        plain = cipher.decrypt(raw)
    except ValueError:
        raise MalformedError

    return plain.strip('\x00')

##
## AES-CBC
##

def aes_cbc_pack(msg, cipher):
    """."""
    b64_string = binascii.b2a_base64(cipher.encrypt(padto(msg, 16)))
    return '+AES ' + b64_string

def aes_cbc_unpack(msg, cipher):
    """."""
    if not msg.startswith('+AES '):
        raise ValueError
    try:
        _, coded = msg.split(' ', 1)
        coded += "=" * (4 - (len(coded) % 4))
        raw = binascii.a2b_base64(coded)
    except TypeError:
        raise MalformedError
    if not raw:
        raise MalformedError
    try:
        padded = cipher.decrypt(raw)
    except ValueError:
        raise MalformedError
    if not padded:
        raise MalformedError

    plain = padded.strip("\x00")
    return plain


##
## DH1080
##

g_dh1080 = 2
p_dh1080 = int('FBE1022E23D213E8ACFA9AE8B9DFAD'
               'A3EA6B7AC7A7B7E95AB5EB2DF85892'
               '1FEADE95E6AC7BE7DE6ADBAB8A783E'
               '7AF7A7FA6A2B7BEB1E72EAE2B72F9F'
               'A2BFB2A2EFBEFAC868BADB3E828FA8'
               'BADFADA3E4CC1BE7E8AFE85E9698A7'
               '83EB68FA07A77AB6AD7BEB618ACF9C'
               'A2897EB28A6189EFA07AB99A8A7FA9'
               'AE299EFA7BA66DEAFEFBEFBF0B7D8B', 16)
q_dh1080 = (p_dh1080 - 1) / 2


# XXX: It is probably possible to implement dh1080 base64 using Pythons own, by
# considering padding, lengths etc. The dh1080 implementation is basically the
# standard one but with the padding character '=' removed. A trailing 'A'
# is also added sometimes.
def dh1080_b64encode(s):
    """A non-standard base64-encode."""
    b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    d = [0]*len(s)*2

    L = len(s) * 8
    m = 0x80
    i, j, k, t = 0, 0, 0, 0
    while i < L:
        if ord(s[i >> 3]) & m:
            t |= 1
        j += 1
        m >>= 1
        if not m:
            m = 0x80
        if not j % 6:
            d[k] = b64[t]
            t &= 0
            k += 1
        t <<= 1
        t %= 0x100
        #
        i += 1
    m = 5 - j % 6
    t <<= m
    t %= 0x100
    if m:
        d[k] = b64[t]
        k += 1
    d[k] = 0
    res = ''
    for q in d:
        if q == 0:
            break
        res += q
    return res


def dh1080_b64decode(s):
    """A non-standard base64-encode."""
    b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    buf = [0]*256
    for i in range(64):
        buf[ord(b64[i])] = i

    L = len(s)
    if L < 2:
        raise ValueError
    for i in reversed(range(L-1)):
        if buf[ord(s[i])] == 0:
            L -= 1
        else:
            break
    if L < 2:
        raise ValueError

    d = [0]*L
    i, k = 0, 0
    while True:
        i += 1
        if k + 1 < L:
            d[i-1] = buf[ord(s[k])] << 2
            d[i-1] %= 0x100
        else:
            break
        k += 1
        if k < L:
            d[i-1] |= buf[ord(s[k])] >> 4
        else:
            break
        i += 1
        if k + 1 < L:
            d[i-1] = buf[ord(s[k])] << 4
            d[i-1] %= 0x100
        else:
            break
        k += 1
        if k < L:
            d[i-1] |= buf[ord(s[k])] >> 2
        else:
            break
        i += 1
        if k + 1 < L:
            d[i-1] = buf[ord(s[k])] << 6
            d[i-1] %= 0x100
        else:
            break
        k += 1
        if k < L:
            d[i-1] |= buf[ord(s[k])] % 0x100
        else:
            break
        k += 1
    return ''.join(map(chr, d[0:i-1]))


def dh_validate_public(public, q, p):
    """See RFC 2631 section 2.1.5."""
    return 1 == pow(public, q, p)


class DH1080Ctx:
    """DH1080 context."""
    def __init__(self):
        self.public = 0
        self.private = 0
        self.secret = 0
        self.state = 0

        bits = 1080
        while True:
            self.private = bytes2int(urandom(bits/8))
            self.public = pow(g_dh1080, self.private, p_dh1080)
            if 2 <= self.public <= p_dh1080 - 1 and \
               dh_validate_public(self.public, q_dh1080, p_dh1080) == 1:
                break


def dh1080_pack(ctx):
    """."""
    cmd = None
    if ctx.state == 0:
        ctx.state = 1
        cmd = "DH1080_INIT "
    else:
        cmd = "DH1080_FINISH "
    return cmd + dh1080_b64encode(int2bytes(ctx.public))


def dh1080_unpack(msg, ctx):
    """."""
    if not msg.startswith("DH1080_"):
        raise ValueError

    invalidmsg = "Key does not validate per RFC 2631. This check is not " \
                 "performed by any DH1080 implementation, so we use the key " \
                 "anyway. See RFC 2785 for more details."

    if ctx.state == 0:
        if not msg.startswith("DH1080_INIT "):
            raise MalformedError
        ctx.state = 1
        try:
            public_raw = msg[msg.index(' ')+1:]
            public = bytes2int(dh1080_b64decode(public_raw))

            if not 1 < public < p_dh1080:
                raise MalformedError

            if not dh_validate_public(public, q_dh1080, p_dh1080):
                print invalidmsg

            ctx.secret = pow(public, ctx.private, p_dh1080)
        except:
            raise MalformedError

    elif ctx.state == 1:
        if not msg.startswith("DH1080_FINISH "):
            raise MalformedError
        ctx.state = 1
        try:
            public_raw = msg[msg.index(' ')+1:]
            public = bytes2int(dh1080_b64decode(public_raw))

            if not 1 < public < p_dh1080:
                raise MalformedError

            if not dh_validate_public(public, q_dh1080, p_dh1080):
                print invalidmsg

            ctx.secret = pow(public, ctx.private, p_dh1080)
        except:
            raise MalformedError

    return True


def dh1080_secret(ctx):
    """."""
    if ctx.secret == 0:
        raise ValueError
    return dh1080_b64encode(sha256(int2bytes(ctx.secret)))


###############################

PLAINTEXT_MARKER = '+p'
AES_MARKER = '+a'
BFS_MARKER = '+b'
KEYPASS= ''
LINELEN=200

class KeyMap(dict):
    def __get_real_key(self, key):
        nick, server = (key[0], key[1].lower())
        same_nick_keys = [k[1] for k in self.iterkeys() if k[0] == nick]
        same_nick_keys.sort(key=lambda k: len(k), reverse=True)
        for k in same_nick_keys:
            if server.rfind(k) >= 0:
                return (nick, k)

    def __getitem__(self, key):
        return dict.__getitem__(self, self.__get_real_key(key))

    def __contains__(self, key):
        return dict.__contains__(self, self.__get_real_key(key))

KEY_MAP = KeyMap()
LOCK_MAP = {}

class SecretKey(object):
    def __init__(self, dh, key=None):
        self.dh = dh
        self.key = key
        self.hashKey = ""
        self.aes = True

def set_processing():
        id_ = xchat.get_info('server')
        LOCK_MAP[id_] = True

def unset_processing():
        id_ = xchat.get_info('server')
        LOCK_MAP[id_] = False

def is_processing():
        id_ = xchat.get_info('server')
        return LOCK_MAP.get(id_, False)

def get_id(ctx):
        return (ctx.get_info('channel'), ctx.get_info('server'))

def get_nick(full):
        if full[0] == ':':
            full = full[1 : ]
        return full[ : full.index('!')]

def get_id_for(ctx, speaker):
    return (get_nick(speaker), ctx.get_info('server'))

def unload(userdata):
        tmp_map = KeyMap()
        encrypted_file = os.path.join(xchat.get_info('xchatdir'),
        'XChatAES_secure.pickle')
        if os.path.exists(encrypted_file):
            return
        for id_, key in KEY_MAP.iteritems():
            if key.key:
                tmp_map[id_] = key
                key.dh = None
        if KEYPASS!='':
            with open(os.path.join(xchat.get_info('xchatdir'),
           'XChatAES.pickle'), 'wb') as f:
                pickle.dump(tmp_map, f)
                print 'Passwords saved!'
        print 'XChatAES unloaded'

def decrypt(key, inp, mode):
        if mode == 'aes':
            decrypt_clz = AESCBC
            decrypt_func = aes_cbc_unpack
            b = decrypt_clz(key.hashKey)
        if mode =='bfs':
            decrypt_clz = Blowfish
            decrypt_func = blowcrypt_unpack
            b = decrypt_clz(key.key)
        return decrypt_func(inp, b)

def encrypt(key, inp, mode):
        if mode == '+':
            encrypt_clz = AESCBC
            encrypt_func = aes_cbc_pack
            b = encrypt_clz(key.hashKey)
            return encrypt_func(inp, b)
        if mode == '-':
            encrypt_clz = Blowfish
            encrypt_func = blowcrypt_pack
            b = encrypt_clz(key.key)
            return encrypt_func(inp, b)
        return inp

def decrypt_print(word, word_eol, userdata):
        if is_processing():
            return xchat.EAT_NONE
        ctx = xchat.get_context()
        id_ = get_id(ctx)
        if id_ not in KEY_MAP:
            return xchat.EAT_NONE
        speaker, message = word[0], word_eol[1]
        if len(word_eol) >= 3:
            message = message[ : -(len(word_eol[2]) + 1)]
        if message.startswith('+AES '):
            message = decrypt(KEY_MAP[id_], message,'aes')
            set_processing()
            ctx.emit_print(userdata, speaker+" +", message)
            unset_processing()
            return xchat.EAT_XCHAT
        if message.startswith('+OK '):
            message = decrypt(KEY_MAP[id_], message,'bfs')
            set_processing()
            ctx.emit_print(userdata, speaker +" -", message)
            unset_processing()
            return xchat.EAT_XCHAT
        else:
            set_processing()
            ctx.emit_print(userdata, speaker +" !", message)
            unset_processing()
            return xchat.EAT_XCHAT

def encrypt_privmsg(word, word_eol, userdata):
        message = word_eol[0]
        ctx = xchat.get_context()
        id_ = get_id(ctx)
        if id_ not in KEY_MAP:
            return xchat.EAT_NONE
        key = KEY_MAP[id_]
        if not key.key or message.startswith(PLAINTEXT_MARKER):
            cipherMode='!'
            if message.startswith(PLAINTEXT_MARKER):
                message=message[len(PLAINTEXT_MARKER)+1:]
        else:
            if (key.aes or message.startswith(AES_MARKER)) and not message.startswith(BFS_MARKER):
                cipherMode='+'
                if message.startswith(AES_MARKER):
                    message=message[len(AES_MARKER)+1:]
            else:
                cipherMode='-'
                if message.startswith(BFS_MARKER):
                    message=message[len(BFS_MARKER)+1:]
        while (len(message)>0):
            messageSplit=""
            if (len(message)>LINELEN):
                messageSplit=message[LINELEN:]
            cipher = encrypt(key, message[0:LINELEN],cipherMode)
            xchat.command('PRIVMSG %s :%s' % (id_[0], cipher))
            xchat.emit_print('Your Message', xchat.get_info('nick')+" "+cipherMode, message)
            message=messageSplit
        return xchat.EAT_ALL

def key(word, word_eol, userdata):
        ctx = xchat.get_context()
        target = ctx.get_info('channel')
        if len(word) >= 2:
            target = word[1]
        server = ctx.get_info('server')
        if len(word) >= 4:
            if word[2] == '--network':
                server = word[3]
        id_ = (target, server)
        try:
            key = KEY_MAP[id_]
        except KeyError:
            key = SecretKey(None)
        if len(word) >= 3 and word[2] != '--network':
            key.key = word_eol[2]
            KEY_MAP[id_] = key
        elif len(word) >= 5 and word[2] == '--network':
            key.key = word_eol[4]
        KEY_MAP[id_] = key
        KEY_MAP[id_].hashKey=sha256(key.key)
        print 'Key for', id_, 'set to', key.key, "( AES =",key.aes,")"
        return xchat.EAT_ALL

def key_exchange(word, word_eol, userdata):
            ctx = xchat.get_context()
            target = ctx.get_info('channel')
            if len(word) >= 2:
                target = word[1]
                id_ = (target, ctx.get_info('server'))
                dh = DH1080Ctx()
                KEY_MAP[id_] = SecretKey(dh)
                ctx.command('NOTICE %s %s' % (target, dh1080_pack(dh)))
            return xchat.EAT_ALL

def dh1080_finish(word, word_eol, userdata):
            ctx = xchat.get_context()
            #speaker, command, target, message = word[0], word[1], word[2], word_eol[3]
            speaker, message = word[0], word_eol[3]
            id_ = get_id_for(ctx, speaker)
            print 'dh1080_finish', id_
            if id_ not in KEY_MAP:
                return xchat.EAT_NONE
            key = KEY_MAP[id_]
            dh1080_unpack(message[1 : ], key.dh)
            key.key = dh1080_secret(key.dh)
            key.hashKey=sha256(key.key)
            print 'Key for', id_[0], 'set to', key.key
            return xchat.EAT_ALL

def dh1080_init(word, word_eol, userdata):
            ctx = xchat.get_context()
            speaker, message = word[0], word_eol[3]
            id_ = get_id_for(ctx, speaker)
            key = SecretKey(None)
            dh = DH1080Ctx()
            dh1080_unpack(message[1 : ], dh)
            key.key = dh1080_secret(dh)
            key.hashKey=sha256(key.key)
            xchat.command('NOTICE %s %s' % (id_[0], dh1080_pack(dh)))
            KEY_MAP[id_] = key
            print 'Key for', id_[0], 'set to', key.key
            return xchat.EAT_ALL

def dh1080(word, word_eol, userdata):
            if word_eol[3].startswith(':DH1080_FINISH'):
                return dh1080_finish(word, word_eol, userdata)
            elif word_eol[3].startswith(':DH1080_INIT'):
                return dh1080_init(word, word_eol, userdata)
            return xchat.EAT_NONE

def load():
            print 'XChatAES loaded'

def key_pass(word, word_eol, userdata):
        global KEYPASS
        KEYPASS=sha256(word[1])
        print 'key pass =',word[1]
        return xchat.EAT_ALL

def key_load(word, word_eol, userdata):
            global KEY_MAP
            try:
                with open(os.path.join(xchat.get_info('xchatdir'),
                'XChatAES.pickle'), 'rb') as f:
                    KEY_MAP = pickle.load(f)
            except IOError:
                pass
            print 'keys loaded'
            return xchat.EAT_ALL

def key_list(word, word_eol, userdata):
            print 'Found', len(KEY_MAP), 'key(s)'
            for id_, key in KEY_MAP.iteritems():
                print id_, key.key, "( AES =",key.aes,")"
            return xchat.EAT_ALL

def key_remove(word, word_eol, userdata):
            id_ = (word[1], xchat.get_info('server'))
            if id_ not in KEY_MAP and len(word) > 2:
                id_ = (word[1], word[2])
            try:
                del KEY_MAP[id_]
            except KeyError:
                print 'Key not found'
            else:
                print 'Key removed'
            return xchat.EAT_ALL

def server_332(word, word_eol, userdata):
            if is_processing():
                return xchat.EAT_NONE
            id_ = get_id(xchat.get_context())
            if id_ not in KEY_MAP:
                return xchat.EAT_NONE
            key = KEY_MAP[id_]
            server, cmd, nick, channel, topic = word[0], word[1], word[2], word[3], word_eol[4]
            if topic[0] == ':':
                topic = topic[1 : ]
            if not topic.startswith('+AES '):
                return xchat.EAT_NONE
            topic = decrypt(key, topic)
            set_processing()
            xchat.command('RECV %s %s %s %s :%s' % (server, cmd, nick, channel, topic))
            unset_processing()
            return xchat.EAT_ALL

def change_nick(word, word_eol, userdata):
            old, new = word[0], word[1]
            old_id = (old, xchat.get_info('server'))
            new_id = (new, xchat.get_info('server'))
            try:
                KEY_MAP[new_id] = KEY_MAP[old_id]
                del KEY_MAP[old_id]
            except KeyError:
                pass
            return xchat.EAT_NONE

def aes(word, word_eol, userdata):
        ctx = xchat.get_context()
        target = ctx.get_info('channel')
        if len(word) >= 2:
            target = word[1]
        server = ctx.get_info('server')
        if len(word) >= 4:
            if word[2] == '--network':
                server = word[3]
        id_ = (target, server)
        try:
            key = KEY_MAP[id_]
        except KeyError:
            print 'Key don\'t exist!'
            return xchat.EAT_ALL
        if len(word) >= 3 and word[2] != '--network':
            if word_eol[2]=="1" or word_eol[2]=="True" or word_eol[2]=="true":
                key.aes = True
            if word_eol[2]=="0" or word_eol[2]=="False" or word_eol[2]=="false":
                key.aes = False
            KEY_MAP[id_] = key
        elif len(word) >= 5 and word[2] == '--network':
            if word_eol[4]=="1" or word_eol[4]=="True" or word_eol[4]=="true":
                key.aes = True
            if word_eol[4]=="0" or word_eol[4]=="False" or word_eol[4]=="false":
                key.aes = False
        print 'Key aes', id_, 'set', key.aes
        return xchat.EAT_ALL

import xchat
xchat.hook_command('key', key, help='show information or set key, /key <nick> [<--network> <network>] [new_key]')
xchat.hook_command('key_exchange', key_exchange, help='exchange a new key, /key_exchange <nick>')
xchat.hook_command('key_list', key_list, help='list keys, /key_list')
xchat.hook_command('key_load', key_load, help='load keys, /key_load')
xchat.hook_command('key_pass', key_pass, help='set key file pass, /key_pass password')
xchat.hook_command('aes', aes, help='aes #channel/nick 1|0 or True|False')
xchat.hook_command('key_remove', key_remove, help='remove key, /key_remove <nick>')
xchat.hook_server('notice', dh1080)
xchat.hook_print('Channel Message', decrypt_print, 'Channel Message')
xchat.hook_print('Change Nick', change_nick)
xchat.hook_print('Private Message to Dialog', decrypt_print, 'Private Message to Dialog')
xchat.hook_server('332', server_332)
xchat.hook_command('', encrypt_privmsg)
xchat.hook_unload(unload)
load()
