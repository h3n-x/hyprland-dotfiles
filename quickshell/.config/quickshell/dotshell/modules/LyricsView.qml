// Letra de la cancion dentro del reproductor (Fase 12 B1, P12.2): ocupa el
// lugar del titulo cuando la letra esta abierta (tecla L o "Letra"). La linea
// actual en el centro, en texto pleno; las demas atenuadas. Se desplaza solo
// al cambiar de linea (motion.medium; con movimiento reducido, salta). Clic en
// una linea = ir ahi (si el reproductor lo permite). Sin sincronia, el texto
// plano con su barra; sin letra, una frase que dice por que.
//
// Los datos y la sincronia son de LyricsState; aca solo se dibuja.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, LyricsState.qml, MediaState.qml

Item {
    id: root
    property bool canSeek: false
    // Alto de una linea: el del texto de la actual, para que entren unas cuatro.
    readonly property int lineHeight: Math.round(Tokens.type.title * 1.55)

    readonly property string message: {
        const s = LyricsState.status;
        if (s === "searching") return "Buscando la letra…";
        if (s === "off") return "Sin letra en tu equipo. Puedes buscarla en internet: Configuración → Multimedia → Letras.";
        if (s === "none") return "No se encontró la letra de esta canción.";
        if (s === "offline") return "No se pudo consultar LRCLIB ahora (sin conexión o el servicio no respondió). Se vuelve a intentar solo.";
        if (LyricsState.instrumental) return "Instrumental";
        return "";
    }

    // ---- Sincronizada ----------------------------------------------------------------------
    ListView {
        id: list
        anchors.fill: parent
        visible: LyricsState.synced && !root.message
        clip: true
        interactive: false
        model: LyricsState.lines
        currentIndex: Math.max(0, LyricsState.current)
        // La linea actual en el centro; se mueve solo cuando cambia.
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (height - root.lineHeight) / 2
        preferredHighlightEnd: (height + root.lineHeight) / 2
        highlightMoveDuration: Tokens.motion.scale > 0 ? Tokens.motion.medium : 0
        highlightMoveVelocity: -1
        delegate: Item {
            id: line
            required property var modelData
            required property int index
            readonly property bool now: line.index === LyricsState.current
            width: list.width
            height: root.lineHeight
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                text: line.modelData.text || "♪"
                elide: Text.ElideRight
                color: line.now ? Colors.text : Colors.textMuted
                opacity: line.now ? 1 : Math.abs(line.index - LyricsState.current) === 1 ? 0.8 : 0.5
                font.family: Tokens.font.ui
                font.pixelSize: line.now ? Tokens.type.title : Tokens.type.body
                font.weight: line.now ? Tokens.weight.semibold : Tokens.weight.regular
                Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.canSeek
                cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: LyricsState.seekTo(line.index)
            }
        }
    }

    // ---- Texto plano -------------------------------------------------------------------------
    Flickable {
        anchors.fill: parent
        visible: !LyricsState.synced && !!LyricsState.plain && !root.message
        clip: true
        contentHeight: plainText.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        Text {
            id: plainText
            width: parent.width
            text: LyricsState.plain
            wrapMode: Text.WordWrap
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            lineHeight: 1.15
        }
    }

    // ---- Sin letra: por que ------------------------------------------------------------------
    Text {
        anchors.fill: parent
        visible: !!root.message
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        text: root.message
        color: LyricsState.instrumental ? Colors.text : Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: LyricsState.instrumental ? Tokens.type.title : Tokens.type.body
    }
}
