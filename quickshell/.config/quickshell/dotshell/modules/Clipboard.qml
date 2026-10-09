// Historial del portapapeles (Fase 4 B2, P4.1), la unica interfaz del
// historial. OverlayWindow + Picker con fila de filtros y vista previa
// a la derecha; todo el acceso a cliphist pasa por scripts/clipboard-store.
//
// Filas: icono por tipo (texto, codigo, enlace, color, ruta, imagen) sacado
// de la vista previa de cliphist, sin decodificar nada. Solo la entrada
// elegida se decodifica (120 ms despues de detenerse): el texto a memoria
// (hasta 8 KB), la imagen a $XDG_RUNTIME_DIR/dotshell-clipboard (RAM, modo
// 700), que se borra al cerrar el panel.
//
// Privacidad (decisiones B2-d/B2-e): lo sensible ya no se guarda (lo filtra
// clipboard-store). Si queda alguna entrada vieja que lo parezca, la fila y la
// vista previa quedan ocultas, no aparece en busquedas y su contenido no se
// decodifica salvo con Ctrl+R (solo esa entrada, mientras siga elegida).
// Enter la copia sin mostrarla. El contenido nunca va a logs.
//
// Teclas: Enter copia y cierra, Supr borra, Tab / Shift+Tab cambian el
// filtro, Ctrl+P pausa o reanuda el historial, Ctrl+R muestra lo oculto,
// Ctrl+Supr vacia (con confirmacion: Enter recien a los 400 ms y sin
// repeticion de tecla, como el menu de energia). Esc o un clic afuera cierran.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml, ClipboardState.qml, Fuzzy.qml, Sensitive.qml

OverlayWindow {
    id: window

    open: ClipboardState.visible
    targetScreen: ClipboardState.screen
    onDismissed: ClipboardState.close()

    readonly property string script: ClipboardState.script

    // ---- Datos ------------------------------------------------------------
    // Entradas de "cliphist list", la mas nueva primero:
    // { id, text, kind, meta, sens, ext, w, h, hay } (hay: texto de busqueda
    // en minusculas, calculado una vez).
    property var entries: []
    property bool loading: false
    // Categoria sensible detectada al decodificar (la vista previa de la
    // lista solo ve los primeros 100 caracteres): id -> categoria.
    property var hiddenIds: ({})

    property string filter: "all"
    readonly property var filters: ["all", "text", "image", "link"]
    readonly property var filterLabels: ({ all: "Todo", text: "Texto", image: "Imágenes", link: "Enlaces" })

    readonly property var icons: ({ text: "notes", code: "code", command: "terminal", link: "link", color: "palette",
        path: "folder", image: "image", binary: "draft", secret: "key" })

    readonly property var commandRe: /^(\$ |sudo |git |cd |ls |yay |paru |pacman |systemctl |journalctl |qs |hyprctl |cat |grep |rg |sed |awk |cp |mv |rm |mkdir |curl |wget |echo |export |npm |pnpm |python3? |pip |make |cargo |stow |nvim |ssh |docker )/

    function parse(line: string): var {
        const tab = line.indexOf("\t");
        if (tab < 0) return null;
        const id = line.slice(0, tab);
        const text = line.slice(tab + 1);
        const img = /^\[\[ binary data ([\d.]+ \w+) (\w+) (\d+)x(\d+) \]\]$/.exec(text);
        if (img)
            return { id, text: "", kind: "image", meta: img[2].toUpperCase() + " · " + img[1].replace("i", ""),
                ext: img[2].toLowerCase(), w: img[3], h: img[4], sens: "",
                hay: "imagen " + img[2].toLowerCase() + " " + img[3] + "x" + img[4] };
        if (/^\[\[ binary data .* \]\]$/.test(text))
            return { id, text: "", kind: "binary", meta: "Datos binarios", sens: "", hay: "" };
        const sens = Sensitive.check(text);
        if (sens) return { id, text: "", kind: "secret", meta: "Oculto · parece " + Sensitive.label(sens), sens, hay: "" };
        const long = text.endsWith("…");
        let kind = "text", meta = long ? "Texto largo" : "Texto · " + text.length + " caracteres";
        if (/^(https?:\/\/|www\.)\S+$/.test(text)) {
            kind = "link";
            const m = /^(?:https?:\/\/)?([^\/?#]+)/.exec(text);
            meta = "Enlace · " + (m ? m[1] : "");
        } else if (/^(#[0-9a-fA-F]{3,4}|#[0-9a-fA-F]{6}|#[0-9a-fA-F]{8}|rgba?\([^)]*\))$/.test(text)) {
            kind = "color"; meta = "Color";
        } else if (/^(~|\/|\.\.?\/)\S*$/.test(text)) {
            kind = "path"; meta = "Ruta";
        } else if (window.commandRe.test(text)) {
            kind = "command"; meta = "Comando";
        } else if (/[{};]|=>|\(\)/.test(text)) {
            kind = "code"; meta = "Código";
        }
        return { id, text, kind, meta, sens: "", hay: text.toLowerCase() };
    }

    function inFilter(e: var): bool {
        if (window.filter === "image") return e.kind === "image";
        if (window.filter === "text") return e.kind !== "image" && e.kind !== "binary";
        if (window.filter === "link") return e.kind === "link";
        return true;
    }
    function isHidden(e: var): bool {
        return e.kind === "secret" || !!window.hiddenIds[e.id];
    }

    readonly property var counts: {
        const c = { all: 0, text: 0, image: 0, link: 0 };
        for (const e of window.entries) {
            c.all++;
            if (e.kind === "image") c.image++;
            else if (e.kind !== "binary") c.text++;
            if (e.kind === "link") c.link++;
        }
        return c;
    }

    // Busqueda literal: todas las palabras tienen que aparecer (sin importar
    // mayusculas). Lo oculto nunca coincide. Orden: el del historial.
    readonly property var shown: {
        const terms = picker.query.trim().toLowerCase().split(/\s+/).filter(t => t.length > 0);
        const out = [];
        for (const e of window.entries) {
            if (!window.inFilter(e)) continue;
            if (terms.length === 0) {
                out.push({ e: e, positions: [] });
                continue;
            }
            if (window.isHidden(e)) continue;
            const hay = e.hay;
            const positions = [];
            let ok = true;
            for (const t of terms) {
                const at = hay.indexOf(t);
                if (at < 0) { ok = false; break; }
                for (let i = 0; i < t.length; i++) positions.push(at + i);
            }
            if (ok) out.push({ e: e, positions: e.kind === "image" ? [] : positions });
        }
        return out;
    }
    readonly property var current: window.shown[picker.currentIndex] ? window.shown[picker.currentIndex].e : null

    Process {
        id: listProc
        command: [window.script, "--list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.split("\n")) {
                    const e = window.parse(line);
                    if (e) out.push(e);
                }
                window.entries = out;
                window.loading = false;
            }
        }
    }

    // ---- Vista previa de la entrada elegida -------------------------------
    property string revealedId: ""
    property var preview: ({ id: "", state: "none" }) // none | loading | text | image | hidden
    readonly property bool currentHidden: !!window.current && window.isHidden(window.current)

    onCurrentChanged: {
        if (!window.current || window.current.id !== window.revealedId) window.revealedId = "";
        previewTimer.restart();
    }
    Timer {
        id: previewTimer
        interval: 120
        onTriggered: window.loadPreview()
    }
    function loadPreview(): void {
        const e = window.current;
        textProc.running = false;
        imageProc.running = false;
        if (!e) {
            window.preview = { id: "", state: "none" };
            return;
        }
        const revealed = e.id === window.revealedId;
        if (window.isHidden(e) && !revealed) {
            window.preview = { id: e.id, state: "hidden", sens: e.sens || window.hiddenIds[e.id] };
            return;
        }
        if (e.kind === "binary") {
            window.preview = { id: e.id, state: "none" };
            return;
        }
        window.preview = { id: e.id, state: "loading" };
        if (e.kind === "image") {
            imageProc.command = [window.script, "--preview-image", e.id, e.ext];
            imageProc.forId = e.id;
            imageProc.running = true;
        } else {
            textProc.command = [window.script, "--preview-text", e.id].concat(revealed ? ["--reveal"] : []);
            textProc.forId = e.id;
            textProc.running = true;
        }
    }
    Process {
        id: textProc
        property string forId: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (!window.current || window.current.id !== textProc.forId) return;
                const out = this.text;
                const nl = out.indexOf("\n");
                const head = nl < 0 ? out : out.slice(0, nl);
                if (head.startsWith("SENSIBLE ")) {
                    const h = Object.assign({}, window.hiddenIds);
                    h[textProc.forId] = head.slice(9);
                    window.hiddenIds = h;
                    window.preview = { id: textProc.forId, state: "hidden", sens: h[textProc.forId] };
                    return;
                }
                const nums = head.split(" ");
                window.preview = { id: textProc.forId, state: "text", body: nl < 0 ? "" : out.slice(nl + 1),
                    bytes: Number(nums[0]) || 0, lines: Number(nums[1]) || 0 };
            }
        }
    }
    Process {
        id: imageProc
        property string forId: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (!window.current || window.current.id !== imageProc.forId) return;
                const path = this.text.trim();
                window.preview = path ? { id: imageProc.forId, state: "image", path: path } : { id: imageProc.forId, state: "none" };
            }
        }
    }

    // ---- Acciones -----------------------------------------------------------
    function copy(e: var): void {
        if (!e) return;
        Quickshell.execDetached([window.script, "--copy", e.id]);
        ClipboardState.close();
    }
    function remove(e: var): void {
        if (!e) return;
        const keep = picker.currentIndex;
        Quickshell.execDetached([window.script, "--delete", e.id]);
        window.entries = window.entries.filter(x => x.id !== e.id);
        Qt.callLater(() => picker.currentIndex = Math.max(0, Math.min(keep, window.shown.length - 1)));
    }
    function cycleFilter(step: int): void {
        const i = window.filters.indexOf(window.filter);
        window.filter = window.filters[(i + step + window.filters.length) % window.filters.length];
        picker.currentIndex = 0;
    }
    function toggleReveal(): void {
        const e = window.current;
        if (!e || !window.isHidden(e)) return;
        window.revealedId = window.revealedId === e.id ? "" : e.id;
        window.loadPreview();
    }

    // Vaciar (con confirmacion).
    property bool confirming: false
    property real confirmSince: 0
    function askWipe(): void {
        if (window.entries.length === 0) return;
        window.confirming = true;
        window.confirmSince = Date.now();
        keys.forceActiveFocus();
    }
    function cancelWipe(): void {
        window.confirming = false;
        picker.focusSearch();
    }
    function confirmWipe(): void {
        if (!window.confirming || Date.now() - window.confirmSince < 400) return;
        Quickshell.execDetached([window.script, "--wipe"]);
        Quickshell.execDetached([window.script, "--clean-previews"]);
        window.entries = [];
        window.hiddenIds = {};
        window.cancelWipe();
    }

    // Teclado: lo que el selector no usa (flechas, Enter y Esc son suyos) y
    // todo durante la confirmacion. Tambien lo usa la sonda de pruebas.
    function handleKey(key: int, modifiers: int, isAutoRepeat: bool): bool {
        if (!window.shouldShow) return false;
        const ctrl = (modifiers & Qt.ControlModifier) !== 0;
        if (window.confirming) {
            if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                if (!isAutoRepeat) window.confirmWipe();
            } else if (key === Qt.Key_Escape) {
                window.cancelWipe();
            }
            return true;
        }
        if (key === Qt.Key_Delete) {
            if (ctrl) window.askWipe();
            else if (!isAutoRepeat) window.remove(window.current);
            return true;
        }
        if (key === Qt.Key_Tab) { window.cycleFilter(1); return true; }
        if (key === Qt.Key_Backtab) { window.cycleFilter(-1); return true; }
        if (ctrl && key === Qt.Key_P) { ClipboardState.setPaused(!ClipboardState.paused); return true; }
        if (ctrl && key === Qt.Key_R) { window.toggleReveal(); return true; }
        return false;
    }
    Item {
        id: keys
        Keys.onPressed: (event) => {
            event.accepted = window.handleKey(event.key, event.modifiers, event.isAutoRepeat);
        }
    }

    // ---- Abrir / cerrar -------------------------------------------------------
    onShouldShowChanged: {
        if (!window.shouldShow) return;
        window.filter = "all";
        window.revealedId = "";
        window.confirming = false;
        window.hiddenIds = {};
        window.preview = { id: "", state: "none" };
        window.loading = true;
        listProc.running = true;
        picker.reset();
    }
    // Al terminar de cerrarse: nada del historial queda en memoria del panel
    // y se borran las imagenes temporales.
    onVisibleChanged: {
        if (window.visible) return;
        textProc.running = false;
        imageProc.running = false;
        window.entries = [];
        window.hiddenIds = {};
        window.revealedId = "";
        window.preview = { id: "", state: "none" };
        Quickshell.execDetached([window.script, "--clean-previews"]);
    }

    // ---- Vista ------------------------------------------------------------------
    component Chip: Rectangle {
        id: chip
        property string label
        property int count
        property bool on
        signal clicked()
        implicitHeight: Tokens.px(28)
        implicitWidth: chipRow.implicitWidth + Tokens.space.md * 2
        radius: Tokens.radius.sm
        color: chip.on ? Colors.accentAltContainer : "transparent"
        border.width: chip.on ? 0 : 1
        border.color: Colors.divider
        StateLayer { hovered: chipMouse.containsMouse; pressed: chipMouse.pressed }
        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: Tokens.space.xs
            Text {
                text: chip.label
                color: chip.on ? Colors.textOnAccentAltContainer : Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.medium
            }
            Text {
                text: chip.count
                color: chip.on ? Colors.textOnAccentAltContainer : Colors.border
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.features: Tokens.tabularNumbers
            }
        }
        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    component KeyHint: Rectangle {
        id: hint
        property string text
        property color fg
        implicitWidth: hintText.implicitWidth + Tokens.space.sm * 2
        implicitHeight: hintText.implicitHeight + Tokens.space.hair * 2
        radius: Tokens.radius.sm
        color: "transparent"
        border.color: Colors.tint(hint.fg, Tokens.tint.hairline)
        Text {
            id: hintText
            anchors.centerIn: parent
            text: hint.text
            color: hint.fg
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
    }

    Picker {
        id: picker
        visible: !window.confirming
        anchors.centerIn: parent
        presence: window.presence
        model: window.shown
        listWidth: Tokens.px(480)
        previewWidth: Tokens.px(340)
        placeholder: "Buscar en el portapapeles..."
        emptyText: window.loading ? "" : (window.entries.length === 0 ? "El historial está vacío" : "Sin resultados")
        hints: "↑↓ navegar   ⏎ copiar   supr borrar   tab filtro   ctrl+p pausar   ctrl+supr vaciar   esc cerrar"
        keyHandler: (event) => window.handleKey(event.key, event.modifiers, event.isAutoRepeat)
        onAccepted: (item) => window.copy(item.e)
        onDismissed: ClipboardState.close()

        header: Component {
            ColumnLayout {
                spacing: Tokens.space.sm

                // Pausa: lo copiado ahora no se guarda.
                Rectangle {
                    visible: ClipboardState.paused
                    Layout.fillWidth: true
                    implicitHeight: Tokens.px(36)
                    radius: Tokens.radius.md
                    // Mas privacidad, no un aviso: neutro con icono y texto (D11).
                    color: Colors.surfaceHighest
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.space.md
                        anchors.rightMargin: Tokens.space.md
                        spacing: Tokens.space.sm
                        Icon { name: "visibility_off"; size: Tokens.icon.sm; color: Colors.text }
                        Text {
                            Layout.fillWidth: true
                            text: "Historial en pausa: lo que copies ahora no se guarda"
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.weight: Tokens.weight.medium
                            elide: Text.ElideRight
                        }
                        Text {
                            text: "ctrl+p reanudar"
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.caption
                        }
                    }
                }

                RowLayout {
                    spacing: Tokens.space.xs
                    Repeater {
                        model: window.filters
                        Chip {
                            required property string modelData
                            label: window.filterLabels[modelData]
                            count: window.counts[modelData]
                            on: window.filter === modelData
                            onClicked: {
                                window.filter = modelData;
                                picker.currentIndex = 0;
                                picker.focusSearch();
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Icon {
                        visible: ClipboardState.paused
                        name: "visibility_off"
                        size: Tokens.icon.sm
                        color: Colors.textMuted
                    }
                    Text {
                        text: (window.shown.length === window.counts.all ? "" : window.shown.length + " de ")
                            + window.counts.all + " entradas"
                        color: Colors.border
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        font.features: Tokens.tabularNumbers
                    }
                }
            }
        }

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool selected: row.index === ListView.view.currentIndex
            readonly property var e: row.modelData.e
            readonly property bool hidden: window.isHidden(row.e)
            readonly property string sens: row.e.sens || window.hiddenIds[row.e.id] || ""
            readonly property bool mono: row.e.kind === "code" || row.e.kind === "command" || row.e.kind === "path" || row.e.kind === "color"
            width: ListView.view.width
            height: picker.rowHeight - Tokens.space.hair
            radius: Tokens.radius.md
            color: row.selected ? Colors.accentAltContainer : "transparent"
            Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }

            StateLayer {
                hovered: rowMouse.containsMouse
                pressed: rowMouse.pressed
                contentColor: row.selected ? Colors.textOnAccentAltContainer : Colors.text
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.space.sm
                anchors.rightMargin: Tokens.space.md
                spacing: Tokens.space.md

                // Icono del tipo; en los colores, la muestra del color.
                Rectangle {
                    implicitWidth: Tokens.space.xxl
                    implicitHeight: Tokens.space.xxl
                    radius: Tokens.radius.sm
                    color: row.e.kind === "color" && !row.hidden ? row.e.text
                        : (row.selected ? Colors.tint(Colors.textOnAccentAltContainer, Tokens.stateLayer.focus) : Colors.surfaceHighest)
                    Icon {
                        anchors.centerIn: parent
                        visible: row.e.kind !== "color" || row.hidden
                        name: row.hidden ? "key" : window.icons[row.e.kind]
                        size: Tokens.icon.sm
                        color: row.hidden ? Colors.text
                            : (row.selected ? Colors.textOnAccentAltContainer : Colors.textMuted)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: row.hidden ? "Oculto"
                            : row.e.kind === "image" ? "Imagen " + row.e.w + "×" + row.e.h
                            : row.e.kind === "binary" ? "Datos binarios"
                            : (row.selected ? Fuzzy.escapeHtml(row.e.text) : Fuzzy.highlight(row.e.text, row.modelData.positions))
                        textFormat: Text.RichText
                        color: row.selected ? Colors.textOnAccentAltContainer : (row.hidden ? Colors.textMuted : Colors.text)
                        font.family: row.mono && !row.hidden ? Tokens.font.mono : Tokens.font.ui
                        font.features: ({ "liga": 0, "calt": 0 })
                        font.pixelSize: Tokens.type.body
                        font.italic: row.hidden
                        font.weight: row.selected ? Tokens.weight.semibold : Tokens.weight.medium
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: row.hidden ? "Parece " + Sensitive.label(row.sens) : row.e.meta
                        color: row.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: window.copy(row.e)
            }
        }

        preview: Component {
            Rectangle {
                id: pane
                readonly property var p: window.preview
                radius: Tokens.radius.md
                color: Colors.surfaceLow
                border.width: 1
                border.color: Colors.divider
                clip: true

                // Imagen (sobre una cuadricula, por las transparencias).
                Item {
                    visible: pane.p.state === "image"
                    anchors.fill: parent
                    anchors.margins: Tokens.space.md
                    Canvas {
                        anchors.centerIn: img
                        width: img.paintedWidth
                        height: img.paintedHeight
                        onPaint: {
                            const c = getContext("2d");
                            for (let y = 0; y < height; y += 12)
                                for (let x = 0; x < width; x += 12) {
                                    c.fillStyle = ((x + y) / 12) % 2 ? Colors.tint(Colors.text, Tokens.tint.track) : Colors.tint(Colors.text, Tokens.tint.faint);
                                    c.fillRect(x, y, 12, 12);
                                }
                        }
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }
                    Image {
                        id: img
                        anchors.fill: parent
                        anchors.bottomMargin: Tokens.space.xl
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        source: pane.p.state === "image" ? "file://" + pane.p.path : ""
                        sourceSize.width: 2 * pane.width
                    }
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: window.current && window.current.kind === "image"
                            ? window.current.w + "×" + window.current.h + " · " + window.current.meta : ""
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                    }
                }

                // Oculto: nada del contenido hasta Ctrl+R.
                ColumnLayout {
                    visible: pane.p.state === "hidden"
                    anchors.centerIn: parent
                    width: parent.width - Tokens.space.xl * 2
                    spacing: Tokens.space.sm
                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        name: "visibility_off"
                        size: Tokens.icon.xl
                        color: Colors.textMuted
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Contenido oculto"
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.title
                        font.weight: Tokens.weight.semibold
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "Parece " + Sensitive.label(pane.p.sens || "") + ". Se guardó antes del filtro de datos sensibles."
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Tokens.space.xs
                        spacing: Tokens.space.xs
                        KeyHint { text: "⏎"; fg: Colors.textMuted }
                        Text { text: "copiar sin mostrar"; color: Colors.textMuted; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption }
                        Item { implicitWidth: Tokens.space.sm }
                        KeyHint { text: "ctrl+r"; fg: Colors.textMuted }
                        Text { text: "mostrar"; color: Colors.textMuted; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption }
                    }
                }

                // Texto (tal cual se pega: sin ligaduras).
                ColumnLayout {
                    visible: pane.p.state === "text"
                    anchors.fill: parent
                    anchors.margins: Tokens.space.md
                    spacing: Tokens.space.sm
                    Rectangle {
                        visible: !!window.current && window.current.kind === "color"
                        Layout.fillWidth: true
                        implicitHeight: Tokens.px(96)
                        radius: Tokens.radius.md
                        color: window.current && window.current.kind === "color" ? window.current.text : "transparent"
                        border.width: 1
                        border.color: Colors.divider
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: pane.p.state === "text" ? pane.p.body : ""
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        clip: true
                        color: Colors.text
                        font.family: window.current && (window.current.kind === "text" || window.current.kind === "link") && window.revealedId === ""
                            ? Tokens.font.ui : Tokens.font.mono
                        font.features: ({ "liga": 0, "calt": 0 })
                        font.pixelSize: Tokens.type.label
                        lineHeight: 1.15
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (pane.p.state !== "text") return "";
                            const parts = [pane.p.bytes >= 1024 ? (pane.p.bytes / 1024).toFixed(1) + " KB" : pane.p.bytes + " bytes"];
                            if (pane.p.lines > 1) parts.push(pane.p.lines + " líneas");
                            if (pane.p.bytes > 8192) parts.push("vista recortada");
                            if (window.revealedId) parts.push("ctrl+r ocultar");
                            return parts.join(" · ");
                        }
                        color: Colors.border
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        elide: Text.ElideRight
                    }
                }

                Text {
                    visible: pane.p.state === "none" && !window.loading
                    anchors.centerIn: parent
                    width: parent.width - Tokens.space.xl * 2
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: window.entries.length === 0 ? "Lo que copies aparecerá aquí"
                        : (window.current && window.current.kind === "binary" ? "Sin vista previa" : "")
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                }
            }
        }
    }

    // Confirmacion de vaciar (mismo diseño que las del menu de energia).
    Surface {
        visible: window.confirming
        anchors.centerIn: parent
        level: 3
        translucent: true
        radius: Tokens.radius.xl
        width: confirmCol.implicitWidth + Tokens.space.xl * 2
        height: confirmCol.implicitHeight + Tokens.space.xl * 2
        opacity: window.presence.progress
        scale: window.presence.contentScale

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: confirmCol
            anchors.centerIn: parent
            spacing: Tokens.space.md

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Tokens.px(56)
                implicitHeight: Tokens.px(56)
                radius: width / 2
                color: Colors.dangerContainer
                Icon {
                    anchors.centerIn: parent
                    name: "delete_sweep"
                    size: Tokens.icon.lg
                    filled: true
                    color: Colors.textOnDangerContainer
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "¿Vaciar el historial?"
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Se borran " + window.counts.all + " entradas" + (window.counts.image ? " (" + window.counts.image + " imágenes)" : "")
                    + ". No se puede deshacer.\nLo que está copiado ahora se mantiene."
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.space.sm
                spacing: Tokens.space.sm

                Rectangle {
                    implicitWidth: cancelRow.implicitWidth + Tokens.space.lg * 2
                    implicitHeight: Tokens.row.height
                    radius: Tokens.radius.pill(height)
                    color: "transparent"
                    border.color: Colors.divider
                    StateLayer { hovered: cancelMouse.containsMouse; pressed: cancelMouse.pressed }
                    Row {
                        id: cancelRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Cancelar"
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                        }
                        KeyHint { anchors.verticalCenter: parent.verticalCenter; text: "Esc"; fg: Colors.textMuted }
                    }
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.cancelWipe()
                    }
                }
                Rectangle {
                    implicitWidth: okRow.implicitWidth + Tokens.space.lg * 2
                    implicitHeight: Tokens.row.height
                    radius: Tokens.radius.pill(height)
                    color: Colors.danger
                    StateLayer { hovered: okMouse.containsMouse; pressed: okMouse.pressed; contentColor: Colors.textOnDanger }
                    Row {
                        id: okRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "delete_sweep"
                            size: Tokens.icon.sm
                            color: Colors.textOnDanger
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Vaciar"
                            color: Colors.textOnDanger
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: Tokens.weight.semibold
                        }
                        KeyHint { anchors.verticalCenter: parent.verticalCenter; text: "Enter"; fg: Colors.textOnDanger }
                    }
                    MouseArea {
                        id: okMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.confirmWipe()
                    }
                }
            }
        }
    }
}
