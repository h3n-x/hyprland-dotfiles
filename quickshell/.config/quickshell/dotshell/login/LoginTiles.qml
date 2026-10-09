// Tarjetas sobre la tarjeta de la contrasena (Fase 9 B3): en el bloqueo, de
// estado y sin accion ("DE UN VISTAZO"); en el greeter, acciones (apagar,
// reiniciar, suspender, sesion). Cada tarjeta tiene una clave estable: la
// lista se sincroniza por clave, asi cuando llega un aviso o se desenchufa el
// cargador solo esa tarjeta entra o sale (M8) y las demas se reacomodan suave.
// Con `actionable`, responden al raton (M3: crecen al pasar, se achican al
// apretar) y avisan con activated(key). QtQuick puro.
import QtQuick
import QtQuick.Effects
import ".." // Colors.qml, Tokens.qml
import "../modules" // Icon

Column {
    id: tiles
    // [{ key, icon, title, sub, tone }]: tone "", "warning" o "danger".
    property var items: []
    property string title: ""
    property bool actionable: false
    signal activated(string key)

    spacing: Tokens.space.lg
    readonly property int tileWidth: Math.round((width - Tokens.space.md) / 2)
    readonly property int live: tileModel.liveCount

    // ---- Lista por clave ----------------------------------------------------------------------
    ListModel {
        id: tileModel
        property int liveCount: 0
    }
    function sync(): void {
        const want = tiles.items || [];
        const keys = want.map(t => t.key);
        // Las que se van: se marcan (animan la salida) y se quitan despues.
        for (let i = 0; i < tileModel.count; i++) {
            const e = tileModel.get(i);
            if (keys.indexOf(e.key) < 0 && !e.gone) tileModel.setProperty(i, "gone", true);
        }
        // Las que estan: en su orden; las nuevas se insertan donde van.
        let pos = 0;
        for (const t of want) {
            let found = -1;
            for (let i = 0; i < tileModel.count; i++) if (tileModel.get(i).key === t.key) { found = i; break; }
            const data = { key: t.key, icon: t.icon, title: t.title, sub: t.sub, tone: t.tone || "", gone: false };
            if (found < 0) tileModel.insert(Math.min(pos, tileModel.count), data);
            else {
                tileModel.set(found, data);
                if (found !== pos && pos < tileModel.count) tileModel.move(found, pos, 1);
            }
            pos++;
        }
        tileModel.liveCount = want.length;
        if (tileModel.count > want.length) reap.restart();
    }
    onItemsChanged: tiles.sync()
    Component.onCompleted: tiles.sync()
    Timer {
        id: reap
        interval: Tokens.motion.medium + 20
        onTriggered: {
            for (let i = tileModel.count - 1; i >= 0; i--) if (tileModel.get(i).gone) tileModel.remove(i);
        }
    }

    // ---- Encabezado -------------------------------------------------------------------------
    Text {
        visible: tiles.live > 0
        text: tiles.title
        // Texto principal, no el atenuado: es chico y va sobre el wallpaper (B2).
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
        font.weight: Tokens.weight.semibold
        font.letterSpacing: 2
        leftPadding: Tokens.space.sm
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colors.shadow
            shadowOpacity: Tokens.shadow.lg.opacity
            shadowBlur: 1.0
            blurMax: Tokens.shadow.md.blur
        }
    }

    // ---- Tarjetas ---------------------------------------------------------------------------
    Grid {
        columns: 2
        spacing: Tokens.space.md
        move: Transition {
            NumberAnimation { properties: "x,y"; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
        }
        Repeater {
            model: tileModel
            Rectangle {
                id: tile
                required property string key
                required property string icon
                required property string title
                required property string sub
                required property string tone
                required property bool gone
                readonly property color toneColor: tile.tone === "danger" ? Colors.dangerContainer
                    : tile.tone === "warning" ? Colors.warningContainer : Colors.accentContainer
                readonly property color onTone: tile.tone === "danger" ? Colors.textOnDangerContainer
                    : tile.tone === "warning" ? Colors.textOnWarningContainer : Colors.textOnAccentContainer

                width: tiles.tileWidth
                height: Tokens.px(96)
                radius: Tokens.radius.pill(height)
                color: Colors.tint(mouse.containsMouse ? Colors.surfaceHighest : Colors.surfaceHigh, Tokens.opacity.surface)
                Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }

                // M8: entra creciendo desde 0.9, sale encogiendose (solo esta tarjeta).
                property real appear: 0
                // Al terminar la creacion: para entonces "reducir movimiento" ya
                // llego (un Binding del anfitrion se aplica despues de crear esto).
                Component.onCompleted: Qt.callLater(() => tile.appear = 1)
                Behavior on appear {
                    NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
                }
                // Un solo valor animado para entrar y salir.
                onGoneChanged: if (tile.gone) tile.appear = 0
                opacity: tile.appear
                // M3: crece al pasar, se achica al apretar (solo si es una accion).
                scale: (0.9 + 0.1 * tile.appear)
                    * (!tiles.actionable ? 1 : mouse.pressed ? 0.95 : mouse.containsMouse ? 1.03 : 1)
                Behavior on scale { NumberAnimation { duration: Tokens.motion.fast; easing.type: Easing.OutBack } }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    enabled: tiles.actionable && !tile.gone
                    hoverEnabled: tiles.actionable
                    cursorShape: tiles.actionable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: tiles.activated(tile.key)
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.space.lg
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space.md
                    Rectangle {
                        width: Tokens.px(60)
                        height: Tokens.px(60)
                        radius: Tokens.px(30)
                        anchors.verticalCenter: parent.verticalCenter
                        color: tile.toneColor
                        Icon {
                            anchors.centerIn: parent
                            name: tile.icon
                            size: Tokens.px(26)
                            filled: true
                            color: tile.onTone
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: tile.title
                            // Un titulo largo (la cancion en el bloqueo) se corta.
                            width: Math.min(implicitWidth, Tokens.px(150))
                            elide: Text.ElideRight
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.headline
                            font.weight: Tokens.weight.semibold
                            font.features: Tokens.tabularNumbers
                        }
                        Text {
                            text: tile.sub
                            width: Tokens.px(150)
                            elide: Text.ElideRight
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                        }
                    }
                }
            }
        }
    }
}
