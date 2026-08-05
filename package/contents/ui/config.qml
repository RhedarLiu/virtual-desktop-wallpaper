/*
    SPDX-FileCopyrightText: 2026 Rhedar
    SPDX-License-Identifier: GPL-2.0-or-later

    Configuration UI shown when the user right-clicks the desktop and chooses
    "Configure Desktop and Wallpaper…".

    Lets the user pick a separate image file for Desktop 1, Desktop 2, …
    based on the live VirtualDesktopInfo model from KF6 TaskManager.
*/

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import org.kde.taskmanager as TaskManager

ColumnLayout {
    id: root

    // Injected by Plasma's wallpaper KCM (ConfigurationContainmentAppearance).
    property var configDialog
    property var wallpaperConfiguration
    property var parentLayout
    property var screenSize

    // KCM wallpaper config convention: cfg_<entryName> mirrors main.xml entries.
    property list<string> cfg_WallpaperPaths: []
    property list<string> cfg_WallpaperPathsDefault: []
    property int cfg_FillMode
    property int cfg_FillModeDefault: 2
    property alias cfg_BackgroundColor: backgroundColorButton.color
    property color cfg_BackgroundColorDefault: "#1d99f3"
    property int cfg_TransitionDuration
    property int cfg_TransitionDurationDefault: 300

    property alias formLayout: formLayout
    signal configurationChanged()

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    function pathsAsArray() {
        const raw = cfg_WallpaperPaths;
        if (raw === undefined || raw === null) {
            return [];
        }
        if (typeof raw !== "string" && raw.length !== undefined) {
            const out = [];
            for (let i = 0; i < raw.length; ++i) {
                out.push(raw[i] !== undefined && raw[i] !== null ? String(raw[i]) : "");
            }
            return out;
        }
        if (typeof raw === "string" && raw.length > 0) {
            if (raw.indexOf(",/") !== -1) {
                return raw.split(",").map(p => String(p));
            }
            return [raw];
        }
        return [];
    }

    readonly property var desktopModel: {
        const names = virtualDesktopInfo.desktopNames || [];
        const count = Math.max(virtualDesktopInfo.numberOfDesktops, names.length, 1);
        const paths = pathsAsArray();
        const result = [];
        for (let i = 0; i < count; ++i) {
            const name = (i < names.length && names[i])
                ? names[i]
                : i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                        "桌面 %1", i + 1);
            result.push({
                index: i,
                number: i + 1,
                name: name,
                path: (i < paths.length) ? (paths[i] || "") : ""
            });
        }
        return result;
    }

    property int editingDesktopIndex: -1

    function setWallpaperPath(desktopIndex, path) {
        let paths = pathsAsArray();
        while (paths.length <= desktopIndex) {
            paths.push("");
        }
        paths[desktopIndex] = path || "";
        cfg_WallpaperPaths = paths.slice();
        configurationChanged();
    }

    function clearWallpaperPath(desktopIndex) {
        setWallpaperPath(desktopIndex, "");
    }

    function localPathFromUrl(url) {
        const s = url.toString();
        if (s.startsWith("file://")) {
            return decodeURIComponent(s.substring(7));
        }
        return s;
    }

    /** Basename for display — full path goes in the tooltip. */
    function fileNameOf(path) {
        if (!path) {
            return "";
        }
        const s = String(path);
        const i = s.lastIndexOf("/");
        return i >= 0 ? s.substring(i + 1) : s;
    }

    Kirigami.FormLayout {
        id: formLayout
        Layout.fillWidth: true
        twinFormLayouts: parentLayout

        // ---- Per-desktop image pickers --------------------------------
        //
        // Important layout rules for FormLayout + RowLayout:
        // - TextField's implicit width tracks its text, so a long path will
        //   push sibling buttons past the dialog edge unless we force
        //   Layout.preferredWidth: 0 (classic Qt "allow shrink" trick).
        // - Fixed-size controls (buttons, thumb) must NOT fillWidth.
        // - Keep the whole row's preferred width modest so FormLayout does
        //   not demand a huge dialog.
        Repeater {
            model: root.desktopModel

            delegate: RowLayout {
                id: desktopRow
                Kirigami.FormData.label: modelData.name + ":"
                Layout.fillWidth: true
                // Cap preferred width so FormLayout doesn't grow the window
                Layout.preferredWidth: Kirigami.Units.gridUnit * 22
                Layout.maximumWidth: Number.POSITIVE_INFINITY
                spacing: Kirigami.Units.smallSpacing

                required property var modelData

                // Thumbnail first — fixed size, never compresses buttons
                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 4
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.disabledTextColor
                        border.width: 1

                        Image {
                            id: thumb
                            anchors.fill: parent
                            anchors.margins: 1
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            source: modelData.path
                                ? (modelData.path.startsWith("file:")
                                    ? modelData.path
                                    : "file://" + modelData.path)
                                : ""
                            visible: status === Image.Ready
                        }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            source: "image-x-generic"
                            opacity: 0.4
                            visible: !thumb.visible
                        }
                    }
                }

                // Path — shrinkable. Shows basename; full path in tooltip.
                QQC2.TextField {
                    id: pathField
                    Layout.fillWidth: true
                    // Critical: preferredWidth 0 lets the field shrink below
                    // its content width instead of forcing the row wider.
                    Layout.preferredWidth: 0
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                    Layout.alignment: Qt.AlignVCenter
                    readOnly: true
                    // Show just the file name so the field stays compact;
                    // hover still reveals the full path.
                    text: root.fileNameOf(modelData.path)
                    placeholderText: i18nd(
                        "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                        "未选择图片")
                    QQC2.ToolTip.visible: hovered && modelData.path.length > 0
                    QQC2.ToolTip.text: modelData.path
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }

                QQC2.Button {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: implicitWidth
                    text: i18nd(
                        "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                        "选择…")
                    icon.name: "document-open-folder"
                    QQC2.ToolTip.text: i18nd(
                        "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                        "为该虚拟桌面选择壁纸图片")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: {
                        root.editingDesktopIndex = modelData.index;
                        if (modelData.path && modelData.path.length > 0) {
                            const dir = modelData.path.substring(
                                0, modelData.path.lastIndexOf("/"));
                            if (dir.length > 0) {
                                fileDialog.currentFolder = "file://" + dir;
                            }
                        }
                        fileDialog.open();
                    }
                }

                QQC2.Button {
                    Layout.alignment: Qt.AlignVCenter
                    icon.name: "edit-clear"
                    display: QQC2.AbstractButton.IconOnly
                    enabled: modelData.path && modelData.path.length > 0
                    QQC2.ToolTip.text: i18nd(
                        "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                        "清除")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: root.clearWallpaperPath(modelData.index)
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: fillModeCombo
            Kirigami.FormData.label: i18nd(
                "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                "位置：")
            model: [
                {
                    label: i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                                 "缩放并裁剪"),
                    value: Image.PreserveAspectCrop
                },
                {
                    label: i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                                 "拉伸"),
                    value: Image.Stretch
                },
                {
                    label: i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                                 "缩放，保持比例"),
                    value: Image.PreserveAspectFit
                },
                {
                    label: i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                                 "居中"),
                    value: Image.Pad
                },
                {
                    label: i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                                 "平铺"),
                    value: Image.Tile
                }
            ]
            textRole: "label"
            currentIndex: {
                for (let i = 0; i < model.length; ++i) {
                    if (model[i].value === root.cfg_FillMode) {
                        return i;
                    }
                }
                return 0;
            }
            onActivated: root.cfg_FillMode = model[currentIndex].value
        }

        KQuickControls.ColorButton {
            id: backgroundColorButton
            Kirigami.FormData.label: i18nd(
                "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                "背景颜色：")
            dialogTitle: i18nd(
                "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                "选择背景颜色")
        }

        QQC2.SpinBox {
            id: transitionSpin
            Kirigami.FormData.label: i18nd(
                "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                "切换动画 (毫秒)：")
            from: 0
            to: 5000
            stepSize: 50
            value: root.cfg_TransitionDuration
            onValueModified: root.cfg_TransitionDuration = value
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18nd(
                "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                "提示：切换虚拟桌面（Meta+F1 / Meta+F2 或分页器）即可看到壁纸变化。也可以把图片拖到桌面上，为当前桌面设置壁纸。")
        }
    }

    FileDialog {
        id: fileDialog
        title: i18nd(
            "plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
            "打开图片")
        currentFolder: {
            const pics = StandardPaths.standardLocations(StandardPaths.PicturesLocation);
            if (pics.length > 0) {
                return pics[0];
            }
            return StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
        }
        nameFilters: [
            i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                  "图片文件") + " (*.jpg *.jpeg *.png *.bmp *.webp *.tiff *.tif *.svg *.svgz *.avif *.heif *.heic *.gif)",
            i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                  "所有文件") + " (*)"
        ]
        fileMode: FileDialog.OpenFile
        options: FileDialog.ReadOnly
        onAccepted: {
            if (root.editingDesktopIndex < 0) {
                return;
            }
            root.setWallpaperPath(
                root.editingDesktopIndex,
                root.localPathFromUrl(selectedFile)
            );
            root.editingDesktopIndex = -1;
        }
        onRejected: root.editingDesktopIndex = -1
    }
}
