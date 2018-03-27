#!/bin/bash

# show all the ports used by the user
function showports()
{
    local p
    local f
    local cmd_fields
    local cmd
    local procs=`ps x | egrep -w -v '(ps x|grep|tail|awk)' | awk '{ print $1 }' | tail -n +2`
    echo getting port information for $USER ..
    TCP_PORTS=`netstat -ae | egrep -i '^tcp'`
    echo done!
    for p in $procs; do
        # if the process is still running and it's file descriptors are accessible
        if [ -d /proc/$p ] && [ -r /proc/$p/fd ]; then
            # find the TCP ports associated with the process
            procports -n $p
            # if there are any ports, display the process command and it's ports
            if [ -n "$PID_PORTS" ]; then
                # note fields in /proc/<pid>/cmdline are \0 delimited
                cmd_fields="$(</proc/$p/cmdline tr '\0' '\n')"

                # this is to make the output more pretty by stripping away the
                # interpreter (if any) and the path to the command or script
                cmd=""
                for f in $cmd_fields; do
                    # strip the path from the command only
                    if [ -z "$cmd" ]; then
                        cmd="${f##*/}"
                        # if it's an interpreter, use script as command instead
                        case "$cmd" in
                            sh) cmd="";;
                            bash) cmd="";;
                            csh) cmd="";;
                            zsh) cmd="";;
                            perl) cmd="";;
                            php) cmd="";;
                            ruby) cmd="";;
                            python) cmd="";;
                        esac
                    else
                        cmd="${cmd} $f"
                    fi
                done
                # display the command, it's PID and associated TCP ports
                echo $cmd : pid $p : ports $PID_PORTS
            fi
        fi
    done
    TCP_PORTS=""
}


# get a list of ports associated with a process
function procports()
{
    local quiet=""
    local socks=""
    local s
    local prt

    PID_PORTS=""
    if [ "$1" = "-n" ]; then
        quiet=$1
        shift
    fi

    if [ -z "$TCP_PORTS" ]; then
        TCP_PORTS=`netstat -ae | egrep -i '^tcp'`
    fi

    # return if no PID or process isn't running
    if [ -z "$1" ] || [ ! -d /proc/$1 ]; then
        return
    fi

    # if don't have access
    if [ ! -r /proc/$1/fd ]; then
        echo "Can't access $1's file descriptors: Permission denied" 1>&2
        return
    fi

    # get a list of sockets associated with this process
    socks=`ls -l /proc/$1/fd | grep socket | awk '{ print $NF }' | sed 's/[^0-9]*//g'`
    for s in $socks; do
        # get the port associated with the socket
        prt=`printf "%s" "$TCP_PORTS" | grep $s | awk '{ print $4 }' | sed 's/.*://'`
        # add it to the list of ports associated with this process
        if [ -z "$PID_PORTS" ]; then
            PID_PORTS=$prt
        elif [ -n "$prt" ]; then
            PID_PORTS="${PID_PORTS} $prt"
        fi
    done

    if [ -n "$socks" ]; then
        # echo so that this command can be used from commandline
        [ -z "$quiet" ] && echo $PID_PORTS
    fi
}


showports

