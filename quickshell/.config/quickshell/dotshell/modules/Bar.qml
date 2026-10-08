// Barra principal (Fase 11 B1): la disposicion viene del almacen
// (bar.layout: izquierda, centro y derecha; cada elemento es un modulo
// "bare", una pildora con uno o mas modulos o un espaciador) y se edita en
// Configuracion -> Barra. El centro va al centro de la pantalla de verdad;
// izquierda y derecha ocupan los costados. Cada modulo es el de siempre
// (BarEntry elige el componente por id); una pildora sin modulos visibles no
// queda como una burbuja vacia.
//
// Volume.qml y Backlight.qml no estan en la barra: corren sin UI en
// shell.qml y disparan el OSD.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, FullscreenState.qml, DashboardState.qml

PanelWindow {
    id: bar

    // En cualquier borde (bar.edge, Fase 11 B3): pegada a ese borde y a lo largo
    // de el. Geometria del design system (D14): el grosor (40), 8 hacia el
    // borde y 12 en los extremos -- el mismo gaps_out de Hyprland, asi los
    // bordes de la barra quedan alineados con los de las ventanas.
    readonly property string edge: Tokens.bar.edge
    readonly property bool vertical: Tokens.bar.vertical
    anchors {
        top: bar.edge !== "bottom"
        bottom: bar.edge !== "top"
        left: bar.edge !== "right"
        right: bar.edge !== "left"
    }
    implicitHeight: bar.vertical ? 0 : Tokens.bar.height
    implicitWidth: bar.vertical ? Tokens.bar.height : 0
    margins {
        top: bar.edge === "top" ? Tokens.bar.marginTop : bar.vertical ? Tokens.bar.marginSide : 0
        bottom: bar.edge === "bottom" ? Tokens.bar.marginTop : bar.vertical ? Tokens.bar.marginSide : 0
        left: bar.edge === "left" ? Tokens.bar.marginTop : bar.vertical ? 0 : Tokens.bar.marginSide
        right: bar.edge === "right" ? Tokens.bar.marginTop : bar.vertical ? 0 : Tokens.bar.marginSide
    }
    color: "transparent"
    // SUPER+SHIFT+B (ver binds.lua + shell.qml) -- toggle global, afecta a
    // todas las pantallas a la vez (BarVisibility es un singleton); y solo en
    // las pantallas elegidas (bar.screens, Fase 11 B1; vacio = todas).
    // bar.peek (Fase 11 B3b): solo mientras se mantiene Super (tras bar.peekDelay).
    // Encima (bar.peekMode "overlay"): no reserva lugar y lleva fondo de panel
    // para leerse sobre lo abierto. Empujar ("push"): reserva su lugar mientras se
    // ve y Hyprland acomoda las ventanas (Auto: el lugar sale del tamano; Normal
    // usaria exclusiveZone, 0, y no reservaria nada).
    readonly property bool peek: SettingsState.value("bar.peek") === true
    readonly property bool peekOverlay: bar.peek && SettingsState.value("bar.peekMode") !== "push"
    // La pantalla se copia una vez: al mostrarse, la ventana vuelve a anunciar
    // screen y leerlo aca seria un bucle de enlaces (en cada aparicion con peek).
    property var home: null
    Component.onCompleted: bar.home = bar.screen
    readonly property bool barShown: !BarVisibility.hidden && BarVisibility.onScreen(bar.home) && (!bar.peek || BarVisibility.peekShown)
    visible: bar.barShown
    exclusionMode: bar.peekOverlay ? ExclusionMode.Ignore : ExclusionMode.Auto

    readonly property var lay: SettingsState.value("bar.layout") || ({ "start": [], "center": [], "end": [] })
    readonly property bool startSpacer: bar.lay.start.indexOf("spacer") >= 0
    readonly property bool endSpacer: bar.lay.end.indexOf("spacer") >= 0

    // Sólida (bar.style, Fase 11 B3b): un solo fondo pegado al borde.
    Rectangle {
        anchors.fill: parent
        visible: Tokens.bar.style === "solid" && !bar.peekOverlay
        color: Colors.surfaceLow
    }
    // Encima de las ventanas (bar.peek, modo "overlay"): un panel para que se lea
    // sobre lo abierto, sea cual sea el estilo (sin sombra: la ventana mide justo la barra).
    Surface {
        anchors.fill: parent
        visible: bar.peekOverlay
        level: 2
        radius: Tokens.bar.style === "solid" ? 0 : Tokens.radius.lg
        shadowEnabled: false
    }

    // Contenedor de las tres secciones (el dashboard se ancla aca).
    Item {
        id: layout
        anchors.fill: parent

        // Inicio (izquierda o arriba): desde el borde hasta el centro.
        GridLayout {
            id: startRow
            flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: bar.vertical ? -1 : 1
            columns: bar.vertical ? 1 : -1
            rowSpacing: Tokens.space.sm
            columnSpacing: Tokens.space.sm
            x: bar.vertical ? (parent.width - width) / 2 : 0
            y: bar.vertical ? 0 : (parent.height - height) / 2
            // Si no entra, crece hacia el centro (lo del borde nunca queda fuera de la pantalla).
            width: bar.vertical ? implicitWidth : Math.max(implicitWidth, centerRow.x - Tokens.space.sm)
            height: bar.vertical ? Math.max(implicitHeight, centerRow.y - Tokens.space.sm) : implicitHeight
            Repeater {
                model: bar.lay.start
                delegate: itemC
            }
            // Sin espaciador propio, lo del inicio queda pegado al borde.
            Item { visible: !bar.startSpacer; Layout.fillWidth: !bar.vertical; Layout.fillHeight: bar.vertical }
        }

        // Centro: al centro de la pantalla de verdad si hay lugar; si el inicio o
        // el fin no le dejan, se corre lo justo para que nada lo tape (una barra
        // vertical en una pantalla baja: 720 px logicos).
        GridLayout {
            id: centerRow
            flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: bar.vertical ? -1 : 1
            columns: bar.vertical ? 1 : -1
            rowSpacing: Tokens.space.sm
            columnSpacing: Tokens.space.sm
            readonly property real ideal: bar.vertical ? (parent.height - height) / 2 : (parent.width - width) / 2
            readonly property real lo: (bar.vertical ? startRow.implicitHeight : startRow.implicitWidth) + Tokens.space.sm
            readonly property real hi: (bar.vertical ? parent.height - endRow.implicitHeight - height : parent.width - endRow.implicitWidth - width) - Tokens.space.sm
            readonly property real along: Math.max(lo, Math.min(ideal, hi))
            x: bar.vertical ? (parent.width - width) / 2 : along
            y: bar.vertical ? along : (parent.height - height) / 2
            Repeater {
                model: bar.lay.center
                delegate: itemC
            }
        }

        // Fin (derecha o abajo): desde el centro hasta el borde.
        GridLayout {
            id: endRow
            flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: bar.vertical ? -1 : 1
            columns: bar.vertical ? 1 : -1
            rowSpacing: Tokens.space.sm
            columnSpacing: Tokens.space.sm
            x: bar.vertical ? (parent.width - width) / 2 : parent.width - width
            y: bar.vertical ? parent.height - height : (parent.height - height) / 2
            width: bar.vertical ? implicitWidth : Math.max(implicitWidth, parent.width - centerRow.x - centerRow.width - Tokens.space.sm)
            height: bar.vertical ? Math.max(implicitHeight, parent.height - centerRow.y - centerRow.height - Tokens.space.sm) : implicitHeight
            Item { visible: !bar.endSpacer; Layout.fillWidth: !bar.vertical; Layout.fillHeight: bar.vertical }
            Repeater {
                model: bar.lay.end
                delegate: itemC
            }
        }
    }

    // ---- Informacion al pasar el raton (bar.tooltips, Fase 11 B2b) ------------------------
    property Item tipItem: null
    function tip(item: var): void {
        bar.tipItem = item;
        if (item) tipDelay.restart();
        else { tipDelay.stop(); tipWin.visible = false; }
    }
    Timer {
        id: tipDelay
        interval: 500
        onTriggered: if (bar.tipItem && bar.tipItem.tooltip) tipWin.visible = true
    }
    PopupWindow {
        id: tipWin
        visible: false
        color: "transparent"
        anchor.window: bar
        // Del lado libre de la barra, centrada en el modulo.
        readonly property point at: bar.tipItem ? bar.tipItem.mapToItem(layout, bar.tipItem.width / 2, bar.tipItem.height / 2) : Qt.point(0, 0)
        anchor.rect.x: bar.vertical ? (bar.edge === "left" ? bar.width + Tokens.space.xs : -tipWin.implicitWidth - Tokens.space.xs)
            : tipWin.at.x - tipWin.implicitWidth / 2
        anchor.rect.y: bar.vertical ? tipWin.at.y - tipWin.implicitHeight / 2
            : (bar.edge === "bottom" ? -tipWin.implicitHeight - Tokens.space.xs : bar.height + Tokens.space.xs)
        implicitWidth: tipText.implicitWidth + 2 * Tokens.space.md
        implicitHeight: tipText.implicitHeight + 2 * Tokens.space.sm
        Rectangle {
            anchors.fill: parent
            radius: Tokens.radius.sm
            color: Colors.surfaceHigh
            border.color: Colors.divider
            Text {
                id: tipText
                anchors.centerIn: parent
                text: bar.tipItem ? bar.tipItem.tooltip : ""
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
        }
    }

    // ---- Rueda sobre la barra (bar.scroll, Fase 11 B2b) ---------------------------------
    // Fuera de los escritorios (su propia rueda va primero): volumen o brillo,
    // con los mismos comandos que las teclas (el tope de media.volumeLimit).
    WheelHandler {
        target: layout
        enabled: ["volume", "brightness"].indexOf(SettingsState.value("bar.scroll")) >= 0
        onWheel: (event) => {
            const up = event.angleDelta.y > 0;
            if (SettingsState.value("bar.scroll") === "volume")
                Quickshell.execDetached(["wpctl", "set-volume", "-l", String(SettingsState.value("media.volumeLimit") || 1),
                    "@DEFAULT_AUDIO_SINK@", up ? "5%+" : "5%-"]);
            else
                Quickshell.execDetached(["brightnessctl", "-e4", "-n2", "set", up ? "5%+" : "5%-"]);
        }
    }

    // Un elemento de una seccion: espaciador, modulo "bare" o pildora.
    Component {
        id: itemC
        Loader {
            id: slot
            required property var modelData
            readonly property bool shown: !!slot.item && slot.item.shown === true
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: !bar.vertical && slot.modelData === "spacer"
            Layout.fillHeight: bar.vertical && slot.modelData === "spacer"
            visible: slot.modelData === "spacer" || slot.shown
            sourceComponent: slot.modelData === "spacer" ? spacerC : typeof slot.modelData === "string" ? bareC : pillC
            onLoaded: slot.item.data_ = slot.modelData
        }
    }
    Component {
        id: spacerC
        Item { property var data_; readonly property bool shown: true }
    }
    Component {
        id: bareC
        BarEntry {
            property var data_
            mid: typeof data_ === "string" ? data_ : ""
            panelWindow: bar
        }
    }
    Component {
        id: pillC
        Pill {
            id: pill
            property var data_
            readonly property var ids: data_ && data_.pill ? data_.pill : []
            readonly property bool shown: pill.parts.some(c => c.shown === true)
            // A un costado, mas juntos (Fase 11 B3): en una pantalla baja (720 px
            // logicos) la disposicion de fabrica no entraria con 12 entre iconos.
            spacing: pill.ids.length > 1 ? (bar.vertical ? Tokens.space.sm : Tokens.space.md) : Tokens.gap.inline
            vertical: bar.vertical
            hovered: pill.parts.some(c => c.wholePill === true && c.hovered)
            pressed: pill.parts.some(c => c.wholePill === true && c.pressed)
            Repeater {
                model: pill.ids
                BarEntry {
                    required property string modelData
                    mid: modelData
                    panelWindow: bar
                }
            }
        }
    }

    // Dashboard (Fase 4 B7): uno por barra, centrado bajo ella (no depende de
    // ningun modulo: se abre solo con SUPER+A).
    // Sobre una pantalla completa (Fase 8 B6, D3-A) cuelga de una franja
    // invisible en la capa Overlay con la misma geometria que la barra: el
    // dashboard se ve encima y la barra sigue tapada. Entrar o salir de
    // pantalla completa lo cierra antes de cambiar de anfitriona
    // (FullscreenState).
    // Sin barra en esta pantalla (oculta, o no elegida en bar.screens) cuelga
    // de la misma franja, para que SUPER+A funcione igual.
    readonly property bool overFullscreen: !!bar.screen && FullscreenState.isFullscreen(bar.screen.name)
    readonly property bool hosted: bar.overFullscreen || !bar.barShown
    Dashboard {
        anchorItem: bar.hosted ? fsAnchor : layout
        panelWindow: bar.hosted ? fsHost : bar
    }
    // La franja existe solo mientras el dashboard esta abierto encima de la
    // pantalla completa (o sin barra); sin input (mascara vacia) ni teclado.
    PanelWindow {
        id: fsHost
        screen: bar.screen
        visible: bar.hosted && DashboardState.visible && DashboardState.screen === bar.screen.name
        // La misma geometria que la barra, en su borde.
        anchors {
            top: bar.anchors.top
            bottom: bar.anchors.bottom
            left: bar.anchors.left
            right: bar.anchors.right
        }
        implicitHeight: bar.implicitHeight
        implicitWidth: bar.implicitWidth
        margins {
            top: bar.margins.top
            bottom: bar.margins.bottom
            left: bar.margins.left
            right: bar.margins.right
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
