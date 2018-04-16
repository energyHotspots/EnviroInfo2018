#!/bin/sh

echo "Start: $(date --rfc-3339=ns)"

i=0

while read p; do
  i=$((i+1))
  if [ $i -eq 100 ]
  then
    echo $i call: ./grep.exe $p
    echo "Start of test $i at $(date --rfc-3339=ns)"
    for n in `seq 1 1`;
    do
      $"./grep.exe $p > out.txt"
    done
    echo "End of test $i at $(date --rfc-3339=ns)"
  fi
done <../coverage/grep-test-suite-without-P.txt

echo "End: $(date --rfc-3339=ns)"
