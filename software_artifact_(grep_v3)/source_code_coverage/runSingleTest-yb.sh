#!/bin/bash

for n in `seq 1 1`;
do
echo "$(date --rfc-3339=ns);startTestrun" >> markers.csv

i=0

while read p; do
  i=$((i+1))
  if [ "$i" == "$1" ]; then
	  echo $i
	  echo "call $i : ./grep.exe $p" > /dev/stderr
	  echo "$(date --rfc-3339=ns);startAction;$i : $p" >> markers.csv
	  for n in `seq 1 1`;
	  do
	    ./grep.exe $p
	  done
	  echo "$(date --rfc-3339=ns);stopAction" >> markers.csv
  fi
done <../coverage/grep-test-suite-without-P-I.txt

echo "$(date --rfc-3339=ns);stopTestrun"
done


# Format of grep-test-suite-without-P.txt:
#   -E "asdfgasg" include < ../inputs/grep1.dat
