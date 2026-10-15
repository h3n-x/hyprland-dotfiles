// Controles del reproductor (Fase 12 B2; de MediaHero, P4 B7): cinco, siempre
// en el mismo lugar (aleatorio, anterior, reproducir/pausar, siguiente,
// repetir); compact = solo los tres del medio, mas chicos (tarjeta de Inicio).
// Lo que el reproductor no admite queda atenuado y, al pasar el mouse, hint
// dice por que (la vista lo muestra donde tenga lugar).
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".." // Colors.qml, Tokens.qml, MediaState.qml, MediaColors.qml

RowLayout {
    id: root
    property MediaSession session
    property bool compact: false
    property string hint: ""
    readonly property var player: root.session ? root.session.player : null
    spacing: root.compact ? Tokens.space.xs : Tokens.space.md

    // N / P desde el teclado: el mismo empujon que el clic.
    function next(): void { nextCtl.press(); }
    function previous(): void { prevCtl.press(); }

    component Control: Item {
        id: ctl
        property string icon
        property string altIcon: ""     // play/pause: los dos iconos se cruzan
        property bool showAlt: false
        property bool on: false
        property bool big: false
        property bool usable: true
        property string label: ""
        property int nudge: 0           // anterior/siguiente: pequeno empujon al usarlo
        signal clicked()
        function press(): void {
            if (!ctl.usable) return;
            if (ctl.nudge !== 0 && Tokens.motion.scale > 0) nudgeAnim.restart();
            ctl.clicked();
        }
        readonly property int side: root.compact ? (ctl.big ? Tokens.control.md : Tokens.control.sm)
                                                 : (ctl.big ? Tokens.px(56) : Tokens.px(40))
        implicitWidth: ctl.side
        implicitHeight: ctl.side

        Rectangle {
            id: face
            anchors.fill: parent
            radius: ctl.big && !root.compact ? Tokens.radius.lg : width / 2
            // El grande lleva el acento de la portada (B4; sin uno valido, el de siempre).
            color: ctl.big ? MediaColors.accent : (ctl.on ? Colors.accentAltContainer : "transparent")
            opacity: ctl.usable ? 1 : 0.35
            scale: ctlMouse.pressed && ctl.usable ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }
            transform: Translate { id: shove; x: 0 }

            StateLayer {
                hovered: ctlMouse.containsMouse && ctl.usable
                pressed: ctlMouse.pressed && ctl.usable
                contentColor: ctl.big ? MediaColors.onAccent : Colors.text
            }
            Icon {
                anchors.centerIn: parent
                name: ctl.icon
                filled: ctl.big || ctl.on
                size: ctl.big && !root.compact ? Tokens.icon.lg : Tokens.icon.md
                color: ctl.big ? MediaColors.onAccent : (ctl.on ? Colors.textOnAccentAltContainer : Colors.textMuted)
                opacity: ctl.altIcon && ctl.showAlt ? 0 : 1
                scale: ctl.altIcon && ctl.showAlt ? 0.6 : 1
                Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                Behavior on scale { NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            }
            Icon {
                visible: !!ctl.altIcon
                anchors.centerIn: parent
                name: ctl.altIcon
                filled: true
                size: ctl.big && !root.compact ? Tokens.icon.lg : Tokens.icon.md
                color: ctl.big ? MediaColors.onAccent : Colors.textMuted
                opacity: ctl.showAlt ? 1 : 0
                scale: ctl.showAlt ? 1 : 0.6
                Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                Behavior on scale { NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            }
        }
        SequentialAnimation {
            id: nudgeAnim
            NumberAnimation { target: shove; property: "x"; to: ctl.nudge; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
            NumberAnimation { target: shove; property: "x"; to: 0; duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
        }
        MouseArea {
            id: ctlMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: ctl.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onContainsMouseChanged: {
                const name = root.session ? root.session.playerName : "";
                if (ctlMouse.containsMouse && !ctl.usable) root.hint = I18n.tr("Not available in %1: %2", name, ctl.label);
                else if (!ctlMouse.containsMouse && root.hint.endsWith(ctl.label)) root.hint = "";
            }
            onClicked: ctl.press()
        }
    }

    Control {
        visible: !root.compact
        icon: "shuffle"
        label: I18n.trc("media control", "shuffle")
        usable: !!root.player && root.player.shuffleSupported
        on: !!root.player && root.player.shuffleSupported && root.player.shuffle
        onClicked: MediaState.toggleShuffle()
    }
    Control {
        id: prevCtl
        icon: "skip_previous"
        label: I18n.trc("media control", "previous")
        nudge: -4
        usable: !!root.player && root.player.canGoPrevious
        onClicked: MediaState.previous()
    }
    Control {
        big: true
        icon: "play_arrow"
        altIcon: "pause"
        showAlt: !!root.player && root.player.isPlaying
        label: I18n.tr("play or pause")
        usable: !!root.player && root.player.canTogglePlaying
        onClicked: MediaState.togglePlaying()
    }
    Control {
        id: nextCtl
        icon: "skip_next"
        label: I18n.trc("media control", "next")
        nudge: 4
        usable: !!root.player && root.player.canGoNext
        onClicked: MediaState.next()
    }
    Control {
        visible: !root.compact
        icon: root.player && root.player.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
        label: I18n.trc("media control", "repeat")
        usable: !!root.player && root.player.loopSupported
        on: !!root.player && root.player.loopSupported && root.player.loopState !== MprisLoopState.None
        onClicked: MediaState.cycleLoop()
    }
}
