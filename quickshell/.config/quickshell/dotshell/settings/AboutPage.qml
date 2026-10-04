// Acerca de (Fase 10 B1): versiones (se leen una vez, al abrir la pagina),
// Diagnostico (lo que el motor dejo en cuarentena: SettingsState.problems),
// "Ver como archivo" (tus cambios en la forma de settings.json con los valores
// en uso, armados desde SettingsState: nadie lee ese archivo salvo el motor)
// y el README.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

ColumnLayout {
    id: page

    required property SettingsModel model
    readonly property string repo: Quickshell.env("HOME") + "/Dotfiles"
    property string dotfiles: "…"
    property string quickshell: "…"
    property string hyprland: "…"
    property bool showFile: false

    readonly property var fileView: {
        const v = {};
        for (const k of SettingsState.modified) v[k] = SettingsState.value(k);
        return JSON.stringify({ values: v }, null, 2);
    }

    spacing: Tokens.space.lg

    // Versiones: tres procesos cortos, una vez.
    Process {
        running: true
        command: ["sh", "-c", "git -C \"$1\" rev-parse --abbrev-ref HEAD && git -C \"$1\" rev-parse --short HEAD", "sh", page.repo]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n");
                page.dotfiles = l.length === 2 ? "rama " + l[0] + " · " + l[1] : "sin datos";
            }
        }
    }
    Process {
        running: true
        command: ["qs", "--version"]
        stdout: StdioCollector {
            onStreamFinished: page.quickshell = (this.text.match(/Quickshell\s+([^\s]+)/) || [, "sin datos"])[1]
        }
    }
    Process {
        running: true
        command: ["hyprctl", "version", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const v = JSON.parse(this.text);
                    page.hyprland = v.version || v.tag || "sin datos";
                } catch (e) {
                    page.hyprland = "sin datos";
                }
            }
        }
    }

    Text {
        text: "Acerca de"
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.display
        font.weight: Tokens.weight.semibold
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: info.implicitHeight + 2 * Tokens.space.lg
        radius: Tokens.radius.lg
        color: Colors.surface
        border.color: Colors.divider
        ColumnLayout {
            id: info
            x: Tokens.space.lg
            y: Tokens.space.lg
            width: parent.width - 2 * Tokens.space.lg
            spacing: Tokens.space.sm
            Repeater {
                model: [
                    ["Dotfiles", page.dotfiles],
                    ["Quickshell", page.quickshell],
                    ["Hyprland", page.hyprland],
                    ["Opciones", Object.keys(page.model.keys).length + " en " + page.model.categories.length + " páginas · "
                        + (SettingsState.modified.length === 1 ? "1 cambiada" : SettingsState.modified.length + " cambiadas")]
                ]
                delegate: Item {
                    id: cellItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.max(k.implicitHeight, v.implicitHeight)
                    Text {
                        id: k
                        width: 140
                        text: cellItem.modelData[0]
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                    }
                    Text {
                        id: v
                        x: 140 + Tokens.space.xl
                        width: parent.width - x
                        text: cellItem.modelData[1]
                        elide: Text.ElideRight
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.features: Tokens.tabularNumbers
                    }
                }
            }
        }
    }

    Text {
        Layout.topMargin: Tokens.space.sm
        Layout.leftMargin: Tokens.space.xs
        text: "Diagnóstico"
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
        font.weight: Tokens.weight.semibold
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: diag.implicitHeight + 2 * Tokens.space.lg
        radius: Tokens.radius.lg
        color: Colors.surface
        border.color: Colors.divider
        ColumnLayout {
            id: diag
            x: Tokens.space.lg
            y: Tokens.space.lg
            width: parent.width - 2 * Tokens.space.lg
            spacing: Tokens.space.md
            // Estado con icono y texto (el color solo no alcanza, C4).
            RowLayout {
                spacing: Tokens.space.sm
                Icon {
                    name: SettingsState.problems.length ? "warning" : "check_circle"
                    filled: true
                    color: SettingsState.problems.length ? Colors.warning : Colors.success
                }
                Text {
                    text: SettingsState.problems.length === 0 ? "Opciones válidas: ningún problema"
                        : SettingsState.problems.length === 1 ? "1 problema: no se aplica, se usa el valor de fábrica"
                        : SettingsState.problems.length + " problemas: no se aplican, se usan los valores de fábrica"
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                }
            }
            Repeater {
                model: SettingsState.problems
                Text {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.icon.md + Tokens.space.sm
                    text: (modelData.key ? (page.model.keys[modelData.key] ? page.model.keys[modelData.key].label : modelData.key) + ": " : "") + modelData.reason
                    wrapMode: Text.WordWrap
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
            }
            Row {
                spacing: Tokens.space.sm
                Button {
                    activeFocusOnTab: true
                    icon: "data_object"
                    label: page.showFile ? "Ocultar el archivo" : "Ver como archivo"
                    onClicked: page.showFile = !page.showFile
                }
                Button {
                    activeFocusOnTab: true
                    icon: "description"
                    label: "Abrir el README"
                    onClicked: Quickshell.execDetached(["xdg-open", page.repo + "/README.md"])
                }
            }
            // Tus cambios como quedan en el archivo (solo lectura).
            Rectangle {
                visible: page.showFile
                Layout.fillWidth: true
                implicitHeight: fileCol.implicitHeight + 2 * Tokens.space.md
                radius: Tokens.radius.md
                color: Colors.surfaceLow
                border.color: Colors.divider
                Column {
                    id: fileCol
                    x: Tokens.space.md
                    y: Tokens.space.md
                    width: parent.width - 2 * Tokens.space.md
                    spacing: Tokens.space.xs
                    Text {
                        text: "Tus cambios, con los valores en uso · " + SettingsState.userPath.replace(Quickshell.env("HOME"), "~")
                        color: Colors.textMuted
                        font.family: Tokens.font.mono
                        font.pixelSize: Tokens.type.caption
                    }
                    TextEdit {
                        width: parent.width
                        readOnly: true
                        selectByMouse: true
                        text: page.fileView
                        wrapMode: TextEdit.Wrap
                        color: Colors.text
                        selectionColor: Colors.accentContainer
                        selectedTextColor: Colors.textOnAccentContainer
                        font.family: Tokens.font.mono
                        font.pixelSize: Tokens.type.label
                    }
                }
            }
        }
    }
}
