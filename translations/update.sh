#!/usr/bin/env bash
# Extract English source strings for translators (requires GNU gettext).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

# The C++/KDE extractor recognizes KI18n placeholders in QML strings.
# JavaScript mode does not emit KDE/Qt format flags for msgfmt to validate.
xgettext --language=C++ --kde --from-code=UTF-8 \
    --keyword=i18nd:2 --flag=i18nd:2:kde-format \
    --package-name=virtual-desktop-wallpaper --package-version=1.0.0 \
    --copyright-holder=Rhedar \
    --msgid-bugs-address=https://github.com/RhedarLiu/virtual-desktop-wallpaper/issues \
    --output=translations/template.pot \
    package/contents/ui/main.qml package/contents/ui/config.qml
