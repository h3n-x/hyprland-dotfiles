// Selector con busqueda (Fase 4 B0, decision E1): la tarjeta del launcher,
// sacada tal cual para reusarla en portapapeles, emoji y otros. Campo de
// busqueda, lista con seleccion y hover, estado vacio y ayuda de teclas; la
// tarjeta crece o encoge segun la cantidad de resultados (hasta
// maxVisibleRows filas, con scroll si hay mas).
//
// Quien lo usa da los datos ya filtrados (model, a partir de query) y la fila
// (delegate: en la fila, ListView.view.currentIndex es el elegido). Solo
// lista por ahora (B0-a): rejilla y vista previa llegan con su primer uso.
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
    // Presence de la ventana (apertura/cierre); null = sin animar.
    property var presence: null

    readonly property string query: searchField.text
    property alias currentIndex: listView.currentIndex

    signal accepted(var item)
    signal dismissed()

    // Al abrir: busqueda vacia, primer elemento, foco en el campo.
    function reset(): void {
        searchField.text = "";
        listView.currentIndex = 0;
        searchField.forceActiveFocus();
    }

    readonly property int count: root.model ? root.model.length : 0
    // Fila de 44 + 2 de separacion entre filas (el delegate resta el hueco).
    readonly property int rowHeight: Tokens.row.heightLarge + Tokens.space.hair
    readonly property int visibleRows: Math.max(1, Math.min(root.maxVisibleRows, root.count))
    readonly property int listHeight: root.count > 0 ? root.visibleRows * root.rowHeight : 56

    width: Tokens.panel.launcherWidth
    // margenes (md*2) + searchBox + lista/"sin resultados" + footer +
    // dos huecos de "spacing" del ColumnLayout (entre esas 3 filas).
    height: Tokens.space.md * 2 + searchBox.height + root.listHeight + footerText.implicitHeight + Tokens.space.md * 2
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
                    Keys.onDownPressed: listView.incrementCurrentIndex()
                    Keys.onUpPressed: listView.decrementCurrentIndex()
                    Keys.onReturnPressed: {
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

            ListView {
                id: listView
                visible: root.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: root.listHeight
                clip: true
                model: root.model
                currentIndex: 0
                highlightMoveDuration: Tokens.motion.fast
                boundsBehavior: Flickable.StopAtBounds
                delegate: root.delegate
            }

            Text {
                visible: root.count === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: root.listHeight
                verticalAlignment: Text.AlignVCenter
                text: root.emptyText
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
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
