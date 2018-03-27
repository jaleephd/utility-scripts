#!/bin/bash

# automation of daily backups, to be run at end of day
#
# if the Dropbox directory exists and is defined by $DROPBOX,
# the specified backups will also be synced to Dropbox when they are newer

# if run from a cronjob then $USER won't be set
[ -z "$USER" ] && USER=$(whoami)
# default home if not set in crontab (it should be!)
[ -z "$HOME" ] && HOME=/home/$USER

DEVDIR=$HOME/workspace/dev

# to check that it's not a new feature just branched today, as we don't want
# to backup the whole branch, test if there are any subdirs under here
# that were modified (created) before today, and if so do the backup, otherwise skip
if test "`find $DEVDIR/* -maxdepth 0 -not -iwholename '*.git' -daystart -mtime +0`"; then
    dailyback.sh $DEVDIR
else
    echo $DEVDIR is a new branch - not backing up!
fi


# backup as host1/bin host2/bin rather than full path or just 'bin'
# assumes these are valid hostnames and there are mountpoints or symlinks to them
# at host*
( cd $HOME; dailyback.sh -l host1/bin )
( cd $HOME; dailyback.sh -l host2/bin )

# and backup local directories
dailyback.sh $HOME/bin
dailyback.sh $HOME/notes

# specific backups (only copy if newer and not a symbolic link)
echo copying newer workstation versions of notes/* bin/* .bashrc .bash_aliases .vimrc ...
cp -uP $HOME/notes/* $HOME/backup
cp -uP $HOME/bin/* $HOME/backup/bin
cp -uP $HOME/.bashrc $HOME/backup/workstation_bashrc
cp -uP $HOME/.bash_aliases $HOME/backup/wokstation_bash_aliases
cp -uP $HOME/.bash_profile $HOME/backup/wokstation_bash_profile
cp -uP $HOME/.bash_logout $HOME/backup/wokstation_bash_logout
cp -uP $HOME/.vimrc $HOME/backup/workstation_vimrc
cp -uP $HOME/.gitconfig $HOME/backup/workstation_gitconfig
cp -uP $HOME/.gitignore $HOME/backup/workstation_gitignore
cp -uP $HOME/.config/autostart $HOME/backup/workstation_autostart
cp -uP $HOME/.local/share/notes/Notes/Notes $HOME/backup/Xfce_Notes
echo done!

# Sync to Dropbox
DROPBOX=$HOME/Dropbox
BACKUPDIR=$HOME/backup

if [ -n "$DROPBOX" ] && [ -d "$DROPBOX" ]; then
    echo backing up modified files to Dropbox ...
    cp -urP $HOME/backup $DROPBOX/work
    echo done!

    # example backup of modified files from a git repo called 'code', without using dailyback.sh
    echo backing up personal repo to Dropbox ...
    PERSONAL_REPO_PATH=$HOME/workspace
    PERSONAL_REPO=${PERSONAL_REPO_PATH}/code
    echo backing up personal code to Dropbox ...
    # note that these will skip Git .git directories
    # first create the directory tree in the backup directory
    find $PERSONAL_REPO -type d ! -iwholename '*.git/*' ! -iwholename '*.git' -print | sed "s|$PERSONAL_REPO_PATH/|$BACKUPDIR/|" | xargs mkdir -p
    # then get the list of files to copy (minus source prefix)
    changedfiles=( $(find $PERSONAL_REPO -type f ! -iwholename '*.git/*' ! -iwholename '*.git' -print | sed "s|$PERSONAL_REPO_PATH/||") )
    # and copy them to the backup directory, if they are newer
    for f in "${changedfiles[@]}"; do
        cp -up $PERSONAL_REPO_PATH/$f $BACKUPDIR/$f 
    done

    echo done!
fi


