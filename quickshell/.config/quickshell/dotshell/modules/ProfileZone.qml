// Zona Perfil de Inicio (Fase 11 B5, P11.6): el avatar (~/.face), un saludo
// segun la hora y, si se quiere, el equipo y cuanto lleva encendido. Ancha:
// ademas el sistema y el kernel. El nombre es dashboard.profile.name o, vacio,
// el de la cuenta (el nombre completo de /etc/passwd, si no el usuario).
//
// Todo se lee al abrir el dashboard (archivos chicos, una vez): nada corre
// mientras esta abierto ni cerrado.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml, SettingsState.qml

Item {
    id: root
    // El dashboard se ve (al abrirlo se releen la hora y el tiempo encendido).
    property bool active: false
    property bool wide: false
    readonly property real ideal: row.implicitHeight

    readonly property string user: Quickshell.env("USER") || ""
    property string fullName: ""
    property string host: ""
    property string distro: ""
    property string kernel: ""
    property real uptime: 0
    property date now: new Date()

    readonly property string chosen: SettingsState.value("dashboard.profile.name") || ""
    readonly property string name: root.chosen || root.fullName || root.user
    readonly property bool showSystem: SettingsState.value("dashboard.profile.showSystem") !== false
    readonly property string greeting: {
        const h = root.now.getHours();
        return h >= 6 && h < 12 ? "Buenos días" : h >= 12 && h < 20 ? "Buenas tardes" : "Buenas noches";
    }

    function refresh(): void {
        root.now = new Date();
        uptimeFile.reload();
    }
    onActiveChanged: if (root.active) root.refresh()
    Component.onCompleted: root.refresh()

    FileView {
        path: "/etc/passwd"
        printErrors: false
        onLoaded: {
            const line = this.text().split("\n").find(l => l.startsWith(root.user + ":"));
            const gecos = line ? (line.split(":")[4] || "").split(",")[0].trim() : "";
            root.fullName = gecos.split(/\s+/)[0] || "";
        }
    }
    FileView {
        path: "/etc/hostname"
        printErrors: false
        onLoaded: root.host = this.text().trim()
    }
    FileView {
        path: root.wide ? "/etc/os-release" : ""
        printErrors: false
        onLoaded: {
            const m = this.text().match(/^PRETTY_NAME="?([^"\n]*)"?/m);
            root.distro = m ? m[1] : "";
        }
    }
    FileView {
        path: root.wide ? "/proc/sys/kernel/osrelease" : ""
        printErrors: false
        onLoaded: root.kernel = this.text().trim()
    }
    FileView {
        id: uptimeFile
        path: root.showSystem ? "/proc/uptime" : ""
        printErrors: false
        onLoaded: root.uptime = Number(this.text().split(" ")[0]) || 0
    }

    RowLayout {
        id: row
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space.lg

        Avatar {
            size: root.wide ? Tokens.px(72) : Tokens.px(56)
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.greeting + ","
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.name
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.display
                font.weight: Tokens.weight.semibold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.space.xs
                visible: root.showSystem
                // Compacta: solo el tiempo encendido (el equipo, en la ancha).
                text: root.wide
                    ? root.user + (root.host ? "@" + root.host : "") + (root.uptime > 0 ? " · encendido hace " + I18n.duration(root.uptime) : "")
                    : root.uptime > 0 ? "Encendido hace " + I18n.duration(root.uptime) : root.host
                color: Colors.border
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                elide: Text.ElideRight
            }
        }
        // Ancha: el sistema, a la derecha.
        ColumnLayout {
            visible: root.wide && root.showSystem && !!root.distro
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.space.xs
            Text {
                Layout.alignment: Qt.AlignRight
                text: root.distro
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.medium
            }
            Text {
                Layout.alignment: Qt.AlignRight
                text: root.kernel
                color: Colors.border
                font.family: Tokens.font.mono
                font.pixelSize: Tokens.type.caption
            }
        }
    }
}
