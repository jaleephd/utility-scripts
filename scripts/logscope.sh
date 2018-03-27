#!/bin/sh

# logscope.sh [ -ihurd ] [ -s secondtag ] [ tag ]
#
# Extract tagged entries from log_trace() generated logfiles, that are in the format:
#	            Date Time [PID] LOGLEVEL [file.ext:line# function_name] TAG: log_message
# Arguments:
# -i            case insensitive matching on tag
# -h            display this help message
# -u			(unique) removes duplicated lines
# -r			display the raw entry
# -d			displays the date of the log entry
# -s secondtag	sets a secondary (important) tag for colour (red) highlighting
#
# if the optional tag is not provided, then a personalised TAG based on username
#     (uppercasing first and last initials) and branch is used.
#     Eg for user Tom Coder (tomc) working on branch 'bug1' the TAG will be: TC_bug1
#
# Note: for indenting of the call stack to work, log a tagged entry on function entry
#     starting with the log_message "entering ..." and on function return or exit
#     with a log_message "returning ..." or "exiting ..." (where ... is an optional
#     continuation of the log message. Also ensure that there is a ':' after the TAG.

USAGE_STR="Usage: `basename $0` [ -ihurd ] [-s secondtag ] [ tag ]"
read -r -d '' HELP_STR<<'END_OF_HELP'
Extract tagged entries from logfiles that are in the format:
              Date Time [PID] LOGLEVEL [file.ext:line# function_name] TAG: log_message
Arguments:
-i            case insensitive matching on tag
-h            display this help message
-u            (unique) removes duplicated lines
-r            display the raw entry
-d            displays the date of the log entry
-s secondtag  sets a secondary (important) tag for colour (red) highlighting

if the optional tag is not provided, then a personalised TAG based on username
    (uppercasing first and last initials) and branch is used.
    Eg for user Tom Coder (tomc) working on branch 'big1' the TAG will be: TC_bug1

Note: for indenting of the call stack to work, log a tagged entry on function entry
    starting with the log_message "entering ..." and on function return or exit
    with a log_message "returning ..." or "exiting ..." (where ... is an optional
    continuation of the log message. Also ensure that there is a ':' after the TAG.

END_OF_HELP

[ -n $RELEASE_NAME ] || RELEASE_NAME="RELEASE_NAME" # change to something valid
[ -n "$REPO" ] || REPO="dev"
[ -n "$BRANCH" ] || BRANCH=`(cd $REPODIR; git branch | egrep "^\*" | awk '{ print $NF }')`
[ -n "$LOGDIR" ] || LOGDIR=${REPODIR}/var/${BRANCH}/logs # /${RELEASE_NAME}

LOGFILE=${RELEASE_NAME}.log


# personalised tag based on uppercase first and last initials and feature joined by a _
# eg: user tomc working on 'bug1' will be: TC_bug1
MYTAG=`echo "${USER:0:1}${USER:(-1)}" | tr '[a-z]' '[A-Z]'`
MYTAG="${MYTAG}_${BRANCH}"

HIGHLIGHTCOLOR="\\e[31m"	# red
CHANGECOLOR="\\e[34m"		# blue
DEFAULTCOLOR='\e[0m'		# terminal default


RAW=0
UNIQCMD="perl -pe '{}'"
DATED=0
SECONDTAG=""
CASEINSENSITIVE=""

while getopts s:ihurd opt; do
	case "$opt" in
		i) CASEINSENSITIVE="-i";;
		h)  echo >&2 "$USAGE_STR"
            echo >&2 "$HELP_STR"
            exit 1;;
		u) UNIQCMD="/usr/bin/uniq -u";;
		r) RAW=1; DATED=0;;
		d) DATED=1;RAW=0;;
		s) SECONDTAG="$OPTARG";;
		\?) # unknown flag
		    echo >&2 "$USAGE_STR"
			exit 1;;
	esac
done
shift `expr $OPTIND - 1`

if [ $# = 0 ]; then
  TAG=$MYTAG
else
  TAG=$1
fi


# logging is in format:
# YYYY-MM-DD HH:MM:SS.99 [ 9999] LOGLEVEL [file.ext:line# function_name] TAG: log_message

EXTRACTDATECMD="";
INDENTCMD="";
EXTRACTMSGCMD="";
CLR1=$DEFAULTCOLOR
CLR2=$CHANGECOLOR
CLR3=$HIGHLIGHTCOLOR

if [ $RAW != 1 ]; then
  # calculate indent based on how deep (logged enters vs returns) the code is
  INDENTCMD='$up=$down=0; $up=1 if (/:\s+entering\s+/); $down=1 if (/:\s+returning\s+/ || /:\s+exiting\s+/); $outer=$indent-2; $branch="";  $pbranch=($outer>=0) ? $pbranch="   |" : ""; if ($up>0) { $outer++; $branch="-> "; $pbranch="   +" if ($outer>=0); } elsif ($down>0) { $branch="<- "; } else { $branch="   " if ($indent>0); }  $spaces=("   |" x $outer).$pbranch.$branch; $indent=$indent+$up-$down; $indent=0 if ($indent<0);'
  # extract date & time info preceding loglevel, ignoring PID
  #                  YYYY-MM-DD        HH:MM:SS    .99      [ 9999]     LOGLEVEL
  EXTRACTDATECMD="s/^([0-9\-]+)\s+(\d\d:\d\d:\d\d)\.\d+\s+\[[ 0-9]+\]\s+[A-Z]+\s+/"
  if [ $DATED = 1 ]; then
	# output date and time
    EXTRACTDATECMD="${EXTRACTDATECMD}(\$1 \$2) ${CLR2}\$spaces${CLR1}/;"
  else
	# output time
    EXTRACTDATECMD="${EXTRACTDATECMD}(\$2) ${CLR2}\$spaces${CLR1}/;"
  fi
  # remove tag from output
  EXTRACTMSGCMD="s/\s*${TAG}//;"
fi

COLORCMD=""
# add colour highlighting to [file:lineno function] when a secondary tag is provided
if [ -n "$SECONDTAG" ]; then
  #         ...             [filename.ext:line# function_name]   ...
  COLORCMD="s/(\[[0-9a-zA-Z_]+\.[a-zA-Z]+:[0-9]+\s+[a-zA-Z_]+\])/${CLR3}\$1${CLR1}/ if (/${SECONDTAG}/);"
fi

# colour highlight function name when entering a new function
#         ...             [filename.ext:line# function_name]: log message
# 2x ${CLR1} because putting the closing ] bracket after the colour escape causes problems
# Bug note: closing ] bracket reverts to default colour overriding secondary match colour
#           as CLR1 reverts to default not previous colour on matched closing ]
COLORCMD="${COLORCMD} s/(\[[0-9a-zA-Z_]+\.[a-zA-Z]+:[0-9]+\s+)([a-zA-Z_]+)\]/\$1${CLR2}\$2${CLR1}${CLR1}]/ if (/\s+entering\s+/);"

echo searching $LOGDIR/$LOGFILE for tag: $TAG ..
echo

# note that we only process logged lines containing the tag
grep $CASEINSENSITIVE -h $TAG $LOGDIR/$LOGFILE | \
    perl -pe "{ ${INDENTCMD} ${EXTRACTDATECMD} ${EXTRACTMSGCMD} ${COLORCMD} }" \
	| $UNIQCMD



