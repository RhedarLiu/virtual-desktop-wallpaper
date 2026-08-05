#!/usr/bin/env bash
# Install Virtual Desktop Wallpaper plugin for the current user (Plasma 6 / KF6).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_SRC="${SCRIPT_DIR}/package"
PLUGIN_ID="org.kde.plasma.virtualdesktopwallpaper"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/${PLUGIN_ID}"

if [[ ! -f "${PKG_SRC}/metadata.json" ]]; then
    echo "error: package/metadata.json not found next to this script" >&2
    exit 1
fi

echo "Installing ${PLUGIN_ID} → ${DEST}"
mkdir -p "$(dirname "${DEST}")"
rm -rf "${DEST}"
cp -a "${PKG_SRC}" "${DEST}"

echo "Done."
echo
echo "Next steps:"
echo "  1. Right-click the desktop → Configure Desktop and Wallpaper…"
echo "  2. Choose wallpaper type: “Virtual Desktop Wallpaper”"
echo "  3. Pick an image for Desktop 1, Desktop 2, …"
echo
echo "If the plugin does not appear, restart plasmashell:"
echo "  kquitapp6 plasmashell || killall plasmashell; plasmashell --replace &"
echo
echo "To uninstall:"
echo "  rm -rf \"${DEST}\""
