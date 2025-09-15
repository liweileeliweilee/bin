#!/bin/sh

if test -h "$1"
then
    disk=$(chase "$1")
else
    disk="$1"
fi

if test -b "$disk"
then
    bash_cmd="echo 1 | sudo tee /sys/block/$(basename "$disk")/device/delete"
    echo "bash_cmd:<${bash_cmd}>"
    /bin/bash -c "${bash_cmd}" || exit 1
#    echo 1 | sudo tee /sys/block/$(basename "$disk")/device/delete
else
    echo "$0: not a block device: $1" >&2
    exit 1
fi

