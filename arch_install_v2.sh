#!/usr/bin/env bash
# install_bspwm_tokyonight.sh
# Полностью автоматическая установка bspwm + rofi + mc в стиле Tokyo Night на Arch Linux
# Запуск: sudo bash install_bspwm_tokyonight.sh

set -euo pipefail

# ─── Проверка root ───
if [[ $EUID -ne 0 ]]; then
    echo "Запустите скрипт от root: sudo bash $0"
    exit 1
fi

# ─── Целевой пользователь (не root) ───
TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    # если запущено не через sudo — берём первого обычного пользователя из /etc/passwd
    TARGET_USER=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}' /etc/passwd)
fi

if [[ -z "$TARGET_USER" ]]; then
    echo "Не удалось определить целевого пользователя. Укажите вручную: TARGET_USER=имя sudo bash $0"
    exit 1
fi

HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)
echo ">>> Целевой пользователь: $TARGET_USER  (home: $HOME_DIR)"

# ─── Палитра Tokyo Night ───
TN_BG="#1a1b26"
TN_BG_DARK="#16161e"
TN_BG_HL="#292e42"
TN_BG_TERM="#414868"
TN_FG="#c0caf5"
TN_FG_DARK="#a9b1d6"
TN_GUTTER="#3b4261"
TN_BLUE="#7aa2f7"
TN_CYAN="#7dcfff"
TN_BLUE1="#2ac3de"
TN_MAGENTA="#bb9af7"
TN_GREEN="#9ece6a"
TN_GREEN1="#73daca"
TN_ORANGE="#ff9e64"
TN_YELLOW="#e0af68"
TN_PURPLE="#9d7cd8"
TN_RED="#f7768e"
TN_RED1="#db4b4b"
TN_TEAL="#1abc9c"
TN_DARK5="#737aa2"

run_as() {
    sudo -u "$TARGET_USER" HOME="$HOME_DIR" "$@"
}

# ─── 1. Установка пакетов ───
echo ">>> [1/8] Установка пакетов..."
pacman -Syu --noconfirm --needed \
    bspwm sxhkd rofi mc \
    xorg xorg-xinit xorg-server \
    lightdm lightdm-gtk-greeter \
    alacritty \
    polybar \
    picom \
    git \
    ttf-jetbrains-mono-nerd \
    feh \
    jq \
    network-manager-applet

# ─── 2. Директории конфигов ───
echo ">>> [2/8] Создание директорий..."
CFG="$HOME_DIR/.config"
run_as mkdir -p "$CFG/bspwm" "$CFG/sxhkd" "$CFG/rofi" \
    "$CFG/polybar" "$CFG/picom" "$CFG/alacritty" \
    "$HOME_DIR/.local/share/mc/skins" \
    "$HOME_DIR/.local/share/backgrounds"

# ─── 3. bspwmrc ───
echo ">>> [3/8] Настройка bspwm..."
cat > "$CFG/bspwm/bspwmrc" <<'BSPWMEOF'
#!/usr/bin/env bash

# ── Автозапуск ──
killall -q sxhkd polybar picom feh nm-applet
while pgrep -x sxhkd >/dev/null; do sleep 0.1; done

sxhkd &
picom --config ~/.config/picom/picom.conf -b &
feh --bg-scale ~/.local/share/backgrounds/tokyonight.jpg &
nm-applet --sm-disable &

# ── Полоски polybar ──
polybar main 2>/dev/null &

# ── Рабочие столы ──
bspc monitor -d 1 2 3 4 5 6 7 8 9 10

# ── Поведение ──
bspc config focus_follows_pointer true
bspc config pointer_follows_focus false
bspc config click_to_focus any
bspc config border_width 2
bspc config window_gap 8
bspc config split_ratio 0.52
bspc config automatic_scheme spiral
bspc config initial_polarity second_child
bspc config pointer_modifier mod4
bspc config pointer_action1 move
bspc config pointer_action2 resize
bspc config pointer_action3 resize_side
bspc config removal_adjustment true

# ── Цвета Tokyo Night ──
bspc config normal_border_color   "#3b4261"
bspc config active_border_color    "#7aa2f7"
bspc config focused_border_color   "#7aa2f7"
bspc config presel_feedback_color  "#bb9af7"

# ── Правила окон ──
bspc rule -a Gimp desktop='^8' state=floating follow=on
bspc rule -a mpv state=floating
bspc rule -a Kupfer.py focus=on
bspc rule -a Screenkey manage=off
bspc rule -a Alacritty state=tiled
bspc rule -a Rofi state=floating
BSPWMEOF
chmod +x "$CFG/bspwm/bspwmrc"
chown "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$CFG/bspwm/bspwmrc"

# ─── 4. sxhkdrc ───
echo ">>> [4/8] Настройка горячих клавиш..."
cat > "$CFG/sxhkd/sxhkdrc" <<'SXHKDEOF'
# ── Терминал ──
super + Return
    alacritty

# ── Запуск приложений (rofi) ──
super + d
    rofi -show drun -config ~/.config/rofi/config.rasi

# ── Запуск команд (rofi) ──
super + shift + d
    rofi -show run -config ~/.config/rofi/config.rasi

# ── Midnight Commander ──
super + e
    alacritty -e mc

# ── Закрыть окно ──
super + q
    bspc node -c

# ── Перезагрузка конфигов ──
super + shift + r
    bspc wm -r && pkill -USR1 -x sxhkd

# ── Выход из сессии ──
super + shift + e
    bspc quit

# ── Фокус между окнами ──
super + {h,j,k,l}
    bspc node -f {west,south,north,east}

# ── Перемещение окон ──
super + shift + {h,j,k,l}
    bspc node -s {west,south,north,east}

# ── Переключение рабочих столов ──
super + {1-9,0}
    bspc desktop -f {1-9,10}

# ── Перемещение окна на рабочий стол ──
super + shift + {1-9,0}
    bspc node -d {1-9,10}

# ── Полноэкранный режим ──
super + f
    bspc node -t ~fullscreen

# ── Переключение между тайлингом и плавающим ──
super + space
    bspc node -t ~floating

# ── Предустановка направления разделения ──
super + ctrl + {h,j,k,l}
    bspc node -p {west,south,north,east}

# ── Отмена предустановки ──
super + ctrl + space
    bspc node -p cancel

# ── Изменение размера ──
super + alt + {h,j,k,l}
    bspc node -z {west -20 0,south 0 20,north 0 -20,east 20 0}

# ── Громкость ──
XF86AudioRaiseVolume
    amixer -q set Master 5%+ unmute
XF86AudioLowerVolume
    amixer -q set Master 5%- unmute
XF86AudioMute
    amixer -q set Master toggle

# ── Скриншот ──
Print
    scrot ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png
SXHKDEOF
chown "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$CFG/sxhkd/sxhkdrc"

# ─── 5. Rofi — тема Tokyo Night ───
echo ">>> [5/8] Настройка rofi..."
mkdir -p "$CFG/rofi/themes"
cat > "$CFG/rofi/themes/tokyonight.rasi" <<ROFIEOF
configuration {
    font: "JetBrains Mono Nerd Font 11";
    show-icons: true;
    icon-theme: "Papirus";
    location: center;
    width: 50%;
    lines: 12;
    columns: 1;
    padding: 18;
    scroll-method: 1;
    cycle: true;
    matching: "fuzzy";
    sort: true;
    fullscreen: false;
    transparency: "real";
}

* {
    bg:                  #1a1b26;
    bg-dark:             #16161e;
    bg-highlight:        #292e42;
    fg:                  #c0caf5;
    fg-dark:             #a9b1d6;
    blue:                #7aa2f7;
    cyan:                #7dcfff;
    magenta:             #bb9af7;
    green:               #9ece6a;
    orange:              #ff9e64;
    red:                 #f7768e;
    yellow:              #e0af68;
    gutter:              #3b4261;
    dark5:               #737aa2;

    background-color:    @bg;
    text-color:          @fg;
    border-color:        @gutter;

    spacing:             8px;
}

window {
    width:               50em;
    height:              32em;
    border:              2px;
    border-color:        @gutter;
    border-radius:       12px;
    padding:             16px;
    background-color:    @bg;
    transparency:        "real";
}

mainbox {
    children:            [ inputbar, listview ];
    spacing:             12px;
    padding:             8px;
}

inputbar {
    children:            [ prompt, entry ];
    spacing:             8px;
    padding:             12px 8px;
    border-radius:       8px;
    background-color:    @bg-dark;
    text-color:          @fg;
}

prompt {
    text-color:          @blue;
    font:                "JetBrains Mono Nerd Font 11";
}

entry {
    placeholder:         "Поиск...";
    placeholder-color:   @dark5;
    text-color:          @fg;
    font:                "JetBrains Mono Nerd Font 11";
}

listview {
    margin:              4px 0 0;
    padding:             6px 0;
    lines:               12;
    columns:             1;
    fixed-height:        false;
    border-radius:       8px;
    background-color:    transparent;
    scrollbar:           true;
}

scrollbar {
    width:               4px;
    border:              0;
    handle-color:        @gutter;
    handle-thickness:    4px;
}

element {
    padding:             8px 12px;
    border-radius:       6px;
    background-color:    transparent;
    text-color:          @fg;
    cursor:              pointer;
}

element-icon {
    size:                24px;
    margin:              0 8px 0 0;
}

element-text {
    vertical-align:      0.5;
    horizontal-align:    0.0;
}

element normal, element alternate {
    background-color:    transparent;
    text-color:          @fg;
}

element selected {
    background-color:    @bg-highlight;
    text-color:          @blue;
    border-radius:       6px;
}

element active {
    background-color:    @bg-highlight;
    text-color:          @green;
    border-radius:       6px;
}

element urgent {
    background-color:    @red;
    text-color:          @bg;
    border-radius:       6px;
}

mode-switcher {
    spacing:             0;
    border:              0;
}

message {
    padding:             8px 12px;
    border-radius:       8px;
    background-color:    @bg-dark;
}

textbox {
    text-color:          @orange;
    font:                "JetBrains Mono Nerd Font 10";
}
ROFIEOF

# Главный конфиг rofi — ссылается на тему
cat > "$CFG/rofi/config.rasi" <<'ROFI_MAIN'
@import "themes/tokyonight.rasi"
ROFI_MAIN
chown -R "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$CFG/rofi"

# ─── 6. Alacritty — терминал Tokyo Night ───
echo ">>> [6/8] Настройка alacritty..."
cat > "$CFG/alacritty/alacritty.toml" <<'ALACRITTYEOF'
[font]
size = 12

[font.normal]
family = "JetBrains Mono Nerd Font"
style = "Regular"

[font.bold]
family = "JetBrains Mono Nerd Font"
style = "Bold"

[window]
opacity = 0.92
padding = { x = 6, y = 6 }
decorations = "none"

[colors.primary]
background = "#1a1b26"
foreground = "#c0caf5"

[colors.normal]
black   = "#15161e"
red     = "#f7768e"
green   = "#9ece6a"
yellow  = "#e0af68"
blue    = "#7aa2f7"
magenta = "#bb9af7"
cyan    = "#7dcfff"
white   = "#a9b1d6"

[colors.bright]
black   = "#414868"
red     = "#f7768e"
green   = "#9ece6a"
yellow  = "#e0af68"
blue    = "#7aa2f7"
magenta = "#bb9af7"
cyan    = "#7dcfff"
white   = "#c0caf5"

[colors.cursor]
cursor = "#7aa2f7"
text   = "#1a1b26"

[colors.selection]
background = "#292e42"
text       = "#c0caf5"
ALACRITTYEOF
chown -R "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$CFG/alacritty"

# ─── 7. Polybar + picom + MC + обои ───
echo ">>> [7/8] Polybar, picom, MC, обои..."

# --- Polybar ---
cat > "$CFG/polybar/config.ini" <<'POLYBAR_EOF'
[colors]
bg          = #1a1b26
bg-dark     = #16161e
bg-hl       = #292e42
fg          = #c0caf5
fg-dark     = #a9b1d6
blue        = #7aa2f7
cyan        = #7dcfff
magenta     = #bb9af7
green       = #9ece6a
orange      = #ff9e64
red         = #f7768e
yellow      = #e0af68
gutter      = #3b4261
dark5       = #737aa2

[bar/main]
width               = 100%
height              = 28
radius              = 0
background          = ${colors.bg}
foreground          = ${colors.fg}
line-size           = 2
border-size         = 0
padding-left        = 0
padding-right       = 2
module-margin       = 1
font-0              = "JetBrains Mono Nerd Font:size=10;3"
modules-left        = bspwm
modules-center      = date
modules-right       = pulseaudio memory cpu network tray
tray-position       = right
tray-padding        = 4
tray-background     = ${colors.bg}
enable-ipc          = true

[module/bspwm]
type                = internal/bspwm
label-focused       = %index%
label-focused-background = ${colors.bg-hl}
label-focused-foreground   = ${colors.blue}
label-focused-padding     = 2
label-occupied      = %index%
label-occupied-foreground = ${colors.fg-dark}
label-occupied-padding    = 2
label-urgent        = %index%!
label-urgent-foreground   = ${colors.red}
label-urgent-padding      = 2
label-empty         = %index%
label-empty-foreground    = ${colors.dark5}
label-empty-padding       = 2
label-separator            = " "
label-separator-foreground = ${colors.gutter}

[module/date]
type                = internal/date
interval            = 1
date                = " %H:%M"
date-alt            = " %d.%m.%Y %H:%M"
label               = %date%
label-foreground    = ${colors.cyan}

[module/pulseaudio]
type                = internal/pulseaudio
format-volume       = <label-volume> <bar-volume>
label-volume        = " %percentage%%"
label-volume-foreground = ${colors.orange}
label-muted         = " muted"
label-muted-foreground = ${colors.red}
bar-volume-width    = 8
bar-volume-indicator    = ${colors.orange}
bar-volume-fill         = ${colors.orange}
bar-volume-empty        = ${colors.gutter}

[module/memory]
type                = internal/memory
interval            = 2
label               = " RAM %percentage_used%%"
label-foreground    = ${colors.magenta}

[module/cpu]
type                = internal/cpu
interval            = 2
label               = " CPU %percentage%%"
label-foreground    = ${colors.green}

[module/network]
type                = internal/network
interface           = auto
label-connected     = " NET"
label-connected-foreground   = ${colors.blue}
label-disconnected  = " OFF"
label-disconnected-foreground = ${colors.red}

[module/tray]
type                = internal/tray

[settings]
screenchange-reload = false

[global/wm]
margin-top    = 0
margin-bottom = 0
POLYBAR_EOF
chown -R "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$CFG/polybar"

# --- Picom ---
cat > "$CFG/picom/picom.conf" <<'PICOM_EOF'
backend = "glx";
vsync = true;

# Тени
shadow = true;
shadow-radius = 7;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.6;
shadow-exclude = [
    "name = 'Polybar'",
    "class_g = 'Rofi'",
];

# Прозрачность
inactive-opacity = 0.95;
active-opacity = 1.0;
frame-opacity = 1.0;
inactive-opacity-override = false;

# Размытие
blur: {
    method = "dual_kawase";
    strength = 5;
    background = false;
}
blur-background-exclude = [ "class_g = 'slop'" ];

# Скругление углов
corner-radius = 8;

# Исключения
fading = true;
fade-in-step = 0.07;
fade-out-step = 0.07;
PICOM_EOF
chown -R "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$CFG/picom"

# --- MC скин Tokyo Night ---
cat > "$HOME_DIR/.local/share/mc/skins/tokyonight.ini" <<'MC_SKIN_EOF'
[skin]
    description = Tokyo Night
[Colors]
    base_color=gray;default
    directory=blue
    executable=green
    link=magenta
    stalelink=brightred
    device=brightyellow
    special=brightcyan
    core=white;default
    error=red;default
    selected=brightcyan;blue
    selected_directory=brightwhite;blue
    selected_executable=brightgreen;blue
    selected_link=brightmagenta;blue
    selected_device=brightyellow;blue
    selected_special=brightcyan;blue
    marked=yellow;default
    marked_selected=brightwhite;blue
    input=brightwhite;default
    reverse=brightmagenta;default
    commandlinemark=yellow;default
    header=brightcyan;default
    dnormal=white;default
    dfocus=brightwhite;blue
    dhotnormal=brightcyan;default
    dhotfocus=brightcyan;blue
    menu=brightwhite;default
    menuhot=brightcyan;default
    menusel=brightwhite;blue
    menuhotsel=brightcyan;blue
    helpnormal=white;default
    helpbold=brightwhite;default
    helplink=brightcyan;default
    helpslink=brightwhite;blue
    gauge=brightwhite;blue
    inputhist=brightwhite;default
    commandhist=brightwhite;default
    cmdmark=brightwhite;blue
    disabled=gray;default
    editnormal=white;default
    editbold=brightwhite;default
    editmarked=brightwhite;blue
    errdhotnormal=brightred;default
    errdhotfocus=brightred;blue
MC_SKIN_EOF
chown -R "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$HOME_DIR/.local/share/mc/skins"

# --- Установка скина MC по умолчанию ---
SHELL_RC="$HOME_DIR/.bashrc"
grep -q 'MC_SKIN=tokyonight' "$SHELL_RC" 2>/dev/null || \
    echo 'export MC_SKIN=tokyonight' >> "$SHELL_RC"
chown "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$SHELL_RC"

# --- Генерация обоев Tokyo Night ---
cat > /tmp/gen_wallpaper.py <<'PYEOF'
import struct, zlib, math

W, H = 1920, 1080
pixels = []
for y in range(H):
    row = []
    for x in range(W):
        cx, cy = W//2, H//2
        dx, dy = x - cx, y - cy
        dist = math.sqrt(dx*dx + dy*dy)
        angle = math.atan2(dy, dx)
        t = dist / max(W, H) * 2.0
        r = int(26  + 30 * math.sin(t * 3.14 + 1.0))
        g = int(27  + 25 * math.sin(t * 2.7 + 2.0))
        b = int(38  + 50 * math.sin(t * 2.3 + 0.5))
        r = max(0, min(255, r))
        g = max(0, min(255, g))
        b = max(0, min(255, b))
        row.append((r, g, b))
    pixels.append(row)

raw = b''
for row in pixels:
    raw += b'\x00'
    for (r, g, b) in row:
        raw += struct.pack('BBB', r, g, b)

def chunk(ctype, data):
    c = ctype + data
    return (struct.pack('>I', len(data)) + c +
            struct.pack('>I', zlib.crc32(c) & 0xffffffff))

sig = b'\x89PNG\r\n\x1a\n'
ihdr = struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)
png = sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
with open('/tmp/tokyonight.png', 'wb') as f:
    f.write(png)
PYEOF
python3 /tmp/gen_wallpaper.py 2>/dev/null || true
cp /tmp/tokyonight.png "$HOME_DIR/.local/share/backgrounds/tokyonight.jpg" 2>/dev/null || true
chown -R "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$HOME_DIR/.local/share/backgrounds"

# ─── 8. LightDM + автологин + Xorg ───
echo ">>> [8/8] Настройка lightDM и автологина..."

# Xorg разрешаем любому пользователю
cat > /etc/X11/xorg.conf.d/00-server-flags.conf <<'XORGEOF'
Section "ServerFlags"
    Option "AllowMouseOpenFail" "true"
EndSection
XORGEOF

# Greeter lightdm
cat > /etc/lightdm/lightdm-gtk-greeter.conf <<'GREETEREOF'
[greeter]
theme-name = Adwaita-dark
icon-theme-name = Adwaita
font-name = JetBrains Mono Nerd Font 11
background = /usr/share/backgrounds/xfce/xfce-verticals.png
cursor-theme-name = Adwaita
GREETEREOF

# Сессия bspwm для lightdm
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/bspwm.desktop <<'SESSIONEOF'
[Desktop Entry]
Encoding=UTF-8
Name=bspwm
Comment=Binary Space Partitioning Window Manager (Tokyo Night)
Exec=bspwm
Type=Application
SESSIONEOF

# Автовход через lightdm
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if [[ -f "$LIGHTDM_CONF" ]]; then
    sed -i 's/^#\?autologin-user=.*/autologin-user='"$TARGET_USER"'/' "$LIGHTDM_CONF"
    sed -i 's/^#\?autologin-session=.*/autologin-session=bspwm/' "$LIGHTDM_CONF"
    sed -i 's/^#\?user-session=.*/user-session=bspwm/' "$LIGHTDM_CONF"
    # Гарантируем секции
    grep -q '
$$
Seat:\*
$$
' "$LIGHTDM_CONF" || echo -e '\n[Seat:*]\nautologin-user='"$TARGET_USER"'\nautologin-session=bspwm' >> "$LIGHTDM_CONF"
else
    cat > "$LIGHTDM_CONF" <<'LIGHTDM_DEFAULT'
[LightDM]
run-directory=/run/lightdm

[Seat:*]
autologin-user=PLACEHOLDER
autologin-session=bspwm
user-session=bspwm
LIGHTDM_DEFAULT
    sed -i "s/PLACEHOLDER/$TARGET_USER/" "$LIGHTDM_CONF"
fi

# Группа autologin
groupadd -f autologin
usermod -aG autologin "$TARGET_USER"

# xinitrc как fallback
cat > "$HOME_DIR/.xinitrc" <<'XINITRC'
#!/bin/sh
exec bspwm
XINITRC
chmod +x "$HOME_DIR/.xinitrc"
chown "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$HOME_DIR/.xinitrc"

# Включаем и запускаем lightdm
systemctl enable lightdm
systemctl set-default graphical.target

# ─── Финал ───
echo ""
echo "═══════════════════════════════════════════"
echo "  Установка завершена!  "
echo "═══════════════════════════════════════════"
echo ""
echo "Установлено:"
echo "  • bspwm + sxhkd — оконный менеджер"
echo "  • rofi — запуск приложений (тема Tokyo Night)"
echo "  • mc — файловый менеджер (скин tokyonight)"
echo "  • alacritty — терминал (палитра Tokyo Night)"
echo "  • polybar — панель задач (тема Tokyo Night)"
echo "  • picom — композитор (тени, скругление, размытие)"
echo "  • lightdm — менеджер входа с автологином"
echo ""
echo "Горячие клавиши:"
echo "  super+Enter     — терминал"
echo "  super+d         — rofi (запуск приложений)"
echo "  super+shift+d   — rofi (запуск команд)"
echo "  super+e         — Midnight Commander"
echo "  super+q         — закрыть окно"
echo "  super+f         — фуллскрин"
echo "  super+space     — плавающий/тайлинг"
echo "  super+1-0       — рабочий стол"
echo "  super+shift+r   — перезагрузка конфигов"
echo ""
echo "Перезагрузите систему, чтобы войти в bspwm:"
echo "  sudo reboot"
echo ""
