#!/bin/bash

# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

winbox_dir="/home/liweilee/Downloads"

#-------------------------------------------
# Starting
#-------------------------------------------
echo -e "${On_IBlack}\n"
echo -e "Starting: <${0}>"
echo -e "${Color_Off}"
#echo -e "${On_IBlack}\n\n${0} starting...\n${Color_Off}"

#-------------------------------------------
# upgrade apt
#-------------------------------------------
echo -e "\033[47;30m\nUpgrading APT packages${Color_Off}"
bash_cmd="sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y"
echo "bash_cmd<${bash_cmd}>"
/bin/bash -c "${bash_cmd}" || exit 1

#-------------------------------------------
# upgrade dkms
#-------------------------------------------
# upgrade r8125-dkms
echo -e "\033[47;30m\nUpgrading dkms${Color_Off}"
bash_cmd="sudo apt install -y r8125-dkms"
echo "bash_cmd<${bash_cmd}>"
/bin/bash -c "${bash_cmd}" || exit 1
# rebuild dkms modules if needed
bash_cmd="sudo dkms autoinstall"
echo "bash_cmd<${bash_cmd}>"
/bin/bash -c "${bash_cmd}" || exit 1

#-------------------------------------------
# upgrade flatpak
#-------------------------------------------
echo -e "\033[47;30m\nUpgrading Flatpak applications${Color_Off}"
bash_cmd="flatpak update -vy"
echo "bash_cmd<${bash_cmd}>"
/bin/bash -c "${bash_cmd}" || exit 1

#-------------------------------------------
# system monitor
#-------------------------------------------
echo -e "\033[47;30m\nSystem monitor${Color_Off}"
bash_cmd="gnome-system-monitor &"
echo "bash_cmd<${bash_cmd}>"
/bin/bash -c "${bash_cmd}" || exit 1

#-------------------------------------------
# logitech
#-------------------------------------------
#echo -e "\033[47;30m\nsolaar${Color_Off}"
#bash_cmd="sudo solaar &"
#echo "bash_cmd<${bash_cmd}>"
#/bin/bash -c "${bash_cmd}" || exit 1

#-------------------------------------------
# Complete
#-------------------------------------------
echo -e "${On_Blue}\n"
echo -e "Complete: <${0}>"
echo -e "${Color_Off}"
#echo -e "${On_Blue}\nComplete${Color_Off}"

exit 0
#-------------------------------------------







#-------------------------------------------
# winbox
#-------------------------------------------
#echo -e "\033[47;30m\nWinbox${Color_Off}"
#bash_cmd="wine64 '"${winbox_dir}"/winbox64.exe' &> '"${winbox_dir}"/winbox64.log' &"
#echo "bash_cmd<${bash_cmd}>"
#/bin/bash -c "${bash_cmd}" || exit 1






echo -e "${On_IBlack}"
echo "=============================="
echo "=          Complete          ="
echo "=============================="
echo -e "${Color_Off}"
echo -e "${On_IRed}"
echo "=============================="
echo "=          Complete          ="
echo "=============================="
echo -e "${Color_Off}"
echo -e "${On_IGreen}"
echo "=============================="
echo "=          Complete          ="
echo "=============================="
echo -e "${Color_Off}"
echo -e "${On_IYellow}"
echo "=============================="
echo "=          Complete          ="
echo "=============================="
echo -e "${Color_Off}"
echo -e "${On_IBlue}"
echo "=============================="
echo "=          Complete          ="
echo "=============================="
echo -e "${Color_Off}"
echo -e "${On_IPurple}"
echo "=============================="
echo "=          Complete          ="
echo "=============================="
echo -e "${Color_Off}"
echo -e "${On_ICyan}"
echo "=============================="
echo "=          Complete          ="
echo "=============================="
echo -e "${Color_Off}"
echo -e "${On_IWhite}"
echo "=============================="
echo "=          Complete          ="
echo "=============================="
echo -e "${Color_Off}"

exit 0


