# Virtual Desktop Wallpaper

[![License: GPL-2.0-or-later](https://img.shields.io/badge/License-GPL--2.0--or--later-blue.svg)](LICENSE)
[![Plasma](https://img.shields.io/badge/Plasma-6-blue)](https://kde.org/plasma-desktop/)

KDE **Plasma 6** / **Qt 6** / **KF6** wallpaper plugin that shows a **different image on each virtual desktop**.

基于 KDE **Plasma 6** / **Qt 6** / **KF6**，为**每个虚拟桌面设置不同壁纸**的插件。

## Features / 功能

- Per-desktop wallpaper paths (Desktop 1, 2, 3, …) / 为每个虚拟桌面单独设置壁纸路径（桌面 1、2、3……）
- Tracks the current virtual desktop through `TaskManager.VirtualDesktopInfo` (an API available to wallpaper plugins, equivalent to KWin’s `VirtualDesktopModel`) / 通过 `TaskManager.VirtualDesktopInfo` 监听当前虚拟桌面（壁纸插件可用的 API，等价于 KWin 的 `VirtualDesktopModel`）
- Smooth fade when switching desktops / 切换桌面时平滑淡入淡出
- Drag-and-drop an image onto the desktop to set it for the **current** desktop / 将图片拖到桌面，即可设为**当前**虚拟桌面的壁纸
- Fill mode, background color, transition duration / 可设置填充模式、背景颜色和切换动画时长
- Compact config UI (file name + thumbnail; full path on hover) / 紧凑的配置界面（文件名与缩略图，悬停显示完整路径）
- Uses Plasma's preferred interface language, with English as the fallback / 跟随 Plasma 的首选界面语言，缺少翻译时回退到英语

## Requirements / 依赖

- KDE Plasma **6.x**
- Qt **6**
- KDE Frameworks **6** (`libplasma`, `kirigami`, `kquickcontrols`, and the taskmanager QML module / `libplasma`、`kirigami`、`kquickcontrols` 及 taskmanager QML 模块)
- GNU gettext (`msgfmt`) to compile translations during installation / 安装时需要 GNU gettext 的 `msgfmt` 来编译翻译文件

## Install / 安装

```bash
git clone https://github.com/RhedarLiu/virtual-desktop-wallpaper.git
cd virtual-desktop-wallpaper
chmod +x install.sh
./install.sh
```

Installation location / 安装位置：

```text
~/.local/share/plasma/wallpapers/org.kde.plasma.virtualdesktopwallpaper/
```

Then / 然后：

1. Right-click the desktop → **Configure Desktop and Wallpaper…** / 桌面右键 → **配置桌面和壁纸…**
2. Wallpaper type → **Virtual Desktop Wallpaper** / 壁纸类型 → **虚拟桌面壁纸**
3. Choose an image for each desktop / 为每个虚拟桌面选择图片

If the plugin does not appear, restart plasmashell / 若插件未出现，请重启 plasmashell：

```bash
kquitapp6 plasmashell || killall plasmashell
plasmashell --replace &
```

## Uninstall / 卸载

```bash
./uninstall.sh
```

## Languages and translations / 语言与翻译

The plugin follows the interface language preferences in KDE System Settings
(Region & Language). English is the source language and fallback for missing
translations. Simplified Chinese (`zh_CN`) uses the original Chinese UI text.
Desktop names and file names are displayed as configured by the user.
Standard file and color dialog controls use KDE/Qt's own system translations.
After changing the system language, log out and back in to apply it to Plasma.

插件跟随 KDE 系统设置中“区域与语言”的界面语言偏好。英语是源语言，也是缺少翻译时的回退语言；简体中文（`zh_CN`）保留原有中文界面文本。桌面名称和文件名按用户设置显示，标准文件与颜色对话框使用 KDE/Qt 自带的系统翻译。修改系统语言后，请注销并重新登录，使设置应用到 Plasma。

`install.sh` compiles all `translations/*.po` catalogs and installs them under
`${XDG_DATA_HOME:-~/.local/share}/locale/<language>/LC_MESSAGES/` using the domain
`plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper`. This also supports
older Plasma 6 versions that do not load translations from wallpaper packages.
`uninstall.sh` removes only this plugin's catalogs.

`install.sh` 编译所有 `translations/*.po` 翻译文件，并以 `plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper` 为翻译域，安装到 `${XDG_DATA_HOME:-~/.local/share}/locale/<language>/LC_MESSAGES/`。此路径也兼容无法从壁纸插件包内加载翻译的早期 Plasma 6 版本。`uninstall.sh` 仅删除本插件的翻译文件。

To add or update a translation (requires GNU gettext) / 添加或更新翻译（需要 GNU gettext）：

```bash
bash translations/update.sh
# For a new language, replace de with the desired locale code / 新增语言时，将 de 替换为目标语言代码：
msginit --input=translations/template.pot --locale=de --output-file=translations/de.po
# For an existing translation after source text changes / 源文本变更后，更新已有翻译：
msgmerge --update --backup=none translations/zh_CN.po translations/template.pot
```

Translate the `msgstr` entries, preserving placeholders such as `%1`, then run
`./install.sh` again. Add matching `Name[<language>]` and
`Description[<language>]` entries to `package/metadata.json` to translate the
plugin's listing in the wallpaper selector as well.

翻译 `msgstr` 内容时，请保留 `%1` 等占位符，完成后重新运行 `./install.sh`。同时在 `package/metadata.json` 中添加对应的 `Name[<language>]` 和 `Description[<language>]`，以翻译壁纸选择器中的插件名称与描述。

After updating translations, restart plasmashell if the running session still
shows the old text (see the commands above). Logging out and back in also
reloads the translations.

更新翻译后，如果当前会话仍显示旧文本，请重启 plasmashell（命令见上方）；注销并重新登录也可重新加载翻译。

## Project layout / 目录结构

```
virtual-desktop-wallpaper/
├── package/                          # KPackage root (installed contents) / KPackage 根目录（安装内容）
│   ├── metadata.json                 # Plasma/Wallpaper metadata / 元数据
│   └── contents/
│       ├── config/
│       │   └── main.xml              # KConfigXT configuration schema / 配置结构
│       └── ui/
│           ├── main.qml              # Wallpaper rendering + desktop index binding / 壁纸渲染与桌面索引绑定
│           └── config.qml            # Desktop configuration UI / 桌面配置界面
├── install.sh
├── uninstall.sh
├── translations/                     # Gettext catalogs and extraction script / 翻译文件与文本提取脚本
├── LICENSE
└── README.md
```

## Technical notes / 技术说明

### Why `VirtualDesktopInfo` instead of `VirtualDesktopModel`? / 为什么使用 `VirtualDesktopInfo`？

| API | Module / 模块 | Available in wallpaper plugins? / 壁纸插件中是否可用？ |
|-----|--------|----------------------------------|
| `VirtualDesktopModel` | `org.kde.kwin` | **No** — only inside KWin effect QML / **不可用**，仅限 KWin 特效 QML |
| `VirtualDesktopInfo` | `org.kde.taskmanager` | **Yes** — used by plasmashell itself / **可用**，plasmashell 自身也在使用 |

Desktop ID comparison must use loose `==` (`currentDesktop` / `desktopIds` are QVariant values, so strict `===` often fails). `VirtualDesktopInfo` may not be populated yet during `Component.onCompleted`, so resolve the index again after a short delay.

比较桌面 ID 时需要使用宽松相等 `==`（`currentDesktop` / `desktopIds` 是 QVariant 值，严格相等 `===` 常会失败）。`Component.onCompleted` 执行时，`VirtualDesktopInfo` 的数据可能尚未填充，需要短暂延迟后再次解析索引。

### Config keys / 配置项 (`contents/config/main.xml`)

| Key / 配置项 | Type / 类型 | Meaning / 含义 |
|-----|------|---------|
| `WallpaperPaths` | `StringList` | One image per virtual desktop (index 0 = Desktop 1) / 每个虚拟桌面一张图片（索引 0 = 桌面 1） |
| `FillMode` | `int` | `Image.fillMode` enum value / `Image.fillMode` 枚举值 |
| `BackgroundColor` | `Color` | Background color when no image is set / 未设置图片时的背景颜色 |
| `TransitionDuration` | `int` | Fade duration when switching desktops, in milliseconds / 切换桌面时的淡入淡出时长，单位为毫秒 |

### Plasma 6 metadata / Plasma 6 元数据

Uses `KPackageStructure: "Plasma/Wallpaper"` (Plasma 6 style).
Also sets `KPlugin.ServiceTypes: ["Plasma/Wallpaper"]` for compatibility with classic plugin discovery.

使用 Plasma 6 风格的 `KPackageStructure: "Plasma/Wallpaper"`，同时设置 `KPlugin.ServiceTypes: ["Plasma/Wallpaper"]`，以兼容传统的插件查找方式。

## License / 许可证

[GPL-2.0-or-later](LICENSE)
