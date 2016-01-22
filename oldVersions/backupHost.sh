#!/bin/sh

# rsync incremental backup script (ribs!)
# reference(s):
#   - https://github.com/thebestsolution/backup-script
#   - www.nickalls.org/dick/papers/linux/usbdrive.pdf

# NOTES:
#   - external backup drive: ext4 partition, fstab entry (/mnt/backup), owner and group changed to 'elpe' user, UUID=7e019d6e-5ea6-4f65-a7a4-fd3b63e03070

# TODO:
#   - write script to backup a specified directory
#   - split backup into sections (root with sudo and home without?) and flush the buffer in-between the sections?
#   - calculate MD5 sums for integrity checks?
#   - prompt root password at the beginning?

# mount point for the backup drive
MNT="/mnt/backup"

# host name and backup source directory
HOST="fafouin"
SRC="/"
#SRC="/home/elpe/tmp/"

# number of backups to keep on the hard drive
NUMBACK=40

# rsync options
OPTS="-aAXHSv --numeric-ids --delete --delete-excluded --delete-after --human-readable --stats --progress"


#################################################
# make sure the backup drive is mounted
testMountInit=$( grep $MNT /etc/mtab )
if [ -z "$testMountInit" ]
then
    # the drive is not mounted, send notification and exit
    #echo "ERROR: the backup drive is not mounted."
    echo "The backup drive is not mounted. Trying to mount it now..."
    mount $MNT
    testMount=$( grep $MNT /etc/mtab )
    if [ -z "$testMount" ]
    then
        echo "ERROR: mounting the backup drive failed. Make sure it is plugged in and/or powered on. Aborting..."
        exit 1
    fi
fi

# make sure the backup source directory exists
if [ ! -d $SRC ]
then
    echo "ERROR: the backup source directory does not exist. Aborting..."
    exit 1
fi

# define backup destination directory and make sure it exists
DEST="$MNT/$HOST"
if [ ! -d $DEST ]; then
    mkdir $DEST
fi

# exclude and log files for the backup
EXCL="$DEST/$HOST.exclude"
LOG="$DEST/$HOST-backup.log"
if [ ! -f $EXCL ]
then
    # create an empty exclusion file if it does not exist
    touch $EXCL
fi

# make sure the directory for the 'current' backup exists
if [ ! -d "$DEST"/current ]
then
    mkdir $DEST/current
fi

# current date
date=$(date -I)
#date=$(date +%Y-%m-%d.%H:%M:%S)

# if a backup for the current day exists, delete it
if [ -d "$DEST/$date" ]
then
    sudo rm -rf $DEST/$date
fi

# run rsync as root
echo "Running rsync now!"
sudo rsync $OPTS --link-dest=$DEST/current --exclude-from=$EXCL $SRC $DEST/$date > $LOG

# run the post-backup steps if rsync was successful
if [ "$?" -eq 0 ]
then
    echo "Backup complete. Cleaning the directory."

    # update the 'current' backup
    rm -rf $DEST/current
    ln -s $DEST/$date $DEST/current

    # check the number of backups and delete the oldest if necessary
    cnt=$(find $DEST/2* -maxdepth 0 -type d | wc -l)
    if [ "$cnt" -gt "$NUMBACK" ]; then
        sudo rm -rf $(ls -d $DEST/2* | sort | head -n 1)
    fi

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

