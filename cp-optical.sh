#!/bin/bash

usage() {
  echo -e "Usage: cp-optical.sh [ <options> ]\n"
  echo -e "    <options> are any of:"
  echo -e "    -h\t\tprint full usage"
  echo -e "    -d\t\tpath to destination root"
  echo -e "    \t\tif not provided, current directory is used"
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
dev_node=
mnt_point=
vol_name=
for disk in $(diskutil list | grep ^/); do
  if diskutil info "$disk" | grep -q Optical; then
    dev_node=$disk
    mnt_point=`df | sed -ne "s,^$disk.*\(/Volumes.*\)$,\1,p"`
    vol_name=`echo $mnt_point | sed "s,^/Volumes/,,"`
    break
  fi
done

echo "cp-optical"

if [ -z "$mnt_point" ]; then
  echo -e "\tNo optical disc found."
  exit 1
fi

dst_folder="`eval echo $vol_name`"
if [ -n "$opt_root_folder" ]; then
  dst_folder=$opt_root_folder/$dst_folder
else
  dst_folder="`pwd`"/$dst_folder
fi

shopt -s extglob
dst_folder="${dst_folder//+(\/)//}"
shopt -u extglob

output_format="\t%-20s %s\n"

printf "$output_format" "Mount point:" "$mnt_point"
printf "$output_format" "Volume name:" "$vol_name"
printf "$output_format" "Destination folder:" "$dst_folder"

if [ ! -d "$dst_folder" ]; then
  mkdir "$dst_folder"
fi

ditto "$mnt_point" "$dst_folder"

diskutil eject "$mnt_point"
