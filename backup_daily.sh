#!/bin/bash
###############################################################################
#
#                Backup to NFS mount script
#
# Author:        Bernd Bierlein (bmuxbeats@gmx.net)
# Version:       1.00
# Date:          2022-11-18
# Description:   Backup direcories with rdiff-backup.
#                The backup host system will be waked up by WOL command,
#                the NFS share will be automatically mounted.
#                After this the backup process starts with rdiff-backup command.
#                When all your backups are done the scripts unmounts the
#                NFS share and hibernates the backup host system.
#                Every single step will be written in a log file.
#
# Prerequisites: requires installation of rdiff-backup, sshpass and wol
#                If not installed yet, please install it.
#                Arch:               yay -S rdiff-backup sshpass wol
#                                    sudo pacman -S rdiff-backup sshpass wol
#                Debian/Mint/Ubuntu: sudo apt-get install rdiff-backup sshpass wol
#
# Usage:         This script requires sudo rights and must be marked as executable.
#                chmod 700 ./backup_daily.sh
#                sudo ./backup_daily.sh
#
# License:     This code is released under the GNU General Public License v3.0
#
#
###############################################################################

# VARIABLES - Please adapt the data to your personal circumstances in this area
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# backup host data
backup_host_ip="192.168.123.123"
backup_host_mac="00:AA:BB:11:22:33"
backup_host_NFS_share="/nfs/backups/"
backup_host_password="start123456"
backup_host_user="username"

# backup paths
backup_paths=("/home/testuser/Dowmloads" \
              "/home/testuser/Documents" \
              "/home/testuser/Videos")

# mount path 
local_mount_path="/mnt/NFS/backups/"

# log file
logfile_path="/var/log/"
logfile_name="backup.log"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# START BACKUP DATA - Please do not change anything from here
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
logfile="${logfile_path}${logfile_name}"
printf "["$(date -Iseconds)"] Backup script started.\n" >> $logfile

# wake up backup host system (WOL)
ping -c1 -t1 $backup_host_ip 2>&1 >/dev/null
exit_status=$?
if [ $exit_status -ne 0 ]
then
  wol -w 5 $backup_host_mac 2>&1 >/dev/null
  printf "["$(date -Iseconds)"] Sent WOL command.\n" >> $logfile
fi

# is systsem meanwhile online?
status_check_cnt=0
while [[ $exit_status -ne 0 ]] && [[ status_check_cnt -lt 25 ]]
do
  ping -c1 -t1 $backup_host_ip 2>&1 >/dev/null
  exit_status=$?
  ((status_check_cnt++))
done

if [ $status_check_cnt -eq 25 ]
then
  printf "["$(date -Iseconds)"] Couldn't find Backup system. Backup process cancelled.\n" >> $logfile
  exit
else
  printf "["$(date -Iseconds)"] Backup system is online. Online status confirmed.\n" >> $logfile
fi

# mount backup drive
mountpoint -q $local_mount_path
exit_status=$?
if [ $exit_status -eq 0 ]
then
  printf "["$(date -Iseconds)"] ""'"$local_mount_path"' ""is already a mount point.\n" >> $logfile
elif [ $exit_status -eq 32 ]
then
  mount -t nfs $backup_host_ip:$backup_host_NFS_share $local_mount_path 2>>$logfile
  exit_status=$?
  if [ $exit_status -eq 0 ]
  then
    printf "["$(date -Iseconds)"] Backup drive successfully mounted in path ""'"$local_mount_path"'"".\n" >> $logfile
  else
    printf "["$(date -Iseconds)"] An error has occured. Failed to mount drive. Error code $system_status.\n" >> $logfile
  fi
fi

# start backup using rdiff-backup
for p in "${backup_paths[@]}"
do
  rdiff-backup --create-full-path $p ${local_mount_path%?}$p
done
printf "["$(date -Iseconds)"] Backup successful.\n" >> $logfile

# check filesystem usage
printf "["$(date -Iseconds)"] $(df -h $local_mount_path | grep $backup_host_ip | \
        awk {'print $1 ": Used " $3 " by total available capacity of " $4 ". Workload: " $5 "%"'})\n" >> $logfile

# Umount backup drive
umount /mnt/NFS/backups
printf "["$(date -Iseconds)"] Backup drive succesfully unmounted.\n" >> $logfile

# Hibernate backup host systems
printf "["$(date -Iseconds)"] Backup host is hibernating.\n" >> $logfile
sshpass -p $backup_host_password ssh sshd@$backup_host_ip 'halt'
printf "["$(date -Iseconds)"] Backup script finished.\n" >> $logfile
