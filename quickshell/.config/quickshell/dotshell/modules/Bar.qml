// Barra principal. Layout a pedido del usuario:
// izquierda: pill de workspaces, pill de mpris (solo titulo) -- separados.
// centro: reloj (toggle hora/fecha al click, ver Clock.qml).
// derecha, en pills separados: (update, bandeja, microfono) / (bateria,
// idle inhibitor) -- y power, aparte, al final del todo.
//
// Se sacaron (a pedido) cpu/memoria/temperatura/gpu/distro -- ver plan de
// migracion para el detalle de por que se habian agregado. Volume.qml y
// Backlight.qml TAMBIEN se sacaron de aca (ya esta el OSD, ver Osd.qml) --
// pero siguen corriendo, instanciados sin UI en shell.qml, porque son los
// que disparan ese OSD (Pipewire/FileView + OsdState.show()).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, FullscreenState.qml, DashboardState.qml

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    // Geometria del design system (D14): 40 de alto, 8 arriba y 12 a los
    // costados -- el mismo gaps_out de Hyprland, asi los bordes de la barra
    // quedan alineados con los de las ventanas.
    implicitHeight: Tokens.bar.height
    margins {
        top: Tokens.bar.marginTop
        left: Tokens.bar.marginSide
        right: Tokens.bar.marginSide
    }
    color: "transparent"
    // SUPER+SHIFT+B (ver binds.lua + shell.qml) -- toggle global, afecta a
    // todas las pantallas a la vez (BarVisibility es un singleton).
    visible: !BarVisibility.hidden

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Tokens.space.sm

        Pill {
            Layout.alignment: Qt.AlignVCenter
            Workspaces { Layout.alignment: Qt.AlignVCenter }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            // Sin esto, con el reproductor cerrado quedaria una "burbuja"
            // vacia (el Item de Mpris.qml se pone invisible, pero Row
            // igual le reserva su espacio -- ver el mismo tema en Pill.qml).
            // No se importa Quickshell.Services.Mpris aca para leer esto
            // directo porque ese modulo exporta un singleton TAMBIEN
            // llamado "Mpris" que chocaria con este componente local del
            // mismo nombre (mismo problema que IdleInhibitor, ver
            // IdleToggle.qml) -- se expone la visibilidad del propio
            // componente en su lugar.
            visible: mprisModule.shown
            // Accion unica: la pill entera responde al hover (Q2 = A).
            hovered: mprisModule.hovered
            pressed: mprisModule.pressed
            Mpris { id: mprisModule; Layout.alignment: Qt.AlignVCenter }
        }

        Item { Layout.fillWidth: true }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            Clock { Layout.alignment: Qt.AlignVCenter }
        }

        Item { Layout.fillWidth: true }

        // Solo mientras se graba (y un momento al terminar), Fase 4 B8.
        RecordingPill { Layout.alignment: Qt.AlignVCenter }

        // Cada modulo se puede ocultar (bar.show.*, Fase 10 B4); la pill sin
        // nada visible adentro no queda como una burbuja vacia.
        Pill {
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.space.md
            visible: updMod.shown || netMod.shown || btMod.shown || trayMod.shown || micMod.shown
            Update { id: updMod; Layout.alignment: Qt.AlignVCenter }
            Network { id: netMod; Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
            Bluetooth { id: btMod; Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
            Tray { id: trayMod; Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
            Microphone { id: micMod; Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.space.md
            visible: batMod.shown || idleMod.shown || portsMod.shown
            Battery { id: batMod; Layout.alignment: Qt.AlignVCenter }
            IdleToggle { id: idleMod; Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
            Ports { id: portsMod; Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
        }

        Power {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Dashboard (Fase 4 B7): uno por barra, centrado bajo ella (no depende de
    // ningun modulo: se abre solo con SUPER+A).
    // Sobre una pantalla completa (Fase 8 B6, D3-A) cuelga de una franja
    // invisible en la capa Overlay con la misma geometria que la barra: el
    // dashboard se ve encima y la barra sigue tapada. Entrar o salir de
    // pantalla completa lo cierra antes de cambiar de anfitriona
    // (FullscreenState).
    readonly property bool overFullscreen: !!bar.screen && FullscreenState.isFullscreen(bar.screen.name)
    Dashboard {
        anchorItem: bar.overFullscreen ? fsAnchor : layout
        panelWindow: bar.overFullscreen ? fsHost : bar
    }
    // La franja existe solo mientras el dashboard esta abierto encima de la
    // pantalla completa; sin input (mascara vacia) ni teclado.
    PanelWindow {
        id: fsHost
        screen: bar.screen
        visible: bar.overFullscreen && DashboardState.visible && DashboardState.screen === bar.screen.name
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Tokens.bar.height
        margins {
            top: Tokens.bar.marginTop
            left: Tokens.bar.marginSide
            right: Tokens.bar.marginSide
        }
        color: "transparent"
        mask: Region {}
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-host"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: fsAnchor
            x: layout.x
            y: layout.y
            width: layout.width
            height: layout.height
        }
    }
}
