#!/bin/bash

USAGE_STR="Usage: `basename $0` [-S | -s ] path/to/file dest/to"
# this is used with a find ... -exec ...
# to copy files from one base dir (path/to/file) to another base dir (dest/to/path/to/file)
# which may not yet exist.
# if -S is specified then the full/path/to/file component is squashed to full__path__to__file
# if -s is specified then the full/path/to/file component is squashed to full/path__to__file

SQUASH=0;
if [ $# -gt 0 ]; then
    if [ "$1" = "-S" ]; then  # squash full/path/to/filename to full__path__to__filename
        SQUASH=2
        shift
    elif [ "$1" = "-s" ]; then  # squash full/path/to/filename to full/path__to__filename
        SQUASH=1
        shift
    fi
fi

if [ $# -ne 2 ]; then
  echo >&2 "$USAGE_STR"
  exit 1
fi

FROM=$1
TOBASEDIR=$2

# extract the path and file components of the origin
FROMFILE=${FROM##*/}
FROMDIR=${FROM%/*}

if [ $SQUASH -eq 2 ]; then
    # squash entire full/path/to/dir for destination filename
    TOFILE=${FROM//\//__}
    TODIR=$TOBASEDIR
elif [ $SQUASH -eq 1 ]; then
    # extract all but root dir of path
    TOFILE=${FROM#*/}
    # squash path/to/dir for destination filename
    TOFILE=${TOFILE//\//__}
    # grab top dir and append to backup dir
    TODIR=$TOBASEDIR/${FROM%%/*}
else
    # get filename
    TOFILE=$FROMFILE
    # add path/to to the destination path
    TODIR="${TOBASEDIR}/${FROMDIR}"
fi

TO="${TODIR}/${TOFILE}"

#echo "FROM: $FROM"
#echo "TO: $TO"


# create the destination directory if it doesn't yet exist
if [ ! -d ${TODIR} ]; then
    mkdir -p ${TODIR}
fi

# copy if there's a file (as opposed to file's parent dir)
if [ "${FROMFILE}" != "" ]; then
    cp -pf ${FROM} ${TO}
fi


