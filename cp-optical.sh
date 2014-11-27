#!/bin/bash

args=$#


# Retrieves the first mount point and device node of a CD/DVD/BD.
device_node=''
mount_point=''
volume_name=''
for disk in $(diskutil list | grep ^/); do
if diskutil info "$disk" | grep -q Optical; then
  device_node=$disk
  mount_point=`df | sed -ne "s,^$disk.*\(/Volumes.*\)$,\1,p"`
  volume_name=`echo $mount_point | sed "s,^/Volumes/,,"`
  break
fi
done

if [ -n "$mount_point" ]; then
  echo "Optical Disk: $mount_point"
  echo "Volume Name: $volume_name"

  destination_folder="`eval echo ${volume_name//>}`"

  mkdir "$destination_folder"
  ditto -v "$mount_point" "$destination_folder"
  
  diskutil eject "$mount_point"
fi
