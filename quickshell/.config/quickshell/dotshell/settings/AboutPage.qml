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
    // Fuentes elegidas que ya no estan instaladas (Fase 10 B2): la shell usa
    // la de fabrica (StoreBindings) y aca se dice.
    readonly property var missingFonts: {
        const fams = Qt.fontFamilies();
        return ["appearance.font.ui", "appearance.font.mono"]
            .filter(k => SettingsState.isModified(k) && fams.indexOf(SettingsState.value(k)) < 0)
            .map(k => I18n.tr("%1: “%2” isn't installed; the default is used", (page.model.keys[k] || {}).label, SettingsState.value(k)));
    }
    readonly property int issues: SettingsState.problems.length + page.missingFonts.length

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
                page.dotfiles = l.length === 2 ? I18n.tr("branch %1 · %2", l[0], l[1]) : I18n.tr("no data");
            }
        }
    }
    Process {
        running: true
        command: ["qs", "--version"]
        stdout: StdioCollector {
            onStreamFinished: page.quickshell = (this.text.match(/Quickshell\s+([^\s]+)/) || [, I18n.tr("no data")])[1]
        }
    }
    Process {
        running: true
        command: ["hyprctl", "version", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const v = JSON.parse(this.text);
                    page.hyprland = v.version || v.tag || I18n.tr("no data");
                } catch (e) {
                    page.hyprland = I18n.tr("no data");
                }
            }
        }
    }

    Text {
        text: I18n.tr("About")
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
                    ["Dotfiles", page.dotfiles], // i18n-ok
                    ["Quickshell", page.quickshell], // i18n-ok
                    ["Hyprland", page.hyprland], // i18n-ok
                    [I18n.tr("Options"), I18n.tr("%1 on %2 pages · %3", I18n.number(Object.keys(page.model.keys).length), I18n.number(page.model.categories.length),
                        I18n.trn("%n changed", "%n changed", SettingsState.modified.length))]
                ]
                delegate: Item {
                    id: cellItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.max(k.implicitHeight, v.implicitHeight)
                    Text {
                        id: k
                        width: Tokens.px(140)
                        text: cellItem.modelData[0]
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                    }
                    Text {
                        id: v
                        x: Tokens.px(140) + Tokens.space.xl
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
        text: I18n.tr("Diagnostics")
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
                    name: page.issues ? "warning" : "check_circle"
                    filled: true
                    color: page.issues ? Colors.warning : Colors.success
                }
                Text {
                    text: page.issues === 0 ? I18n.tr("Valid options: no problems")
                        : I18n.trn("%n problem: it isn't applied, the default value is used", "%n problems: they aren't applied, the default values are used", page.issues)
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                }
            }
            Repeater {
                model: page.missingFonts
                Text {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.icon.md + Tokens.space.sm
                    text: modelData
                    wrapMode: Text.WordWrap
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
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
                    label: page.showFile ? I18n.tr("Hide the file") : I18n.tr("View as a file")
                    onClicked: page.showFile = !page.showFile
                }
                Button {
                    activeFocusOnTab: true
                    icon: "description"
                    label: I18n.tr("Open the README")
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
                        text: I18n.tr("Your changes, with the values in use · %1", SettingsState.userPath.replace(Quickshell.env("HOME"), "~"))
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
