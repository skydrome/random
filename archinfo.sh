#/bin/bash

clear
echo -e "\e[34m
   _____                .__      .____    .__
  /  _  \_______   ____ |  |__   |    |   |__| ____  __ _____  ___
 /  /_\  \_  __ \_/ ___\|  |  \  |    |   |  |/    \|  |  \  \/  /
/    |    \  | \/\  \___|   Y  \ |    |___|  |   |  \  |  />    <
\____|__  /__|    \___  >___|  / |_______ \__|___|  /____//__/\_ \\
        \/            \/     \/          \/       \/            \/
\e[0m"


awk '// {
	sec = int($1)
	days = int(sec/3600/24)
	sec -= days*24*3600
	hours = int(sec/3600)
	sec -= hours*3600
	mins = int(sec/60)
	sec -= mins*60
	secs = int(sec)
	printf "\033[1;32m Uptime \033[1;34m»\033[0m %i days, %ih %im %is\n",
    days, hours, mins, secs; }' /proc/uptime

awk '// {printf "\033[1;32m Kernel \033[1;34m»\033[0m %s\n", $3}' /proc/version

awk '/^model name/ {
	print "\033[1;32m CPU    \033[1;34m»\033[0m",$4,$5,$6,$7,$8,$9;
	exit; }' /proc/cpuinfo

awk '
/Mem:/ { total=$2; }
/cache:/ {
	printf "\033[1;32m RAM    \033[1;34m»\033[0m %i MB / %i MB (\033[0;33m%i\033[0m%)\n",
        $3, total, $3*100/total; }' <(free -m)

awk '
/root/ {
	printf "\033[1;32m ROOT   \033[1;34m»\033[0m %.1f GB / %.1f GB (\033[0;33m%i\033[0m%) (%s)\n",
		$4/1000000,$3/1000000,$4*100/$3,$2;
}
/home/ {
	printf "\033[1;32m HOME   \033[1;34m»\033[0m %.1f GB / %.1f GB (\033[0;33m%i\033[0m%) (%s)\n",
		$4/1000000,$3/1000000,$4*100/$3,$2; }' <(/bin/df -T)

echo
