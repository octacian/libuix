#! /bin/bash

pattern=""
if [[ -n $1 ]]; then
	pattern="--pattern='$1_spec'"
fi

busted --lua=lua5.1 --coverage ${pattern} .
temp_file=$(mktemp)
awk -- '/\/usr\/|_spec/ {skip = 1; next} skip == 1 {skip = 0; next} {print $0}' luacov.stats.out > ${temp_file}
rm luacov.stats.out
mv ${temp_file} luacov.stats.out
luacov
