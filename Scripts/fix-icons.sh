#!/usr/bin/env bash
set -u

SUDO=""
[ "$EUID" -ne 0 ] && SUDO="sudo"

ICON_DIRS=(
  /usr/share/icons
  /usr/share/pixmaps
  "$HOME/.local/share/icons"
  "$HOME/.icons"
  /var/lib/flatpak/exports/share/icons
  "$HOME/.local/share/flatpak/exports/share/icons"
  /var/lib/snapd/desktop/icons
)
APP_DIRS=(
  /usr/share/applications
  /usr/local/share/applications
  "$HOME/.local/share/applications"
  /var/lib/flatpak/exports/share/applications
  "$HOME/.local/share/flatpak/exports/share/applications"
  /var/lib/snapd/desktop/applications
)
APPIMAGE_DIRS=(
  "$HOME/Applications"
  "$HOME/Downloads"
  "$HOME/Transferências"
  "$HOME/.local/bin"
  "$HOME/Desktop"
  "$HOME/Área de trabalho"
)
USER_APPS="$HOME/.local/share/applications"
USER_ICONS="$HOME/.local/share/icons"
FALLBACK="application-x-executable"
INDEX=""
FIXED=0

install_pkgs() {
  local pkgs=()
  if command -v apt-get >/dev/null; then
    pkgs=(hicolor-icon-theme adwaita-icon-theme gnome-icon-theme humanity-icon-theme papirus-icon-theme librsvg2-common librsvg2-2 gdk-pixbuf2.0-bin libgdk-pixbuf2.0-bin desktop-file-utils gtk-update-icon-cache libgtk-3-bin)
    $SUDO apt-get update -qq >/dev/null 2>&1
    for p in "${pkgs[@]}"; do $SUDO apt-get install -y -qq "$p" >/dev/null 2>&1; done
  elif command -v dnf >/dev/null; then
    pkgs=(hicolor-icon-theme adwaita-icon-theme papirus-icon-theme librsvg2 gdk-pixbuf2 desktop-file-utils gtk-update-icon-cache gtk3)
    for p in "${pkgs[@]}"; do $SUDO dnf install -y -q "$p" >/dev/null 2>&1; done
  elif command -v pacman >/dev/null; then
    pkgs=(hicolor-icon-theme adwaita-icon-theme papirus-icon-theme librsvg gdk-pixbuf2 desktop-file-utils gtk3)
    for p in "${pkgs[@]}"; do $SUDO pacman -S --needed --noconfirm "$p" >/dev/null 2>&1; done
  elif command -v zypper >/dev/null; then
    pkgs=(hicolor-icon-theme adwaita-icon-theme papirus-icon-theme librsvg gdk-pixbuf-query-loaders desktop-file-utils gtk3-tools)
    for p in "${pkgs[@]}"; do $SUDO zypper -n install "$p" >/dev/null 2>&1; done
  fi
}

build_index() {
  INDEX=$(mktemp)
  for d in "${ICON_DIRS[@]}"; do
    [ -d "$d" ] && find -L "$d" -type f \( -name '*.png' -o -name '*.svg' -o -name '*.svgz' -o -name '*.xpm' \) -printf '%f\n' 2>/dev/null
  done | sed -E 's/\.(png|svg|svgz|xpm)$//' | sort -u > "$INDEX"
}

has_icon() {
  local name="$1"
  [[ "$name" = /* ]] && [ -f "$name" ] && return 0
  name=$(sed -E 's/\.(png|svg|svgz|xpm)$//' <<<"$name")
  grep -Fxq -- "$name" "$INDEX"
}

guess_icon() {
  local f="$1" c m base exec_bin wm nm
  base=$(basename "$f" .desktop)
  exec_bin=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | awk '{print $1}' | sed 's|.*/||')
  wm=$(grep -m1 '^StartupWMClass=' "$f" | cut -d= -f2-)
  nm=$(grep -m1 '^Name=' "$f" | cut -d= -f2- | tr 'A-Z ' 'a-z-')
  for c in "$base" "${base##*.}" "$wm" "$exec_bin" "$nm"; do
    [ -z "$c" ] && continue
    m=$(grep -Fxi -m1 -- "$c" "$INDEX")
    [ -n "$m" ] && { echo "$m"; return; }
  done
}

fix_desktop() {
  local f="$1" icon guess target
  grep -q '^NoDisplay=true' "$f" && return
  icon=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)
  [ -n "$icon" ] && has_icon "$icon" && return
  guess=$(guess_icon "$f")
  [ -z "$guess" ] && guess="$FALLBACK"
  target="$USER_APPS/$(basename "$f")"
  [ "$f" != "$target" ] && cp "$f" "$target"
  if grep -q '^Icon=' "$target"; then
    sed -i "s|^Icon=.*|Icon=$guess|" "$target"
  else
    sed -i "0,/^\[Desktop Entry\]/s//[Desktop Entry]\nIcon=$guess/" "$target"
  fi
  FIXED=$((FIXED + 1))
  echo "corrigido: $(basename "$f") -> $guess"
}

fix_all_desktops() {
  local d f
  for d in "${APP_DIRS[@]}"; do
    [ -d "$d" ] || continue
    while IFS= read -r -d '' f; do
      fix_desktop "$f"
    done < <(find -L "$d" -maxdepth 1 -name '*.desktop' -print0)
  done
}

integrate_appimages() {
  local tmp d img id src df iname icon_src ext name
  tmp=$(mktemp -d)
  mkdir -p "$USER_ICONS"
  for d in "${APPIMAGE_DIRS[@]}"; do
    [ -d "$d" ] || continue
    while IFS= read -r -d '' img; do
      id=$(basename "$img" | sed -E 's/\.[Aa]pp[Ii]mage$//' | tr ' ' '-' | tr 'A-Z' 'a-z')
      [ -f "$USER_APPS/appimage-$id.desktop" ] && continue
      chmod +x "$img"
      rm -rf "$tmp/squashfs-root"
      ( cd "$tmp" && "$img" --appimage-extract >/dev/null 2>&1 )
      src="$tmp/squashfs-root"
      [ -d "$src" ] || continue
      df=$(find "$src" -maxdepth 2 -name '*.desktop' | head -n1)
      name=$(grep -m1 '^Name=' "$df" 2>/dev/null | cut -d= -f2-)
      [ -z "$name" ] && name="$id"
      iname=$(grep -m1 '^Icon=' "$df" 2>/dev/null | cut -d= -f2-)
      icon_src=""
      if [ -n "$iname" ]; then
        icon_src=$(find "$src" -maxdepth 1 \( -name "$iname.png" -o -name "$iname.svg" \) | head -n1)
        [ -z "$icon_src" ] && icon_src=$(find "$src/usr/share/icons" -type f \( -name "$iname.png" -o -name "$iname.svg" \) 2>/dev/null | sort -V | tail -n1)
      fi
      [ -z "$icon_src" ] && [ -e "$src/.DirIcon" ] && icon_src=$(readlink -f "$src/.DirIcon")
      icon="$FALLBACK"
      if [ -n "$icon_src" ] && [ -f "$icon_src" ]; then
        ext="${icon_src##*.}"
        [[ "$ext" =~ ^(png|svg)$ ]] || ext="png"
        cp "$icon_src" "$USER_ICONS/appimage-$id.$ext"
        icon="$USER_ICONS/appimage-$id.$ext"
      fi
      cat > "$USER_APPS/appimage-$id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Exec="$img" %U
Icon=$icon
Terminal=false
Categories=Utility;
EOF
      FIXED=$((FIXED + 1))
      echo "appimage integrado: $name"
    done < <(find "$d" -maxdepth 2 -iname '*.appimage' -print0)
  done
  rm -rf "$tmp"
}

update_caches() {
  local t
  for t in /usr/share/icons/*; do
    [ -f "$t/index.theme" ] && $SUDO gtk-update-icon-cache -f -q "$t" >/dev/null 2>&1
  done
  for t in "$USER_ICONS"/* "$HOME/.icons"/*; do
    [ -d "$t" ] && gtk-update-icon-cache -f -q --ignore-theme-index "$t" >/dev/null 2>&1
  done
  command -v update-icon-caches >/dev/null && $SUDO update-icon-caches /usr/share/icons/* >/dev/null 2>&1
  command -v update-desktop-database >/dev/null && {
    $SUDO update-desktop-database /usr/share/applications >/dev/null 2>&1
    update-desktop-database "$USER_APPS" >/dev/null 2>&1
  }
  rm -f "$HOME"/.cache/icon-cache.kcache
  command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1
  command -v kbuildsycoca5 >/dev/null && kbuildsycoca5 >/dev/null 2>&1
}

slug() {
  tr 'A-Z' 'a-z' <<<"$1" | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

install_icon() {
  local src="$1" name="$2" ext
  [ -f "$src" ] || return 1
  ext="${src##*.}"
  case "$ext" in png|svg|svgz|xpm) ;; *) ext="png" ;; esac
  mkdir -p "$USER_ICONS/custom"
  cp "$src" "$USER_ICONS/custom/$name.$ext"
  echo "$USER_ICONS/custom/$name.$ext"
}

write_desktop() {
  local file="$1" name="$2" exec_line="$3" icon="$4" wmclass="$5" hidden="${6:-0}"
  {
    echo "[Desktop Entry]"
    echo "Type=Application"
    echo "Name=$name"
    echo "Exec=$exec_line"
    echo "Icon=$icon"
    echo "Terminal=false"
    [ -n "$wmclass" ] && echo "StartupWMClass=$wmclass"
    [ "$hidden" = 1 ] && echo "NoDisplay=true"
  } > "$USER_APPS/$file"
  FIXED=$((FIXED + 1))
  echo "criado: $file"
}

asset_hash() {
  python3 - "$1" <<'PY' 2>/dev/null
import json, sys
objs = json.load(open(sys.argv[1])).get("objects", {})
for k in ("icons/icon_256x256.png", "minecraft/icons/icon_256x256.png", "icons/icon_128x128.png", "icons/icon_32x32.png"):
    if k in objs:
        print(objs[k]["hash"])
        break
PY
}

minecraft_icon() {
  local idx h
  for idx in "$HOME"/.minecraft/assets/indexes/*.json; do
    [ -f "$idx" ] || continue
    h=$(asset_hash "$idx")
    if [ -n "$h" ] && [ -f "$HOME/.minecraft/assets/objects/${h:0:2}/$h" ]; then
      echo "$HOME/.minecraft/assets/objects/${h:0:2}/$h"
      return
    fi
  done
  find "$HOME/.minecraft" -iname 'icon_*.png' 2>/dev/null | head -n1
}

jar_icon() {
  local jar="$1" entry tmp
  command -v unzip >/dev/null || return
  entry=$(unzip -Z1 "$jar" 2>/dev/null | grep -iE '(icon|logo)[^/]*\.png$' | head -n1)
  [ -z "$entry" ] && return
  tmp=$(mktemp -d)
  unzip -qo "$jar" "$entry" -d "$tmp" 2>/dev/null
  echo "$tmp/$entry"
}

setup_tlauncher() {
  local jar mc_icon icon launcher_icon launcher v n
  jar=$(find "$HOME" /opt -maxdepth 5 -iname 'TLauncher*.jar' 2>/dev/null | head -n1)
  if [ -z "$jar" ]; then
    echo "TLauncher.jar não encontrado"
    return
  fi
  launcher="java -jar \"$jar\""
  mc_icon=$(minecraft_icon)
  icon="$FALLBACK"
  [ -n "$mc_icon" ] && icon=$(install_icon "$mc_icon" minecraft)
  launcher_icon=$(jar_icon "$jar")
  if [ -n "$launcher_icon" ]; then
    launcher_icon=$(install_icon "$launcher_icon" tlauncher)
  else
    launcher_icon="$icon"
  fi
  write_desktop tlauncher.desktop "TLauncher" "$launcher" "$launcher_icon" "" 0
  [ -d "$HOME/.minecraft/versions" ] || return
  while read -r v; do
    [ -z "$v" ] && continue
    write_desktop "minecraft-$(slug "$v").desktop" "Minecraft $v" "$launcher" "$icon" "Minecraft* $v" 1
  done < <(
    for d in "$HOME"/.minecraft/versions/*/; do
      [ -d "$d" ] || continue
      v=$(basename "$d")
      echo "$v"
      n=$(grep -oE '^[0-9]+\.[0-9]+(\.[0-9]+)?' <<<"$v")
      [ -n "$n" ] && echo "$n"
    done | sort -u
  )
}

setup_eclipse() {
  local bin dir icon
  bin=$(find "$HOME" /opt /usr/lib -maxdepth 4 -type f -name eclipse -perm -u+x 2>/dev/null | head -n1)
  if [ -z "$bin" ]; then
    echo "Eclipse não encontrado"
    return
  fi
  dir=$(dirname "$bin")
  icon=$(find "$dir/plugins" -maxdepth 3 -iname 'eclipse*.png' 2>/dev/null | sort -V | tail -n1)
  [ -z "$icon" ] && icon=$(find "$dir" -maxdepth 1 -name 'icon.xpm' | head -n1)
  if [ -n "$icon" ]; then
    icon=$(install_icon "$icon" eclipse)
  else
    icon="$FALLBACK"
  fi
  write_desktop eclipse.desktop "Eclipse IDE" "\"$bin\"" "$icon" "Eclipse" 0
}

setup_unity() {
  local ed icon
  ed=$(find "$HOME/Unity/Hub/Editor" -maxdepth 3 -type f -name Unity -perm -u+x 2>/dev/null | sort -V | tail -n1)
  [ -z "$ed" ] && ed=$(find "$HOME" /opt -maxdepth 6 -type f -name Unity -perm -u+x 2>/dev/null | sort -V | tail -n1)
  if [ -z "$ed" ]; then
    echo "Unity Editor não encontrado"
    return
  fi
  icon=$(find "$(dirname "$ed")/Data" -maxdepth 3 -iname '*unity*.png' 2>/dev/null | sort -V | tail -n1)
  if [ -n "$icon" ]; then
    icon=$(install_icon "$icon" unity-editor)
  elif has_icon unityhub; then
    icon="unityhub"
  else
    icon="$FALLBACK"
  fi
  write_desktop unity-editor.desktop "Unity Editor" "\"$ed\"" "$icon" "Unity" 0
}

exec_from_pid() {
  local a out=""
  while IFS= read -r -d '' a; do
    a=${a//\"/\\\"}
    a=${a//%/%%}
    out+="\"$a\" "
  done < "/proc/$1/cmdline"
  echo "${out% }"
}

fix_windows() {
  if ! command -v xprop >/dev/null; then
    echo "xprop não encontrado (instale x11-utils)"
    return
  fi
  local known ids id cls pid cmd sl m c exe icon d skip
  known=$(mktemp)
  grep -rh '^StartupWMClass=' "${APP_DIRS[@]}" 2>/dev/null | cut -d= -f2- | sort -u > "$known"
  ids=$(xprop -root _NET_CLIENT_LIST 2>/dev/null | grep -o '0x[0-9a-fA-F]*')
  for id in $ids; do
    cls=$(xprop -id "$id" WM_CLASS 2>/dev/null | sed -E 's/.*= *"[^"]*", *"(.*)"/\1/')
    [ -z "$cls" ] && continue
    grep -Fxiq -- "$cls" "$known" && continue
    skip=0
    for d in "${APP_DIRS[@]}"; do
      [ -f "$d/$cls.desktop" ] || [ -f "$d/${cls,,}.desktop" ] && skip=1
    done
    [ "$skip" = 1 ] && continue
    pid=$(xprop -id "$id" _NET_WM_PID 2>/dev/null | awk '{print $3}')
    [ -r "/proc/${pid:-0}/cmdline" ] || continue
    cmd=$(exec_from_pid "$pid")
    [ -z "$cmd" ] && continue
    sl=$(slug "$cls")
    exe=$(basename "$(tr '\0' '\n' < "/proc/$pid/cmdline" | head -n1)")
    icon=""
    for c in "$cls" "$sl" "${cls,,}" "$exe"; do
      m=$(grep -Fxi -m1 -- "$c" "$INDEX")
      [ -n "$m" ] && { icon="$m"; break; }
    done
    [ -z "$icon" ] && icon="$FALLBACK"
    write_desktop "janela-$sl.desktop" "$cls" "$cmd" "$icon" "$cls" 0
    echo "$cls" >> "$known"
  done
  rm -f "$known"
}

main() {
  local arg with_appimages=0 with_windows=0
  for arg in "$@"; do
    [ "$arg" = "--appimages" ] && with_appimages=1
    [ "$arg" = "--janelas" ] && with_windows=1
  done
  mkdir -p "$USER_APPS" "$USER_ICONS"
  install_pkgs
  update_caches
  build_index
  fix_all_desktops
  setup_tlauncher
  setup_eclipse
  setup_unity
  [ "$with_windows" -eq 1 ] && fix_windows
  [ "$with_appimages" -eq 1 ] && integrate_appimages
  update_caches
  rm -f "$INDEX"
  echo "total corrigido: $FIXED"
  echo "faça logout/login para o shell recarregar os ícones"
}

[ "${BASH_SOURCE[0]}" = "$0" ] && main "$@"
