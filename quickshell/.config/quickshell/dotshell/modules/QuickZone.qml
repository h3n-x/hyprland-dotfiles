// Zona Accesos rapidos de Inicio (Fase 11 B5, P11.6): las aplicaciones de
// dashboard.quick.apps (ids de desktop entries, en orden) y las carpetas de
// dashboard.quick.folders (vacio: las carpetas personales de user-dirs.dirs).
// Clic abre y cierra el dashboard; el nombre de la app bajo el raton va en
// el titulo. Las listas se editan en un solo lugar, el
// centro de configuracion ("+" lleva ahi, D-B5-4).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, SettingsState.qml, AppInfo.qml, DashboardState.qml

ColumnLayout {
    id: root
    property bool wide: false
    readonly property real ideal: root.implicitHeight
    spacing: Tokens.space.sm

    readonly property string home: Quickshell.env("HOME")
    readonly property var appIds: SettingsState.value("dashboard.quick.apps") || []
    readonly property var apps: root.appIds.map(id => ({ id: id, entry: AppInfo.entry(id) })).filter(a => !!a.entry)
    property string hoveredName: ""
    readonly property var chosenFolders: SettingsState.value("dashboard.quick.folders") || []
    // Carpetas personales (XDG), leidas solo si no se eligio ninguna.
    property var xdg: ({})
    readonly property var folders: root.chosenFolders.length ? root.chosenFolders
        : [root.home].concat(["DOWNLOAD", "DOCUMENTS", "PICTURES"].map(k => root.xdg[k]).filter(p => !!p && p !== root.home))

    FileView {
        path: root.chosenFolders.length ? "" : root.home + "/.config/user-dirs.dirs"
        printErrors: false
        onLoaded: {
            const out = {};
            for (const line of this.text().split("\n")) {
                const m = line.match(/^XDG_([A-Z]+)_DIR="(.*)"\s*$/);
                if (m) out[m[1]] = m[2].replace(/^\$HOME/, root.home);
            }
            root.xdg = out;
        }
    }

    function launch(entry: var): void {
        DashboardState.close();
        entry.execute();
    }
    function openFolder(path: string): void {
        DashboardState.close();
        Quickshell.execDetached(["xdg-open", path]);
    }
    function edit(key: string): void {
        DashboardState.close();
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-ui", "open", key]);
    }
    function folderName(p: string): string {
        if (p === root.home) return I18n.tr("Home folder");
        const parts = p.replace(/\/+$/, "").split("/");
        return parts[parts.length - 1] || p;
    }
    function folderIcon(p: string): string {
        if (p === root.home) return "home";
        if (p === root.xdg.DOWNLOAD) return "download";
        if (p === root.xdg.DOCUMENTS) return "description";
        if (p === root.xdg.PICTURES) return "image";
        if (p === root.xdg.MUSIC) return "music_note";
        if (p === root.xdg.VIDEOS) return "movie";
        return "folder";
    }

    ZoneTitle {
        Layout.fillWidth: true
        text: I18n.tr("Quick access")
        // El nombre de la app bajo el raton (sin ventana emergente).
        detail: root.hoveredName
    }

    // Aplicaciones: iconos; el nombre aparece al pasar el raton.
    Flow {
        Layout.fillWidth: true
        spacing: Tokens.space.xs
        Repeater {
            model: root.apps
            Rectangle {
                id: app
                required property var modelData
                width: Tokens.px(44)
                height: Tokens.px(44)
                radius: Tokens.radius.md
                color: "transparent"
                StateLayer { hovered: appMouse.containsMouse; pressed: appMouse.pressed }
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: Tokens.px(32)
                    source: AppInfo.entryIcon(app.modelData.entry)
                }
                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(app.modelData.entry)
                    onContainsMouseChanged: root.hoveredName = appMouse.containsMouse ? app.modelData.entry.name : ""
                }
            }
        }
        // Agregar (o la invitacion, sin ninguna): al centro, a la lista.
        Rectangle {
            width: root.apps.length ? Tokens.px(44) : addRow.implicitWidth + Tokens.space.lg * 2
            height: Tokens.px(44)
            radius: Tokens.radius.md
            color: "transparent"
            border.color: Colors.divider
            StateLayer { hovered: addMouse.containsMouse; pressed: addMouse.pressed }
            Row {
                id: addRow
                anchors.centerIn: parent
                spacing: Tokens.space.xs
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "add"; size: Tokens.icon.sm; color: Colors.textMuted }
                Text {
                    visible: !root.apps.length
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("Pin applications")
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
            }
            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.edit("dashboard.quick.apps")
            }
        }
    }
    // Carpetas: fichas con icono y nombre.
    Flow {
        Layout.fillWidth: true
        spacing: Tokens.space.xs
        Repeater {
            model: root.folders
            Rectangle {
                id: folder
                required property string modelData
                height: Tokens.px(32)
                width: Math.min(folderRow.implicitWidth + Tokens.space.md * 2, root.width)
                radius: Tokens.radius.pill(height)
                color: "transparent"
                border.color: Colors.divider
                StateLayer { hovered: folderMouse.containsMouse; pressed: folderMouse.pressed }
                Row {
                    id: folderRow
                    anchors.centerIn: parent
                    spacing: Tokens.space.xs
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: root.folderIcon(folder.modelData); size: Tokens.icon.sm; color: Colors.textMuted }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, root.width - 3 * Tokens.space.md - Tokens.icon.sm)
                        elide: Text.ElideRight
                        text: root.folderName(folder.modelData)
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                }
                MouseArea {
                    id: folderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openFolder(folder.modelData)
                }
            }
        }
    }
    // Junto a una zona mas alta: lo de arriba queda arriba.
    Item { Layout.fillHeight: true }
}
