#!/bin/bash

source /home/sample/scripts/dataset.sh

function bot_log() {
	egrep -i "bot" /var/log/apache2/domlogs/*/* | awk '{for(i=1;i<=NF;i++) {for(j=1;j<=NF;j++) {if($i~/HTTP/ && $j~/+http:/) print $1,$4,$6,$(i+1),$(j-1)}}}' | awk -F'[/ :]' '{printf "%-20s %-22s %-13s %-12s %-20s %-25s %-50s\n","DATE: "$11"-"$10"-"$9,"IP: "$8,"TYPE: "$15,"STAT: "$16,"BOT: "$17,"USER: "$6,"LOG: "$7}' | sed 's/[][]//;s/(//;s/;//;s/"//g' | sort | uniq -c | sort -nr | grep -ie "$(date +"%Y-%b-%d")" | awk '{if($1>=100 && $9==200) print}' >>$temp/botlog_$time.txt

	ips=$(cat $temp/botlog_$time.txt | awk '{print $5}' | sort | uniq)

	if [[ ! -z $ips ]]; then
		while IFS= read -r line || [[ -n "$line" ]]; do
			ip=$(echo "$line" | awk '{print $5}')
			user=$(echo "$line" | awk '{print $13}')
            bot=$(echo "$line" | awk '{print $11}')

			stat=$(csf -g $ip | grep "csf.deny\|csf.allow")

			if [[ -z $stat ]]; then
				csf -d $ip loadavg-$user-$bot-botlog

				logline=$(echo "$line" | awk -F'LOG:' '{print $1}')

				printf "%-120s %-20s\n" "$logline" "CSF: Blocked" >>$svrlogs/status/botipblock_$time.txt
			fi

		done <"$temp/botlog_$time.txt"
	fi
}

bot_log
