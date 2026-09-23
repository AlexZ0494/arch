# Обновление системы и установка базовых зависимостей для AUR
sudo pacman -Syu --noconfirm git base-devel alacritty

# Установка yay (AUR helper)
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~

# Установка основных компонентов окружения (bspwm, sxhkd, polybar, rofi, mc, picom, feh)
yay -S --noconfirm bspwm sxhkd polybar rofi mc picom feh nitrogen xorg-xsetroot

# Установка тем и иконок Tokyo Night
yay -S --noconfirm tokyonight-gtk-theme-git tela-icon-theme-git

# Установка Nerd Font (JetBrains Mono)
yay -S --noconfirm ttf-jetbrains-mono-nerd

# Создание директорий конфигов
mkdir -p ~/.config/{bspwm,sxhkd,polybar,rofi}

# Настройка bspwmrc
cat > ~/.config/bspwm/bspwmrc << 'EOF'
bspc config border_width         3
bspc config window_gap           10
bspc config split_ratio          0.50
bspc config borderless_monocle   true
bspc config focus_by_distance     true
bspc config history_aware_focus   true

bspc rule -a Polybar state=floating sticky=on
bspc rule -a Rofi state=floating

bspc config normal_border_color "#1a1b26"
bspc config active_border_color  "#7aa2f7"
bspc config focused_border_color "#7aa2f7"
bspc config presel_border_color  "#bb9af7"
EOF

# Настройка sxhkdrc
cat > ~/.config/sxhkd/sxhkdrc << 'EOF'
super + Return
	alacritty

super + w
	firefox

super + Escape
	rofi -show run

super + {_,shift + }{h,j,k,l}
	bspc node -{f,s} {west,south,north,east}

super + {1-9}
	bspc desktop -f {^1}

super + {_,shift + }{Tab,grave}
	bspc node -{f,s} {big,monocle}

super + q
	bspc node -c
EOF

# Настройка polybar (часы по центру, трей слева, рабочие столы и поиск справа)
cat > ~/.config/polybar/config << 'EOF'
[bar/default]
monitor = \${env:MONITOR:}
width = 100%
height = 32
offset-x = 0
offset-y = 0
bottom = false
fixed-center = true

background = #1a1b2600
foreground = #c0caf5

border-size = 2px
border-color = #7aa2f750
border-radius = 12px

padding-left = 12
padding-right = 12
module-margin-left = 8
module-margin-right = 8

font-0 = JetBrainsMono Nerd Font:size=12;3

modules-left = tray volume wifi xkeyboard
modules-center = date
modules-right = bspwm-workspaces search shutdown-menu

[module/date]
type = internal/date
date = "%H:%M"
format-prefix = " "
format-foreground = #7aa2f7

[module/tray]
type = internal/tray
tray-position = left
tray-padding = 8
tray-max-size = 24px

[module/volume]
type = internal/pulseaudio
format = <ramp> <label>
label = %percentage%%
format-foreground = #9ece6a
ramp-size = 14
ramp-characters = 

[module/wifi]
type = internal/network
interface = wlp*
format-connected = <label-connected>
format-disconnected = <label-disconnected>
label-connected = 
label-disconnected = 
format-connected-foreground = #cba6f7
format-disconnected-foreground = #565f89

[module/xkeyboard]
type = internal/xkeyboard
format = <label>
label = %name%
format-foreground = #f7768e

[module/bspwm-workspaces]
type = internal/bspwm
format = <label>
label-active = %name%
label-occupied = %name%
label-empty = %name%
format-active-foreground = #1a1b26
format-active-background = #7aa2f7
format-occupied-foreground = #c0caf5
format-empty-foreground = #565f89
max-workspaces = 10

[module/search]
type = custom/script
exec = rofi -show run -theme ~/.config/rofi/config.rasi
interval = 1
format = <label>
label =  Search
format-foreground = #7aa2f7
click-left = exec

[module/shutdown-menu]
type = custom/menu
format = <label>
label = 
format-foreground = #f7768e
menu-0 = Power
menu-0-0 = Shutdown
menu-0-0-exec = systemctl poweroff
menu-0-1 = Sleep
menu-0-1-exec = systemctl suspend
menu-0-2 = Logout
menu-0-2-exec = bspc quit
EOF

# Настройка rofi
cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    font: "JetBrainsMono Nerd Font 12";
    show-icons: true;
}

* {
    background-color: #1a1b26;
    text-color: #c0caf5;
}

window {
    background-color: #1a1b26;
    border: 1px;
    border-color: #7aa2f7;
    radius: 8px;
    padding: 10px;
}

inputbar {
    padding: 10px;
    background-color: #16161e;
}

listview {
    lines: 10;
    columns: 1;
    padding: 10px;
}

element {
    padding: 10px;
    background-color: transparent;
    text-color: #c0caf5;
}

element selected {
    background-color: #7aa2f7;
    text-color: #1a1b26;
    border-radius: 6px;
}

element-text, inputbar-text {
    text-color: #c0caf5;
}
EOF

# Настройка mc (цветовая схема Tokyo Night)
mkdir -p ~/.local/share/mc/skins
cat > ~/.local/share/mc/skins/tokyonight.ini << 'EOF'
[skin]
name=TokyoNight

[color]
default=lightgray,black
selected=black,lightcyan
marked=yellow,black
markselect=yellow,lightcyan
reverse=black,lightgray
disabled=gray,black
directory=lightcyan,black
executable=lightgreen,black
link=cyan,black
device=magenta,black
special=white,black
errormsg=red,black
info=white,black
header=white,blue
dnormal=lightgray,black
dsel=black,lightcyan
dmarked=yellow,black
dmsel=yellow,lightcyan
menu=white,blue
menusel=black,lightcyan
menumark=yellow,blue
menumarksel=yellow,lightcyan
button=white,blue
buttonsel=black,lightcyan
dialog=white,blue
dialogsel=black,lightcyan
error=white,red
errsel=black,lightred
helpnormal=white,blue
helpsel=black,lightcyan
EOF

# Настройка автозапуска сервисов (добавить в .xinitrc)
cat >> ~/.xinitrc << 'EOF'
picom --config /dev/null &
nitrogen --restore &
bspwm &
sxhkd &
polybar main &
EOF

# Применение GTK тем
gsettings set org.gnome.desktop.interface gtk-theme "TokyoNight-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Tela-blue-dark"
gsettings set org.gnome.desktop.interface cursor-theme "Tela-blue-cursors"
EOF
