// Ventana activa en la barra (Fase 11 B2; no esta en la barra de fabrica,
// se agrega desde el editor): icono de la aplicacion y titulo, recortado a
// bar.activeWindow.maxWidth. Sin ventana enfocada, no se muestra. Solo
// informa: sin clic.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, AppInfo.qml

Item {
    id: root
    // La ventana enfocada (asignable en las pruebas: offscreen no hay toplevels).
    property var toplevel: ToplevelManager.activeToplevel
    readonly property bool shown: !!root.toplevel && !!(root.toplevel.title || root.toplevel.appId)
    visible: shown
    // Texto de la informacion al pasar el raton (bar.tooltips, Fase 11 B2b).
    readonly property string tooltip: root.toplevel ? (root.toplevel.title || "") : ""

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    BarFlow {
        id: row
        spacing: Tokens.space.sm
        IconImage {
            implicitSize: Tokens.icon.sm
            source: root.toplevel && root.toplevel.appId ? AppInfo.icon(root.toplevel.appId) : ""
        }
        // A un costado (Fase 11 B3): solo el icono de la aplicacion.
        Text {
            visible: !Tokens.bar.vertical
            width: Math.min(implicitWidth, SettingsState.value("bar.activeWindow.maxWidth") || 320)
            text: root.toplevel ? (root.toplevel.title || AppInfo.name(root.toplevel.appId)) : ""
            elide: Text.ElideRight
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
    }
}
