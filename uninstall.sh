#!/usr/bin/env bash
# Remove the user-installed Virtual Desktop Wallpaper plugin.
set -euo pipefail

PLUGIN_ID="org.kde.plasma.virtualdesktopwallpaper"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/${PLUGIN_ID}"

if [[ -d "${DEST}" ]]; then
    rm -rf "${DEST}"
    echo "Removed ${DEST}"
    echo "Restart plasmashell if the entry still appears:"
    echo "  kquitapp6 plasmashell || killall plasmashell; plasmashell --replace &"
else
    echo "Plugin not installed at ${DEST}"
fi
