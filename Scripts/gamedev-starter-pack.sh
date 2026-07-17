#!/usr/bin/env bash
# ============================================================
#  GAME DEV STARTER PACK
#  Unity Hub | Antigravity IDE | Rider | Git | GitHub Desktop Plus
# ============================================================

set -uo pipefail

LOG_FILE="/tmp/gamedev-starter-pack.log"
: > "$LOG_FILE"

# ---------- cores ----------
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_CYAN="\033[36m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_BLUE="\033[34m"

TOTAL_STEPS=11
CURRENT_STEP=0

# ---------- utilidades visuais (somente ASCII) ----------
term_width() { tput cols 2>/dev/null || echo 60; }

hr() {
  local w; w=$(term_width)
  printf "${C_DIM}%${w}s${C_RESET}\n" | tr ' ' '-'
}

banner() {
  clear
  local w; w=$(term_width)
  local title="GAME DEV STARTER PACK"
  local pad=$(( (w - ${#title} - 2) / 2 ))
  (( pad < 0 )) && pad=0
  echo -e "${C_CYAN}${C_BOLD}"
  hr
  printf "%${pad}s %s\n" "" "$title"
  hr
  echo -e "${C_RESET}${C_DIM}Unity Hub | Antigravity IDE | Rider | Git | GitHub Desktop Plus${C_RESET}\n"
}

progress_bar() {
  local step="$1" total="$2" label="$3"
  local w; w=$(term_width)
  local bar_width=$(( w > 50 ? 34 : 20 ))
  local filled=$(( step * bar_width / total ))
  local empty=$(( bar_width - filled ))
  local pct=$(( step * 100 / total ))

  local bar="["
  bar+=$(printf "%${filled}s" | tr ' ' '#')
  bar+=$(printf "%${empty}s" | tr ' ' '-')
  bar+="]"

  printf "\r${C_CYAN}%s${C_RESET} ${C_BOLD}%3d%%${C_RESET}  ${C_YELLOW}%-2d/%-2d${C_RESET}  %s" \
    "$bar" "$pct" "$step" "$total" "$label"
}

step_start() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  progress_bar "$CURRENT_STEP" "$TOTAL_STEPS" "$1"
}

step_done() {
  local label="$1"
  printf "\r\033[K${C_GREEN}[OK]${C_RESET} [%d/%d] %s\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$label"
}

step_skip() {
  local label="$1"
  printf "\r\033[K${C_BLUE}[--]${C_RESET} [%d/%d] %s ${C_DIM}(ja instalado)${C_RESET}\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$label"
}

step_fail() {
  local label="$1"
  printf "\r\033[K${C_RED}[XX]${C_RESET} [%d/%d] %s ${C_DIM}(falhou - veja %s)${C_RESET}\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$label" "$LOG_FILE"
}

run_quiet() {
  # roda um comando redirecionando saida pro log, mantendo o terminal limpo
  eval "$1" >>"$LOG_FILE" 2>&1
}

# ---------- checagens ----------
need_root_prefix() {
  if [[ $EUID -ne 0 ]]; then echo "sudo"; else echo ""; fi
}
SUDO=$(need_root_prefix)

cmd_exists() { command -v "$1" >/dev/null 2>&1; }
apt_pkg_installed() { dpkg -s "$1" >/dev/null 2>&1; }
snap_installed() { snap list 2>/dev/null | grep -q "^$1 "; }

# ============================================================
banner

# ---------- 1. Dependencias base ----------
step_start "Verificando dependencias do sistema"
DEPS=(curl wget gpg ca-certificates apt-transport-https software-properties-common desktop-file-utils)
MISSING_DEPS=()
for d in "${DEPS[@]}"; do
  apt_pkg_installed "$d" || MISSING_DEPS+=("$d")
done

if [[ ${#MISSING_DEPS[@]} -eq 0 ]]; then
  step_done "Dependencias do sistema"
else
  run_quiet "$SUDO apt-get update -y"
  if run_quiet "$SUDO apt-get install -y ${MISSING_DEPS[*]}"; then
    step_done "Dependencias instaladas: ${MISSING_DEPS[*]}"
  else
    step_fail "Dependencias do sistema"
    exit 1
  fi
fi

# ---------- 2. snapd ----------
step_start "Verificando snapd"
if apt_pkg_installed snapd; then
  step_skip "snapd"
else
  if run_quiet "$SUDO apt-get install -y snapd"; then
    step_done "snapd instalado"
  else
    step_fail "snapd"
    exit 1
  fi
fi

# ---------- 3. Git ----------
step_start "Instalando Git"
if cmd_exists git; then
  step_skip "Git ($(git --version | awk '{print $3}'))"
else
  if run_quiet "$SUDO apt-get install -y git"; then
    step_done "Git instalado"
  else
    step_fail "Git"
  fi
fi

# ---------- 4. Unity Hub ----------
step_start "Configurando repositorio Unity Hub"
UNITY_KEYRING="/etc/apt/keyrings/unityhub.gpg"
UNITY_LIST="/etc/apt/sources.list.d/unityhub.list"
if [[ ! -f "$UNITY_LIST" ]]; then
  run_quiet "$SUDO install -d /etc/apt/keyrings"
  run_quiet "curl -fsSL https://hub.unity3d.com/linux/keys/public | $SUDO gpg --dearmor -o $UNITY_KEYRING"
  run_quiet "echo 'deb [arch=amd64 signed-by=$UNITY_KEYRING] https://hub.unity3d.com/linux/repos/deb stable main' | $SUDO tee $UNITY_LIST"
fi
step_start "Instalando Unity Hub"
if cmd_exists unityhub; then
  step_skip "Unity Hub"
else
  run_quiet "$SUDO apt-get update -y"
  if run_quiet "$SUDO apt-get install -y unityhub"; then
    step_done "Unity Hub instalado"
  else
    step_fail "Unity Hub"
  fi
fi

# ---------- 5. Compatibilidade Unity Editor (libxml2 legado) ----------
# O Unity Editor (varias versoes 6000.x) e linkado contra a ABI antiga
# libxml2.so.2, que nao existe mais em distros recentes (Ubuntu 25.04+,
# Debian 13+, Fedora recentes) que ja migraram para libxml2.so.16.
# Sem isso o Editor morre silenciosamente ao abrir um projeto, sem
# nenhum erro visivel no Hub.
step_start "Aplicando compatibilidade libxml2 para o Unity Editor"
LIBXML2_OLD="/usr/lib/x86_64-linux-gnu/libxml2.so.2"
LIBXML2_NEW=""
for candidate in \
  /usr/lib/x86_64-linux-gnu/libxml2.so.16 \
  /usr/lib/x86_64-linux-gnu/libxml2.so \
  /usr/lib64/libxml2.so.16 \
  /usr/lib64/libxml2.so \
  /lib/x86_64-linux-gnu/libxml2.so.16 \
  /usr/lib/libxml2.so.16
do
  [[ -f "$candidate" ]] && LIBXML2_NEW="$candidate" && break
done

if [[ -e "$LIBXML2_OLD" ]]; then
  step_skip "Compatibilidade libxml2"
elif [[ -n "$LIBXML2_NEW" ]]; then
  if run_quiet "$SUDO ln -sf $LIBXML2_NEW $LIBXML2_OLD && $SUDO ldconfig"; then
    step_done "Symlink libxml2.so.2 -> $(basename "$LIBXML2_NEW") criado"
  else
    step_fail "Compatibilidade libxml2"
  fi
else
  step_fail "Compatibilidade libxml2 (libxml2 nao encontrada no sistema)"
fi

# ---------- 6. Antigravity IDE ----------
step_start "Configurando repositorio Antigravity"
AG_KEYRING="/usr/share/keyrings/google-antigravity.gpg"
AG_SOURCES="/etc/apt/sources.list.d/google-antigravity.sources"
if [[ ! -f "$AG_SOURCES" ]]; then
  run_quiet "curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | $SUDO gpg --dearmor -o $AG_KEYRING"
  run_quiet "printf 'Types: deb\nURIs: https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/\nSuites: antigravity-debian\nComponents: main\nSigned-By: $AG_KEYRING\n' | $SUDO tee $AG_SOURCES"
fi
step_start "Instalando Antigravity IDE"
if cmd_exists antigravity; then
  step_skip "Antigravity IDE"
else
  run_quiet "$SUDO apt-get update -y"
  if run_quiet "$SUDO apt-get install -y antigravity"; then
    step_done "Antigravity IDE instalado"
  else
    step_fail "Antigravity IDE"
  fi
fi

# ---------- 7. JetBrains Rider ----------
step_start "Instalando Rider (snap)"
run_quiet "$SUDO systemctl enable --now snapd.socket"
if snap_installed rider; then
  step_skip "Rider"
else
  if run_quiet "$SUDO snap install rider --classic"; then
    step_done "Rider instalado"
  else
    step_fail "Rider"
  fi
fi

# ---------- 8. GitHub Desktop Plus ----------
step_start "Configurando repositorio GitHub Desktop Plus"
GHDP_KEYRING="/usr/share/keyrings/polrivero.gpg"
GHDP_LIST="/etc/apt/sources.list.d/github-desktop-plus.list"
if [[ ! -f "$GHDP_LIST" ]]; then
  run_quiet "curl -fsSL https://gpg.polrivero.com/public.key | $SUDO gpg --dearmor -o $GHDP_KEYRING"
  run_quiet "echo 'deb [arch=amd64,arm64 signed-by=$GHDP_KEYRING] https://deb.github-desktop.polrivero.com/ stable main' | $SUDO tee $GHDP_LIST"
fi
step_start "Instalando GitHub Desktop Plus"
if apt_pkg_installed github-desktop-plus; then
  step_skip "GitHub Desktop Plus"
else
  run_quiet "$SUDO apt-get update -y"
  if run_quiet "$SUDO apt-get install -y github-desktop-plus"; then
    step_done "GitHub Desktop Plus instalado"
  else
    step_fail "GitHub Desktop Plus"
  fi
fi

# ============================================================
echo
hr
echo -e "${C_GREEN}${C_BOLD} Instalacao concluida.${C_RESET} ${C_DIM}Log completo em: $LOG_FILE${C_RESET}"
hr
echo
