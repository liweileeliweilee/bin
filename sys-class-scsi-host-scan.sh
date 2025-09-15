#!/bin/bash

bash_cmd="sudo tee /sys/class/scsi_host/host*/scan <<<'- - -' >/dev/null"
echo "bash_cmd:<${bash_cmd}>"
/bin/bash -c "${bash_cmd}" || exit 1
#exec sudo tee /sys/class/scsi_host/host*/scan <<<'- - -' >/dev/null

