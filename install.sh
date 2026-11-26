#!/usr/bin/env bash
# Install Virtual Desktop Wallpaper plugin for the current user (Plasma 6 / KF6).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_SRC="${SCRIPT_DIR}/package"
PLUGIN_ID="org.kde.plasma.virtualdesktopwallpaper"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
DEST="${DATA_DIR}/plasma/wallpapers/${PLUGIN_ID}"
DOMAIN="plasma_wallpaper_${PLUGIN_ID}"

if [[ ! -f "${PKG_SRC}/metadata.json" ]]; then
    echo "error: package/metadata.json not found next to this script" >&2
    exit 1
fi

# Validate and compile every catalog before replacing an existing installation.
if ! command -v msgfmt >/dev/null 2>&1; then
    echo "error: msgfmt is required; install GNU gettext and try again" >&2
    exit 1
fi
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "${BUILD_DIR}"' EXIT
for catalog in "${SCRIPT_DIR}"/translations/*.po; do
    [[ -f "${catalog}" ]] || continue
    language="$(basename "${catalog}" .po)"
    msgfmt --check --check-format -o "${BUILD_DIR}/${language}.mo" "${catalog}"
done

echo "Installing ${PLUGIN_ID} → ${DEST}"
mkdir -p "$(dirname "${DEST}")"
rm -rf "${DEST}"
cp -a "${PKG_SRC}" "${DEST}"

# Use the standard KI18n search path, including on older Plasma 6 versions
# which do not load wallpaper-package-local catalogs.
for catalog in "${BUILD_DIR}"/*.mo; do
    [[ -f "${catalog}" ]] || continue
    language="$(basename "${catalog}" .mo)"
    install -Dm644 "${catalog}" "${DATA_DIR}/locale/${language}/LC_MESSAGES/${DOMAIN}.mo"
done

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
echo "  ${SCRIPT_DIR}/uninstall.sh"
