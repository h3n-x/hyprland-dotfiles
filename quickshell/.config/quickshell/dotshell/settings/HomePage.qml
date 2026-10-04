// Inicio del centro de configuracion (Fase 10 B1): el tema actual (fondo,
// esquema y contraste; "Cambiar fondo" abre la galeria, "Opciones de tema"
// lleva a Apariencia), tres opciones rapidas y "Tus cambios": cada opcion
// cambiada con su valor, el de fabrica y volver; clic en una lleva a su fila.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

ColumnLayout {
    id: page

    required property SettingsModel model
    // Ir a una pagina o a una opcion (SettingsWindow).
    signal openPage(string id)
    signal reveal(string key)

    readonly property var quickKeys: ["accessibility.reduceMotion", "appearance.transparency", "accessibility.highContrast"]
        .filter(k => !!page.model.keys[k])
    // Cambiadas, en el orden de las paginas.
    readonly property var changed: {
        const out = [];
        for (const c of page.model.categories)
            for (const k of page.model.byCategory[c.id] || [])
                if (SettingsState.modified.indexOf(k) >= 0) out.push(k);
        return out;
    }

    spacing: Tokens.space.lg

    Text {
        text: "Inicio"
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.display
        font.weight: Tokens.weight.semibold
    }

    // ---- Tema actual ----------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: themeRow.implicitHeight + 2 * Tokens.space.lg
        radius: Tokens.radius.lg
        color: Colors.surface
        border.color: Colors.divider
        RowLayout {
            id: themeRow
            x: Tokens.space.lg
            y: Tokens.space.lg
            width: parent.width - 2 * Tokens.space.lg
            spacing: Tokens.space.xl
            ClippingRectangle {
                implicitWidth: 224
                implicitHeight: 126
                radius: Tokens.radius.md
                color: Colors.surfaceHigh
                Image {
                    anchors.fill: parent
                    source: Colors.image ? "file://" + Colors.image : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 448
                    asynchronous: true
                    cache: false
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.xs
                Text {
                    text: "Tema actual"
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
                Text {
                    Layout.fillWidth: true
                    text: (Colors.image || "").split("/").pop() || "Sin fondo"
                    elide: Text.ElideMiddle
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.headline
                    font.weight: Tokens.weight.semibold
                }
                Text {
                    Layout.fillWidth: true
                    text: "Esquema " + page.model.format("appearance.scheme", SettingsState.value("appearance.scheme")).toLowerCase()
                        + " · contraste " + page.model.format("appearance.contrast", SettingsState.value("appearance.contrast")).toLowerCase()
                    elide: Text.ElideRight
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                }
                Row {
                    Layout.topMargin: Tokens.space.sm
                    spacing: Tokens.space.sm
                    Button {
                        activeFocusOnTab: true
                        main: true
                        icon: "wallpaper"
                        label: "Cambiar fondo"
                        onClicked: Quickshell.execDetached(["qs", "-c", "dotshell", "ipc", "call", "gallery", "open"])
                    }
                    Button {
                        activeFocusOnTab: true
                        icon: "palette"
                        label: "Opciones de tema"
                        onClicked: page.openPage("appearance")
                    }
                }
            }
        }
    }

    // ---- Rapido ----------------------------------------------------------------------------
    Text {
        Layout.topMargin: Tokens.space.sm
        Layout.leftMargin: Tokens.space.xs
        text: "Rápido"
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
        font.weight: Tokens.weight.semibold
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: quick.implicitHeight
        radius: Tokens.radius.lg
        color: Colors.surface
        border.color: Colors.divider
        Column {
            id: quick
            width: parent.width
            Repeater {
                model: page.quickKeys
                Column {
                    id: qcell
                    required property string modelData
                    required property int index
                    width: quick.width
                    Rectangle { visible: qcell.index > 0; x: Tokens.space.lg; width: parent.width - 2 * Tokens.space.lg; height: 1; color: Colors.divider }
                    SettingRow { width: parent.width; key: qcell.modelData; model: page.model }
                }
            }
        }
    }

    // ---- Tus cambios -------------------------------------------------------------------------
    Text {
        Layout.topMargin: Tokens.space.sm
        Layout.leftMargin: Tokens.space.xs
        text: "Tus cambios" + (page.changed.length ? " (" + page.changed.length + ")" : "")
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
        font.weight: Tokens.weight.semibold
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: page.changed.length ? changes.implicitHeight : emptyText.implicitHeight + 2 * Tokens.space.lg
        radius: Tokens.radius.lg
        color: Colors.surface
        border.color: Colors.divider
        Text {
            id: emptyText
            visible: page.changed.length === 0
            x: Tokens.space.lg
            anchors.verticalCenter: parent.verticalCenter
            text: "Todo está como de fábrica."
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
        }
        Column {
            id: changes
            width: parent.width
            Repeater {
                model: page.changed
                Column {
                    id: ch
                    required property string modelData
                    required property int index
                    readonly property var meta: page.model.keys[ch.modelData] || ({})
                    width: changes.width
                    Rectangle { visible: ch.index > 0; x: Tokens.space.lg; width: parent.width - 2 * Tokens.space.lg; height: 1; color: Colors.divider }
                    Item {
                        width: parent.width
                        height: Math.max(Tokens.row.heightLarge + Tokens.space.md, chInfo.implicitHeight + 2 * Tokens.space.md)
                        StateLayer { radius: Tokens.radius.lg; hovered: chMouse.containsMouse; pressed: chMouse.pressed }
                        MouseArea {
                            id: chMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.reveal(ch.modelData)
                        }
                        RowLayout {
                            x: Tokens.space.lg
                            width: parent.width - 2 * Tokens.space.lg
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Tokens.space.md
                            ColumnLayout {
                                id: chInfo
                                Layout.fillWidth: true
                                spacing: Tokens.space.hair
                                Text {
                                    Layout.fillWidth: true
                                    text: ch.meta.label || ch.modelData
                                    elide: Text.ElideRight
                                    color: Colors.text
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.body
                                    font.weight: Tokens.weight.medium
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: page.model.categoryLabel(ch.meta.category) + " · de fábrica: " + page.model.format(ch.modelData, ch.meta.default)
                                    elide: Text.ElideRight
                                    color: Colors.textMuted
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.caption
                                }
                            }
                            Text {
                                Layout.maximumWidth: 260
                                text: page.model.format(ch.modelData, SettingsState.value(ch.modelData))
                                elide: Text.ElideMiddle
                                color: Colors.text
                                font.family: Tokens.font.ui
                                font.pixelSize: Tokens.type.body
                                font.weight: Tokens.weight.semibold
                            }
                            Rectangle {
                                id: undoBtn
                                implicitWidth: Tokens.pill.height
                                implicitHeight: Tokens.pill.height
                                radius: width / 2
                                color: "transparent"
                                activeFocusOnTab: true
                                Keys.onReturnPressed: SettingsState.reset(ch.modelData)
                                Keys.onSpacePressed: SettingsState.reset(ch.modelData)
                                StateLayer { hovered: undoMouse.containsMouse; pressed: undoMouse.pressed; focused: undoBtn.activeFocus }
                                Icon { anchors.centerIn: parent; name: "undo"; size: Tokens.icon.sm; color: Colors.textMuted }
                                MouseArea {
                                    id: undoMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SettingsState.reset(ch.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
