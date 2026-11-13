#!/usr/bin/env bash
# Remove the user-installed Virtual Desktop Wallpaper plugin.
set -euo pipefail

PLUGIN_ID="org.kde.plasma.virtualdesktopwallpaper"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
DEST="${DATA_DIR}/plasma/wallpapers/${PLUGIN_ID}"
DOMAIN="plasma_wallpaper_${PLUGIN_ID}"

# Remove only this plugin's catalogs; leave other applications' locales intact.
for catalog in "${DATA_DIR}"/locale/*/LC_MESSAGES/"${DOMAIN}.mo"; do
    [[ -f "${catalog}" ]] || continue
    rm -f "${catalog}"
done

if [[ -d "${DEST}" ]]; then
    rm -rf "${DEST}"
    echo "Removed ${DEST}"
    echo "Restart plasmashell if the entry still appears:"
    echo "  kquitapp6 plasmashell || killall plasmashell; plasmashell --replace &"
else
    echo "Plugin not installed at ${DEST}"
fi
