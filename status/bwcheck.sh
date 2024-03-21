#!/bin/bash

source /home/sample/scripts/dataset.sh

function bw_check() {
	bandwidthusage=($(find $svrlogs/serverwatch -type f -name "bandwidth*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $bandwidthusage ]]; then
		bandwidth=$(cat $bandwidthusage | grep "Total" | sed 's/Total//')

		type=$(echo "$bandwidth" | awk '{print $2}')

		bw=$(echo "$bandwidth" | awk -F'.' '{print $1}')

		header

		ctime=$(date +"%T")

		printf "%-13s %-11s %-10s\n" "$date" "$ctime" "$bw $type" >>$svrlogs/status/bwcheck_$logtime.txt

		if [[ "$type" == "G" ]]; then

			if [ $bw -gt 2048 ]; then
				content=$(echo "Bandwidth: $bw $type - LIMIT EXCEEDED")

				send_sms

				send_mail
			fi
		fi
	fi
}

function header() {
	if [ ! -f $svrlogs/status/bwcheck_$logtime.txt ]; then
		printf "%-13s %-11s %-12s\n" "DATE" "TIME" "BANDWIDTH" >>$svrlogs/status/bwcheck_$logtime.txt
	fi
}

function send_sms() {
	message=$(echo "$hostname: $content")

	#php $scripts/send_sms.php "$message" "$validation"

	curl -X POST -H "Content-type: application/json" --data "{\"text\":\"$message\"}" $statusslack
}

function send_mail() {
	echo "SUBJECT: BW Check - $(hostname) - $(date +"%F")" >>$svrlogs/mail/bwmail_$time.txt
	echo "FROM: Bandwidth Check <root@$(hostname)>" >>$svrlogs/mail/bwmail_$time.txt
	echo "" >>$svrlogs/mail/bwmail_$time.txt
	printf "%-10s %20s\n" "Date:" "$(date +"%F")" >>$svrlogs/mail/bwmail_$time.txt
	printf "%-10s %20s\n" "Time:" "$(date +"%T")" >>$svrlogs/mail/bwmail_$time.txt
	printf "%-10s %20s\n" "BW:" "$bw $type" >>$svrlogs/mail/bwmail_$time.txt
	printf "%-10s %20s\n" "Status:" "LIMIT EXCEEDED" >>$svrlogs/mail/bwmail_$time.txt
	sendmail "$emailmo,$emailmg" <$svrlogs/mail/bwmail_$time.txt
}

bw_check
