#!/bin/bash

source /home/sample/scripts/dataset.sh

sec=5

function kill_proc() {
    header

    onecheck=$(uptime | awk '{print $(NF-2)*100}' | sed 's/,//g')

    while [ $onecheck -gt 1000 ]; do
        kill -9 $(ps aux | grep "wp-cron.php\|admin-ajax.php\|index.php" | grep -v "grep" | awk '{print $2}')

        printf "%-13s %-11s %-21s\n" "$date" "$(date +"%T")" "PHP Process Killed" >>$svrlogs/status/killproc_$date.txt

        sleep $sec

        onecheck=$(uptime | awk '{print $(NF-2)*100}' | sed 's/,//g')

    done
}

function header() {
    if [ ! -f $svrlogs/status/killproc_$date.txt ]; then
        printf "%-13s %-11s %-21s\n" "DATE" "TIME" "STAT" >>$svrlogs/status/killproc_$date.txt
    fi
}

kill_proc
