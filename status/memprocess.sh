#!/bin/bash

source /home/sample/scripts/dataset.sh

function mem_check() {
	memproc=$(ps aux | grep "$scripts/status/memcheck.sh" | grep -v grep)

	if [[ -z $memproc ]]; then
		sh $scripts/status/memcheck.sh
	else
		echo "$(date +"%F %T")" >>$svrlogs/status/memproc_$logtime.txt
		echo "$memproc" >>$svrlogs/status/memproc_$logtime.txt
	fi
}

function swap_check() {
	swapproc=$(ps aux | grep "$scripts/status/swapcheck.sh" | grep -v grep)

	if [[ -z $swapproc ]]; then
		sh $scripts/status/swapcheck.sh
	else
		echo "$(date +"%F %T")" >>$svrlogs/status/swapproc_$logtime.txt
		echo "$swapproc" >>$svrlogs/status/swapproc_$logtime.txt
	fi
}

mem_check

swap_check
