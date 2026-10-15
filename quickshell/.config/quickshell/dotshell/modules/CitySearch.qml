// Busqueda de ciudad para el clima (Fase 10 B4; sacada de WeatherView, unica
// copia): el campo, una consulta al dejar de escribir (weather-fetch --search,
// geocoding de Open-Meteo, solo mientras se busca), el estado y los
// resultados. Quien la usa decide que hacer con la elegida: chosen(place).
// La usan la vista Hoy del dashboard y la fila "Ciudad del clima" del centro.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml

ColumnLayout {
    id: root

    property var results: []
    property bool searching: false
    property bool failed: false
    property alias text: field.text
    signal chosen(var place)
    signal escaped

    function focusInput(): void {
        field.focusInput();
    }
    function reset(): void {
        field.text = "";
        root.results = [];
        root.failed = false;
    }
    function search(query: string): void {
        const q = query.trim();
        if (q.length < 2) {
            root.results = [];
            return;
        }
        proc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/weather-fetch", "--search", q];
        root.searching = true;
        root.failed = false;
        proc.running = true;
    }
    property Process proc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                root.searching = false;
                try {
                    root.results = JSON.parse(this.text);
                } catch (e) {
                    root.results = [];
                    root.failed = true;
                }
            }
        }
    }

    spacing: Tokens.space.sm

    // Una consulta al dejar de escribir, no una por tecla.
    SearchField {
        id: field
        objectName: "weatherSearch"
        Layout.fillWidth: true
        size: "regular"
        placeholder: I18n.tr("Search a city…")
        onTextChanged: searchDelay.restart()
        keyHandler: (event) => {
            if (event.key === Qt.Key_Return) {
                if (root.results.length) root.chosen(root.results[0]);
                return true;
            }
            if (event.key === Qt.Key_Escape) {
                root.escaped();
                return true;
            }
            return false;
        }
        Timer { id: searchDelay; interval: 400; onTriggered: root.search(field.text) }
    }
    Text {
        visible: root.searching || root.failed || (field.text.trim().length >= 2 && !root.searching && root.results.length === 0)
        Layout.fillWidth: true
        text: root.searching ? I18n.tr("Searching…") : root.failed ? I18n.tr("Couldn't search (offline?)") : I18n.tr("No results")
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
    }
    Repeater {
        model: root.results
        Rectangle {
            id: res
            required property var modelData
            required property int index
            Layout.fillWidth: true
            implicitHeight: Tokens.px(44)
            radius: Tokens.radius.md
            color: res.index === 0 ? Colors.accentAltContainer : "transparent"
            StateLayer { hovered: resMouse.containsMouse; pressed: resMouse.pressed }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Tokens.space.md
                width: parent.width - Tokens.space.md * 2
                Text { width: parent.width; text: res.modelData.name; color: res.index === 0 ? Colors.textOnAccentAltContainer : Colors.text; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.body; font.weight: Tokens.weight.medium; elide: Text.ElideRight }
                Text { width: parent.width; text: res.modelData.detail; color: res.index === 0 ? Colors.textOnAccentAltContainer : Colors.textMuted; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; elide: Text.ElideRight }
            }
            MouseArea {
                id: resMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.chosen(res.modelData)
            }
        }
    }
}
