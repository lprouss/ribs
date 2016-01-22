#!/bin/sh

# script to do a single backup of the specified directory on a Linux system
# reference(s):
#   - https://github.com/thebestsolution/backup-script
#   - www.nickalls.org/dick/papers/linux/usbdrive.pdf

# NOTE: you must have write permissions on the backup destination

# TODO:
#   - prompt root password at the beginning?

# mount point for the backup drive
MNT="/media/elpe/LaCieLinux"

# backup name and source directory
#NAME="backupLaptop"
#SRC="/"
NAME="backupPhD"
SRC="/home/elpe/PhD"

# exclude file
EXCL="/home/elpe/bin/backup.exclude"

# rsync options
OPTS="-aAXHSv --numeric-ids --delete --delete-excluded --delete-after --human-readable --stats --progress"


#################################################
# make sure the backup drive is mounted
testMountInit=$( grep $MNT /etc/mtab )
if [ -z "$testMountInit" ]
then
    # the drive is not mounted, send notification and exit
    echo "The backup drive is not mounted. Mount it and try again. Aborting..."
    exit 1

    #echo "The backup drive is not mounted. Trying to mount it now..."
    #mount $MNT
    #testMount=$( grep $MNT /etc/mtab )
    #if [ -z "$testMount" ]
    #then
        #echo "ERROR: mounting the backup drive failed. Make sure it is plugged in and/or powered on. Aborting..."
        #exit 1
    #fi
fi

# current date
#date=$(date -I)

# make sure the backup source directory exists
if [ ! -d $SRC ]
then
    echo "ERROR: the backup source directory does not exist. Aborting..."
    exit 1
fi

# define backup destination directory and make sure it exists
DEST="$MNT/$NAME"
if [ ! -d $DEST ]; then
    mkdir $DEST
fi

# exclude and log files for the backup
LOG="$MNT/backup.log"
if [ ! -f $EXCL ]
then
    # create an empty exclusion file if it does not exist
    touch $EXCL
fi

# if a backup for the current day exists, delete it
#if [ -d "$DEST" ]
#then
    #rm -rf $DEST
#fi

# run rsync
echo "Running rsync now!"
sudo rsync $OPTS --exclude-from=$EXCL $SRC $DEST > $LOG

# run the post-backup steps if rsync was successful
if [ "$?" -eq 0 ]
then
    echo "Backup complete!"

    # if it was not mounted before the backup, unmount the drive
    #if [ -z "$testMountInit" ]
    #then
        # first make sure read/write events are complete
        #echo "Flushing the buffers and unmounting the backup drive."
        #sync

        # unmount the drive
        #umount $MNT
    #fi
fi

