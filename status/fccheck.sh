#!/bin/bash

source /home/sample/scripts/dataset.sh

function fc_check() {
	filecount=($(find $svrlogs/filecount -type f -name "homedir*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $filecount ]]; then
		fcount=$(cat $filecount | grep "FILE COUNT" | awk '{print $NF}')

		header

		ctime=$(date +"%T")

		printf "%-13s %-11s %-13s\n" "$date" "$ctime" "$fcount" >>$svrlogs/status/fccheck_$logtime.txt

		if [ $fcount -gt 30000000 ]; then
			content=$(echo "File Count: $fcount - LIMIT EXCEEDED")

			send_sms

			send_mail
		fi
	fi
}

function header() {
	if [ ! -f $svrlogs/status/fccheck_$logtime.txt ]; then
		printf "%-13s %-11s %-13s\n" "DATE" "TIME" "FILE_COUNT" >>$svrlogs/status/fccheck_$logtime.txt
	fi
}

function send_sms() {
	message=$(echo "$hostname: $content")

	#php $scripts/send_sms.php "$message" "$validation"

	curl -X POST -H "Content-type: application/json" --data "{\"text\":\"$message\"}" $statusslack
}

function send_mail() {
	echo "SUBJECT: File Count Check - $(hostname) - $(date +"%F")" >>$svrlogs/mail/fcmail_$time.txt
	echo "FROM: File Count Check <root@$(hostname)>" >>$svrlogs/mail/fcmail_$time.txt
	echo "" >>$svrlogs/mail/fcmail_$time.txt
	printf "%-10s %20s\n" "Date:" "$(date +"%F")" >>$svrlogs/mail/fcmail_$time.txt
	printf "%-10s %20s\n" "Time:" "$(date +"%T")" >>$svrlogs/mail/fcmail_$time.txt
	printf "%-10s %20s\n" "FC:" "$fcount" >>$svrlogs/mail/fcmail_$time.txt
	printf "%-10s %20s\n" "Status:" "LIMIT EXCEEDED" >>$svrlogs/mail/fcmail_$time.txt
	sendmail "$emailmo,$emailmg" <$svrlogs/mail/fcmail_$time.txt
}

fc_check
