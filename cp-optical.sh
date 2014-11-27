#!/bin/bash

usage() {
  echo -e "Usage: $0 [arguments] \n"
}

if [[ "$(uname)" != "Darwin" ]]; then
  echo "$0 currently only runs on Mac OS X."
  exit 1
fi

OPTIND=1
readopt='getopts $opts opt; rc=$?; [ $rc$opt == 0? ] && exit 1; [ $rc == 0 ] || { shift $[OPTIND - 1]; false; }'
opts=hd:
opt_root_folder=

while eval $readopt; do
  case "$opt" in
    h)
      usage
      exit 0
      ;;
    d)
      opt_root_folder=$OPTARG
      echo $opt_root_folder
      ;;
  esac
done

# Retrieves the first mount point and device node of a CD/DVD/BD.
device_node=
mount_point=
volume_name=
for disk in $(diskutil list | grep ^/); do
  if diskutil info "$disk" | grep -q Optical; then
    device_node=$disk
    mount_point=`df | sed -ne "s,^$disk.*\(/Volumes.*\)$,\1,p"`
    volume_name=`echo $mount_point | sed "s,^/Volumes/,,"`
    break
  fi
done

if [ -n "$mount_point" ]; then
  echo -e "\tOptical Disk:\t$mount_point"
  echo -e "\tVolume Name:\t$volume_name"

  destination_folder="`eval echo $volume_name`"

  mkdir "$destination_folder"
  ditto -v "$mount_point" "$destination_folder"
  
  diskutil eject "$mount_point"
fi
