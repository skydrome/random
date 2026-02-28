# Preferences -> Package Settings -> Theme Monokai Pro -> Settings

import hashlib
import sys

email = 'alt@alt.net'

if len(sys.argv) > 1:
    email = sys.argv[1]

hash_object = hashlib.md5(email.encode('utf-8'))
hex_digest = hash_object.hexdigest()
hash_array = [hex_digest[i:i + 5] for i in range(0, len(hex_digest), 5)]
license = '-'.join(hash_array[0:5])

print(f'"email": "{email}",')
print(f'"license_key": "{license}",')
