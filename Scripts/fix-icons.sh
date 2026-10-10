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

main() {
  local with_appimages=0
  [ "${1:-}" = "--appimages" ] && with_appimages=1
  mkdir -p "$USER_APPS" "$USER_ICONS"
  install_pkgs
  update_caches
  build_index
  fix_all_desktops
  [ "$with_appimages" -eq 1 ] && integrate_appimages
  update_caches
  rm -f "$INDEX"
  echo "total corrigido: $FIXED"
  echo "faça logout/login para o shell recarregar os ícones"
}

main "$@"
