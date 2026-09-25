// Selector con busqueda (Fase 4 B0, decision E1): la tarjeta del launcher,
// sacada tal cual para reusarla en portapapeles, emoji y otros. Campo de
// busqueda, lista con seleccion y hover, estado vacio y ayuda de teclas; la
// tarjeta crece o encoge segun la cantidad de resultados (hasta
// maxVisibleRows filas, con scroll si hay mas).
//
// Quien lo usa da los datos ya filtrados (model, a partir de query) y la fila
// (delegate: en la fila, ListView.view.currentIndex es el elegido). Solo
// lista por ahora (B0-a): rejilla y vista previa llegan con su primer uso.
//
// Fase 4 B2 (portapapeles, primer uso): "header" (fila bajo el buscador) y
// "preview" (panel a la derecha, previewWidth). Con vista previa la altura es
// fija (no salta al filtrar). keyHandler(event) recibe las teclas que el
// selector no usa (devuelve true si las consume). Sin nada de esto el
// selector queda igual que en B0.
//
// Fase 4 B3 (emoji): layout "grid" (GridView de columns x cellSize, flechas
// en 2D; el indice sigue viviendo en la lista, que queda oculta y sin filas)
// y "detail" (franja entre los resultados y la ayuda de teclas). En la
// rejilla la altura es fija (maxVisibleRows filas de cellSize). Enter pasa
// primero por keyHandler (Ctrl+Enter del emoji).
//
// Fase 4 B4 (ventanas): cellHeight (celdas rectangulares; por defecto
// cuadradas) y keyReleaseHandler(event) para teclas soltadas (soltar Super).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

Item {
    id: root

    property var model: []
    property Component delegate
    property string placeholder: ""
    property string hints: ""
    property string emptyText: "Sin resultados"
    property int maxVisibleRows: 8
    property Component header: null
    property Component preview: null
    property int listWidth: Tokens.panel.launcherWidth
    property int previewWidth: 340
    readonly property bool fixedHeight: root.preview !== null
    property var keyHandler: null
    property var keyReleaseHandler: null
    property string layout: "list" // list | grid
    property int columns: 10
    property int cellSize: 48
    property int cellHeight: root.cellSize
    // Reusar celdas al filtrar (emoji); el selector de ventanas lo apaga.
    property bool reuseCells: true
    property Component detail: null
    // Presence de la ventana (apertura/cierre); null = sin animar.
    property var presence: null

    readonly property string query: searchField.text
    property alias currentIndex: listView.currentIndex

    signal accepted(var item)
    signal dismissed()

    // Al abrir: busqueda vacia, primer elemento, foco en el campo.
    function focusSearch(): void {
        searchField.forceActiveFocus();
    }

    function reset(): void {
        searchField.text = "";
        listView.currentIndex = 0;
        searchField.forceActiveFocus();
    }

    readonly property int count: root.model ? root.model.length : 0
    // Fila de 44 + 2 de separacion entre filas (el delegate resta el hueco).
    readonly property int rowHeight: Tokens.row.heightLarge + Tokens.space.hair
    readonly property int visibleRows: root.fixedHeight ? root.maxVisibleRows : Math.max(1, Math.min(root.maxVisibleRows, root.count))
    readonly property int listHeight: root.layout === "grid" ? root.maxVisibleRows * root.cellHeight
        : ((root.count > 0 || root.fixedHeight) ? root.visibleRows * root.rowHeight : 56)

    width: root.listWidth + (root.preview ? root.previewWidth + Tokens.space.md : 0)
    // margenes (md*2) + searchBox + [header] + lista/"sin resultados" + footer
    // + los huecos de "spacing" del ColumnLayout entre esas filas.
    height: Tokens.space.md * 2 + searchBox.height + (headerLoader.item ? headerLoader.height + Tokens.space.md : 0) + root.listHeight + (detailLoader.item ? detailLoader.height + Tokens.space.md : 0) + footerText.implicitHeight + Tokens.space.md * 2
    opacity: root.presence ? root.presence.progress : 1
    scale: root.presence ? root.presence.contentScale : 1
    Behavior on height { NumberAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

    // Nivel de elevacion 3 (surface_container_high translucida sobre blur,
    // sombra md). Radio xl con inset md: buscador y filas en radio md,
    // concentricos (Q1).
    Surface {
        anchors.fill: parent
        level: 3
        translucent: true
        radius: Tokens.radius.xl

        // Sin esto, clickear el padding de la tarjeta (no cubierto por ningun
        // control) atravesaria hacia el fondo de la ventana y la cerraria --
        // un Rectangle solo no consume clicks.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.space.md
            spacing: Tokens.space.md

            // Campo de busqueda en el contenedor mas alto; foco = borde primary.
            Rectangle {
                id: searchBox
                Layout.fillWidth: true
                implicitHeight: Tokens.row.heightLarge
                radius: Tokens.radius.md
                color: Colors.m3surfaceContainerHighest
                border.color: searchField.activeFocus ? Colors.m3primary : Colors.m3outlineVariant
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: Tokens.motion.fast } }

                Icon {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.space.md
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    color: Colors.m3onSurfaceVariant
                }

                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.space.md + searchIcon.width + Tokens.space.sm
                    anchors.rightMargin: Tokens.space.md
                    verticalAlignment: TextInput.AlignVCenter
                    color: Colors.m3onSurface
                    selectionColor: Colors.m3primary
                    selectedTextColor: Colors.m3onPrimary
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                    clip: true

                    onTextChanged: listView.currentIndex = 0
                    Keys.onPressed: (event) => {
                        if (root.keyHandler && root.keyHandler(event)) event.accepted = true;
                    }
                    Keys.onReleased: (event) => {
                        if (root.keyReleaseHandler && root.keyReleaseHandler(event)) event.accepted = true;
                    }
                    Keys.onDownPressed: root.layout === "grid" ? gridView.moveCurrentIndexDown() : listView.incrementCurrentIndex()
                    Keys.onUpPressed: root.layout === "grid" ? gridView.moveCurrentIndexUp() : listView.decrementCurrentIndex()
                    // En la rejilla izquierda/derecha mueven la seleccion; en
                    // la lista siguen moviendo el cursor del texto.
                    Keys.onLeftPressed: (event) => {
                        if (root.layout === "grid") gridView.moveCurrentIndexLeft();
                        else event.accepted = false;
                    }
                    Keys.onRightPressed: (event) => {
                        if (root.layout === "grid") gridView.moveCurrentIndexRight();
                        else event.accepted = false;
                    }
                    Keys.onReturnPressed: (event) => {
                        if (root.keyHandler && root.keyHandler(event)) return;
                        const item = root.model[listView.currentIndex];
                        if (item) root.accepted(item);
                    }
                    Keys.onEscapePressed: root.dismissed()
                }

                Text {
                    visible: searchField.text.length === 0
                    anchors.left: parent.left
                    anchors.leftMargin: searchField.anchors.leftMargin
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.placeholder
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                }
            }

            Loader {
                id: headerLoader
                Layout.fillWidth: true
                visible: !!item
                sourceComponent: root.header
            }

            RowLayout {
                visible: root.count > 0 || root.fixedHeight
                Layout.fillWidth: true
                Layout.preferredHeight: root.listHeight
                spacing: Tokens.space.md

                GridView {
                    id: gridView
                    visible: root.layout === "grid" && root.count > 0
                    Layout.preferredWidth: root.columns * root.cellSize
                    Layout.preferredHeight: root.listHeight
                    Layout.alignment: Qt.AlignHCenter
                    clip: true
                    cellWidth: root.cellSize
                    cellHeight: root.cellHeight
                    reuseItems: root.reuseCells
                    model: root.layout === "grid" ? root.model : []
                    currentIndex: listView.currentIndex
                    onCurrentIndexChanged: if (listView.currentIndex !== currentIndex) listView.currentIndex = currentIndex
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: root.delegate
                }

                ListView {
                    id: listView
                    visible: root.layout === "list" && root.count > 0
                    Layout.fillWidth: !root.preview
                    Layout.preferredWidth: root.listWidth - Tokens.space.md * 2
                    Layout.preferredHeight: root.listHeight
                    clip: true
                    model: root.model
                    currentIndex: 0
                    highlightMoveDuration: Tokens.motion.fast
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: root.layout === "list" ? root.delegate : null
                }

                // "Sin resultados" con vista previa (altura fija): en el lugar de la lista.
                Text {
                    visible: root.count === 0
                    Layout.preferredWidth: root.listWidth - Tokens.space.md * 2
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: root.emptyText
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                }

                Loader {
                    visible: !!root.preview
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: root.preview
                }
            }

            Text {
                visible: root.count === 0 && !root.fixedHeight
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: root.listHeight
                verticalAlignment: Text.AlignVCenter
                text: root.emptyText
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }

            Loader {
                id: detailLoader
                Layout.fillWidth: true
                visible: !!item
                sourceComponent: root.detail
            }

            Text {
                id: footerText
                Layout.alignment: Qt.AlignHCenter
                text: root.hints
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
            }
        }
    }
}
