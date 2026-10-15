// Vista previa de capturas y marcas de grabacion (Fase 4 B8). Una instancia
// por pantalla (shell.qml); solo se muestra en la pantalla de la captura
// (CaptureState.screen).
//
// Tras una captura: destello sobre la zona capturada (120 ms), la imagen vuela
// desde ahi hasta su lugar en la tarjeta por un arco (Bezier cuadratica con
// Tokens.motion.easeEmphasized) y la tarjeta se forma alrededor. Movimiento
// reducido, grabaciones o captura sin zona: la tarjeta aparece sin mas.
// La tarjeta (abajo a la derecha, sin tomar el foco del teclado) se va a los
// 6 s, en pausa mientras el puntero esta encima; una captura nueva la reemplaza.
//
// Mientras se graba una zona: cuatro marcas en las esquinas, justo afuera de
// la zona (no salen en el video), estaticas y sin input.
//
// Coste: la ventana de la tarjeta solo existe mientras se ve; la imagen se
// decodifica una vez (compartida con la miniatura). Sin nada que mostrar no
// hay ventanas.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, CaptureState.qml

Scope {
    id: root
    property ShellScreen screen

    readonly property string screenName: root.screen ? root.screen.name : ""

    PanelWindow {
        id: win
        screen: root.screen

        readonly property var cap: CaptureState.current
        readonly property bool onThisScreen: CaptureState.screen === root.screenName
        readonly property bool wanted: CaptureState.shown && win.onThisScreen && !!win.cap
        // idle | flash (destello y vuelo) | card
        property string phase: "idle"
        // Aparicion de la tarjeta: 0 = no esta, 1 = formada. Animacion propia
        // (no Presence): cada captura nueva la reinicia desde 0 al instante.
        property real cp: 0
        readonly property bool motion: Tokens.motion.scale > 0

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        // Input solo sobre la tarjeta ya formada.
        mask: Region { item: win.phase === "card" ? cardSlot : null }
        visible: win.phase !== "idle"

        // Zona capturada en coordenadas de esta pantalla.
        readonly property rect from: {
            const c = win.cap;
            if (!c || !c.hasRegion || !root.screen) return Qt.rect(0, 0, 0, 0);
            return Qt.rect(c.x - root.screen.x, c.y - root.screen.y, c.w, c.h);
        }
        // Destino del vuelo: donde se dibuja la imagen en la tarjeta formada.
        readonly property rect to: Qt.rect(cardSlot.x + card.x + thumb.x + thumb.imageRect.x,
                                           cardSlot.y + card.y + thumb.y + thumb.imageRect.y,
                                           thumb.imageRect.width, thumb.imageRect.height)

        function begin(): void {
            sequence.stop();
            cardIn.stop();
            cardOut.stop();
            win.cp = 0;
            card.status = "";
            card.hint = "";
            const c = win.cap;
            if (!win.motion || !c || c.kind === "recording" || !c.hasRegion) {
                win.phase = "card";
                win.formCard();
                return;
            }
            win.phase = "flash";
            // La secuencia arranca cuando la imagen esta decodificada.
            if (flyerImg.status === Image.Ready && thumb.ready) sequence.start();
        }

        function formCard(): void {
            if (win.motion) {
                cardIn.start();
            } else {
                win.cp = 1;
            }
        }
        // Se va: sale la tarjeta y despues se desmapea la ventana.
        function leave(): void {
            sequence.stop();
            cardIn.stop();
            if (win.phase === "idle") return;
            if (win.motion && win.cp > 0) {
                cardOut.start();
            } else {
                win.cp = 0;
                win.phase = "idle";
            }
        }

        Connections {
            target: CaptureState
            function onSerialChanged() {
                if (win.onThisScreen) win.begin();
                else win.leave();
            }
            function onShownChanged() {
                if (!CaptureState.shown) win.leave();
            }
        }

        // ---- Destello y vuelo --------------------------------------------------
        property real fp: 0 // progreso del vuelo, ya con la curva

        readonly property point p0: Qt.point(win.from.x + win.from.width / 2, win.from.y + win.from.height / 2)
        readonly property point p2: Qt.point(win.to.x + win.to.width / 2, win.to.y + win.to.height / 2)
        // Punto de control: arco que sale de lado y cae sobre la tarjeta.
        readonly property point p1: Qt.point(win.p2.x, win.p0.y)

        Rectangle {
            id: flash
            x: win.from.x
            y: win.from.y
            width: win.from.width
            height: win.from.height
            visible: win.phase === "flash"
            z: 2
            color: Qt.alpha("white", win.cap && win.cap.kind === "full" ? 0.15 : 0.22)
            border.width: win.cap && win.cap.kind === "full" ? 0 : 2
            border.color: Colors.accent
            opacity: 0
        }

        Item {
            id: flyer
            readonly property real t: win.fp
            readonly property real u: 1 - flyer.t
            readonly property real cx: flyer.u * flyer.u * win.p0.x + 2 * flyer.u * flyer.t * win.p1.x + flyer.t * flyer.t * win.p2.x
            readonly property real cy: flyer.u * flyer.u * win.p0.y + 2 * flyer.u * flyer.t * win.p1.y + flyer.t * flyer.t * win.p2.y
            width: win.from.width + (win.to.width - win.from.width) * flyer.t
            height: win.from.height + (win.to.height - win.from.height) * flyer.t
            x: flyer.cx - flyer.width / 2
            y: flyer.cy - flyer.height / 2
            z: 1
            visible: win.phase === "flash"

            RectangularShadow {
                anchors.fill: parent
                radius: flyerClip.radius
                blur: Tokens.shadow.lg.blur
                offset.y: Tokens.shadow.lg.offsetY
                color: Colors.tint(Colors.shadow, Tokens.shadow.lg.opacity * flyer.t)
            }
            ClippingRectangle {
                id: flyerClip
                anchors.fill: parent
                radius: thumb.imageRadius * flyer.t
                color: "transparent"
                Image {
                    id: flyerImg
                    anchors.fill: parent
                    // Misma fuente que la miniatura: una sola decodificacion.
                    source: win.phase === "flash" ? thumb.source : ""
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    onStatusChanged: {
                        if (win.phase !== "flash" || sequence.running) return;
                        if (status === Image.Ready && thumb.ready) {
                            sequence.start();
                        } else if (status === Image.Error) {
                            // Imagen ilegible: la tarjeta sin vuelo.
                            win.phase = "card";
                            win.formCard();
                        }
                    }
                }
            }
        }

        Connections {
            target: thumb
            function onReadyChanged() {
                if (thumb.ready && flyerImg.status === Image.Ready && win.phase === "flash" && !sequence.running) sequence.start();
            }
        }

        SequentialAnimation {
            id: sequence
            ScriptAction { script: { win.fp = 0; flash.opacity = 1; } }
            ParallelAnimation {
                // Destello de 120 ms; el vuelo sale a la mitad.
                NumberAnimation { target: flash; property: "opacity"; from: 1; to: 0; duration: Math.round(120 * Tokens.motion.scale); easing.type: Easing.OutQuad }
                SequentialAnimation {
                    PauseAnimation { duration: Math.round(60 * Tokens.motion.scale) }
                    NumberAnimation {
                        target: win
                        property: "fp"
                        from: 0
                        to: 1
                        duration: Tokens.motion.long
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Tokens.motion.easeEmphasized
                    }
                }
            }
            // Aterriza: la tarjeta se forma alrededor y recien ahi se cambia la
            // imagen que vuela por la de la tarjeta (mismo lugar, mismo tamano).
            ScriptAction { script: cardIn.start() }
            PauseAnimation { duration: Tokens.motion.short }
            ScriptAction { script: win.phase = "card" }
        }

        // ---- Tarjeta -------------------------------------------------------------
        NumberAnimation {
            id: cardIn
            target: win
            property: "cp"
            to: 1
            duration: Tokens.motion.short
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.motion.easeEnter
        }
        NumberAnimation {
            id: cardOut
            target: win
            property: "cp"
            to: 0
            duration: Tokens.motion.exitFor(Tokens.motion.short)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.motion.easeExit
            onFinished: win.phase = "idle"
        }

        readonly property int shadowMargin: card.shadowMargin

        Item {
            id: cardSlot
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: Tokens.screenEdge
            anchors.bottomMargin: Tokens.screenEdge
            width: Tokens.px(380)
            height: card.implicitHeight

            HoverHandler { id: cardHover }

            Surface {
                id: card
                // "" | "copied:<accion>" (confirmacion 1,2 s)
                property string status: ""
                property string hint: ""
                readonly property bool trashed: CaptureState.status === "trashed"

                width: parent.width
                implicitHeight: col.implicitHeight + 2 * Tokens.space.md
                level: 2
                radius: Tokens.radius.xl
                opacity: win.cp
                scale: 0.96 + 0.04 * win.cp
                // Crece desde la miniatura.
                transformOrigin: Item.Top

                Timer {
                    id: statusTimer
                    interval: 1200
                    onTriggered: card.status = ""
                }
                function confirm(action: string): void {
                    card.status = "copied:" + action;
                    statusTimer.restart();
                }

                ColumnLayout {
                    id: col
                    x: Tokens.space.md
                    y: Tokens.space.md
                    width: parent.width - 2 * Tokens.space.md
                    spacing: Tokens.space.md

                    CaptureThumb {
                        id: thumb
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(width * 9 / 16)
                        path: win.cap ? win.cap.path : ""
                        kind: win.cap ? win.cap.kind : "region"
                        duration: win.cap ? win.cap.duration : 0
                        imageVisible: win.phase === "card"
                        opacity: card.trashed ? Tokens.opacity.disabled : 1

                        // Doble clic: la accion principal.
                        TapHandler {
                            enabled: !card.trashed
                            onDoubleTapped: {
                                CaptureState.primary(thumb.path);
                                CaptureState.dismiss();
                            }
                        }

                        // Cerrar (al pasar el puntero)
                        Rectangle {
                            visible: cardHover.hovered
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.space.sm
                            width: Tokens.control.sm
                            height: Tokens.control.sm
                            radius: width / 2
                            color: Colors.tint(Colors.surfaceHighest, Tokens.tint.overlay)
                            StateLayer { hovered: closeMouse.containsMouse; pressed: closeMouse.pressed }
                            Icon {
                                anchors.centerIn: parent
                                name: "close"
                                size: Tokens.icon.sm
                            }
                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CaptureState.dismiss()
                            }
                        }
                    }

                    // Datos; o el nombre de la accion bajo el puntero, o la confirmacion.
                    Text {
                        id: meta
                        readonly property bool accent: !!card.hint || card.status !== "" || card.trashed
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.space.xs
                        text: card.status !== "" ? card.statusText
                            : card.trashed ? I18n.tr("Moved to the trash")
                            : card.hint !== "" ? card.hint
                            : card.details
                        color: meta.accent ? Colors.accent : Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        font.weight: meta.accent ? Tokens.weight.medium : Tokens.weight.regular
                        font.features: Tokens.tabularNumbers
                        elide: Text.ElideRight
                    }

                    // Una accion principal y el resto como iconos.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.space.xs

                        Rectangle {
                            id: mainBtn
                            readonly property string icon: card.trashed ? "undo" : thumb.video ? "play_arrow" : "edit"
                            readonly property string label: card.trashed ? I18n.tr("Undo") : thumb.video ? I18n.tr("Play") : I18n.tr("Annotate")
                            implicitHeight: Tokens.px(36)
                            implicitWidth: mainRow.implicitWidth + Tokens.px(28)
                            radius: Tokens.radius.pill(height)
                            color: Colors.accent
                            StateLayer { hovered: mainMouse.containsMouse; pressed: mainMouse.pressed; contentColor: Colors.textOnAccent }
                            Row {
                                id: mainRow
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: mainBtn.icon
                                    filled: true
                                    size: Tokens.icon.sm
                                    color: Colors.textOnAccent
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: mainBtn.label
                                    color: Colors.textOnAccent
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.label
                                    font.weight: Tokens.weight.semibold
                                }
                            }
                            MouseArea {
                                id: mainMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (card.trashed) {
                                        CaptureState.restore(thumb.path);
                                    } else {
                                        CaptureState.primary(thumb.path);
                                        CaptureState.dismiss();
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Repeater {
                            model: [
                                { id: "copy", icon: "content_copy", hint: thumb.video ? I18n.tr("Copy the file") : I18n.tr("Copy the image again") },
                                { id: "path", icon: "link", hint: I18n.tr("Copy the file path") },
                                { id: "open", icon: "open_in_new", hint: I18n.tr("Open with the default application") },
                                { id: "folder", icon: "folder_open", hint: I18n.tr("Show in the folder") },
                                { id: "trash", icon: "delete", hint: I18n.tr("Move to the trash") }
                            ]

                            Rectangle {
                                id: iconBtn
                                required property var modelData
                                readonly property bool done: card.status === "copied:" + iconBtn.modelData.id
                                readonly property bool danger: iconBtn.modelData.id === "trash"
                                implicitWidth: Tokens.control.md
                                implicitHeight: Tokens.control.md
                                radius: width / 2
                                enabled: !card.trashed
                                opacity: iconBtn.enabled ? 1 : Tokens.opacity.disabled
                                // Hecho (copiado): resultado = success (P8.7).
                                color: iconBtn.done ? Colors.successContainer : "transparent"
                                StateLayer {
                                    hovered: iconMouse.containsMouse
                                    pressed: iconMouse.pressed
                                    contentColor: iconBtn.danger ? Colors.danger : Colors.textMuted
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    name: iconBtn.done ? "check" : iconBtn.modelData.icon
                                    filled: iconBtn.done
                                    size: Tokens.icon.md
                                    color: iconBtn.danger ? Colors.danger : iconBtn.done ? Colors.textOnSuccessContainer : Colors.textMuted
                                }
                                MouseArea {
                                    id: iconMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onContainsMouseChanged: {
                                        if (iconMouse.containsMouse) card.hint = iconBtn.modelData.hint;
                                        else if (card.hint === iconBtn.modelData.hint) card.hint = "";
                                    }
                                    onClicked: card.act(iconBtn.modelData.id)
                                }
                            }
                        }
                    }
                }

                function act(id: string): void {
                    const p = thumb.path;
                    switch (id) {
                    case "copy":
                        CaptureState.copy(p);
                        card.confirm(id);
                        break;
                    case "path":
                        CaptureState.copyPath(p);
                        card.confirm(id);
                        break;
                    case "open":
                        CaptureState.open(p);
                        CaptureState.dismiss();
                        break;
                    case "folder":
                        CaptureState.showInFolder(p);
                        CaptureState.dismiss();
                        break;
                    case "trash":
                        card.hint = "";
                        CaptureState.trash(p);
                        break;
                    }
                }

                readonly property string statusText: card.status === "copied:copy" ? (thumb.video ? I18n.tr("File copied") : I18n.tr("Image copied again"))
                                : card.status === "copied:path" ? I18n.tr("Path copied") : ""

                // "800 × 400 · 312 kB · 08:41"
                readonly property string details: {
                    const c = win.cap;
                    if (!c) return "";
                    const w = c.video ? c.w : thumb.imageSize.width;
                    const h = c.video ? c.h : thumb.imageSize.height;
                    const parts = [];
                    if (w > 0 && h > 0) parts.push(w + " × " + h);
                    if (c.bytes > 0) parts.push(c.bytes < 1e6 ? I18n.tr("%1 kB", Math.max(1, Math.round(c.bytes / 1000))) : I18n.tr("%1 MB", I18n.number(c.bytes / 1e6, 1)));
                    parts.push(I18n.date(new Date(c.time), "HH:mm"));
                    return parts.join("  ·  ");
                }
            }
        }

        // 6 s en pantalla, en pausa con el puntero encima.
        Timer {
            running: win.phase === "card" && win.wanted && !cardOut.running && !cardHover.hovered
            // capture.cardSeconds (settings store)
            interval: SettingsState.value("capture.cardSeconds") * 1000
            onTriggered: CaptureState.dismiss()
        }
    }

    // ---- Marcas de la zona que se graba -----------------------------------------
    PanelWindow {
        id: marks
        screen: root.screen

        readonly property var r: CaptureState.recordRegion
        readonly property bool onThisScreen: !!marks.r && !!root.screen
            && marks.r.x + marks.r.w / 2 >= root.screen.x && marks.r.x + marks.r.w / 2 < root.screen.x + root.screen.width
            && marks.r.y + marks.r.h / 2 >= root.screen.y && marks.r.y + marks.r.h / 2 < root.screen.y + root.screen.height
        readonly property int len: 18
        readonly property int thick: 3
        readonly property int gap: 4

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        visible: marks.onThisScreen

        Repeater {
            model: marks.onThisScreen ? 4 : 0

            // Una L por esquina, apuntando hacia afuera de la zona.
            Item {
                id: corner
                required property int index
                readonly property bool isRight: corner.index === 1 || corner.index === 3
                readonly property bool isBottom: corner.index >= 2
                readonly property real zx: marks.r.x - root.screen.x
                readonly property real zy: marks.r.y - root.screen.y
                width: marks.len
                height: marks.len
                x: corner.isRight ? corner.zx + marks.r.w + marks.gap - marks.len + marks.thick : corner.zx - marks.gap - marks.thick
                y: corner.isBottom ? corner.zy + marks.r.h + marks.gap - marks.len + marks.thick : corner.zy - marks.gap - marks.thick

                // Contorno oscuro fino: se leen sobre cualquier fondo.
                Rectangle {
                    x: (corner.isRight ? corner.width - marks.thick : 0) - 1
                    y: -1
                    width: marks.thick + 2
                    height: corner.height + 2
                    radius: 2
                    color: Colors.tint(Colors.scrim, Tokens.opacity.scrimImage)
                }
                Rectangle {
                    x: -1
                    y: (corner.isBottom ? corner.height - marks.thick : 0) - 1
                    width: corner.width + 2
                    height: marks.thick + 2
                    radius: 2
                    color: Colors.tint(Colors.scrim, Tokens.opacity.scrimImage)
                }
                Rectangle {
                    x: corner.isRight ? corner.width - marks.thick : 0
                    width: marks.thick
                    height: corner.height
                    radius: 1.5
                    color: Colors.danger
                }
                Rectangle {
                    y: corner.isBottom ? corner.height - marks.thick : 0
                    width: corner.width
                    height: marks.thick
                    radius: 1.5
                    color: Colors.danger
                }
            }
        }
    }
}
