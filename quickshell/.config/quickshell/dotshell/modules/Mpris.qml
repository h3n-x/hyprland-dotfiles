// Pill multimedia de la barra: la vista compacta del reproductor (Fase 4 B5).
// Solo se muestra si hay un reproductor MPRIS; muestra el mismo reproductor
// que el dashboard y las teclas multimedia (MediaState.active). Clic central:
// pausa/reanuda (el dashboard se abre unicamente con SUPER+A, Fase 4 B7).
// Presentacion neutra:
// mismo icono Material Symbols para cualquier reproductor, sin iconos de la
// app (desktop entry).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, MediaState.qml

Item {
    id: root
    readonly property var player: MediaState.active
    // Condicion de datos para el Pill contenedor (ver Bar.qml). No usar
    // "visible" para eso: en QML visible es la visibilidad EFECTIVA -- si el
    // Pill arranca oculto (la lista de reproductores llega unos ms despues
    // del arranque), el hijo reporta false por tener al padre oculto y el
    // Pill no vuelve a mostrarse nunca (deadlock).
    readonly property bool active: !!root.player
    visible: root.active

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // RowLayout (no Row) a proposito: el icono (16px) y el texto (13px)
    // tienen alturas distintas, y Row no deja usar Layout.alignment /
    // anchors por hijo para centrarlos -- ver el mismo problema que se
    // encontro y se corrigio en Volume.qml.
    // Estado sin animaciones permanentes: sonando = ecualizador en el color
    // primario y titulo pleno; en pausa = icono de pausa y titulo atenuado.
    // Al cambiar de estado, un unico pulso corto; al cambiar de cancion, el
    // titulo se funde. Titulo con ancho maximo y "..." (no estira la barra).
    readonly property bool playing: !!root.player && root.player.isPlaying
    readonly property string title: root.player ? (root.player.trackTitle || "Sin título") : ""
    onPlayingChanged: if (Tokens.motion.scale > 0) pulse.restart()
    onTitleChanged: if (Tokens.motion.scale > 0) titleFade.restart()

    RowLayout {
        id: row
        spacing: Tokens.gap.inline

        Icon {
            id: stateIcon
            Layout.alignment: Qt.AlignVCenter
            name: root.playing ? "equalizer" : "pause"
            filled: true
            size: Tokens.icon.sm
            color: root.playing ? Colors.m3primary : Colors.m3onSurfaceVariant
            Behavior on color { ColorAnimation { duration: Tokens.motion.short } }
            SequentialAnimation {
                id: pulse
                NumberAnimation { target: stateIcon; property: "scale"; to: 1.25; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
                NumberAnimation { target: stateIcon; property: "scale"; to: 1; duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            }
        }

        Text {
            id: titleText
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 240
            color: root.playing ? Colors.m3onSurface : Colors.m3onSurfaceVariant
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            font.weight: Tokens.weight.medium
            elide: Text.ElideRight
            // Solo el titulo -- sin artista, a pedido del usuario.
            text: root.title
            Behavior on color { ColorAnimation { duration: Tokens.motion.short } }
            SequentialAnimation {
                id: titleFade
                NumberAnimation { target: titleText; property: "opacity"; from: 0.2; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            }
        }
    }

    // Accion unica: la Pill que lo contiene se ilumina entera (Bar.qml, Q2 = A).
    readonly property bool hovered: hoverArea.containsMouse
    readonly property bool pressed: hoverArea.pressed

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: MediaState.togglePlaying()
    }
}
