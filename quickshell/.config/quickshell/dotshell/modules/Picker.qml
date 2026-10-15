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
    property string emptyText: I18n.tr("No results")
    property int maxVisibleRows: 8
    property Component header: null
    property Component preview: null
    property int listWidth: Tokens.panel.launcherWidth
    property int previewWidth: Tokens.px(340)
    readonly property bool fixedHeight: root.preview !== null
    property var keyHandler: null
    property var keyReleaseHandler: null
    property string layout: "list" // list | grid
    property int columns: 10
    property int cellSize: Tokens.px(48)
    property int cellHeight: root.cellSize
    // Reusar celdas al filtrar (emoji); el selector de ventanas lo apaga.
    property bool reuseCells: true
    property Component detail: null
    // Presence de la ventana (apertura/cierre); null = sin animar.
    property var presence: null

    readonly property string query: searchBox.text
    property alias currentIndex: listView.currentIndex

    signal accepted(var item)
    signal dismissed()

    // Al abrir: busqueda vacia, primer elemento, foco en el campo.
    function focusSearch(): void {
        searchBox.focusInput();
    }

    function reset(): void {
        searchBox.text = "";
        listView.currentIndex = 0;
        searchBox.focusInput();
    }

    // Teclas del selector: primero las de quien lo usa (keyHandler); despues
    // las propias. En la rejilla izquierda/derecha mueven la seleccion; en la
    // lista siguen al texto (false).
    function handleKey(event: var): bool {
        if (root.keyHandler && root.keyHandler(event)) return true;
        const grid = root.layout === "grid";
        switch (event.key) {
        case Qt.Key_Down:
            if (grid) gridView.moveCurrentIndexDown();
            else listView.incrementCurrentIndex();
            return true;
        case Qt.Key_Up:
            if (grid) gridView.moveCurrentIndexUp();
            else listView.decrementCurrentIndex();
            return true;
        case Qt.Key_Left:
            if (!grid) return false;
            gridView.moveCurrentIndexLeft();
            return true;
        case Qt.Key_Right:
            if (!grid) return false;
            gridView.moveCurrentIndexRight();
            return true;
        case Qt.Key_Return: {
            const item = root.model[listView.currentIndex];
            if (item) root.accepted(item);
            return true;
        }
        case Qt.Key_Escape:
            root.dismissed();
            return true;
        }
        return false;
    }

    readonly property int count: root.model ? root.model.length : 0
    // Fila de 44 + 2 de separacion entre filas (el delegate resta el hueco).
    readonly property int rowHeight: Tokens.row.heightLarge + Tokens.space.hair
    readonly property int visibleRows: root.fixedHeight ? root.maxVisibleRows : Math.max(1, Math.min(root.maxVisibleRows, root.count))
    readonly property int listHeight: root.layout === "grid" ? root.maxVisibleRows * root.cellHeight
        : ((root.count > 0 || root.fixedHeight) ? root.visibleRows * root.rowHeight : Tokens.px(56))

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

            // El campo de busqueda de la shell (P8.8): todas las teclas pasan
            // por handleKey antes que el texto.
            SearchField {
                id: searchBox
                Layout.fillWidth: true
                placeholder: root.placeholder
                keyHandler: (event) => root.handleKey(event)
                keyReleaseHandler: root.keyReleaseHandler
                onTextChanged: listView.currentIndex = 0
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
                    color: Colors.textMuted
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
                color: Colors.textMuted
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
                // Con texto grande (Fase 10 B2), si no entran, los atajos pasan
                // a dos lineas (solo entonces: en una linea quedan igual).
                readonly property bool wraps: footerMetrics.advanceWidth > parent.width
                Layout.maximumWidth: parent.width
                wrapMode: footerText.wraps ? Text.WordWrap : Text.NoWrap
                horizontalAlignment: footerText.wraps ? Text.AlignHCenter : Text.AlignLeft
                text: root.hints
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
            }
            TextMetrics {
                id: footerMetrics
                text: root.hints
                font: footerText.font
            }
        }
    }
}
