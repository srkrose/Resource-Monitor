#!/bin/bash

source /home/sample/scripts/dataset.sh

function dom_log() {
	egrep "wp-login.php|xmlrpc.php|admin.php" /var/log/apache2/domlogs/*/* | awk '{for(i=1;i<=NF;i++) {if($i~/HTTP/) print $1,$4,$6,$(i+1)}}' | awk -F'[/ :]' '{printf "%-20s %-22s %-13s %-12s %-25s %-50s\n","DATE: "$11"-"$10"-"$9,"IP: "$8,"TYPE: "$15,"STAT: "$16,"USER: "$6,"LOG: "$7}' | sed 's/[][]//;s/"//g' | sort | uniq -c | sort -nr | grep -ie "$(date +"%Y-%b-%d")" | awk '{if($1>=1000 && $9==200) print}' >>$temp/domlog_$time.txt

	ips=$(cat $temp/domlog_$time.txt | awk '{print $5}' | sort | uniq)

	if [[ ! -z $ips ]]; then
		while IFS= read -r line || [[ -n "$line" ]]; do
			ip=$(echo "$line" | awk '{print $5}')
			user=$(echo "$line" | awk '{print $11}')

			stat=$(csf -g $ip | grep "csf.deny\|csf.allow")

			if [[ -z $stat ]]; then
				csf -d $ip loadavg-$user-domlog

				logline=$(echo "$line" | awk -F'LOG:' '{print $1}')

				printf "%-100s %-20s\n" "$logline" "CSF: Blocked" >>$svrlogs/status/domipblock_$time.txt
			fi

		done <"$temp/domlog_$time.txt"
	fi
}

dom_log
