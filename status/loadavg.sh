#!/bin/bash

source /home/sample/scripts/dataset.sh

function load_avg() {
	loadavg=$(uptime | awk '{print $1,$(NF-2),$(NF-1),$NF}' | sed 's/,//g')

	avgt=$(echo "$loadavg" | awk '{print $1}')
	onem=$(echo "$loadavg" | awk '{print $2}')
	fivm=$(echo "$loadavg" | awk '{print $3}')
	fifm=$(echo "$loadavg" | awk '{print $4}')
	onecheck=$(echo "$loadavg" | awk '{print $2*100}')

	if [[ $onecheck -gt 1000 ]]; then
		header

		printf "%-13s %-11s %-9s %-9s %-9s\n" "$date" "$avgt" "$onem" "$fivm" "$fifm" >>$svrlogs/status/loadavg_$date.txt

		prev=$(cat $svrlogs/status/loadavg_$date.txt | tail -2 | head -1 | awk '{print $2}' | awk -F':' '{print $1":"$2}')
		mago=$(date -d '1 minute ago' +"%H:%M")

		if [[ $prev == $mago ]]; then
			prvcheck=$(cat $svrlogs/status/loadavg_$date.txt | tail -2 | head -1 | awk '{print $3*100}')

			if [[ $onecheck -gt $prvcheck && $onecheck -gt 1500 ]]; then
				content=$(echo "HLA: $loadavg")

				sh $scripts/status/killproc.sh

				stat="PHP Process Killed"

				dtime=$(date +"%F_%H:%M:")

				sh $scripts/status/domlog.sh

				btime=$(date +"%F_%H:%M:")

				sh $scripts/status/botlog.sh

				send_sms

				send_mail
			fi
		fi
	fi
}

function header() {
	if [ ! -f $svrlogs/status/loadavg_$date.txt ]; then
		printf "%-13s %-11s %-9s %-9s %-9s\n" "DATE" "TIME" "1 MIN" "5 MIN" "15 MIN" >>$svrlogs/status/loadavg_$date.txt
	fi
}

function send_sms() {
	message=$(echo "$hostname: $content")

	php $scripts/send_sms.php "$message" "$validation"

	curl -X POST -H "Content-type: application/json" --data "{\"text\":\"$message\"}" $statusslack
}

function send_mail() {
	domip=($(find $svrlogs/status -type f -name "domipblock*" -exec ls -lat {} + | grep "$dtime" | head -1 | awk '{print $NF}'))
	dcount=$(cat $domip | wc -l)

	botip=($(find $svrlogs/status -type f -name "botipblock*" -exec ls -lat {} + | grep "$btime" | head -1 | awk '{print $NF}'))
	bcount=$(cat $botip | wc -l)

	echo "SUBJECT: High Load Average - $(hostname) - $(date +"%F")" >>$svrlogs/mail/hlamail_$time.txt
	echo "FROM: Load Average <root@$(hostname)>" >>$svrlogs/mail/hlamail_$time.txt
	echo "" >>$svrlogs/mail/hlamail_$time.txt
	printf "%-10s %20s\n" "Date:" "$(date +"%F")" >>$svrlogs/mail/hlamail_$time.txt
	printf "%-10s %20s\n" "Time:" "$(date +"%T")" >>$svrlogs/mail/hlamail_$time.txt
	printf "%-10s %20s\n" "One:" "$onem" >>$svrlogs/mail/hlamail_$time.txt
	printf "%-10s %20s\n" "Five:" "$fivm" >>$svrlogs/mail/hlamail_$time.txt
	printf "%-10s %20s\n" "Fifteen:" "$fifm" >>$svrlogs/mail/hlamail_$time.txt

	if [[ ! -z $stat ]]; then
		echo "" >>$svrlogs/mail/hlamail_$time.txt
		echo "STAT: $stat" >>$svrlogs/mail/hlamail_$time.txt
	fi

	if [[ ! -z $domip ]]; then
		echo "" >>$svrlogs/mail/hlamail_$time.txt
		echo "Dom CSF Blocked:" >>$svrlogs/mail/hlamail_$time.txt
		echo "Total: $dcount" >>$svrlogs/mail/hlamail_$time.txt
		cat $domip >>$svrlogs/mail/hlamail_$time.txt
	fi

	if [[ ! -z $botip ]]; then
		echo "" >>$svrlogs/mail/hlamail_$time.txt
		echo "Bot CSF Blocked:" >>$svrlogs/mail/hlamail_$time.txt
		echo "Total: $bcount" >>$svrlogs/mail/hlamail_$time.txt
		cat $botip >>$svrlogs/mail/hlamail_$time.txt
	fi

	sendmail "$emailmo,$emailmg" <$svrlogs/mail/hlamail_$time.txt
}

load_avg
