// Singleton chico para los popups OSD (Osd.qml, una instancia por
// pantalla). Volume.qml/Microphone.qml/Backlight.qml llaman a show()
// cuando cambia el valor -- reemplaza a los notify-send que usaban antes
// para esto (Battery.qml sigue con notify-send real para sus umbrales de
// warning/critical/full, esas SI tienen que persistir, no desaparecer
// solas como un OSD).
pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool visible: false
    property string icon: ""
    property real value: 0
    property string label: ""

    function show(icon, value, label) {
        root.icon = icon;
        root.value = value;
        root.label = label;
        root.visible = true;
        hideTimer.restart();
    }

    property Timer hideTimer: Timer {
        // appearance.osdSeconds (settings store)
        interval: SettingsState.value("appearance.osdSeconds") * 1000
        onTriggered: root.visible = false
    }
}
