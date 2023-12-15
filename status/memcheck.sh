#!/bin/bash

source /home/sample/scripts/dataset.sh

function mem_check() {
    mem=$(free -m | grep "Mem:")

    total=$(echo "$mem" | awk '{print $2}')
    used=$(echo "$mem" | awk '{print $3}')
    free=$(echo "$mem" | awk '{print $4}')
    cache=$(echo "$mem" | awk '{print $6}')

    usedp=$(echo "$used" | awk -v used=$used -v total=$total 'BEGIN {pct=(used/total)*100 ; printf "%d",pct}')
    freep=$(echo "$free" | awk -v free=$free -v total=$total 'BEGIN {pct=(free/total)*100 ; printf "%d",pct}')
    cachep=$(echo "$cache" | awk -v cache=$cache -v total=$total 'BEGIN {pct=(cache/total)*100 ; printf "%d",pct}')

    if [ $freep -lt 5 ]; then
        header

        ctime=$(date +"%T")

        printf "%-13s %-11s %-10s %-10s %-11s\n" "$date" "$ctime" "$usedp" "$freep" "$cachep" >>$svrlogs/status/memcheck_$date.txt

        sync; echo 1 >/proc/sys/vm/drop_caches

        #send_mail
    fi
}

function header() {
    if [ ! -f $svrlogs/status/memcheck_$date.txt ]; then
		printf "%-13s %-11s %-10s %-10s %-11s\n" "DATE" "TIME" "USED(%)" "FREE(%)" "CACHE(%)" >>$svrlogs/status/memcheck_$date.txt
	fi
}

function send_mail() {
        echo "SUBJECT: Mem Check - $(hostname) - $(date +"%F")" >>$svrlogs/mail/mcmail_$time.txt
        echo "FROM: Memory Check <root@$(hostname)>" >>$svrlogs/mail/mcmail_$time.txt
        echo "" >>$svrlogs/mail/mcmail_$time.txt
        printf "%-10s %20s\n" "Date:" "$(date +"%F")" >>$svrlogs/mail/mcmail_$time.txt
        printf "%-10s %20s\n" "Time:" "$(date +"%T")" >>$svrlogs/mail/mcmail_$time.txt
        printf "%-10s %20s\n" "Used:" "$usedp%" >>$svrlogs/mail/mcmail_$time.txt
        printf "%-10s %20s\n" "Free:" "$freep%" >>$svrlogs/mail/mcmail_$time.txt
        printf "%-10s %20s\n" "Cache:" "$cachep%" >>$svrlogs/mail/mcmail_$time.txt
        sendmail "$emailmo,$emailmg" <$svrlogs/mail/mcmail_$time.txt
}

mem_check
