import QtQuick

// Small pill button used across the config pages.
//
// `highlight` (accent fill) means SELECTED — the chosen option in a group, like
// the profile you're editing. For a button that reports a STATE instead, use
// `statusDot` with a semantic colour (Theme.ok / Theme.warn) and leave highlight
// off; a state toggle filled with accent reads as one more selected option.
Rectangle {
    id: b
    property string label: ""
    property bool highlight: false
    property color statusDot: "transparent"     // e.g. Theme.warn; transparent = none
    signal clicked()
    readonly property bool _dot: statusDot.a > 0
    implicitWidth: row.implicitWidth + 22; implicitHeight: 30; radius: 7
    color: highlight ? Theme.accent : (hh.hovered ? Theme.buttonHover : Theme.button)
    border.color: highlight ? Qt.lighter(Theme.accent, 1.2) : Theme.cardBorder
    border.width: 1
    opacity: enabled ? 1 : 0.45
    Behavior on color { ColorAnimation { duration: 100 } }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Rectangle {
            visible: b._dot
            anchors.verticalCenter: parent.verticalCenter
            width: 6; height: 6; radius: 3
            color: b.statusDot
        }
        Text {
            id: t; text: b.label
            anchors.verticalCenter: parent.verticalCenter
            color: b.highlight ? Theme.textOnAccent : Theme.text
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontM
        }
    }
    HoverHandler { id: hh }
    TapHandler { enabled: b.enabled; onTapped: b.clicked() }
}
