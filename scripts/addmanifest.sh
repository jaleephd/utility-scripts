#!/bin/bash

# look for all the modified files
M=`git status | grep '\Wmodified:' | sed 's/.*:[ \t]*//'`

# for each modified file
for i in $M; do
	# extract filename, directory and basename without extension
	f=${i##*/}; d=${i%/*}; n=${f%%.*}
	echo "adding $f to MANIFEST in $d"
	# now look for the file in the MANIFEST (1st field, tab deliminated)
	# and if it doesn't have an entry in the 2nd field
	# add the file's basename as the 2nd field
	if [ -n "$f" ]; then
		sed "s/^$f$/$f\t$n/" $d/MANIFEST # view MANIFEST update
		#sed "s/^$f$/$f\t$n/" $d/MANIFEST > $d/MANIFEST # update MANIFEST
	fi
	#git add $d/MANIFEST # add MANIFEST to staging area
	#git reset HEAD $d/MANIFEST # remove MANIFEST from staging area
	#git checkout -- $d/MANIFEST # restore MANIFEST to previous ver
done

