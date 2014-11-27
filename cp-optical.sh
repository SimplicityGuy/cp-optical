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
      if [ ! -d "$opt_root_folder" ]; then
        echo -e "Root output folder, $opt_root_folder, does not exist."
        exit 1
      fi
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

echo "cp-optical"

if [ -n "$mount_point" ]; then
  destination_folder="`eval echo $volume_name`"
  if [ -n "$opt_root_folder" ]; then
    destination_folder=$opt_root_folder/$destination_folder
  else
    destination_folder="`pwd`"/$destination_folder
  fi

  shopt -s extglob
  destination_folder="${destination_folder//+(\/)//}"
  shopt -u extglob

  output_format="\t%-20s %s\n"

  printf "$output_format" "Mount point:" "$mount_point"
  printf "$output_format" "Volume name:" "$volume_name"
  printf "$output_format" "Destination folder:" "$destination_folder"

  mkdir "$destination_folder"
  ditto "$mount_point" "$destination_folder"
  
  diskutil eject "$mount_point"
else
  echo -e "\tNo optical disc found."
fi
