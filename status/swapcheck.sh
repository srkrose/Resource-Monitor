#!/bin/bash

source /home/sample/scripts/dataset.sh

function swap_check() {
	swap=$(free -m | grep "Swap:")

	total=$(echo "$swap" | awk '{print $2}')
	used=$(echo "$swap" | awk '{print $3}')
	free=$(echo "$swap" | awk '{print $4}')

	usedp=$(echo "$used" | awk -v used=$used -v total=$total 'BEGIN {pct=(used/total)*100 ; printf "%d",pct}')
	freep=$(echo "$free" | awk -v free=$free -v total=$total 'BEGIN {pct=(free/total)*100 ; printf "%d",pct}')

	if [ $usedp -ge 75 ]; then
		header

		content=$(echo "Swap Usage: $usedp - LIMIT EXCEEDED")

		send_sms

		ctime=$(date +"%T")

		start=$(date +"%T")

		swapoff -a

		swapon -a

		end=$(date +"%T")

		printf "%-13s %-11s %-10s %-10s %-11a %-11s\n" "$date" "$ctime" "$usedp" "$freep" "$start" "$end" >>$svrlogs/status/swapcheck_$date.txt

		send_mail
	fi
}

function header() {
	if [ ! -f $svrlogs/status/swapcheck_$date.txt ]; then
		printf "%-13s %-11s %-10s %-10s %-11s %-11s\n" "DATE" "TIME" "USED(%)" "FREE(%)" "START" "END" >>$svrlogs/status/swapcheck_$date.txt
	fi
}

function send_sms() {
	message=$(echo "$hostname: $content")

	php $scripts/send_sms.php "$message" "$validation"

	curl -X POST -H "Content-type: application/json" --data "{\"text\":\"$message\"}" $statusslack
}

function send_mail() {
	echo "SUBJECT: Swap Check - $(hostname) - $(date +"%F")" >>$svrlogs/mail/scmail_$time.txt
	echo "FROM: Swap Check <root@$(hostname)>" >>$svrlogs/mail/scmail_$time.txt
	echo "" >>$svrlogs/mail/scmail_$time.txt
	printf "%-10s %20s\n" "Date:" "$(date +"%F")" >>$svrlogs/mail/scmail_$time.txt
	printf "%-10s %20s\n" "Time:" "$(date +"%T")" >>$svrlogs/mail/scmail_$time.txt
	printf "%-10s %20s\n" "Used:" "$usedp%" >>$svrlogs/mail/scmail_$time.txt
	printf "%-10s %20s\n" "Free:" "$freep%" >>$svrlogs/mail/scmail_$time.txt
	printf "%-10s %20s\n" "Start:" "$start" >>$svrlogs/mail/scmail_$time.txt
	printf "%-10s %20s\n" "End:" "$end" >>$svrlogs/mail/scmail_$time.txt
	sendmail "$emailmo,$emailmg" <$svrlogs/mail/scmail_$time.txt
}

swap_check
