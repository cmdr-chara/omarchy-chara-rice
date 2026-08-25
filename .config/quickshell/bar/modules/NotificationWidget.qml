import QtQuick
import Quickshell

Item {
    id: rootMod
    required property var root

    readonly property string tooltipText: root.notifCount > 0
        ? (root.notifCount + (root.notifCount === 1 ? " notification" : " notifications"))
        : "No notifications"

    implicitWidth: 22
    implicitHeight: 28

    IconText {
        id: bellIcon
        anchors.centerIn: parent
        text: "\uE7F4"   // notifications (bell)
        font.pixelSize: 15
        color: root.notifCount > 0
            ? root.ink
            : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.4)
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Minimal unread marker: warm gold is readable without dominating the bar.
    // The exact count remains available in the tooltip and notification panel.
    Rectangle {
        visible: root.notifCount > 0
        width: 6
        height: 6
        radius: 3
        color: root.color03
        anchors {
            verticalCenter: bellIcon.verticalCenter; verticalCenterOffset: -7
            horizontalCenter: bellIcon.horizontalCenter; horizontalCenterOffset: 6
        }
    }

    TooltipMixin { id: tip; root: rootMod.root; owner: rootMod; text: rootMod.tooltipText }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tip.show()
        onExited: { tip.hide() }
        onClicked: { tip.hide(); root.notifVisible = !root.notifVisible }
    }
}
