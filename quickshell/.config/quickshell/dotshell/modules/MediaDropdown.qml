// Desplegable del media hub (Fase 4 B5): la tarjeta completa (MediaCard)
// bajo la pill de la barra. Mismo patron que AudioDropdown.qml (Presence,
// grabFocus, clic afuera cierra); se alinea al borde izquierdo de la pill.
// Abierto/cerrado vive en MediaState (hubOpen + hubScreen) para que la pill,
// el IPC "media" y un clic afuera digan lo mismo.
//
// Teclado (tiene el foco mientras esta abierto): Espacio reproduce/pausa,
// izquierda/derecha buscan -/+10 s, Esc cierra. La altura se anima cuando
// cambia el contenido (chips, lineas).
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml, MediaState.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow

    readonly property bool shouldShow: MediaState.hubOpen
        && !!popup.panelWindow && !!popup.panelWindow.screen && MediaState.hubScreen === popup.panelWindow.screen.name

    Presence { id: presence }
    Connections {
        target: presence
        function onShownChanged() {
            popup.visible = presence.shown;
        }
    }
    onShouldShowChanged: {
        presence.open = popup.shouldShow;
        if (popup.shouldShow) keys.forceActiveFocus();
    }
    // Quickshell cierra el popup por su cuenta (clic afuera): cerrar al
    // instante y avisar al estado.
    onVisibleChanged: {
        if (!popup.visible && presence.shown) {
            presence.snapClosed();
            MediaState.closeHub();
        }
    }

    readonly property int cardWidth: Tokens.panel.widthLg + Tokens.space.xl
    implicitWidth: popup.cardWidth + card.shadowMargin * 2
    implicitHeight: card.implicitHeight + card.shadowMargin * 2
    color: "transparent"
    mask: Region { item: card }
    grabFocus: true

    anchor.window: popup.panelWindow
    function absoluteX(item) {
        let x = 0;
        let cur = item;
        while (cur && cur !== popup.panelWindow.contentItem) {
            x += cur.x;
            cur = cur.parent;
        }
        return x;
    }
    anchor.rect.x: {
        if (!popup.anchorItem || !popup.panelWindow || !popup.panelWindow.contentItem) return 0;
        return Math.max(0, popup.absoluteX(popup.anchorItem) - card.shadowMargin);
    }
    anchor.rect.y: popup.panelWindow ? popup.panelWindow.height - card.shadowMargin : 0

    // Nivel de elevacion 2, como los otros desplegables de la barra.
    Surface {
        id: card
        x: card.shadowMargin
        y: card.shadowMargin
        width: popup.cardWidth
        implicitHeight: mediaCard.implicitHeight + (Tokens.pad.card + Tokens.space.xs) * 2
        Behavior on implicitHeight { NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
        level: 2
        translucent: true
        radius: Tokens.radius.lg
        opacity: presence.progress
        scale: presence.contentScale
        transformOrigin: Item.Top
        transform: Translate { y: presence.offsetY }

        MediaCard {
            id: mediaCard
            anchors.fill: parent
            anchors.margins: Tokens.pad.card + Tokens.space.xs
            active: presence.shown
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: (event) => {
                const p = MediaState.active;
                if (event.key === Qt.Key_Space) {
                    if (!event.isAutoRepeat) MediaState.togglePlaying();
                } else if (event.key === Qt.Key_Left && p) {
                    MediaState.seek(p.position - 10);
                } else if (event.key === Qt.Key_Right && p) {
                    MediaState.seek(p.position + 10);
                } else if (event.key === Qt.Key_Escape) {
                    MediaState.closeHub();
                } else {
                    return;
                }
                event.accepted = true;
            }
        }
    }
}
