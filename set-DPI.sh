#!/bin/bash
# set-DPI.sh
# 最終版：最簡潔、最正確、只執行一次

set -e

# === 可調參數 ===
DPI=144
SCALE=1.5
CURSOR_SIZE=48
FONT_SIZE=15

echo "==== 1. 設定使用者 Xresources (字型 DPI + 游標大小) ===="
mkdir -p "$HOME"/.Xresources.d
cat > "$HOME"/.Xresources.d/hidpi <<EOF
Xft.dpi: $DPI
Xcursor.size: $CURSOR_SIZE
Xcursor.theme: Adwaita
EOF
xrdb -merge "$HOME"/.Xresources.d/hidpi || true

echo "==== 2. 設定 XFCE 游標主題 ===="
mkdir -p "$HOME"/.icons/default
cat > "$HOME"/.icons/default/index.theme <<EOF
[Icon Theme]
Inherits=Adwaita
EOF

echo "==== 3. 設定 XFCE 核心參數 (xfconf-query) ===="
# 取得並設定一般字體大小
CURRENT_FONT=$(xfconf-query -c xsettings -p /Gtk/FontName)
FONT_NAME=$(echo "$CURRENT_FONT" | sed -E 's/ [0-9]+$//')
xfconf-query -c xsettings -p /Gtk/FontName -s "$FONT_NAME $FONT_SIZE"

# 取得並設定等寬字體大小
CURRENT_MONO_FONT=$(xfconf-query -c xsettings -p /Gtk/MonospaceFontName)
MONO_FONT_NAME=$(echo "$CURRENT_MONO_FONT" | sed -E 's/ [0-9]+$//')
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "$MONO_FONT_NAME $FONT_SIZE"

# 設定其他核心參數
xfconf-query -c xsettings -p /Xft/DPI -s 144
xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s $CURSOR_SIZE
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Adwaita"

echo "==== 4. 設定 Flatpak 全局游標大小 ===="
# Flatpak 指令直接以使用者權限運行
flatpak override --user --env=XCURSOR_SIZE=$CURSOR_SIZE || true

echo "==== 5. 設定全局 HiDPI 環境變數 (/etc/environment) ===="
# 這是唯一需要 root 權限的步驟，單獨用 sudo 執行
sudo tee /etc/environment > /dev/null <<EOF
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
LANG=zh_TW.UTF-8

GDK_SCALE=$SCALE
QT_SCALE_FACTOR=$SCALE
_JAVA_OPTIONS='-Dsun.java2d.uiScale='$SCALE
XFT_DPI=$DPI
XCURSOR_SIZE=$CURSOR_SIZE
EOF

echo ""
echo "✅ 所有設定已完成！"
echo "   → DPI=$DPI, Scale=$SCALE, Font=$FONT_SIZE, Cursor=$CURSOR_SIZE"
echo "⚠️  請務必重新登入 XFCE 後才會生效！"
