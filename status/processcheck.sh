#!/bin/bash

source /home/sample/scripts/dataset.sh

function process_list() {
    ps aux | awk 'NR==1; NR > 1 {if ($1!="root" && $1!="nobody" && $1!="mailman" && $1!="mailnull" && $1!="dovecot" && $1!="dovenull" && $1!="named" && $1!="dbus" && $1!="rpc" && $1!="nscd" && $1!="mysql" && $1!="postgres" && $1!="csf" && $1!="chrony" && $1!="libstor+" && $1!="wp-tool+" && $1!="polkitd" && $1!="memcach+" && $1!="zabbix") print $0 | "sort -hk3"}' | grep -v "dovecot\|php-fpm" >>$temp/processlist_$time.txt
}

function process_kill() {
    if [ -r $temp/processlist_$time.txt ] && [ -s $temp/processlist_$time.txt ]; then
        curhour=$(date +"%H")

        while IFS= read -r line || [[ -n "$line" ]]; do
            proctime=$(echo "$line" | awk '{print $9}')

            if [[ "$proctime" == "START" ]]; then
                echo "$line" >>$temp/killedprocesslist_$time.txt
            else
                prochour=$(echo "$proctime" | awk -F':' '{print $1}')

                if [[ "$prochour" != "$curhour" ]]; then
                    echo "$line" >>$temp/killedprocesslist_$time.txt

                    pid=$(echo "$line" | awk '{print $2}')

                    kill -9 $pid
                fi
            fi

        done <"$temp/processlist_$time.txt"
    fi
}

function process_print() {
    if [ -r $temp/killedprocesslist_$time.txt ] && [ -s $temp/killedprocesslist_$time.txt ]; then
        count=$(cat $temp/killedprocesslist_$time.txt | wc -l)

        if [[ $count -gt 1 ]]; then
            cat $temp/killedprocesslist_$time.txt >>$svrlogs/status/killedprocesslist_$time.txt
        fi
    fi
}

process_list

process_kill

process_print
