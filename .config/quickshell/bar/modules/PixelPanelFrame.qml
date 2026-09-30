import QtQuick

// Static decoration only: all panel input remains with its existing controls.
Item {
    id: frame
    property color accent: "#F13B45"
    anchors.fill: parent
    z: 8

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 2
        border.width: 1
        border.color: Qt.rgba(frame.accent.r, frame.accent.g, frame.accent.b, 0.35)
    }

    Repeater {
        model: 4
        Item {
            required property int index
            x: index % 2 === 0 ? 0 : frame.width - 20
            y: index < 2 ? 0 : frame.height - 12
            width: 20
            height: 12
            Rectangle {
                x: 0
                y: parent.index < 2 ? 0 : parent.height - height
                width: parent.width
                height: 2
                color: frame.accent
            }
            Rectangle {
                x: parent.index % 2 === 0 ? 0 : parent.width - width
                width: 2
                height: parent.height
                color: frame.accent
            }
        }
    }
}
