#!/bin/bash

source /home/sample/scripts/dataset.sh

function df_check() {
	diskfree=$(echo "$(df -Th | egrep "vda1|sda1" | awk '{print $(NF-1)}')")

	df=$(echo "$diskfree" | awk -F'%' '{print $1}')

	header

	ctime=$(date +"%T")

	printf "%-13s %-11s %-8s\n" "$date" "$ctime" "$df" >>$svrlogs/status/dfcheck_$logtime.txt

	if [ $df -ge 85 ]; then
		content=$(echo "Disk Usage: $diskfree - LIMIT EXCEEDED")

		send_sms

		send_mail
	fi
}

function header() {
	if [ ! -f $svrlogs/status/dfcheck_$logtime.txt ]; then
		printf "%-13s %-11s %-8s\n" "DATE" "TIME" "DU(%)" >>$svrlogs/status/dfcheck_$logtime.txt
	fi
}

function send_sms() {
	message=$(echo "$hostname: $content")

	php $scripts/send_sms.php "$message" "$validation"

	curl -X POST -H "Content-type: application/json" --data "{\"text\":\"$message\"}" $statusslack
}

function send_mail() {
	echo "SUBJECT: Disk Usage Check - $(hostname) - $(date +"%F")" >>$svrlogs/mail/dfmail_$time.txt
	echo "FROM: Disk Usage Check <root@$(hostname)>" >>$svrlogs/mail/dfmail_$time.txt
	echo "" >>$svrlogs/mail/dfmail_$time.txt
	printf "%-10s %20s\n" "Date:" "$(date +"%F")" >>$svrlogs/mail/dfmail_$time.txt
	printf "%-10s %20s\n" "Time:" "$(date +"%T")" >>$svrlogs/mail/dfmail_$time.txt
	printf "%-10s %20s\n" "DU:" "$diskfree" >>$svrlogs/mail/dfmail_$time.txt
	printf "%-10s %20s\n" "Status:" "LIMIT EXCEEDED" >>$svrlogs/mail/dfmail_$time.txt
	sendmail "$emailmo,$emailmg" <$svrlogs/mail/dfmail_$time.txt
}

df_check
