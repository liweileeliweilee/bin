#!/bin/bash
# auto-vcpu-pinning.sh
#
# 功能說明：
# - 固定將 E-core 分配給 RouterOS（VM 812）與 DSM（VM 820）
# - 其他 VM 自動平均分配 P-core（不包含 HT 超執行緒）
# - 自動抓取所有 VM ID 並排除上述兩個 VM
# - 輸出每個執行的實際 qm set 指令，方便手動驗證或重複執行
#
# 注意：需使用 Proxmox VE 且 CPU 支援 Intel 混合架構（如 i5-12600K）

# === 設定區 ===
VCPUS_PER_VM=2          # 一般 VM 每台分配幾個 vCPU
FIXED_VCPUS_PER_VM=2    # 固定 VM（RouterOS / DSM）每台分配幾個 vCPU

# 固定分配 E-core 的 VM ID
FIXED_VMS=("812" "820")

# 定義 P-core（不含 HT）和 E-core ID（請根據實際系統調整）
P_CORES=(0 2 4 6 8 10)        # P-core 單執行緒（避開 HT）
E_CORES=(12 13 14 15)        # 所有 E-core ID

# === 分配固定 VM ===
USED_CORES=()
ecore_index=0

for vmid in "${FIXED_VMS[@]}"; do
  SELECTED=("${E_CORES[@]:$ecore_index:$FIXED_VCPUS_PER_VM}")
  CORES_STR=$(IFS=';'; echo "${SELECTED[*]}")
  USED_CORES+=("${SELECTED[@]}")

  echo "固定分配 E-core 給 VM $vmid: ${SELECTED[*]}"
  echo "執行：qm set $vmid --cpu host --numa0 cpus=$CORES_STR"
  qm set "$vmid" --cpu host --numa0 cpus="$CORES_STR"
  ecore_index=$((ecore_index + FIXED_VCPUS_PER_VM))
done

# === 自動分配給其他 VM（排除 FIXED_VMS） ===
ALL_VMS=($(qm list | awk 'NR>1 {print $1}'))
OTHER_VMS=()
for vmid in "${ALL_VMS[@]}"; do
  if [[ ! " ${FIXED_VMS[*]} " =~ " $vmid " ]]; then
    OTHER_VMS+=("$vmid")
  fi
done

# 建立 P-core 使用計數器
declare -A USED
for core in "${P_CORES[@]}"; do USED[$core]=0; done

for vmid in "${OTHER_VMS[@]}"; do
  SELECTED=()
  while [ "${#SELECTED[@]}" -lt "$VCPUS_PER_VM" ]; do
    least_used=""
    least_count=999
    for core in "${P_CORES[@]}"; do
      if [[ ! " ${SELECTED[*]} " =~ " $core " ]] && [ "${USED[$core]}" -lt "$least_count" ]; then
        least_used=$core
        least_count=${USED[$core]}
      fi
    done
    SELECTED+=("$least_used")
    USED[$least_used]=$((USED[$least_used] + 1))
  done

  CORES_STR=$(IFS=';'; echo "${SELECTED[*]}")
  echo "自動分配 P-core 給 VM $vmid: ${SELECTED[*]}"
  echo "執行：qm set $vmid --cpu host --numa0 cpus=$CORES_STR"
  qm set "$vmid" --cpu host --numa0 cpus="$CORES_STR"
done

echo "✅ 所有 VM 的 CPU pinning 已完成。"

