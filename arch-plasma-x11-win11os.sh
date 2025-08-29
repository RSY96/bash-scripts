#!/bin/bash
# Arch + KDE Plasma (X11) + VMware tools + Win11OS-dark (Global Theme) by yeyushengfan258
set -euo pipefail

echo "==> Actualizando sistema"
sudo pacman -Syu --noconfirm

echo "==> Instalando Plasma mínimo (sin metapaquete pesado)"
sudo pacman -S --needed --noconfirm plasma-desktop dolphin konsole kde-gtk-config

echo "==> Añadiendo sesión X11 para Plasma 6"
sudo pacman -S --needed --noconfirm plasma-x11-session kwin-x11

# Display manager: si ya tienes LightDM, no habilitamos SDDM
if systemctl is-enabled lightdm.service >/dev/null 2>&1; then
  echo "==> Detectado LightDM habilitado; no se tocará SDDM"
else
  echo "==> Instalando y habilitando SDDM (si no usas LightDM)"
  sudo pacman -S --needed --noconfirm sddm
  sudo systemctl enable sddm.service --force || true
fi

echo "==> Integración VMware (clipboard, drag&drop)"
sudo pacman -S --needed --noconfirm open-vm-tools gtkmm3
sudo systemctl enable --now vmtoolsd.service vmware-vmblock-fuse.service

echo "==> Descargando Win11OS-kde (Global Theme + piezas)"
WORK="$(mktemp -d)"
git clone --depth=1 https://github.com/yeyushengfan258/Win11OS-kde.git "$WORK/Win11OS-kde"

echo "==> Ejecutando instalador oficial del tema"
chmod +x "$WORK/Win11OS-kde/install.sh"
# instala en ~/.local/share (usuario), no ensucia el sistema
"$WORK/Win11OS-kde/install.sh" || true

echo "==> Intentando aplicar el Look-and-Feel Win11OS (si está registrado)"
# listar y coger el LNF que contenga 'win11' o 'we10x'
LNF_ID="$(lookandfeeltool -l | awk '{print $1}' | grep -i -E 'win11|we10x' | head -n1 || true)"
if [[ -n "${LNF_ID}" ]]; then
  lookandfeeltool -a "${LNF_ID}" || true
  echo "   Aplicado Look-and-Feel: ${LNF_ID}"
else
  echo "   ⚠️  No se detectó LNF Win11OS; aplicaremos componentes por separado."

  # 1) Plasma Desktop Theme
  DT_DIR="$HOME/.local/share/plasma/desktoptheme"
  THEME_NAME="$(ls -1 "$DT_DIR" 2>/dev/null | grep -i -E 'win11|we10x' | head -n1 || true)"
  [[ -n "${THEME_NAME}" ]] && plasma-apply-desktoptheme "${THEME_NAME}" || true

  # 2) Colores
  COLORS_DIR="$HOME/.local/share/color-schemes"
  COLOR_FILE="$(ls -1 "$COLORS_DIR" 2>/dev/null | grep -i -E 'win11|we10x' | head -n1 || true)"
  [[ -n "${COLOR_FILE}" ]] && plasma-apply-colorscheme "${COLOR_FILE%.colors}" || true

  # 3) Kvantum (widgets Qt)
  sudo pacman -S --needed --noconfirm kvantum
  KVA_DIR="$HOME/.local/share/Kvantum"
  KVA_THEME="$(ls -1 "$KVA_DIR" 2>/dev/null | grep -i -E 'win11|we10x' | head -n1 || true)"
  kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "kvantum"
  mkdir -p "$HOME/.config/Kvantum"
  printf "[General]\ntheme=%s\n" "${KVA_THEME:-Win11OS}" > "$HOME/.config/Kvantum/kvantum.kvconfig"

  # 4) Aurorae (decoración de ventanas)
  AUR_DIR="$HOME/.local/share/aurorae"
  AUR_THEME="$(ls -1 "$AUR_DIR" 2>/dev/null | grep -i -E 'win11|we10x' | head -n1 || true)"
  [[ -n "${AUR_THEME}" ]] && kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__${AUR_THEME}"

fi

# (Opcional) Iconos Win11 del mismo autor
if [[ "${1:-}" == "--icons" ]]; then
  echo "==> Instalando iconos Win11 (opcional)"
  git clone --depth=1 https://github.com/yeyushengfan258/Win11-icon-theme.git "$WORK/Win11-icon-theme"
  chmod +x "$WORK/Win11-icon-theme/install.sh"
  "$WORK/Win11-icon-theme/install.sh" -d "$HOME/.local/share/icons" || true
  ICON_NAME="$(ls -1 "$HOME/.local/share/icons" | grep -i 'Win11' | head -n1 || true)"
  [[ -n "${ICON_NAME}" ]] && kwriteconfig6 --file kdeglobals --group Icons --key Theme "${ICON_NAME}"
fi

echo "==> Reiniciando shell/ventanas para ver cambios al instante"
kquitapp6 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
(plasmashell --replace >/dev/null 2>&1 & disown) || true
if command -v kwin_x11 >/dev/null 2>&1; then
  (kwin_x11 --replace >/dev/null 2>&1 & disown) || true
fi

rm -rf "$WORK"

cat <<'OUT'

✅ Listo.

1) Sal de la sesión actual y en el login elige **Plasma (X11)**.
2) Si aún ves Breeze, abre:
   - Preferencias → Apariencia → Global Theme → busca “Win11OS / We10XOS / Win11”
   - o en “Plasma Style” y “Colors” aplica los que empiecen por Win11/We10X.
3) Si quieres iconos Win11, vuelve a ejecutar el script con:
   ./arch-plasma-x11-win11os.sh --icons

OUT
