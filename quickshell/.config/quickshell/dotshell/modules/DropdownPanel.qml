// Base de los desplegables de la barra con tarjetas (Fase 4 B6; B7 la
// reutiliza para el dashboard): PopupWindow anclado bajo un elemento de la
// barra (izquierda, centro o derecha), tarjeta de elevacion 2, apertura y
// cierre con Presence, clic afuera y Esc cierran, altura animada cuando cambia
// el contenido. El contenido (las tarjetas) se pone como hijo.
//
// "active" dice si el panel se ve de verdad (Presence): el contenido debe
// ligar a eso cualquier actividad (relojes, temporizadores). Un item dentro de
// un PopupWindow oculto sigue con visible = true (KI-L19).
//
// Abierto/cerrado vive afuera (open + closeRequested): el estado del panel lo
// decide un singleton (DashboardState, MediaState...), no la ventana.
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow
    property bool open: false
    property string alignment: "center" // left | center | right
    default property alias content: body.data
    readonly property bool active: presence.shown
    readonly property int cardWidth: body.childrenRect.width + Tokens.pad.card * 2 + Tokens.space.sm * 2
    // Teclas del panel (con el foco en el panel, no en un campo de texto):
    // keyHandler(event) devuelve true si la usa. Esc siempre cierra.
    property var keyHandler: null
    signal closeRequested()
    // Devolver el foco al panel (p. ej. al salir de un campo de texto que se
    // oculta: si no, las teclas no llegan a ningun lado).
    function focusPanel(): void {
        keys.forceActiveFocus();
    }

    Presence { id: presence }
    Connections {
        target: presence
        function onShownChanged() {
            popup.visible = presence.shown;
        }
    }
    onOpenChanged: {
        presence.open = popup.open;
        if (popup.open) keys.forceActiveFocus();
    }
    // Quickshell cierra el popup por su cuenta (clic afuera).
    onVisibleChanged: {
        if (!popup.visible && presence.shown) {
            presence.snapClosed();
            popup.closeRequested();
        }
    }

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
        const ax = popup.absoluteX(popup.anchorItem);
        const w = popup.cardWidth;
        const x = popup.alignment === "left" ? ax
            : popup.alignment === "right" ? ax + popup.anchorItem.width - w
            : ax + popup.anchorItem.width / 2 - w / 2;
        const maxX = popup.panelWindow.width - w;
        return Math.max(0, Math.min(maxX, x)) - card.shadowMargin;
    }
    anchor.rect.y: popup.panelWindow ? popup.panelWindow.height - card.shadowMargin : 0

    Surface {
        id: card
        x: card.shadowMargin
        y: card.shadowMargin
        width: popup.cardWidth
        implicitHeight: body.childrenRect.height + Tokens.pad.card * 2 + Tokens.space.sm * 2
        Behavior on implicitHeight { NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
        level: 2
        translucent: true
        radius: Tokens.radius.lg
        opacity: presence.progress
        scale: presence.contentScale
        transformOrigin: Item.Top
        transform: Translate { y: presence.offsetY }

        MouseArea { anchors.fill: parent }
        Item {
            id: body
            x: Tokens.pad.card + Tokens.space.sm
            y: Tokens.pad.card + Tokens.space.sm
            width: childrenRect.width
            height: childrenRect.height
        }
        // Esc cierra (los campos de texto de las tarjetas tienen su propio foco).
        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: popup.closeRequested()
            Keys.onPressed: (event) => {
                if (popup.keyHandler && popup.keyHandler(event)) event.accepted = true;
            }
        }
    }
}
