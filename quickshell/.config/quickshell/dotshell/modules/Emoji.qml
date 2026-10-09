// Selector de emoji (Fase 4 B3, P4.3), la unica interfaz de emoji.
// OverlayWindow +
// Picker en rejilla (10 columnas) con pestañas de categoria arriba y una
// franja abajo con el emoji grande, su nombre y el tono de piel.
//
// Enter escribe el emoji en la ventana que tenia el foco (wtype, despues de
// que el panel se cierra y devuelve el foco) sin copiarlo; Ctrl+Enter solo lo
// copia. Tab / Shift+Tab cambian de categoria, Ctrl+T el tono (global, se
// recuerda). Busqueda por comienzo de palabra en nombre y claves, en espanol
// e ingles y sin tildes ("gat" -> gato, "corazon" -> corazón). Abre en
// Recientes (los ultimos 30) si hay alguno.
//
// La rejilla existe solo con el panel abierto (Loader): al cerrar se liberan
// sus filas. EMOJI_DRY=1 (solo pruebas) registra el comando en vez de
// escribir o copiar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, EmojiState.qml

OverlayWindow {
    id: window

    open: EmojiState.visible
    targetScreen: EmojiState.screen
    onDismissed: EmojiState.close()
    // Los datos de emoji solo mientras el panel se ve (y 10 min despues, D3).
    property Subscription emojiData: Subscription { demand: EmojiState.demand; active: window.shouldShow || window.visible }

    readonly property var categories: [
        { id: "recent", icon: "schedule", label: "Recientes" },
        { id: "smileys", icon: "sentiment_satisfied", label: "Caras" },
        { id: "people", icon: "waving_hand", label: "Personas" },
        { id: "animals", icon: "pets", label: "Animales" },
        { id: "food", icon: "restaurant", label: "Comida" },
        { id: "travel", icon: "flight", label: "Viajes" },
        { id: "activities", icon: "sports_soccer", label: "Actividades" },
        { id: "objects", icon: "lightbulb", label: "Objetos" },
        { id: "symbols", icon: "emoji_symbols", label: "Símbolos" },
        { id: "flags", icon: "flag", label: "Banderas" }]
    // Muestras de los 6 tonos (amarillo + Fitzpatrick 1-2 a 6).
    readonly property var toneColors: ["#ffcc4d", "#f7dece", "#f3d2a2", "#d5ab88", "#af7e57", "#7c533e"]
    readonly property var toneNames: ["Sin tono", "Tono claro", "Tono claro medio", "Tono medio", "Tono oscuro medio", "Tono oscuro"]

    readonly property bool dry: Quickshell.env("EMOJI_DRY") === "1"
    property var lastCommand: null

    // El emoji tal como se muestra y se escribe (con el tono si lo admite).
    function glyph(x: var): string {
        return EmojiState.tone > 0 && x.t ? x.t[EmojiState.tone - 1] : x.e;
    }

    // Escribir (Enter) o copiar (Ctrl+Enter): cierra y actua al terminar la
    // salida, cuando el foco ya volvio a la ventana de antes.
    function act(x: var, copy: bool): void {
        if (!x) return;
        const s = window.glyph(x);
        EmojiState.use(x.e);
        EmojiState.close();
        window.pendingCommand = copy ? ["wl-copy", s] : ["wtype", s];
        runTimer.restart();
    }
    property var pendingCommand: null
    Timer {
        id: runTimer
        interval: Tokens.motion.exitFor(Tokens.motion.long) + 60
        onTriggered: {
            const cmd = window.pendingCommand;
            window.pendingCommand = null;
            if (!cmd) return;
            if (window.dry) {
                window.lastCommand = cmd;
                console.log("EMOJI_DRY " + JSON.stringify(cmd));
            } else {
                Quickshell.execDetached(cmd);
            }
        }
    }

    function handleKey(key: int, modifiers: int, isAutoRepeat: bool): bool {
        return body.item ? body.item.handleKey(key, modifiers, isAutoRepeat) : false;
    }

    Loader {
        id: body
        anchors.fill: parent
        active: window.visible || window.shouldShow
        sourceComponent: Item {
            id: content

            property string category: EmojiState.recent.length > 0 ? "recent" : "smileys"

            Component.onCompleted: picker.reset()
            Connections {
                target: window
                function onShouldShowChanged() {
                    if (!window.shouldShow) return;
                    content.category = EmojiState.recent.length > 0 ? "recent" : "smileys";
                    picker.reset();
                }
            }

            // Consulta sin mayusculas ni tildes (como las palabras del generador).
            function fold(s: string): string {
                return s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
            }

            readonly property var shown: {
                if (!EmojiState.ready) return [];
                const terms = content.fold(picker.query.trim()).split(/[^a-z0-9ñ]+/).filter(t => t.length > 0);
                if (terms.length > 0) {
                    // Palabra exacta del nombre 3, comienzo de palabra del
                    // nombre 2, de una clave 1; a igual puntaje, el nombre mas
                    // corto (gato antes que "gato sonriendo") y el orden Unicode.
                    const out = [];
                    const all = EmojiState.all;
                    const pre = terms.map(t => " " + t);
                    const whole = terms.map(t => " " + t + " ");
                    for (let i = 0; i < all.length; i++) {
                        const x = all[i];
                        let score = 0;
                        for (let j = 0; j < pre.length; j++) {
                            if (x.hn.indexOf(whole[j]) >= 0) score += 3;
                            else if (x.hn.indexOf(pre[j]) >= 0) score += 2;
                            else if (x.hk.indexOf(pre[j]) >= 0) score += 1;
                            else { score = -1; break; }
                        }
                        if (score >= 0) out.push({ x: x, score: score, i: i });
                    }
                    out.sort((a, b) => b.score - a.score || a.x.nw - b.x.nw || a.i - b.i);
                    return out.map(r => r.x);
                }
                if (content.category === "recent")
                    return EmojiState.recent.map(e => EmojiState.byE[e]).filter(x => !!x);
                return EmojiState.all.filter(x => x.g === content.category);
            }
            readonly property var current: content.shown[picker.currentIndex] || null

            function cycleCategory(step: int): void {
                const ids = window.categories.map(c => c.id);
                const i = picker.query ? (step > 0 ? -1 : 0) : ids.indexOf(content.category);
                content.category = ids[(i + step + ids.length) % ids.length];
                picker.reset();
            }

            function handleKey(key: int, modifiers: int, isAutoRepeat: bool): bool {
                if (!window.shouldShow) return false;
                const ctrl = (modifiers & Qt.ControlModifier) !== 0;
                if (key === Qt.Key_Tab) { content.cycleCategory(1); return true; }
                if (key === Qt.Key_Backtab) { content.cycleCategory(-1); return true; }
                if (ctrl && key === Qt.Key_T) { EmojiState.setTone((EmojiState.tone + 1) % 6); return true; }
                if (ctrl && (key === Qt.Key_Return || key === Qt.Key_Enter)) {
                    if (!isAutoRepeat) window.act(content.current, true);
                    return true;
                }
                return false;
            }

            Picker {
                id: picker
                anchors.centerIn: parent
                presence: window.presence
                layout: "grid"
                columns: 10
                cellSize: Tokens.px(48)
                maxVisibleRows: 6
                model: content.shown
                placeholder: "Buscar emoji..."
                emptyText: EmojiState.ready ? (content.category === "recent" && !picker.query ? "Todavía no usaste ningún emoji" : "Sin resultados") : ""
                hints: "←↑↓→ navegar   ⏎ escribir   ctrl+⏎ copiar   tab categoría   ctrl+t tono   esc cerrar"
                keyHandler: (event) => content.handleKey(event.key, event.modifiers, event.isAutoRepeat)
                onAccepted: (item) => window.act(item, false)
                onDismissed: EmojiState.close()

                // Pestañas de categoria (sin ninguna marcada mientras se busca).
                header: Component {
                    RowLayout {
                        spacing: Tokens.space.xs
                        Repeater {
                            model: window.categories
                            Rectangle {
                                id: tab
                                required property var modelData
                                readonly property bool on: !picker.query && content.category === tab.modelData.id
                                Layout.fillWidth: true
                                implicitHeight: Tokens.px(36)
                                radius: Tokens.radius.md
                                color: tab.on ? Colors.accentAltContainer : "transparent"
                                Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }
                                StateLayer { hovered: tabMouse.containsMouse; pressed: tabMouse.pressed }
                                Icon {
                                    anchors.centerIn: parent
                                    name: tab.modelData.icon
                                    filled: tab.on
                                    color: tab.on ? Colors.textOnAccentAltContainer : Colors.textMuted
                                }
                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        content.category = tab.modelData.id;
                                        picker.reset();
                                    }
                                }
                            }
                        }
                    }
                }

                delegate: Rectangle {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: cell.index === picker.currentIndex
                    width: picker.cellSize
                    height: picker.cellSize
                    radius: Tokens.radius.md
                    color: cell.selected ? Colors.accentAltContainer : "transparent"
                    StateLayer { hovered: cellMouse.containsMouse; pressed: cellMouse.pressed }
                    // Imagen si ya estan generadas; si no (o si falta), texto.
                    Image {
                        id: cellImage
                        anchors.centerIn: parent
                        width: Tokens.px(28)
                        height: Tokens.px(28)
                        sourceSize: Qt.size(Tokens.px(56), Tokens.px(56))
                        asynchronous: true
                        source: EmojiState.imageOf(cell.modelData)
                    }
                    // Mientras la imagen carga no se dibuja nada (dibujar el
                    // texto un instante llenaria la cache de glifos de color).
                    Text {
                        visible: !EmojiState.imagesReady || cellImage.status === Image.Error
                        anchors.centerIn: parent
                        text: visible ? window.glyph(cell.modelData) : ""
                        font.family: Tokens.font.emoji
                        font.pixelSize: Tokens.px(28)
                    }
                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: picker.currentIndex = cell.index
                        onClicked: window.act(cell.modelData, false)
                    }
                }

                // Emoji elegido: grande, nombre, claves y el tono.
                detail: Component {
                    Rectangle {
                        implicitHeight: Tokens.px(64)
                        radius: Tokens.radius.md
                        color: Colors.surfaceHighest
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.space.md
                            anchors.rightMargin: Tokens.space.md
                            spacing: Tokens.space.md
                            Item {
                                implicitWidth: Tokens.px(40)
                                implicitHeight: Tokens.px(40)
                                Image {
                                    id: bigImage
                                    anchors.fill: parent
                                    asynchronous: true
                                    source: content.current ? EmojiState.imageOf(content.current) : ""
                                }
                                Text {
                                    visible: !EmojiState.imagesReady || bigImage.status === Image.Error
                                    anchors.centerIn: parent
                                    text: visible && content.current ? window.glyph(content.current) : ""
                                    font.family: Tokens.font.emoji
                                    font.pixelSize: Tokens.px(40)
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.space.hair
                                Text {
                                    Layout.fillWidth: true
                                    text: content.current ? content.current.n : ""
                                    color: Colors.text
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.body
                                    font.weight: Tokens.weight.semibold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: content.current ? [content.current.en].concat(content.current.k || []).join(" · ") : ""
                                    color: Colors.textMuted
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.caption
                                    elide: Text.ElideRight
                                }
                            }
                            // Tono de piel global (Ctrl+T o clic): el nombre del tono
                            // y un aro en el elegido; "sin tonos" si este emoji no
                            // los admite (el tono igual queda elegido para los demas).
                            Text {
                                text: window.toneNames[EmojiState.tone] + (content.current && !content.current.t ? " · sin tonos" : "")
                                color: Colors.textMuted
                                font.family: Tokens.font.ui
                                font.pixelSize: Tokens.type.caption
                            }
                            Row {
                                spacing: Tokens.space.xs
                                Repeater {
                                    model: 6
                                    Item {
                                        id: dot
                                        required property int index
                                        readonly property bool on: dot.index === EmojiState.tone
                                        width: Tokens.px(24)
                                        height: Tokens.px(24)
                                        // Aro separado del punto: se ve sobre cualquier color.
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: "transparent"
                                            border.width: 2
                                            border.color: Colors.accent
                                            visible: dot.on
                                        }
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: dot.on ? Tokens.px(16) : Tokens.px(14)
                                            height: width
                                            radius: width / 2
                                            color: window.toneColors[dot.index]
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: EmojiState.setTone(dot.index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
