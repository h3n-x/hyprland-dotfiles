// Popups temporales de notificaciones reales (no OSD -- ver Osd.qml para
// eso) -- reemplaza a las notificaciones emergentes de swaync. Una
// instancia por pantalla (ver shell.qml). Se autodescartan a los
// expireTimeout segundos salvo urgencia critica (quedan hasta que el
// usuario las cierra a mano, mismo criterio que la mayoria de los
// daemons de notificaciones).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".." // Colors.qml, Tokens.qml, NotificationState.qml, AppInfo.qml, SettingsState.qml

PanelWindow {
    id: toastWindow

    // Alto completo de la pantalla a proposito: los toasts se reacomodan con
    // un spring (P2.7) y una ventana que se achicara al instante los recortaria
    // a mitad de camino (la geometria de las ventanas no se anima, guia 3.6.1).
    // El input queda limitado a los toasts (mask) y el blur solo cae donde hay
    // tarjeta (ignore_alpha).
    // Donde aparecen (notifications.position, Fase 10 B4): arriba o abajo a la
    // derecha (la ventana va a lo alto de la pantalla y la pila arriba o abajo)
    // o arriba al centro (sin anclar a los lados, el compositor la centra).
    readonly property string position: SettingsState.value("notifications.position") || "top-right"
    readonly property bool atBottom: toastWindow.position === "bottom-right"
    anchors {
        top: true
        right: toastWindow.position !== "top-center"
        bottom: true
    }
    // Debajo de la barra y alineado con su borde derecho, igual que
    // ControlCenter.qml (mismo ancho: los toasts quedan encolumnados con el panel).
    // La ventana suma alrededor el margen de la sombra de nivel 3 y solo
    // acepta input sobre los toasts (mask).
    readonly property int shadowMargin: Tokens.elevationShadow[3].blur + Tokens.elevationShadow[3].offsetY
    WlrLayershell.namespace: "quickshell-panel"
    // Capa Overlay (Fase 8 B6): por encima de una pantalla completa; que
    // avisos se ven ahi lo decide FullscreenState al llegar cada uno.
    WlrLayershell.layer: WlrLayer.Overlay
    // Nombre fijo de la pantalla: "screen" se vuelve a notificar al mostrar u
    // ocultar la ventana y leerlo en "toasts" (que decide visible) cerraria
    // un ciclo.
    property string screenName: ""
    onScreenChanged: if (toastWindow.screen && toastWindow.screen.name !== toastWindow.screenName) { toastWindow.screenName = toastWindow.screen.name; toastWindow.home = toastWindow.screen; }
    Component.onCompleted: { toastWindow.screenName = toastWindow.screen ? toastWindow.screen.name : ""; toastWindow.home = toastWindow.screen; }
    // Hasta notifications.maxVisible a la vez (0 = sin limite); los demas
    // esperan su turno (su tiempo corre al aparecer).
    readonly property int maxVisible: Number(SettingsState.value("notifications.maxVisible") || 0)
    readonly property var toasts: {
        const l = NotificationState.activeToasts.filter(n => NotificationState.shownOn(n, toastWindow.screenName));
        return toastWindow.maxVisible > 0 ? l.slice(0, toastWindow.maxVisible) : l;
    }
    // Pegados al marco (Fase 13 B2, estilo Marco): la pila es una sola columna
    // al ras de la barra y del lado fino (su esquina) o colgada del borde de
    // arriba (al centro), sin espacio entre avisos, con orejas donde se junta y
    // solo la esquina de afuera redonda; cada aviso sale del lado del marco.
    property var home: null
    readonly property bool attached: BarVisibility.framed(toastWindow.home)
    readonly property bool centered: toastWindow.position === "top-center"
    readonly property int ear: toastWindow.attached ? Tokens.frame.radius : 0
    function edgeGap(side: string): int {
        return BarVisibility.edgeSize(side);
    }
    margins {
        // Nunca encima de la barra, este en el borde que este (Fase 11 B3: inset).
        top: toastWindow.attached ? toastWindow.edgeGap("top") : Tokens.insetTop - toastWindow.shadowMargin
        right: toastWindow.attached ? toastWindow.edgeGap("right") : Tokens.insetRight - toastWindow.shadowMargin
        bottom: toastWindow.atBottom ? (toastWindow.attached ? toastWindow.edgeGap("bottom") : Tokens.insetBottom - toastWindow.shadowMargin) : 0
    }
    implicitWidth: Tokens.panel.widthLg + (!toastWindow.attached ? toastWindow.shadowMargin * 2 : toastWindow.centered ? 2 * toastWindow.ear : toastWindow.ear)
    color: "transparent"
    mask: Region { item: column }
    exclusionMode: ExclusionMode.Ignore
    visible: toastWindow.toasts.length > 0

    // Column (posicionador) y no ColumnLayout: el layout ubica a los hijos
    // desde C++ y saltea cualquier Behavior on y, asi que el reacomodo no se
    // animaba. Column dispara su transicion "move" cuando sale un toast.
    // Orejas (pegados): en la esquina (CornerEars, alineadas con la columna) o a
    // los costados de arriba (al centro).
    CornerEars {
        id: ears
        on: toastWindow.attached && !toastWindow.centered
        corner: toastWindow.atBottom ? "br" : "tr"
        x: column.x - ears.cardX
        y: column.y - ears.cardY
        cardW: column.width
        cardH: column.height
    }
    Repeater {
        model: toastWindow.attached && toastWindow.centered ? 2 : 0
        FrameCorner {
            required property int index
            x: index === 0 ? column.x - toastWindow.ear : column.x + column.width
            y: 0
            width: toastWindow.ear; height: toastWindow.ear
            v: "top"; h: index === 0 ? "right" : "left"
            color: Colors.surfaceLow
        }
    }

    Column {
        id: column
        x: !toastWindow.attached ? toastWindow.shadowMargin : toastWindow.centered ? toastWindow.ear : ears.cardX
        // Abajo: la pila crece hacia arriba desde el borde inferior.
        y: toastWindow.atBottom ? toastWindow.height - column.height - (toastWindow.attached ? 0 : toastWindow.shadowMargin)
                                : (toastWindow.attached ? 0 : toastWindow.shadowMargin)
        width: Tokens.panel.widthLg
        spacing: toastWindow.attached ? 0 : Tokens.space.sm

        // Reacomodo de la pila con el spring calibrado (guia 3.6.1).
        move: Transition {
            enabled: Tokens.motion.scale > 0
            SpringAnimation {
                properties: "y"
                spring: Tokens.motion.spring.qmlSpring
                damping: Tokens.motion.spring.qmlDamping
            }
        }

        Repeater {
            // ScriptModel en vez del array directo: activeToasts se reasigna
            // entero en cada cambio, y con el array el Repeater recreaba todos
            // los toasts (la entrada se repetia y no habia reacomodo). ScriptModel
            // compara los arrays y solo crea o destruye el que cambio.
            model: ScriptModel { values: toastWindow.toasts }

            // Nivel de elevacion 3 (surface_container_high translucida sobre
            // blur, sombra md); critica con borde en error.
            Surface {
                id: toast
                required property var modelData
                required property int index
                readonly property bool critical: toast.modelData.urgency === NotificationUrgency.Critical
                width: column.width
                implicitHeight: content.implicitHeight + Tokens.space.md * 2
                level: 3
                translucent: true
                framed: toastWindow.attached
                radius: Tokens.radius.lg
                border.color: toast.critical ? Colors.danger : Colors.divider
                // Pegados: el critico conserva su borde (dice algo).
                border.width: toast.critical ? 1 : toastWindow.attached ? 0 : 1
                // Pegados: redonda solo la esquina de afuera de la columna (abajo en
                // el primero o ultimo segun crezca), el resto recto.
                readonly property bool last: toast.index === toastWindow.toasts.length - 1
                readonly property bool first: toast.index === 0
                readonly property int r: Tokens.radius.lg
                topLeftRadius: !toastWindow.attached ? toast.r : (toastWindow.atBottom && toast.first ? toast.r : 0)
                topRightRadius: !toastWindow.attached ? toast.r : 0
                bottomLeftRadius: !toastWindow.attached ? toast.r : (!toastWindow.atBottom && toast.last ? toast.r : 0)
                bottomRightRadius: !toastWindow.attached ? toast.r : (toastWindow.centered && toast.last ? toast.r : 0)
                // Pegados: una linea entre avisos.
                Rectangle {
                    visible: toastWindow.attached && !toast.first
                    width: parent.width; height: 1
                    color: Colors.divider
                }

                // Entrada al aparecer; al cerrarlo (click o timer) primero anima
                // la salida y recien despues se descarta la notificacion. Si la
                // cierra la app o "Limpiar todo", sale sin animacion.
                Presence { id: presence; Component.onCompleted: open = true }
                property string pendingClose: ""
                function leave(kind) {
                    toast.pendingClose = kind;
                    presence.open = false;
                }
                Connections {
                    target: presence
                    function onShownChanged() {
                        if (presence.shown || !toast.pendingClose) return;
                        if (toast.pendingClose === "expire") toast.modelData.expire();
                        else toast.modelData.dismiss();
                    }
                }
                // Pegados: sale del lado del marco (a la derecha; al centro, de arriba).
                opacity: toastWindow.attached ? 1 : presence.progress
                scale: toastWindow.attached ? 1 : presence.contentScale
                transformOrigin: Item.TopRight
                transform: Translate {
                    x: toastWindow.attached && !toastWindow.centered ? (1 - presence.progress) * toast.width : 0
                    y: !toastWindow.attached ? presence.offsetY : toastWindow.centered ? -(1 - presence.progress) * toast.height : 0
                }

                Timer {
                    running: !toast.critical
                    interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout * 1000 : SettingsState.value("notifications.defaultSeconds") * 1000
                    onTriggered: toast.leave("expire")
                }

                ColumnLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Tokens.space.md
                    spacing: Tokens.space.xs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.gap.inline

                        // Icono de la app que manda la notificacion (identifica
                        // el origen; no es iconografia de la shell).
                        // Sin icono propio: el de su aplicacion (AppInfo), si se conoce.
                        IconImage {
                            id: appIconImage
                            readonly property string src: toast.modelData.appIcon ? Quickshell.iconPath(toast.modelData.appIcon)
                                : AppInfo.entry(toast.modelData.appName) ? AppInfo.icon(toast.modelData.appName) : ""
                            visible: !!appIconImage.src
                            Layout.alignment: Qt.AlignVCenter
                            implicitSize: Tokens.icon.md
                            source: appIconImage.src
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: toast.modelData.summary
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: Tokens.weight.semibold
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: !!toast.modelData.body
                        Layout.fillWidth: true
                        text: toast.modelData.body
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    RowLayout {
                        visible: toast.modelData.actions.length > 0
                        Layout.topMargin: Tokens.space.xs
                        spacing: Tokens.space.sm

                        Repeater {
                            model: toast.modelData.actions

                            // Boton tonal M3 (secondary_container), forma de pildora.
                            Rectangle {
                                id: actionBtn
                                required property var modelData
                                implicitWidth: actionLabel.implicitWidth + Tokens.pad.pillH * 2
                                implicitHeight: Tokens.pill.height
                                radius: Tokens.radius.pill(height)
                                color: Colors.accentAltContainer

                                StateLayer {
                                    hovered: actionMouse.containsMouse
                                    pressed: actionMouse.pressed
                                    contentColor: Colors.textOnAccentAltContainer
                                }

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionBtn.modelData.text
                                    color: Colors.textOnAccentAltContainer
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.label
                                    font.weight: Tokens.weight.medium
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: actionBtn.modelData.invoke()
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: toast.leave("dismiss")
                }
            }
        }
    }
}
