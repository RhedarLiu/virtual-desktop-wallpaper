# Virtual Desktop Wallpaper

[![License: GPL-2.0-or-later](https://img.shields.io/badge/License-GPL--2.0--or--later-blue.svg)](LICENSE)
[![Plasma](https://img.shields.io/badge/Plasma-6-blue)](https://kde.org/plasma-desktop/)

KDE **Plasma 6** / **Qt 6** / **KF6** wallpaper plugin that shows a **different image on each virtual desktop**.

为每个虚拟桌面设置不同壁纸的 Plasma 6 壁纸插件。

## Features / 功能

- Per-desktop wallpaper paths (Desktop 1, 2, 3, …)
- 通过 `TaskManager.VirtualDesktopInfo` 监听当前虚拟桌面（壁纸插件可用的 API，等价于 KWin 的 `VirtualDesktopModel`）
- Smooth fade when switching desktops / 切换桌面时淡入淡出
- Drag-and-drop an image onto the desktop to set it for the **current** desktop
- Fill mode, background color, transition duration
- Compact config UI (file name + thumbnail; full path on hover)

## Requirements / 依赖

- KDE Plasma **6.x**
- Qt **6**
- KDE Frameworks **6**（`libplasma`、`kirigami`、`kquickcontrols`、taskmanager QML 模块）

## Install / 安装

```bash
git clone https://github.com/RhedarLiu/virtual-desktop-wallpaper.git
cd virtual-desktop-wallpaper
chmod +x install.sh
./install.sh
```

安装位置：

```text
~/.local/share/plasma/wallpapers/org.kde.plasma.virtualdesktopwallpaper/
```

然后：

1. 桌面右键 → **配置桌面和壁纸…** / **Configure Desktop and Wallpaper…**
2. 壁纸类型 → **虚拟桌面壁纸** / **Virtual Desktop Wallpaper**
3. 为每个桌面选择图片

若插件未出现，重启 plasmashell：

```bash
kquitapp6 plasmashell || killall plasmashell
plasmashell --replace &
```

## Uninstall / 卸载

```bash
./uninstall.sh
```

## Project layout / 目录结构

```
virtual-desktop-wallpaper/
├── package/                          # KPackage 根目录（安装内容）
│   ├── metadata.json                 # Plasma/Wallpaper 元数据
│   └── contents/
│       ├── config/
│       │   └── main.xml              # KConfigXT 配置 schema
│       └── ui/
│           ├── main.qml              # 壁纸渲染 + 桌面 index 绑定
│           └── config.qml            # 「配置桌面」UI
├── install.sh
├── uninstall.sh
├── LICENSE
└── README.md
```

## Technical notes / 技术说明

### Why `VirtualDesktopInfo` instead of `VirtualDesktopModel`?

| API | Module | Available in wallpaper plugins? |
|-----|--------|----------------------------------|
| `VirtualDesktopModel` | `org.kde.kwin` | **No** — only inside KWin effect QML |
| `VirtualDesktopInfo` | `org.kde.taskmanager` | **Yes** — used by plasmashell itself |

Desktop id comparison must use loose `==`（`currentDesktop` / `desktopIds` 是 QVariant，严格 `===` 常失败）。`VirtualDesktopInfo` 在 `Component.onCompleted` 时可能尚未填充，需要短暂延迟后再 resolve。

### Config keys (`contents/config/main.xml`)

| Key | Type | Meaning |
|-----|------|---------|
| `WallpaperPaths` | `StringList` | 每个虚拟桌面一张图（index 0 = 桌面 1） |
| `FillMode` | `int` | `Image.fillMode` 枚举 |
| `BackgroundColor` | `Color` | 无图时的底色 |
| `TransitionDuration` | `int` | 切换淡入淡出毫秒 |

### Plasma 6 metadata

使用 `KPackageStructure: "Plasma/Wallpaper"`（Plasma 6 风格）。  
同时设置 `KPlugin.ServiceTypes: ["Plasma/Wallpaper"]` 以兼容经典插件查找。

## License

[GPL-2.0-or-later](LICENSE)
