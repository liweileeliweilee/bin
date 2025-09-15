#!/bin/bash

# ==========================================================
# 腳本說明：將目前使用者的所有 Flatpak 設定檔複製給 root 帳號
# ==========================================================

# 檢查是否以 root 權限運行
if [[ $EUID -ne 0 ]]; then
   echo "此腳本需要以 root 權限運行，請使用 sudo。"
   exit 1
fi

# 獲取原始使用者名稱
CURRENT_USER="${SUDO_USER}"

if [ -z "$CURRENT_USER" ]; then
    echo "錯誤：無法獲取原始使用者名稱。請直接以該使用者帳號執行此腳本（例如：sudo ./腳本名稱）。"
    exit 1
fi

echo "正在將使用者 '$CURRENT_USER' 的 Flatpak 設定檔複製給 'root'..."

# 獲取使用者已安裝的所有 Flatpak 應用程式 ID
# 這裡直接列出 .var/app/ 目錄下的所有子目錄名稱
APP_IDS=$(find "/home/$CURRENT_USER/.var/app" -maxdepth 1 -mindepth 1 -type d -printf '%P\n')

# 檢查是否有找到任何應用程式
if [ -z "$APP_IDS" ]; then
    echo "警告：找不到使用者 '$CURRENT_USER' 安裝的任何 Flatpak 應用程式。"
    echo "請確認你已經用此帳號安裝過 Flatpak 應用程式。"
    exit 0
fi

# 遍歷每個應用程式 ID 並複製設定檔
for APP_ID in $APP_IDS; do
    SOURCE_DIR="/home/$CURRENT_USER/.var/app/$APP_ID"
    TARGET_DIR="/root/.var/app/$APP_ID"

    # 檢查來源設定目錄是否存在
    if [ -d "$SOURCE_DIR" ]; then
        echo "正在複製 '$APP_ID' 的設定檔..."
        # 確保目標目錄存在
        mkdir -p "$TARGET_DIR"

        # 複製 config 和 data 資料夾
        if [ -d "$SOURCE_DIR/config" ]; then
            cp -r "$SOURCE_DIR/config" "$TARGET_DIR"
            echo "  - 複製 config 資料夾"
        fi

        if [ -d "$SOURCE_DIR/data" ]; then
            cp -r "$SOURCE_DIR/data" "$TARGET_DIR"
            echo "  - 複製 data 資料夾"
        fi
        
        echo "'$APP_ID' 的設定檔複製完成。"
        echo "-------------------------------------------"
    else
        echo "警告：找不到 '$APP_ID' 的設定目錄，跳過。"
        echo "-------------------------------------------"
    fi
done

echo "所有 Flatpak 應用程式設定複製完畢。"
echo "注意：某些應用程式（如 SMPlayer）的設定可能包含絕對路徑，複製後仍可能需要手動調整。"
