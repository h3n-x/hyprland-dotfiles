// Miniatura de un workspace (Fase 4 B7): la pantalla real a escala. Fondo de
// pantalla actual (el mismo archivo que Wallpaper.qml), la barra, y cada
// ventana en su geometria real con la decoracion de Hyprland: gaps, rounding
// y borde (activo con los colores de col.active_border), todo leido de
// Hyprland (DesktopState), no copiado. Ventanas flotantes arriba; las
// pestanas ocultas de un grupo no se dibujan.
//
// En Inicio cada ventana lleva el icono de su aplicacion (limpio a este
// tamano). En la vista Escritorios (detailed) cada ventana es su captura
// (WindowPreview, una vez al abrir), pasar el mouse muestra su titulo y un
// clic va a esa ventana; la usada justo antes lleva una marca.
// En los dos, la ventana del reproductor que suena lleva el ecualizador.
//
// Movimiento: una ventana nueva aparece con un fundido; si cambia el
// mosaico mientras se ve, las ventanas se deslizan a su lugar.
import QtQuick
import QtQuick.Effects
import Quickshell
import ".." // Colors.qml, Tokens.qml, DesktopState.qml, AppInfo.qml

Item {
    id: thumb
    // HyprlandWorkspace o marcador { id, placeholder: true } (DesktopState.slots).
    required property var slot
    // Pantalla del dashboard: la de un marcador y la de respaldo.
    property string screenName: ""
    // Seleccion del teclado o mouse encima: se levanta un poco.
    property bool selected: false
    // Elegida (se esta cambiando a este workspace) / las demas, veladas.
    property bool chosen: false
    property bool veiled: false
    // El dashboard se ve: solo entonces se animan los cambios.
    property bool live: false
    // Vista Escritorios: capturas, titulo al pasar el mouse, clic por ventana.
    property bool detailed: false
    signal picked()
    signal windowPicked(string address)

    readonly property int wsId: thumb.slot.id
    readonly property bool placeholder: !!thumb.slot.placeholder
    readonly property string monitorName: !thumb.placeholder && thumb.slot.monitor ? thumb.slot.monitor.name : thumb.screenName
    readonly property var mon: DesktopState.monitors[thumb.monitorName]
        || DesktopState.monitors[thumb.screenName]
        || { width: 1280, height: 720, reserved: [0, 0, 0, 0] }
    readonly property real k: thumb.width / thumb.mon.width
    readonly property var deco: DesktopState.decoration
    readonly property var wins: DesktopState.windows
        .filter(w => w.wsId === thumb.wsId && !w.hidden)
        .sort((a, b) => (a.floating ? 1 : 0) - (b.floating ? 1 : 0))
    readonly property bool empty: thumb.wins.length === 0
    readonly property bool hovered: hover.hovered

    implicitHeight: Math.round(thumb.mon.height * thumb.k)

    scale: thumb.chosen ? 1.04 : (thumb.selected || thumb.hovered) ? 1.03 : 1
    Behavior on scale { NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter } }
    z: thumb.chosen ? 2 : (thumb.selected || thumb.hovered) ? 1 : 0

    // ---- Pantalla -----------------------------------------------------------------
    Item {
        id: screenArea
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: screenMask
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.m3surfaceContainerLowest
        }
        Image {
            anchors.fill: parent
            source: Colors.image ? "file://" + Colors.image : ""
            fillMode: Image.PreserveAspectCrop
            // Decodificado chico una vez por fondo (lo comparten las miniaturas).
            sourceSize: Qt.size(320, 180)
            asynchronous: true
            smooth: true
        }
        // Vacio: el fondo velado, para que no compita con los que tienen ventanas.
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colors.m3scrim, thumb.empty ? 0.68 : 0.08)
            Behavior on color { ColorAnimation { duration: Tokens.motion.short } }
        }

        // La barra: tres grupos como la de verdad (izquierda, reloj, derecha).
        Item {
            x: Tokens.bar.marginSide * thumb.k
            y: Tokens.bar.marginTop * thumb.k
            width: parent.width - 2 * Tokens.bar.marginSide * thumb.k
            height: Math.max(3, Tokens.pill.height * thumb.k)
            readonly property color pill: Qt.alpha(Colors.m3surfaceContainerLow, 0.9)
            Rectangle { width: parent.width * 0.2; height: parent.height; radius: height / 2; color: parent.pill }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width * 0.09; height: parent.height; radius: height / 2; color: parent.pill }
            Rectangle { anchors.right: parent.right; width: parent.width * 0.26; height: parent.height; radius: height / 2; color: parent.pill }
        }

        // Ventanas.
        Repeater {
            model: thumb.wins
            Item {
                id: win
                required property var modelData
                readonly property real bw: Math.max(1, thumb.deco.border * thumb.k)
                readonly property real r: Math.max(2, thumb.deco.rounding * thumb.k)
                readonly property var borderColors: win.modelData.focused
                    ? (thumb.deco.active.length ? thumb.deco.active : [Colors.m3primary])
                    : (thumb.deco.inactive.length ? thumb.deco.inactive : [Colors.m3outlineVariant])
                x: win.modelData.x * thumb.k
                y: win.modelData.y * thumb.k
                width: win.modelData.w * thumb.k
                height: win.modelData.h * thumb.k
                Behavior on x { enabled: thumb.live; NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                Behavior on y { enabled: thumb.live; NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                Behavior on width { enabled: thumb.live; NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                Behavior on height { enabled: thumb.live; NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

                // Aparece con un fundido si se abre mientras se ve.
                opacity: 1
                Component.onCompleted: if (thumb.live && Tokens.motion.scale > 0) appear.start()
                NumberAnimation { id: appear; target: win; property: "opacity"; from: 0; to: 1; duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }

                // Borde (degradado de Hyprland; horizontal a esta escala).
                Rectangle {
                    anchors.fill: parent
                    radius: win.r
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: win.borderColors[0] }
                        GradientStop { position: 1; color: win.borderColors[win.borderColors.length - 1] }
                    }
                }
                Rectangle {
                    id: winFace
                    anchors.fill: parent
                    anchors.margins: win.bw
                    radius: Math.max(1, win.r - win.bw)
                    color: win.modelData.focused ? Colors.m3surfaceContainerHigh : Qt.alpha(Colors.m3surfaceContainer, 0.94)
                    // Con captura: recortada a las esquinas de la ventana.
                    layer.enabled: thumb.detailed
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: winMask
                    }
                    // Solo en la vista Escritorios se captura (en Inicio, nada).
                    WindowPreview {
                        visible: thumb.detailed
                        capture: thumb.detailed
                        anchors.fill: parent
                        address: win.modelData.address
                        cls: win.modelData.cls
                        capturable: win.modelData.capturable
                        constraintSize: Qt.size(winFace.width * 2, winFace.height * 2)
                        iconSize: Math.min(40, winFace.height * 0.5)
                    }
                }
                Item {
                    id: winMask
                    anchors.fill: winFace
                    visible: false
                    layer.enabled: thumb.detailed
                    Rectangle {
                        anchors.fill: parent
                        radius: winFace.radius
                    }
                }
                Image {
                    visible: !thumb.detailed
                    anchors.centerIn: parent
                    width: Math.min(22, parent.height * 0.5, parent.width * 0.5)
                    height: width
                    sourceSize: Qt.size(44, 44)
                    source: AppInfo.icon(win.modelData.cls)
                    asynchronous: true
                }
                // Marcas: reproductor sonando; la ventana usada justo antes.
                Row {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Math.max(2, win.bw + 2)
                    spacing: 3
                    Rectangle {
                        visible: DesktopState.mediaWindow === win.modelData.address
                        width: thumb.detailed ? 22 : 14
                        height: width
                        radius: width / 2
                        color: Colors.m3primary
                        Icon { anchors.centerIn: parent; name: "equalizer"; filled: true; size: parent.width - 6; color: Colors.m3onPrimary }
                    }
                    Rectangle {
                        visible: thumb.detailed && win.modelData.history === 1
                        width: 22
                        height: 22
                        radius: 11
                        color: Qt.alpha(Colors.m3surfaceContainerHighest, 0.92)
                        Icon { anchors.centerIn: parent; name: "history"; size: 16; color: Colors.m3onSurfaceVariant }
                    }
                }
                // Titulo al pasar el mouse (vista Escritorios).
                Rectangle {
                    visible: thumb.detailed && winMouse.containsMouse
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: win.bw + 2
                    height: winTitle.implicitHeight + 8
                    radius: Tokens.radius.xs
                    color: Qt.alpha(Colors.m3surfaceContainerHighest, 0.94)
                    Text {
                        id: winTitle
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        verticalAlignment: Text.AlignVCenter
                        text: win.modelData.title
                        color: Colors.m3onSurface
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: winMouse
                    anchors.fill: parent
                    enabled: thumb.detailed
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: thumb.windowPicked(win.modelData.address)
                }
            }
        }

        Icon {
            anchors.centerIn: parent
            visible: thumb.empty
            name: "add"
            size: Tokens.icon.sm
            color: Colors.m3onSurface
        }

        // Seleccion del teclado: la misma capa de estado que el foco en M3.
        Rectangle {
            anchors.fill: parent
            color: Colors.m3onSurface
            opacity: thumb.selected ? Tokens.stateLayer.focus * 1.6 : 0
            Behavior on opacity { NumberAnimation { duration: Tokens.motion.fast } }
        }

        // Elegido otro workspace: este se apaga con un velo del color de la superficie.
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colors.m3surfaceContainer, 0.72)
            opacity: thumb.veiled ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
        }
    }
    Item {
        id: screenMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: Tokens.radius.sm
        }
    }

    // Numero del workspace (abajo a la izquierda).
    Rectangle {
        x: Tokens.space.xs
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.space.xs
        width: 16
        height: 16
        radius: 8
        color: Qt.alpha(Colors.m3surfaceContainerHighest, 0.9)
        opacity: thumb.veiled ? 0.4 : 1
        Text {
            anchors.centerIn: parent
            text: thumb.wsId
            color: Colors.m3onSurfaceVariant
            font.family: Tokens.font.ui
            font.pixelSize: 10
            font.weight: Tokens.weight.semibold
        }
    }
    // Urgente: punto en el color de error (como en la barra).
    Rectangle {
        visible: thumb.wins.some(w => w.urgent)
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.space.xs
        width: 8
        height: 8
        radius: 4
        color: Colors.m3error
    }

    // Clic en el fondo: el workspace (debajo de las ventanas, que en la vista
    // Escritorios tienen su propio clic). El hover no bloquea a nadie.
    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: thumb.picked()
    }
}
