#!/bin/bash

echo "Function sizes (by line count):"

linenums=($(grep -e "^........................................os" -e "^........................................int" build/kernel.lst -n | awk '{print $1}' | grep -o '[0-9]\+'))
linelabels=($(grep -e "^........................................os" -e "^........................................int" build/kernel.lst -n | awk '{print $NF}'))

for i in $(seq 0 `expr ${#linenums[@]} - 2`); do
	next=`expr $i + 1`
	echo "`expr ${linenums[$next]} - ${linenums[$i]}` ${linelabels[$i]}"
done | sort -n
