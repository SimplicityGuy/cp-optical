#!/bin/bash

usage() {
  echo -e "Usage: cp-optical.sh [ <options> ]\n"
  echo -e "    <options> are any of:"
  echo -e "    -h\t\tprint full usage"
  echo -e "    -d\t\tpath to destination root"
  echo -e "    \t\tif not provided, current directory is used"
  echo -e "    -m\t\tcopy multiple optical discs"
  echo -e "    -i\t\tinteractive mode during multiple optical disc copy"
}

if [[ "$(uname)" != "Darwin" ]]; then
  echo "$0 currently only runs on Mac OS X.\n"
  exit 1
fi

OPTIND=1
readopt='getopts $opts opt; rc=$?; [ $rc$opt == 0? ] && exit 1; [ $rc == 0 ] || { shift $[OPTIND - 1]; false; }'
opts=himd:
opt_root_folder=
loop=false
interactive=false

while eval $readopt; do
  case "$opt" in
    h)
      usage
      exit 0
      ;;
    d)
      opt_root_folder=$OPTARG
      if [ ! -d "$opt_root_folder" ]; then
        echo -e "Root output folder, $opt_root_folder, does not exist.\n"
        exit 1
      fi
      ;;
    m)
      loop=true
      ;;
    i)
      loop=true
      interactive=true
      ;;
  esac
done

echo "cp-optical"

while [ : ]; do
  
  printf "Waiting for optical disc to be inserted..."
  optical_found=false
  while [ "$optical_found" = false ]; do
    for disk in $(diskutil list | grep ^/); do
      printf "."
      diskutil info "$disk" | grep -q Optical >/dev/null 2>&1
      [ "$?" = "0" ] && optical_found=true && break
    done
    printf "."
    sleep 3
  done
  printf "\n"

  # Retrieves the first mount point and device node of a CD/DVD/BD.
  dev_node=
  mnt_point=
  vol_name=
  for disk in $(diskutil list | grep ^/); do
    if diskutil info "$disk" | grep -q Optical; then
      dev_node="$disk"
      mnt_point=`df | sed -ne "s,^$disk.*\(/Volumes.*\)$,\1,p"`
      vol_name=`echo "$mnt_point" | sed "s,^/Volumes/,,"`
      break
    fi
  done

  if [ -z "$mnt_point" ]; then
    echo -e "\tNo optical disc found.\n"
  fi

  dst_folder="$vol_name"
  if [ -n "$opt_root_folder" ]; then
    dst_folder="$opt_root_folder"/"$dst_folder"
  else
    dst_folder="`pwd`"/"$dst_folder"
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

  if [ "$loop" != true ]; then 
    break
  fi

  if [ "$interactive" = true ]; then
    read -p "Copy another disc? [Y|n] " _answer
    _answer=${_answer:-Y}
    echo ${_answer} | grep -E -i -e '^y$' > /dev/null 2>&1
    [ "$?" != "0" ] && break
  fi
done