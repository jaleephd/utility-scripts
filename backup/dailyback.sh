#!/bin/bash

USAGE_STR="Usage: `basename $0` [ -h ] [-l ] [ -s ] [-b backupdir ] [ -d ndays ] dir1 dir2 .. dirN"

read -r -d '' HELP_STR<<'END_OF_HELP'
Do a backup of files that have changed in the last 'ndays' days, from the
specified directories to backupdir/dirX/. If no backupdir is specified,
then $HOME/daily_backup/dayofweek will be used. By default only files
changed in the last day (starting at midnight) are backed up.
Arguments:
-h            display this help message
-l            by default backup only keeps short path (tail of specified dir)
              eg: work/docs/projectX -> daily_backup/Tue/projectX
              use this option to create full path for backed up directories
              eg: work/docs/projectX -> daily_backup/Tue/work/docs/projectX
-S            squash /'s in path to __'s and prepend to filenames
              eg: work/docs/projectX/web/index.php ->
                  daily_backup/Tue/projectX__web__index.php
-s            squash all but path of specified dir
              eg: work/docs/projectX/web/index.php ->
                  daily_backup/Tue/projectX/web__index.php
-b backupdir  the destination directory for today's backups
-d ndays      files modified in the last 'ndays' days will be backed up (default is 1)
END_OF_HELP

# this requires copyback to be located in the same directory as this script
COPYBACK_DIR=$(dirname $(readlink -f $BASH_SOURCE))
COPYBACK="$COPYBACK_DIR/copyback.sh"

DAY=`date +%a`
BACKUPDIR=$HOME/daily_backup/${DAY}

NDAYS=1
SHORTPATH=1;
SQUASH=0;

while getopts d:b:lsSh opt; do
        case "$opt" in
                h)  echo >&2 "$USAGE_STR"
            echo >&2 "$HELP_STR"
            exit 1;;
                s) SQUASH=1;COPYBACK="${COPYBACK} -s";;
                S) SQUASH=2;COPYBACK="${COPYBACK} -S";;
                l) SHORTPATH=0;;
                b) BACKUPDIR="$OPTARG";;
                d) NDAYS="$OPTARG";;
                \?) # unknown flag
                    echo >&2 "$USAGE_STR"
                        exit 1;;
        esac
done
shift `expr $OPTIND - 1`

if [ ! -d ${BACKUPDIR} ]; then
    mkdir -p ${BACKUPDIR}
fi

for WORKDIR in $*; do

    # remove any trailing /
    if [ ${WORKDIR:(-1)} = "/" ]; then
        WORKDIR=${WORKDIR%/*}
    fi

    if [ $SHORTPATH -eq 1 ]; then
        # only keep the path from the directory specified
        # get parent dir
        WKBASE=${WORKDIR%/*}
        # and subdir of WORKDIR
        WKDIR=${WORKDIR##*/}
        # sanity check that the depth is more than 1
        if [ "$WKDIR" != "$WORKDIR" ]; then
            cd ${WKBASE}
            #echo changed to ${WKBASE}
        fi
    else
        WKDIR=${WORKDIR}
    fi

    if [ $SQUASH -eq 2 ]; then
        # squashing entire path/to/file to path__to__file
        echo backing up ${WORKDIR} to ${BACKUPDIR}
    else
        BACKUPDEST="${BACKUPDIR}/${WKDIR}"
        # remove old backup
        echo cleaning out any old backups in ${BACKUPDIR}/${WKDIR} ...
        /bin/rm -rf ${BACKUPDIR}/${WKDIR} 2>/dev/null
        # (re)create new backup directory
        mkdir -p ${BACKUPDIR}/${WKDIR}
        echo backing up ${WORKDIR} to ${BACKUPDIR}/${WKDIR} ...
    fi

    # copy files that have changed in the last Ndays to the backup dir
    # note that it will skip Bazaar .bzr and Git .git directories
    find ${WKDIR} -type f -daystart -mtime -${NDAYS} ! -iwholename '*.bzr/*' ! -iwholename '*.git/*' ! -iwholename '*.swp' -print -exec ${COPYBACK} {} ${BACKUPDIR} \;

    echo done!
done


