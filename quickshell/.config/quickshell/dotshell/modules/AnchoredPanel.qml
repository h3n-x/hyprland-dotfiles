// Popup anclado (Fase 8 B5, P8.4): la UNICA implementacion de un panel que se
// abre pegado a un elemento -- el dashboard y los desplegables de la barra, y
// mas adelante los menus del centro de configuracion (P10), de los widgets y
// de la barra vertical (P11). Reemplaza a DropdownPanel y a los cinco
// PopupWindow propios de audio, bluetooth, red, puertos y bandeja.
//
// Se abre pegado al borde de la ventana del ancla (la barra) del lado que
// diga "side"; "auto" lo deduce del borde de la barra (Tokens.bar.edge): barra
// arriba -> abajo, barra a la izquierda -> a la derecha. "align" lo alinea con
// el ancla (start, center, end a lo largo de ese lado). La posicion final la
// resuelve el compositor (xdg positioner): desliza el panel para que entre en
// la pantalla y lo voltea si del lado pedido no hay lugar. Al abrir se
// recalcula el ancla (anchor.updateAnchor): reanclar el mismo popup a otro
// elemento, como la bandeja, deja la geometria vieja si no.
//
// Abierto/cerrado vive en PopupState (popupId): uno solo en toda la shell,
// solo en la pantalla de su ancla; toggle() lo alterna. "active" dice si se ve
// de verdad (Presence): el contenido liga ahi cualquier actividad (escaneos,
// relojes). Un item dentro de un PopupWindow oculto sigue con visible = true
// (KI-L19).
//
// Alto: nunca mas que el espacio de la pantalla (maxHeight); si el contenido
// no entra, se desplaza adentro (scrollable). El dashboard maneja su propio
// desplazamiento (scrollable: false) y usa maxHeight para su vista.
//
// Pegado al marco (Fase 13 B2; bar.style "marco" y anclado a la barra): la
// tarjeta va al ras de la barra, del color del marco, sin sombra, con las
// esquinas del lado de la barra rectas y dos "orejas" concavas (FrameCorner)
// donde se junta con ella; la ventana es un radio mas ancha de cada lado para
// dibujarlas (la mascara cubre solo la tarjeta). Al abrir sale del borde de la
// barra deslizandose (la ventana la recorta), sin fundido ni escala.
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml, PopupState.qml

PopupWindow {
    id: popup
    // El elemento del que cuelga; puede cambiar entre aperturas (la bandeja
    // ancla el mismo panel al icono que se toco).
    property Item anchorItem: null
    // Ventana del ancla (la barra, o la ventana del centro de configuracion, P10).
    required property var panelWindow
    property string popupId: ""
    property string side: "auto"   // auto | below | above | left | right
    property string align: "center" // start | center | end
    default property alias content: body.data
    readonly property bool active: presence.shown

    // Margen interior, radio, duracion de entrada y altura animada: los
    // valores de un desplegable salvo que el contenido pida otros.
    property int padding: Tokens.pad.card + Tokens.space.sm
    property int cardRadius: Tokens.radius.lg
    property int enterDuration: Tokens.motion.medium
    // false si el contenido anima su propia altura (seguirla con otra
    // animacion la atrasa y recorta el contenido a mitad de camino).
    property bool animateHeight: true
    property bool scrollable: true
    // Teclas del panel (con el foco en el panel, no en un campo de texto):
    // keyHandler(event) devuelve true si la usa. Esc siempre cierra.
    property var keyHandler: null
    // Esc: escapeHandler() devuelve true si lo usa (p. ej. volver atras en
    // una vista); si no, cierra.
    property var escapeHandler: null
    signal closeRequested()

    // ---- Ventana y pantalla del ancla ------------------------------------------------------
    readonly property var hostWindow: popup.panelWindow
    readonly property var hostScreen: popup.hostWindow ? popup.hostWindow.screen : null
    readonly property string hostScreenName: popup.hostScreen ? popup.hostScreen.name : ""
    // Tamano de la anfitriona: el declarado si lo tiene (una ventana recien
    // mapeada todavia no recibio su tamano del compositor, B6), si no el real.
    readonly property real hostWidth: !popup.hostWindow ? 0 : popup.hostWindow.implicitWidth > 0 ? popup.hostWindow.implicitWidth : popup.hostWindow.width
    readonly property real hostHeight: !popup.hostWindow ? 0 : popup.hostWindow.implicitHeight > 0 ? popup.hostWindow.implicitHeight : popup.hostWindow.height
    readonly property string resolvedSide: popup.side !== "auto" ? popup.side
        : ({ top: "below", bottom: "above", left: "right", right: "left" })[Tokens.bar.edge] || "below"
    readonly property bool vertical: popup.resolvedSide === "below" || popup.resolvedSide === "above"
    // Pegado al marco: con el estilo Marco y colgado de la barra (frameHost).
    readonly property bool attached: Tokens.frame.on && !!popup.hostWindow && popup.hostWindow.frameHost === true
    readonly property int ear: popup.attached ? Tokens.frame.radius : 0

    // ---- Estado (PopupState) ---------------------------------------------------------------
    property bool open: popup.popupId !== "" && PopupState.isOpen(popup.popupId, popup.hostScreenName)
    function toggle(): void {
        PopupState.toggle(popup.popupId, popup.hostScreenName);
    }
    function close(): void {
        PopupState.close(popup.popupId);
    }
    onCloseRequested: if (popup.popupId) PopupState.close(popup.popupId)

    // Devolver el foco al panel (p. ej. al salir de un campo de texto que se
    // oculta: si no, las teclas no llegan a ningun lado).
    function focusPanel(): void {
        keys.forceActiveFocus();
    }

    Presence {
        id: presence
        enterDuration: popup.enterDuration
    }
    Connections {
        target: presence
        function onShownChanged() {
            popup.visible = presence.shown;
        }
    }
    // La ventana anfitriona puede mapearse junto con el panel (la franja del
    // dashboard sobre una pantalla completa, Fase 8 B6): el panel se ancla y
    // se muestra recien cuando la anfitriona esta en pantalla de verdad; antes
    // el compositor lo ubicaria con una geometria que todavia no existe.
    readonly property bool hostReady: !!popup.hostWindow && popup.hostWindow.backingWindowVisible
    readonly property bool showing: popup.open && popup.hostReady
    onShowingChanged: {
        if (popup.showing) popup.place();
        presence.open = popup.showing;
        if (popup.showing) keys.forceActiveFocus();
    }
    // Quickshell cierra el popup por su cuenta (clic afuera).
    onVisibleChanged: {
        if (!popup.visible && presence.shown) {
            presence.snapClosed();
            popup.closeRequested();
        }
    }

    // ---- Posicion -----------------------------------------------------------------------------
    // El rectangulo del ancla (relativo al elemento) se estira hasta el borde
    // de la ventana del lado del panel, menos el margen de la sombra: la
    // tarjeta queda al ras de la barra, no del elemento. A lo largo del lado
    // se ensancha la sombra a cada costado, asi "start"/"end" alinean la
    // tarjeta (no la ventana) con el elemento.
    function place(): void {
        // Pegado: a lo largo, las orejas; del lado de la barra, nada (al ras).
        const r = popup.attached ? popup.anchorRect(popup.anchorItem, popup.ear, 0)
                                 : popup.anchorRect(popup.anchorItem, card.shadowMargin, card.shadowMargin);
        if (!r) return;
        popup.anchor.rect = r;
        popup.anchor.updateAnchor();
    }
    // Rectangulo del ancla (relativo al elemento) hasta el borde de la ventana:
    // "along" lo ensancha a lo largo del lado (sombra u orejas a cada costado),
    // "side" compensa lo que la ventana sobra del lado del ancla (la sombra; 0
    // para un menu o pegado al marco).
    function anchorRect(item: Item, along: real, side: real): rect {
        const win = popup.hostWindow;
        if (!item || !win || !win.contentItem) return Qt.rect(0, 0, 0, 0);
        const p = item.mapToItem(win.contentItem, 0, 0);
        let r;
        switch (popup.resolvedSide) {
        case "above":
            r = Qt.rect(-along, -p.y + side, item.width + 2 * along, item.height + p.y - side);
            break;
        case "right":
            r = Qt.rect(0, -along, popup.hostWidth - p.x - side, item.height + 2 * along);
            break;
        case "left":
            r = Qt.rect(-p.x + side, -along, item.width + p.x - side, item.height + 2 * along);
            break;
        default: // below
            r = Qt.rect(-along, -side, item.width + 2 * along, popup.hostHeight - p.y);
        }
        return r;
    }
    // Menus nativos (QsMenuAnchor de la bandeja): la misma politica que el
    // panel (lado, alineacion, deslizar/voltear), sin la sombra.
    function anchorMenu(menuAnchor: var, item: Item): void {
        menuAnchor.anchor.window = popup.hostWindow;
        menuAnchor.anchor.item = item;
        menuAnchor.anchor.rect = popup.anchorRect(item, 0, 0);
        menuAnchor.anchor.edges = popup.anchor.edges;
        menuAnchor.anchor.gravity = popup.anchor.gravity;
        menuAnchor.anchor.adjustment = popup.anchor.adjustment;
        menuAnchor.anchor.updateAnchor();
    }
    // Arista del ancla y hacia donde crece el panel (xdg positioner).
    readonly property int alongStart: popup.vertical ? Edges.Left : Edges.Top
    readonly property int alongEnd: popup.vertical ? Edges.Right : Edges.Bottom
    readonly property int sideEdge: ({ below: Edges.Bottom, above: Edges.Top, right: Edges.Right, left: Edges.Left })[popup.resolvedSide]
    anchor.item: popup.anchorItem
    anchor.edges: popup.sideEdge | (popup.align === "start" ? popup.alongStart : popup.align === "end" ? popup.alongEnd : 0)
    anchor.gravity: popup.sideEdge | (popup.align === "start" ? popup.alongEnd : popup.align === "end" ? popup.alongStart : 0)
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip

    // Alto disponible: la pantalla menos la barra (si el panel sale de ella
    // hacia abajo o arriba) y los margenes.
    // heightCap: tope propio del contenido (0 = solo la pantalla).
    property int heightCap: 0
    readonly property int maxHeight: {
        const h = popup.hostScreen ? popup.hostScreen.height : 720;
        const used = popup.vertical && popup.hostWindow ? popup.hostHeight + Tokens.bar.marginTop : 0;
        const screenMax = h - used - 2 * Tokens.screenEdge;
        return popup.heightCap > 0 ? Math.min(popup.heightCap, screenMax) : screenMax;
    }
    readonly property int maxBodyHeight: popup.maxHeight - 2 * popup.padding

    readonly property int cardWidth: body.childrenRect.width + popup.padding * 2
    // Pegado: un radio de mas a cada lado a lo largo de la barra (las orejas).
    implicitWidth: popup.attached ? popup.cardWidth + (popup.vertical ? 2 * popup.ear : 0) : popup.cardWidth + card.shadowMargin * 2
    implicitHeight: popup.attached ? card.implicitHeight + (popup.vertical ? 0 : 2 * popup.ear) : card.implicitHeight + card.shadowMargin * 2
    color: "transparent"
    mask: Region { item: card }
    grabFocus: true

    // Las orejas (pegado): del lado de la barra, a cada costado de la tarjeta.
    Repeater {
        model: popup.attached ? 2 : 0
        FrameCorner {
            required property int index
            readonly property bool first: index === 0
            width: popup.ear
            height: popup.ear
            // below/above: a la izquierda y a la derecha; right/left: arriba y abajo.
            x: popup.vertical ? (first ? 0 : popup.ear + popup.cardWidth) : (popup.resolvedSide === "left" ? popup.cardWidth - popup.ear : 0)
            y: popup.vertical ? (popup.resolvedSide === "above" ? card.implicitHeight - popup.ear : 0) : (first ? 0 : popup.ear + card.implicitHeight)
            v: popup.vertical ? (popup.resolvedSide === "above" ? "bottom" : "top") : (first ? "bottom" : "top")
            h: popup.vertical ? (first ? "right" : "left") : (popup.resolvedSide === "left" ? "right" : "left")
            color: Colors.surfaceLow
            opacity: presence.progress
        }
    }

    Surface {
        id: card
        x: popup.attached ? (popup.vertical ? popup.ear : 0) : card.shadowMargin
        y: popup.attached ? (popup.vertical ? 0 : popup.ear) : card.shadowMargin
        width: popup.cardWidth
        implicitHeight: (popup.scrollable ? Math.min(body.childrenRect.height, popup.maxBodyHeight) : body.childrenRect.height) + popup.padding * 2
        Behavior on implicitHeight {
            enabled: popup.animateHeight
            NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
        }
        level: 2
        translucent: true
        framed: popup.attached
        radius: popup.cardRadius
        // Pegado: rectas las esquinas del lado de la barra.
        topLeftRadius: popup.attached && (popup.resolvedSide === "below" || popup.resolvedSide === "right") ? 0 : popup.cardRadius
        topRightRadius: popup.attached && (popup.resolvedSide === "below" || popup.resolvedSide === "left") ? 0 : popup.cardRadius
        bottomLeftRadius: popup.attached && (popup.resolvedSide === "above" || popup.resolvedSide === "right") ? 0 : popup.cardRadius
        bottomRightRadius: popup.attached && (popup.resolvedSide === "above" || popup.resolvedSide === "left") ? 0 : popup.cardRadius
        // Entrada/salida: se acerca space.sm hacia el ancla y crece desde 0.98.
        // Pegado: sale del borde de la barra (todo su tamano, recortada por la ventana).
        opacity: popup.attached ? 1 : presence.progress
        scale: popup.attached ? 1 : presence.contentScale
        transformOrigin: ({ below: Item.Top, above: Item.Bottom, right: Item.Left, left: Item.Right })[popup.resolvedSide]
        readonly property real hidden: 1 - presence.progress
        transform: Translate {
            x: popup.attached ? (popup.resolvedSide === "right" ? -card.hidden * card.width : popup.resolvedSide === "left" ? card.hidden * card.width : 0)
               : (popup.resolvedSide === "right" ? presence.offsetY : popup.resolvedSide === "left" ? -presence.offsetY : 0)
            y: popup.attached ? (popup.resolvedSide === "below" ? -card.hidden * card.implicitHeight : popup.resolvedSide === "above" ? card.hidden * card.implicitHeight : 0)
               : (popup.resolvedSide === "below" ? presence.offsetY : popup.resolvedSide === "above" ? -presence.offsetY : 0)
        }

        MouseArea { anchors.fill: parent }
        Flickable {
            id: scroller
            x: popup.padding
            y: popup.padding
            width: body.childrenRect.width
            height: card.implicitHeight - popup.padding * 2
            contentWidth: width
            contentHeight: body.childrenRect.height
            interactive: popup.scrollable && contentHeight > height
            clip: interactive
            boundsBehavior: Flickable.StopAtBounds
            Item {
                id: body
                width: childrenRect.width
                height: childrenRect.height
            }
        }
        // Esc cierra (los campos de texto de las tarjetas tienen su propio foco).
        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: {
                if (!(popup.escapeHandler && popup.escapeHandler())) popup.closeRequested();
            }
            Keys.onPressed: (event) => {
                if (popup.keyHandler && popup.keyHandler(event)) event.accepted = true;
            }
        }
    }
}
