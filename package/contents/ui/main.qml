/*
    SPDX-FileCopyrightText: 2026 Rhedar
    SPDX-License-Identifier: GPL-2.0-or-later

    Virtual Desktop Wallpaper — main rendering surface for Plasma 6.

    Listens to the current virtual desktop via TaskManager.VirtualDesktopInfo
    (the wallpaper-safe equivalent of KWin's VirtualDesktopModel) and displays
    the image path configured for that desktop index.
*/

import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

WallpaperItem {
    id: root

    // ------------------------------------------------------------------
    // Virtual desktop tracking
    //
    // KWin exposes VirtualDesktopModel only inside effect QML contexts.
    // Wallpaper plugins run inside plasmashell, so we use
    // TaskManager.VirtualDesktopInfo — the public KF6 API for the same data.
    // ------------------------------------------------------------------
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    /**
     * 0-based index of the currently active virtual desktop.
     * Updated from VirtualDesktopInfo signals (not only a pure binding),
     * so QVariant notify quirks cannot leave us stuck on index 0.
     */
    property int currentDesktopIndex: 0

    /** 1-based desktop number shown to users (Desktop 1, Desktop 2, …). */
    readonly property int currentDesktopNumber: currentDesktopIndex + 1

    /** Human-readable name of the current desktop, if available. */
    readonly property string currentDesktopName: {
        const names = virtualDesktopInfo.desktopNames;
        if (names && currentDesktopIndex >= 0 && currentDesktopIndex < names.length) {
            return names[currentDesktopIndex];
        }
        return i18nd("plasma_wallpaper_org.kde.plasma.virtualdesktopwallpaper",
                     "Desktop %1", currentDesktopNumber);
    }

    /**
     * Resolve 0-based desktop index from VirtualDesktopInfo.
     * Uses loose == (same as working vallpaper6) because currentDesktop /
     * desktopIds are QVariant / QVariantList — strict === often fails.
     */
    function resolveDesktopIndex() {
        const currentId = virtualDesktopInfo.currentDesktop;
        const ids = virtualDesktopInfo.desktopIds;

        if (currentId === undefined || currentId === null || !ids || ids.length === 0) {
            return 0;
        }

        for (let i = 0; i < ids.length; ++i) {
            if (ids[i] == currentId) {
                return i;
            }
        }
        return 0;
    }

    function refreshDesktopIndex() {
        const idx = resolveDesktopIndex();
        if (idx !== currentDesktopIndex) {
            currentDesktopIndex = idx;
        }
    }

    Connections {
        target: virtualDesktopInfo
        function onCurrentDesktopChanged() { root.refreshDesktopIndex(); }
        function onDesktopIdsChanged() { root.refreshDesktopIndex(); }
        function onNumberOfDesktopsChanged() { root.refreshDesktopIndex(); }
    }

    /**
     * Normalize configuration.WallpaperPaths into a plain string array.
     *
     * On disk (appletsrc) a StringList is comma-joined. At runtime
     * KConfigPropertyMap may expose it as QStringList OR as a single
     * QString. Defend against both — and against iterating a QString by
     * character (which would turn "/home/…" into ["/", "h", "o", …]).
     */
    function wallpaperPathsList() {
        const raw = root.configuration.WallpaperPaths;
        if (raw === undefined || raw === null) {
            return [];
        }

        // Exclude JS strings first (they also have .length / [i]).
        if (typeof raw !== "string" && raw.length !== undefined) {
            const out = [];
            let allSingleChar = raw.length > 1;
            for (let i = 0; i < raw.length; ++i) {
                const s = raw[i] !== undefined && raw[i] !== null ? String(raw[i]) : "";
                if (s.length > 1) {
                    allSingleChar = false;
                }
                out.push(s);
            }
            if (out.length > 0 && allSingleChar) {
                // Almost certainly iterated a QString as a char array
                return parsePathString(out.join(""));
            }
            return out;
        }

        return parsePathString(String(raw));
    }

    function parsePathString(asString) {
        if (!asString || asString.length === 0 || asString === "[object Object]") {
            return [];
        }
        // KConfig joins StringList with commas. Absolute Linux paths start
        // with '/', so ",/" is a reliable split between entries.
        if (asString.indexOf(",/") !== -1) {
            return asString.split(",").map(p => p.trim()).filter(p => p.length > 0);
        }
        return [asString];
    }

    /** Raw stored path for a 0-based desktop index, or "". */
    function wallpaperPathForIndex(index) {
        const paths = wallpaperPathsList();
        if (index < 0 || index >= paths.length) {
            return "";
        }
        const path = paths[index];
        return path && String(path).length > 0 ? String(path) : "";
    }

    /**
     * Turn a stored path into something QtQuick Image can load.
     * Match org.kde.image: plain file:// + UTF-8 path (no encodeURIComponent).
     */
    function toImageUrl(path) {
        if (!path || path.length === 0) {
            return "";
        }
        const s = String(path).trim();
        if (s.length === 0) {
            return "";
        }
        if (s.startsWith("file:") || s.startsWith("http:") || s.startsWith("https:")
                || s.startsWith("qrc:") || s.startsWith("image:")) {
            return s;
        }
        // Absolute or relative local path
        return "file://" + s;
    }

    /**
     * Bound image URL for the active desktop.
     * Depends on currentDesktopIndex AND configuration.WallpaperPaths so
     * both desktop switches and config edits re-evaluate automatically.
     */
    readonly property string currentWallpaper: {
        const _idx = currentDesktopIndex;
        const _paths = root.configuration.WallpaperPaths;
        void _idx;
        void _paths;
        return toImageUrl(wallpaperPathForIndex(currentDesktopIndex));
    }

    readonly property int fillModeValue: {
        const v = root.configuration.FillMode;
        return (v === undefined || v === null) ? Image.PreserveAspectCrop : v;
    }

    // Decode size — never pass 0×0 to Image (triggers GL_INVALID_VALUE in kwin).
    readonly property size wallpaperSourceSize: {
        const dpr = (typeof Screen !== "undefined" && Screen.devicePixelRatio > 0)
                    ? Screen.devicePixelRatio : 1;
        const w = Math.max(1, Math.round(Math.max(width, 1) * dpr));
        const h = Math.max(1, Math.round(Math.max(height, 1) * dpr));
        return Qt.size(w, h);
    }

    // Accept drag-and-drop of image files onto the desktop
    onOpenUrlRequested: (url) => {
        let paths = wallpaperPathsList();
        while (paths.length <= currentDesktopIndex) {
            paths.push("");
        }
        let s = url.toString();
        if (s.startsWith("file://")) {
            s = decodeURIComponent(s.substring(7));
        }
        paths[currentDesktopIndex] = s;
        root.configuration.WallpaperPaths = paths.slice();
        root.configuration.writeConfig();
    }

    // Solid fallback color
    Rectangle {
        anchors.fill: parent
        color: root.configuration.BackgroundColor || "#1d99f3"
        z: -1
    }

    // ------------------------------------------------------------------
    // Rendering — single Image bound directly to currentWallpaper.
    // Cross-fade is nice-to-have; a working solid image comes first.
    // A second Image peeks in only during source transitions (opacity fade).
    // ------------------------------------------------------------------
    Image {
        id: mainImage
        anchors.fill: parent
        fillMode: root.fillModeValue
        asynchronous: true
        autoTransform: true
        cache: true
        smooth: true
        // Only set sourceSize once we have a real size; binding to a changing
        // sourceSize reloads the image on every geometry tweak otherwise.
        sourceSize: (root.width > 1 && root.height > 1) ? root.wallpaperSourceSize
                                                        : undefined
        source: root.currentWallpaper
        visible: status === Image.Ready || status === Image.Loading
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Math.max(0, root.configuration.TransitionDuration || 0)
                easing.type: Easing.InOutQuad
            }
        }

        onStatusChanged: {
            if (status === Image.Ready || status === Image.Null) {
                root.loading = false;
            } else if (status === Image.Error) {
                root.loading = false;
                console.warn("virtualdesktopwallpaper: failed to load",
                             source.toString());
            } else if (status === Image.Loading) {
                root.loading = true;
            }
        }
    }

    Component.onCompleted: {
        root.loading = !!currentWallpaper;
        refreshDesktopIndex();
        if (!currentWallpaper) {
            root.loading = false;
        }
    }

    // VirtualDesktopInfo often populates desktopIds a frame or two after
    // construction — re-resolve so we don't stick on index 0's image.
    Timer {
        interval: 200
        running: true
        repeat: false
        onTriggered: {
            root.refreshDesktopIndex();
            if (mainImage.status === Image.Ready || !root.currentWallpaper) {
                root.loading = false;
            }
        }
    }
}
