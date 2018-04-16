#!/bin/bash
rm singletestcoverage 
rm multitestcoverage

i=0

while read p; do
  i=$((i+1))
  echo $i
  echo "call $i : ./grep.exe $p" > /dev/stderr
  make clean-cov
  make build
  ./grep.exe $p > /dev/null
  gcov -f grep.c|grep -B 1 Lines.*\:[^0].*|grep \'.*\'|cut -c 11-|rev|cut -c 2-|rev|grep -v "\.c" > singletestcoverage
  
  sed ':a;N;$!ba;s/\n/ /g' singletestcoverage >> multitestcoverage
done <../coverage/grep-test-suite-without-P-I.txt
