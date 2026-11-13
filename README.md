# Virtual Desktop Wallpaper

[![License: GPL-2.0-or-later](https://img.shields.io/badge/License-GPL--2.0--or--later-blue.svg)](LICENSE)
[![Plasma](https://img.shields.io/badge/Plasma-6-blue)](https://kde.org/plasma-desktop/)

KDE **Plasma 6** / **Qt 6** / **KF6** wallpaper plugin that shows a **different image on each virtual desktop**.

## Features

- Per-desktop wallpaper paths (Desktop 1, 2, 3, …)
- Tracks the current virtual desktop through `TaskManager.VirtualDesktopInfo` (an API available to wallpaper plugins, equivalent to KWin’s `VirtualDesktopModel`)
- Smooth fade when switching desktops
- Drag-and-drop an image onto the desktop to set it for the **current** desktop
- Fill mode, background color, transition duration
- Compact config UI (file name + thumbnail; full path on hover)
- Uses Plasma's preferred interface language, with English as the fallback

## Requirements

- KDE Plasma **6.x**
- Qt **6**
- KDE Frameworks **6** (`libplasma`, `kirigami`, `kquickcontrols`, and the taskmanager QML module)
- GNU gettext (`msgfmt`) to compile translations during installation

## Install

```bash
git clone https://github.com/RhedarLiu/virtual-desktop-wallpaper.git
cd virtual-desktop-wallpaper
chmod +x install.sh
./install.sh
```

Installation location:

```text
~/.local/share/plasma/wallpapers/org.kde.plasma.virtualdesktopwallpaper/
```

Then:

1. Right-click the desktop → **Configure Desktop and Wallpaper…**
2. Wallpaper type → **Virtual Desktop Wallpaper**
3. Choose an image for each desktop

If the plugin does not appear, restart plasmashell:

```bash
kquitapp6 plasmashell || killall plasmashell
plasmashell --replace &
```

## Uninstall

```bash
./uninstall.sh
```

## Languages and translations

The plugin follows the interface language preferences in KDE System Settings
(Region & Language). English is the source language and fallback for missing
translations. Simplified Chinese (`zh_CN`) uses the original Chinese UI text.
Desktop names and file names are displayed as configured by the user.
Standard file and color dialog controls use KDE/Qt's own system translations.
After changing the system language, log out and back in to apply it to Plasma.

`install.sh` compiles all `translations/*.po` catalogs and installs them under
`${XDG_DATA_HOME:-~/.local/share}/locale/<language>/LC_MESSAGES/` using the domain
`plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper`. This also supports
older Plasma 6 versions that do not load translations from wallpaper packages.
`uninstall.sh` removes only this plugin's catalogs.

To add or update a translation (requires GNU gettext):

```bash
bash translations/update.sh
# For a new language, replace de with the desired locale code:
msginit --input=translations/template.pot --locale=de --output-file=translations/de.po
# For an existing translation after source text changes:
msgmerge --update --backup=none translations/zh_CN.po translations/template.pot
```

Translate the `msgstr` entries, preserving placeholders such as `%1`, then run
`./install.sh` again. Add matching `Name[<language>]` and
`Description[<language>]` entries to `package/metadata.json` to translate the
plugin's listing in the wallpaper selector as well.

## Project layout

```
virtual-desktop-wallpaper/
├── package/                          # KPackage root (installed contents)
│   ├── metadata.json                 # Plasma/Wallpaper metadata
│   └── contents/
│       ├── config/
│       │   └── main.xml              # KConfigXT configuration schema
│       └── ui/
│           ├── main.qml              # Wallpaper rendering + desktop index binding
│           └── config.qml            # Desktop configuration UI
├── install.sh
├── uninstall.sh
├── translations/                     # Gettext catalogs and extraction script
├── LICENSE
└── README.md
```

## Technical notes

### Why `VirtualDesktopInfo` instead of `VirtualDesktopModel`?

| API | Module | Available in wallpaper plugins? |
|-----|--------|----------------------------------|
| `VirtualDesktopModel` | `org.kde.kwin` | **No** — only inside KWin effect QML |
| `VirtualDesktopInfo` | `org.kde.taskmanager` | **Yes** — used by plasmashell itself |

Desktop ID comparison must use loose `==` (`currentDesktop` / `desktopIds` are QVariant values, so strict `===` often fails). `VirtualDesktopInfo` may not be populated yet during `Component.onCompleted`, so resolve the index again after a short delay.

### Config keys (`contents/config/main.xml`)

| Key | Type | Meaning |
|-----|------|---------|
| `WallpaperPaths` | `StringList` | One image per virtual desktop (index 0 = Desktop 1) |
| `FillMode` | `int` | `Image.fillMode` enum value |
| `BackgroundColor` | `Color` | Background color when no image is set |
| `TransitionDuration` | `int` | Fade duration when switching desktops, in milliseconds |

### Plasma 6 metadata

Uses `KPackageStructure: "Plasma/Wallpaper"` (Plasma 6 style).
Also sets `KPlugin.ServiceTypes: ["Plasma/Wallpaper"]` for compatibility with classic plugin discovery.

## License

[GPL-2.0-or-later](LICENSE)
