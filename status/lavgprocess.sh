#!/bin/bash

source /home/sample/scripts/dataset.sh

function lavg_check() {
	lavgproc=$(ps aux | grep "$scripts/status/loadavg.sh" | grep -v grep)

	if [[ -z $lavgproc ]]; then
		sh $scripts/status/loadavg.sh
	else
		echo "$(date +"%F %T")" >>$svrlogs/status/lavgproc_$logtime.txt
		echo "$lavgproc" >>$svrlogs/status/lavgproc_$logtime.txt
	fi
}

lavg_check
