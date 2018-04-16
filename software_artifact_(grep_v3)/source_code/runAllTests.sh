#!/bin/bash

for n in `seq 1 30`;
do
echo "$(date --rfc-3339=ns);startTestrun" >> markers.csv

i=0

while read p; do
  i=$((i+1))
  echo $i
  echo "call $i : ./grep.exe $p" > /dev/stderr
  echo "$(date --rfc-3339=ns);startAction;$i : $p" >> markers.csv
  for n in `seq 1 5000`;
  do
    ./grep.exe $p > /dev/null
  done
  echo "$(date --rfc-3339=ns);stopAction" >> markers.csv
done <../coverage/grep-test-suite-without-P-I.txt

echo "$(date --rfc-3339=ns);stopTestrun"
done


# Format of grep-test-suite-without-P.txt:
#   -E "asdfgasg" include < ../inputs/grep1.dat
