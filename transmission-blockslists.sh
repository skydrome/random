#!/usr/bin/env bash

url=('http://list.iblocklist.com/?list=ijfqtofzixtwayqovmxn&fileformat=p2p&archiveformat=gz'
	 'http://list.iblocklist.com/?list=bt_level1&fileformat=p2p&archiveformat=gz')

name=('tbgprimarythreats' 'bluetacklevel1')

cd ~/.config/transmission/blocklists

ok='echo -e "\e[1;32m✔ ok\e[0m"'
fail='echo -e "\e[1;31m✘ fail\e[0m"'

for (( i=0; i<${#url[@]}; i++ )); do
	echo -en "[${name[$i]}]\n\tdownloading» "
	curl -L "${url[$i]}" -o "${name[$i]}.gz" &>/dev/null && {
		echo -en "extracting» "
		gunzip -f "${name[$i]}.gz" &&
			eval $ok || eval $fail
	} || eval $fail
done
