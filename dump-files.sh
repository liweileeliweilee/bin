#!/bin/bash
# dump-files.sh - 輸出目錄下或遞迴目錄下的所有文字檔內容
# 輸出檔可自訂，二進位檔自動跳過，輸出檔自身會自動跳過
# 更新: 加入隱藏檔（例如 .gitignore）的支援

usage() {
    echo "用法:"
    echo "  $0                     # 顯示使用說明"
    echo "  $0 <目錄>              # 輸出目錄下的文字檔案內容"
    echo "  $0 -r <目錄>           # 遞迴輸出目錄及子目錄下文字檔案內容"
    echo "  $0 -o <檔名> <目錄>    # 指定輸出檔案"
    echo "  $0 -r -o <檔名> <目錄> # 遞迴並指定輸出檔案"
    echo ""
    echo "範例:"
    echo "  $0 ./mydir"
    echo "  $0 -r ./mydir"
    echo "  $0 -o dump.txt ./mydir"
    echo "  $0 -r -o dump.txt ./mydir"
    echo ""
    echo "注意:"
    echo "  - 僅輸出文字檔，二進位檔會自動跳過"
    echo "  - 預設輸出檔為 dump-files-output.txt"
    exit 1
}

recursive=false
output="dump-files-output.txt"

# 解析選項
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r)
            recursive=true
            shift
            ;;
        -o)
            shift
            [ -z "$1" ] && { echo "錯誤: -o 需要指定檔名"; usage; }
            output="$1"
            shift
            ;;
        -*)
            echo "未知選項: $1"
            usage
            ;;
        *)
            dir="$1"
            shift
            ;;
    esac
done

# 檢查目錄
[ -z "$dir" ] && usage
[ ! -d "$dir" ] && { echo "錯誤: $dir 不是目錄"; exit 1; }

: > "$output"

# 遞迴模式
if $recursive; then
    find "$dir" -type f | while read -r f; do
        # 跳過輸出檔自己
        [ "$(realpath "$f")" = "$(realpath "$output")" ] && continue
        # 判斷是否為文字檔（不是二進位）
        if grep -Iq . "$f"; then
            echo "===== $f =====" >> "$output"
            cat "$f" >> "$output"
            echo "" >> "$output"
        fi
    done
else
    shopt -s dotglob nullglob
    for f in "$dir"/*; do
        [ "$(realpath "$f")" = "$(realpath "$output")" ] && continue
        [ ! -f "$f" ] && continue
        if grep -Iq . "$f"; then
            echo "===== $f =====" >> "$output"
            cat "$f" >> "$output"
            echo "" >> "$output"
        fi
    done
    shopt -u dotglob nullglob
fi

echo "已輸出到 $output"

