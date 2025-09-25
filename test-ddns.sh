#!/bin/bash
# =====================================================================
# DSM DDNS 服務商品質測試（Bash 版，最終穩定，含總表與最佳回應）
#
# 【關鍵技術說明：為什麼這樣可以測試出真正的 DDNS 服務品質】
# 1. 隨機子網域 + SOA 查詢：以隨機子網域 (如 abc123.domain.com) 查 SOA，避免命中遞迴快取，
#    強迫遞迴伺服器去權威伺服器取資料，真實反映 DDNS 響應品質（存在/不存在都能得到明確答案）。
# 2. 指定公共遞迴器：使用 @8.8.8.8 等公共 DNS，避免本地快取造成 0ms 假象，量測的是網路解析往返。
# 3. 成功定義：NOERROR 與 NXDOMAIN 都視為成功，因為權威鏈路有正確回覆（有/無此名）。
# 4. 嚴格超時與重試：+time=2 +tries=2，統一比較標準，能暴露最差情況（尾部延遲/偶發停頓）。
# 5. 指標完整：同時計算平均、最佳(最快)、最差(最慢)響應與成功率，並給星級評分，避免只看平均被波動誤導。
#
# 【需求如下：(把需求也原封不動的寫入腳本說明中)】
# 1. 跟本次要求無關的地方禁止更改程式碼，要對程式碼任何地方做更動必須要先取得同意才能改。
# 2. 測試這些DDNS服務商：
# #DSM 預置的DDNS服務商域名
#     "changeip.com"
#     "dnspod.cn"
#     "dnspod.com"
#     "dyndns.org"
#     "freedns.afraid.org"
#     "dns.google"
#     "no-ip.com"
#     "ovh.com"
#     "oray.com"
#     "strato.de"
#     "selfhost.de"
# #額外測試的免費服務商
#     "duckdns.org"
#     "dynu.com"
#     "cloudns.net"
#     "dynv6.com"
#     "desec.io"
#     "ydns.io"
# 3. 要測試ddns服務的品質，而不是測試網站的速度。
# 4. 真正的測試指令要提示給使用者。
# 5. 響應不能只看平均，如果平均很低但波動太大，也就是響應最差的時候太久也不行。
# 6. 執行過程：6.1 完整無刪減的部份輸出到檔案，檔案路徑顯示在總表之後。6.2 摘要的部份輸出到螢幕上。
# 7. 執行完畢後把所有的執行結果用一張總表統計詳細列出所有被測試過的DDNS服務商，要標明清楚讓使用者知道什麼是DSM預設什麼是額外測試的，推薦程度用進度來表示比較清楚，比如說零顆星一顆星兩顆星三顆星等等。
# 8. 把測試指令的關鍵技術寫到腳本說明的最開頭處，為什麼這樣可以測試出ddns的服務品質。
# 9. 測試過程如下：
# 正在執行 DDNS 服務品質測試...
# ===============================================================
# [1/17] 測試 changeip.com (DSM)
# ===============================================================
# 執行指令: dig +time=2 +tries=2 @8.8.8.8 edrzv7.changeip.com SOA +stats +comments
# 結果: 成功 (94ms)
#
# 執行指令: dig +time=2 +tries=2 @8.8.8.8 y8zl8x.changeip.com SOA +stats +comments
# 結果: 成功 (100ms)
#
# 執行指令: dig +time=2 +tries=2 @1.1.1.1 3phev7.changeip.com SOA +stats +comments
# 結果: 成功 (89ms)
#
# 執行指令: dig +time=2 +tries=2 @1.1.1.1 drq5kb.changeip.com SOA +stats +comments
# 結果: 成功 (98ms)
#
# 執行指令: dig +time=2 +tries=2 @208.67.222.222 3l0xib.changeip.com SOA +stats +comments
# 結果: 成功 (94ms)
#
# 執行指令: dig +time=2 +tries=2 @208.67.222.222 hjh8i4.changeip.com SOA +stats +comments
# 結果: 成功 (97ms)
#
# changeip.com         95ms     89ms     100ms    100%    5     ★★☆☆☆
#
# 10. 總表如下：(要調整好格式對齊)
# ===============================================================
# DSM 預設服務商          平均回應  最佳回應  最差回應  成功率   節點  評分
# -------------------------------------------------------------------
# changeip.com         156ms     16ms     2345ms    83%     5     ★☆☆☆☆
# dnspod.cn            31ms      16ms     100ms     100%    2     ★★★★☆
# dyndns.org           32ms      16ms     116ms     100%    4     ★★★☆☆
# dns.google           17ms      16ms     19ms      100%    4     ★★★★★
# no-ip.com            29ms      16ms     88ms      100%    4     ★★★★☆
# ovh.com              16ms      16ms     20ms      100%    6     ★★★★★
# strato.de            17ms      16ms     19ms      100%    4     ★★★★★
# selfhost.de          58ms      16ms     263ms     67%     2     ☆☆☆☆☆
#
# 額外測試服務商          平均回應  最佳回應  最差回應  成功率   節點  評分
# -------------------------------------------------------------------
# duckdns.org          18ms      16ms     19ms      100%    9     ★★★★★
# dynu.com             17ms      15ms     18ms      100%    7     ★★★★★
# cloudns.net          14ms      16ms     18ms      100%    6     ★★★★★
# ydns.io              17ms      16ms     19ms      100%    2     ★★★★★
#
# ===============================================================
# =====================================================================

set -o pipefail
export LC_ALL=C
export LANG=C

# DSM 預置服務商
DSM_SERVICES=(
  "changeip.com" "dnspod.cn" "dnspod.com" "dyndns.org"
  "freedns.afraid.org" "dns.google" "no-ip.com" "ovh.com"
  "oray.com" "strato.de" "selfhost.de"
)

# 額外測試服務商
EXTRA_SERVICES=(
  "duckdns.org" "dynu.com" "cloudns.net"
  "dynv6.com" "desec.io" "ydns.io"
)

# 公共遞迴解析器
RECURSORS=("8.8.8.8" "1.1.1.1" "208.67.222.222")
ATTEMPTS=2
DETAIL_FILE="/tmp/ddns_quality_$(date +%Y%m%d_%H%M%S).log"

# 總表結果（全域陣列）
RESULTS=()

# 星級評分
get_star_rating() {
  local avg="$1" max="$2" rate="$3"
  if (( rate < 60 )); then echo "☆☆☆☆☆"; return; fi
  if (( rate < 80 )); then echo "★☆☆☆☆"; return; fi
  if (( avg < 20 && max < 50 )); then echo "★★★★★"; return; fi
  if (( avg < 30 && max < 100 )); then echo "★★★★☆"; return; fi
  if (( avg < 50 && max < 200 )); then echo "★★★☆☆"; return; fi
  if (( avg < 100 && max < 500 )); then echo "★★☆☆☆"; return; fi
  echo "★☆☆☆☆"
}

# 執行 dig 並回傳 qtime|rcode（完整輸出寫入檔案）
run_dig() {
  local cmd="$*"
  local out
  out=$(timeout 5s $cmd 2>&1)
  {
    echo "----- $(date +'%F %T') -----"
    echo "$cmd"
    echo "$out"
    echo "----------------------------"
  } >> "$DETAIL_FILE"

  local qtime rcode
  qtime=$(echo "$out" | awk '/^;; Query time:/ {print $4; exit}')
  rcode=$(echo "$out" | awk -F'status: ' '/status:/ {split($2,a,","); print a[1]; exit}')

  [[ "$qtime" =~ ^[0-9]+$ ]] || qtime=""
  [[ -n "$rcode" ]] || rcode="UNKNOWN"

  echo "${qtime}|${rcode}"
}

# 測試單一服務商（即時摘要輸出，並把一行資料加入總表）
test_domain() {
  local domain="$1" category="$2" idx="$3" total="$4"
  echo "==============================================================="
  echo "[$idx/$total] 測試 $domain ($category)"
  echo "==============================================================="

  local success=0 total_time=0 min_time=1000000 max_time=0 attempts=0

  for dns in "${RECURSORS[@]}"; do
    for i in $(seq 1 $ATTEMPTS); do
      attempts=$((attempts+1))
      rnd=$(head /dev/urandom | tr -dc a-z0-9 | head -c6)
      fqdn="${rnd}.${domain}"
      echo "執行指令: dig +time=2 +tries=2 @${dns} ${fqdn} SOA +stats +comments"
      parsed=$(run_dig dig +time=2 +tries=2 @"$dns" "$fqdn" SOA +stats +comments)
      qtime="${parsed%%|*}"
      rcode="${parsed##*|}"

      if [[ -n "$qtime" && ( "$rcode" == "NOERROR" || "$rcode" == "NXDOMAIN" ) ]]; then
        echo "結果: 成功 (${qtime}ms)"
        success=$((success+1))
        total_time=$((total_time+qtime))
        (( qtime < min_time )) && min_time=$qtime
        (( qtime > max_time )) && max_time=$qtime
      else
        echo "結果: 失敗"
      fi
      echo ""
      sleep 0.5
    done
  done

  local avg="N/A" rate=0 stars="☆☆☆☆☆" max_disp="N/A" min_disp="N/A"
  if (( success > 0 )); then
    avg=$(( total_time / success ))
    rate=$(( success * 100 / attempts ))
    max_disp="${max_time}ms"
    min_disp="${min_time}ms"
    stars=$(get_star_rating "$avg" "$max_time" "$rate")
  fi

  local nodes
  nodes=$(dig +short NS "$domain" | wc -l)

  # 即時摘要輸出（螢幕）
  if [[ "$avg" == "N/A" ]]; then
    printf "%-20s %-8s %-8s %-8s %-7s %-5s %s\n" "$domain" "N/A" "N/A" "N/A" "${rate}%" "$nodes" "$stars"
  else
    printf "%-20s %-8s %-8s %-8s %-7s %-5s %s\n" "$domain" "${avg}ms" "${min_disp}" "${max_disp}" "${rate}%" "$nodes" "$stars"
  fi

  # 加入總表（全域 RESULTS）
  if [[ "$avg" == "N/A" ]]; then
    RESULTS+=("$domain|$category|N/A|N/A|N/A|${rate}%|$nodes|$stars")
  else
    RESULTS+=("$domain|$category|${avg}ms|${min_disp}|${max_disp}|${rate}%|$nodes|$stars")
  fi
}

# 主程式
ALL_SERVICES=("${DSM_SERVICES[@]}" "${EXTRA_SERVICES[@]}")
TOTAL=${#ALL_SERVICES[@]}
CURRENT=0

echo "正在執行 DDNS 服務品質測試..."

for d in "${DSM_SERVICES[@]}"; do
  CURRENT=$((CURRENT+1))
  test_domain "$d" "DSM" "$CURRENT" "$TOTAL"
done

for d in "${EXTRA_SERVICES[@]}"; do
  CURRENT=$((CURRENT+1))
  test_domain "$d" "EXTRA" "$CURRENT" "$TOTAL"
done

# 最終總表（分區列出；檔案路徑放在總表之後）
echo "==============================================================="
echo "DSM 預設服務商          平均回應  最佳回應  最差回應  成功率   節點  評分"
echo "-------------------------------------------------------------------"
for line in "${RESULTS[@]}"; do
  IFS="|" read -r domain category avg min max rate nodes stars <<< "$line"
  [[ "$category" != "DSM" ]] && continue
  printf "%-20s %-9s %-9s %-10s %-7s %-5s %s\n" "$domain" "$avg" "$min" "$max" "$rate" "$nodes" "$stars"
done

echo ""
echo "額外測試服務商          平均回應  最佳回應  最差回應  成功率   節點  評分"
echo "-------------------------------------------------------------------"
for line in "${RESULTS[@]}"; do
  IFS="|" read -r domain category avg min max rate nodes stars <<< "$line"
  [[ "$category" != "EXTRA" ]] && continue
  printf "%-20s %-9s %-9s %-10s %-7s %-5s %s\n" "$domain" "$avg" "$min" "$max" "$rate" "$nodes" "$stars"
done

echo "==============================================================="
echo "完整 dig 輸出保存於: $DETAIL_FILE"

