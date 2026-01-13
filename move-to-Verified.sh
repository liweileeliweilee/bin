#!/bin/bash
# 20240213: add echo "[Line:${LINENO}]"
#
# 20241202:
#      add verify_dirname
#      add 複製整個目錄：判斷最後一個字元'*'
#
# 20250215: add error_lines.txt
#
# 20250216:
#      判斷verify_dir已經有該目錄或檔案，就不輸出到error_lines.txt
#     add current_file
#
# 20250216_2:
#      add remove_Finish_dir_file and remove_base_dir_file
#
# 20260113: 
#      add error_lines.txt check feature (Red Alert)
#########################################################################################

echo "[Line:${LINENO}]"
Color_Off='\033[0m'       # Text Reset
On_IBlack='\033[0;100m'   # Black
On_Blue='\033[44m'        # Blue
On_Red='\033[41m'         # Red Background (New)
White='\033[97m'          # White Text (New)

echo -e "${On_IBlack}\n"
echo -e "Starting: <${0}>"
echo -e "${Color_Off}"
#echo -e "${On_IBlack}\n\nStarting: <${0}>\n${Color_Off}"

# 20250216_2 add
base_dir=$(pwd)
echo "[Line:${LINENO}]"
echo "Working dir: ${base_dir}"
finish_dir="${base_dir}/Finish"
echo "Finish dir: ${finish_dir}"

# =======================================================
# 20260113 [新增功能] 記錄執行前的 error_lines.txt 行數
# =======================================================
error_log_file="${base_dir}/error_lines.txt"
init_err_count=0
if [ -f "${error_log_file}" ]; then
    init_err_count=$(wc -l < "${error_log_file}")
fi
# =======================================================

if [ "${1}" == ""  ]; then
echo "[Line:${LINENO}]"
  input_file="${base_dir}/working.txt"
else
echo "[Line:${LINENO}]"
  input_file="${base_dir}/${1}"
fi
echo "input_file: ${input_file}"
echo "[Line:${LINENO}]"

remove_Finish_dir_file="1_remove_Finish_dir_${1}"
remove_base_dir_file="2_remove_base_dir_${1}"

bash_cmd="sed \"s|${finish_dir}||g\" ${input_file} > ${remove_Finish_dir_file}"
#bash_cmd="sed \"s|${finish_dir}||g\" working_files.txt > working_files_1_remove_Finish_dir.txt"
echo "===> bash_cmd<${bash_cmd}>"
/bin/bash -c "${bash_cmd}"  || exit 1

bash_cmd="sed \"s|${base_dir}||g\" ${remove_Finish_dir_file} > ${remove_base_dir_file}"
#bash_cmd="sed \"s|${base_dir}||g\" working_files_1_remove_Finish_dir.txt > working_files_2_remove_base_dir.txt"
echo "===> bash_cmd<${bash_cmd}>"
 /bin/bash -c "${bash_cmd}"  || exit 1 

input_file="${remove_base_dir_file}"
echo "input_file: ${input_file}"
echo "[Line:${LINENO}]"

# 20250216_2
#base_dir=$(pwd)
#echo "[Line:${LINENO}]"
#echo "Working dir: ${base_dir}"
#finish_dir="${base_dir}/Finish"
#echo "Finish dir: ${finish_dir}"
#
#if [ "${1}" == ""  ]; then
#echo "[Line:${LINENO}]"
#  input_file="${base_dir}/working.txt"
#else
#echo "[Line:${LINENO}]"
#  input_file="${base_dir}/${1}"
#fi
#echo "input_file: ${input_file}"
#echo "[Line:${LINENO}]"

working_dir=""
working_dir_exist=0
working_files=""
current_file=""
verify_dir=""
verify_dirname=""
trash_dir=""
pre_line=""
while IFS= read -r line
do
  case "${line:0:1}" in
    "/")
#########################################################################################
# mv files
#########################################################################################
echo "[Line:${LINENO}]"
          verify_file=""$verify_dir"/"$current_file""
      echo "<mv files>: $working_files"
      echo "<verify_file>: $verify_file"
       
      if [ "$working_files" ] && [ ! -f "$verify_file" ]; then
#20250216       if [ "$working_files" ]; then
        echo "-=-=-=-=-=-=-=-=-=-=-=-=-="
        echo "pwd:<$(pwd)>"
#        echo "mkdir -p $verify_dir"
#        echo "cp -t $verify_dir $working_files"
#        echo "mkdir -p "$verify_dir"

            bash_cmd="mv -t \""${verify_dir}"\" "${working_files}""
            #20240213 bash_cmd="mv -t ""${verify_dir}"" "${working_files}""
            #20240112 bash_cmd="mv -t '"${verify_dir}"' "${working_files}""
            #bash_cmd="cp -t '"${verify_dir}"' "${working_files}""
            echo "===> bash_cmd<${bash_cmd}>"
            /bin/bash -c "${bash_cmd}" || echo "$pre_line" >> "${base_dir}/error_lines.txt"
            #20250215 /bin/bash -c "${bash_cmd}" || exit 1
            #"$bash_cmd"
echo "[Line:${LINENO}]"

      fi
#########################################################################################



echo "[Line:${LINENO}]"
      working_files=""

      echo "----------------------------------------------------"
#      echo "${line:0:1}: Found new directory name"


      echo "New Line: <$line>"
      if [ "${line:0-1}" == "/" ]; then # 此行只有目錄名：判斷最後一個字元'/'
echo "[Line:${LINENO}]"
        dir_name="$line"
        echo "dir_name: <${dir_name}> is a directory"
      else                              # 此行包含完整的目錄名跟檔名
        dir_name=$(dirname "$line")
        echo "dir_name: <${dir_name}>"
        if [ "${line:0-1}" == "*" ]; then #20241202 複製整個目錄：判斷最後一個字元'*'
echo "[Line:${LINENO}]"
        echo "Moving directory: Symbol <${line:0:1}> in <${input_file}>"
        #整個目錄從Finish搬到Verify
        verify_dir="${finish_dir}/Verified${dir_name}"
#        verify_dir="${finish_dir}/Verified/${dir_name}"
        verify_parent_dir=${verify_dir%/*}
    verify_dirname="$(dirname "$verify_dir")"
        echo "verify dirname: "\"$verify_dirname\"""
        echo "verify basename: "\""$(basename "$verify_dir")"\"""
        echo "verify_dir \"$verify_dir\""
        echo "verify_parent_dir \"$verify_parent_dir\""

          if [ ! -d "$verify_dir" ]; then #20250216
echo "[Line:${LINENO}]"
           echo "mkdir -p \"$verify_dir\""
          #20240112 echo "verify_dir '$verify_dir'"
          #20240112 echo "verify_parent_dir '$verify_parent_dir'"
          #20240112 echo "mkdir -p '$verify_dir'"
          bash_cmd="mkdir -p \""$verify_dirname"\""
          echo "===> bash_cmd<${bash_cmd}>"
          /bin/bash -c "${bash_cmd}"  || exit 1
          #20241202 mkdir -p "$verify_dir"

          working_dir="${finish_dir}${dir_name}"
          echo "working dir: ${working_dir}"
       
          bash_cmd="mv \""$working_dir"\" \""$verify_parent_dir"\""
          echo "===> bash_cmd<${bash_cmd}>"
          /bin/bash -c "${bash_cmd}" || echo "$line" >> "${base_dir}/error_lines.txt"
          #20250215 /bin/bash -c "${bash_cmd}" || exit 1
          #20240112
      #echo "mv -f \"$working_dir\" \"$verify_parent_dir\""
          #mv "$working_dir" "$verify_parent_dir" || exit 1
          #echo "mv -f '$working_dir' '$verify_parent_dir'"
        
          working_files=""
          fi #20250216

        else                              # 此行包含完整的目錄名跟檔名
echo "[Line:${LINENO}]"
        working_files=""\""$(basename "$line")"\"" "
        #20240112 working_files=""\'"$(basename "$line")"\'" "
        echo "working_files: <${working_files}>"
        
        #20250216 add
    current_file="$(basename "$line")"
        echo "current_file: <${current_file}>"
        fi
      fi


echo "[Line:${LINENO}]"

      echo "<${dir_name}>: Symbol <${line:0:1}> in <${input_file}>"
      echo ""
#      dir_name=${line:1} # 移除第一個字元
#      echo "<${dir_name}>: Symbol <${line:0:1}> in <${input_file}>"
#      echo ""

      working_dir="${finish_dir}${dir_name}"
#      working_dir="${finish_dir}/${dir_name}"
      echo "working dir: ${working_dir}"


      if [ -d "$working_dir" ]; then
echo "[Line:${LINENO}]"
#      cd "$working_dir"    
#      if [ $? -eq 0 ]; then
        cd "$working_dir"    
        echo "pwd:<$(pwd)>"
      working_dir_exist=1
        verify_dir="${finish_dir}/Verified${dir_name}"
#        verify_dir="${finish_dir}/Verified/${dir_name}"
        echo "verify dir: ${verify_dir}"
        trash_dir="${finish_dir}/Trash${dir_name}"
#        trash_dir="${finish_dir}/Trash/${dir_name}"
        echo "trash dir: ${trash_dir}"
        echo ""

        echo "mkdir -p \"$verify_dir\""
        #20240112 echo "mkdir -p '$verify_dir'"
        mkdir -p "$verify_dir"
        echo ""

      else
echo "[Line:${LINENO}]"
        working_dir_exist=0
        echo "<$working_dir>: directory not found"
      fi

      #20250215
      pre_line="$line"
      echo "pre_line:<$pre_line>"
#cd "$working_dir"
#echo "----------------------------------------------------"
#ls -al;echo $(pwd)
#echo "----------------------------------------------------"
#      cd "${working_dir}" && ls -al 
      ;;

    "#")
echo "[Line:${LINENO}]"
      echo "${line}"
      ;;

    "")
echo "[Line:${LINENO}]"
      echo "${line}"
      ;;

    "*")
echo "[Line:${LINENO}]"
        echo "Moving directory: Symbol <${line:0:1}> in <${input_file}>"
        #整個目錄從Finish搬到Verify
        verify_dir="${finish_dir}/Verified${dir_name}"
#        verify_dir="${finish_dir}/Verified/${dir_name}"
        verify_parent_dir=${verify_dir%/*}
        echo "verify_dir \"$verify_dir\""
        echo "verify_parent_dir \"$verify_parent_dir\""
        echo "mkdir -p \"$verify_dir\""
        #20240112 echo "verify_dir '$verify_dir'"
        #20240112 echo "verify_parent_dir '$verify_parent_dir'"
        #20240112 echo "mkdir -p '$verify_dir'"
        mkdir -p "$verify_dir"

        echo "mv -f \"$working_dir\" \"$verify_parent_dir\""
        #20240112 echo "mv -f '$working_dir' '$verify_parent_dir'"
        mv "$working_dir" "$verify_parent_dir" || exit 1
echo "[Line:${LINENO}]"
      ;;

    "@")
echo "[Line:${LINENO}]"
        echo "Moving directory reverse: Symbol <${line:0:1}> in <${input_file}>"
        #注意：反向整個目錄從Verify搬到Finish
        verify_dir="${finish_dir}/Verified${dir_name}"
#        verify_dir="${finish_dir}/Verified/${dir_name}"
        working_parent_dir=${working_dir%/*}
        echo "working_dir \"$working_dir\""
        echo "working_parent_dir \"$working_parent_dir\""
        echo "mkdir -p \"$working_dir\""
        #20240112 echo "working_dir '$working_dir'"
        #20240112 echo "working_parent_dir '$working_parent_dir'"
        #20240112 echo "mkdir -p '$working_dir'"
        mkdir -p "$working_dir"

        echo "mv \"$verify_dir\" \"$working_parent_dir\""
        #20240112 echo "mv '$verify_dir' '$working_parent_dir'"
        mv "$verify_dir" "$working_parent_dir"  || exit 1
echo "[Line:${LINENO}]"
      ;;

    *)
echo "[Line:${LINENO}]"
      if [ $working_dir_exist -eq 1 ]; then
echo "[Line:${LINENO}]"

            #從Finish搬到Verify
        ##20230117 echo "mv -t '$verify_dir' '${line}'"
        ##20230117 mv -t "$verify_dir" "$line"

            #注意：反向從Verify搬到Finish
        #echo "mv '$verify_dir/${line}' '$working_dir/${line}'"
        #mv "$verify_dir/$line" "$working_dir/$line"

            #從Finish拷貝到Verify
        #echo "cp -t '$verify_dir' '${line}'"
        #cp -t "$verify_dir" "$line"



        working_files="${working_files}"\""${line}"\"" "
        #20240112 working_files="${working_files}"\'"${line}"\'" "
        ##20230117 working_files="${working_files}"\'"${working_dir}"/"${line}"\'" "
        #working_files="$working_files""$line"" "
            echo "${line}"
            ##20230117 echo "${working_dir}/${line}"
echo "[Line:${LINENO}]"
      fi
      ;;
  esac
done < "$input_file"
#########################################################################################
# mv files end
#########################################################################################
echo "[Line:${LINENO}]"
          verify_file=""$verify_dir"/"$current_file""
      echo "<mv files end>: $working_files"
      echo "<verify_file>: $verify_file"
       
      if [ "$working_files" ] && [ ! -f "$verify_file" ]; then
#      if [ "$working_files" ]; then
#20250216       if [ "$working_files" ]; then
        echo "-=-=-=-=-=-=-=-=-=-=-=-=-="
        echo "pwd:<$(pwd)>"
#        echo "mkdir -p $verify_dir"
#        echo "cp -t $verify_dir $working_files"
#        echo "mkdir -p "$verify_dir"

            bash_cmd="mv -t \""${verify_dir}"\" "${working_files}""
            #20240213 bash_cmd="mv -t ""${verify_dir}"" "${working_files}""
            #20240112 bash_cmd="mv -t '"${verify_dir}"' "${working_files}""
            #bash_cmd="cp -t '"${verify_dir}"' "${working_files}""
            echo "===> bash_cmd<${bash_cmd}>"
            /bin/bash -c "${bash_cmd}" || echo "$pre_line" >> "${base_dir}/error_lines.txt"
            #20250215 /bin/bash -c "${bash_cmd}" || exit 1
            #"$bash_cmd"
echo "[Line:${LINENO}]"

      fi
#########################################################################################



working_files=""

echo -e "${On_Blue}\n"
echo -e "Complete: <${0}>"
echo -e "${Color_Off}"
#echo -e "${On_Blue}\nComplete: <${0}>${Color_Off}"

# =======================================================
# 20260113 [新增功能] 檢查是否有新的錯誤產生，並以紅底白字提示
# =======================================================
curr_err_count=0
if [ -f "${error_log_file}" ]; then
    curr_err_count=$(wc -l < "${error_log_file}")
fi

if [ "$curr_err_count" -gt "$init_err_count" ]; then
    echo -e "${On_Red}${White}"
    echo "################################################################"
    echo " !!! 注意：腳本執行期間產生了新的錯誤記錄 !!! "
    echo " 錯誤檔案: ${error_log_file}"
    echo " 新增行數: $((curr_err_count - init_err_count)) 行"
    echo "################################################################"
    echo -e "${Color_Off}"
fi
# =======================================================

echo "[Line:${LINENO}]"
exit 0










echo "[Line:${LINENO}]"
  if [ "${line:0:1}" == "/" ]; then
    echo "${line:0:1}: this line is a directory"
    echo "<${line:1}>" # 移除第一個'#'
    working_dir=${line:1}
  else
    echo "${working_dir}/${line}"
  fi
