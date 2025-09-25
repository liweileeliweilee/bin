# 自用工具腳本集合

這個倉庫收錄了一些日常使用的 Linux / Proxmox / Git / XFCE 等相關工具腳本。  
所有腳本均為 **可直接執行的 Shell Script 或 Python Script**，使用前請先確認檔案有執行權限 (`chmod +x <script>`)

---

## 📂 腳本列表

### 1. `auto-vcpu-pinning.sh`
- **用途**：自動化 Proxmox VE VM vCPU 綁定（CPU pinning）。
- **特色**：
  - 固定將 E-core 分配給 RouterOS（VM 812）與 DSM（VM 820）
  - 其他 VM 平均分配 P-core（不含超執行緒）
  - 自動產生 `qm set` 指令並執行

---

### 2. `copy-all-flatpak-settings-to-root.sh`
- **用途**：將使用者的 Flatpak 設定檔複製到 root 帳號。
- **特色**：
  - 支援多個 App ID
  - 複製 `config/` 與 `data/`
  - 適合讓 root 執行 Flatpak 應用時，沿用使用者設定

---

### 3. `dump-files.sh`
- **用途**：輸出指定目錄下所有文字檔內容到單一檔案。
- **特色**：
  - 支援遞迴模式
  - 可指定輸出檔名（預設：`dump-files-output.txt`）
  - 自動略過二進位檔與輸出檔自身
  - 支援隱藏檔（例如 `.gitignore`）

---

### 4. `git-helper.py`
- **用途**：Git 操作輔助工具（互動式選單）。
- **功能**：
  - 狀態檢查、提交、推送、拉取
  - 智能初始化/克隆倉庫
  - 自動設定遠端倉庫（SSH）
  - 檔案回復 / 歷史查詢
  - 自動產生帶有識別標記的 commit 訊息

---

### 5. `move_to_Verified.sh`
- **用途**：依據 `working.txt` 搬移檔案/資料夾到 `Finish/Verified`。
- **特色**：
  - 支援整個目錄或單檔案搬移
  - 失敗的路徑會記錄到 `error_lines.txt`
  - 自動處理目錄結構

---

### 6. `mystartup.sh`
- **用途**：個人啟動流程腳本。
- **動作**：
  - 更新 APT 與 Flatpak
  - 可選掛載 CIFS 共享資料夾
  - 啟動 Winbox（透過 Wine）
  - 結束時輸出多色「Complete」提示

---

### 7. `set-DPI.sh`
- **用途**：XFCE HiDPI 與字型縮放設定。
- **設定項目**：
  - DPI / Scale / 字型大小 / 游標大小
  - 修改 `.Xresources`、`xfconf-query`、`/etc/environment`
  - Flatpak 游標大小覆蓋

---

### 8. `sys-block-device-delete.sh`
- **用途**：刪除 Linux block device。
- **功能**：
  - 驗證輸入是否為 block device
  - 執行 `echo 1 > /sys/block/.../device/delete`

---

### 9. `sys-class-scsi-host-scan.sh`
- **用途**：重新掃描所有 SCSI host bus。
- **指令**：
  - `echo "- - -" > /sys/class/scsi_host/host*/scan`

---

### 10. `vil-copy-layers.py`
- **用途**：複製 Vial (QMK/VIA 相容) JSON 檔案的鍵盤圖層。
- **範例**：
  - `vil-copy-layers.py keyboard.vil 0 1` → 複製 layer0 到 layer1
  - `vil-copy-layers.py keyboard.vil 1,2 3,4` → 複製多個圖層

---

### 11. `test-ddns.sh`
- **用途**：測試多家 DDNS 服務商的解析品質。
- **特色**：
  - 使用隨機子網域 + SOA 查詢，避免快取干擾，真實測試權威伺服器回應
  - 指定公共遞迴器（8.8.8.8 / 1.1.1.1 / 208.67.222.222）
  - 記錄平均、最佳、最差回應時間與成功率
  - 完整輸出保存到檔案，摘要輸出到螢幕
  - 最後生成總表，清楚標示 DSM 預設與額外測試服務商，並給予星級評分

---

## 🚀 使用方式

```bash
# 賦予執行權限
chmod +x *.sh
chmod +x *.py

# 執行範例
./auto-vcpu-pinning.sh
./copy-all-flatpak-settings-to-root.sh
./test-ddns.sh
python3 git-helper.py

