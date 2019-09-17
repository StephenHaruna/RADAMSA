#!/bin/bash

set -e
echo "HAL 9000" | $@ -o tmp/uniq-%n -n 100 -p od -m num 
case $(uname -s) in
  Darwin) md5cmd="md5 -r";;
  *) md5cmd="md5sum";;
esac
test 0 = $($md5cmd tmp/uniq-* | sed -e 's/ .*//' | sort | uniq -c | grep -v " 1 " | wc -l)
rm tmp/uniq-*
