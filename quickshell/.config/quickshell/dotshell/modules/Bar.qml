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
    // todas las pantallas a la vez (BarVisibility es un singleton); y solo en
    // las pantallas elegidas (bar.screens, Fase 11 B1; vacio = todas).
    readonly property bool barShown: !BarVisibility.hidden && BarVisibility.onScreen(bar.screen)
    visible: bar.barShown

    readonly property var lay: SettingsState.value("bar.layout") || ({ "start": [], "center": [], "end": [] })
    readonly property bool startSpacer: bar.lay.start.indexOf("spacer") >= 0
    readonly property bool endSpacer: bar.lay.end.indexOf("spacer") >= 0

    // Contenedor de las tres secciones (el dashboard se ancla aca).
    Item {
        id: layout
        anchors.fill: parent

        RowLayout {
            id: startRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, centerRow.x - Tokens.space.sm)
            spacing: Tokens.space.sm
            Repeater {
                model: bar.lay.start
                delegate: itemC
            }
            // Sin espaciador propio, lo de la izquierda queda pegado a la izquierda.
            Item { visible: !bar.startSpacer; Layout.fillWidth: true }
        }

        RowLayout {
            id: centerRow
            anchors.centerIn: parent
            spacing: Tokens.space.sm
            Repeater {
                model: bar.lay.center
                delegate: itemC
            }
        }

        RowLayout {
            id: endRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - centerRow.x - centerRow.width - Tokens.space.sm)
            spacing: Tokens.space.sm
            Item { visible: !bar.endSpacer; Layout.fillWidth: true }
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
        anchor.rect.x: bar.tipItem ? bar.tipItem.mapToItem(layout, bar.tipItem.width / 2, 0).x - tipWin.implicitWidth / 2 : 0
        anchor.rect.y: bar.height + Tokens.space.xs
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
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: slot.modelData === "spacer"
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
            spacing: pill.ids.length > 1 ? Tokens.space.md : Tokens.gap.inline
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
