import QtQuick

Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  readonly property color soulColor: "#ffd428"

  implicitWidth: content.implicitWidth + 16
  implicitHeight: bar ? bar.barSize : 36

  Row {
    id: content
    anchors.centerIn: parent
    spacing: 7

    Item {
      width: 18
      height: 16
      anchors.verticalCenter: parent.verticalCenter

      scale: 1.0
      SequentialAnimation on scale {
        running: true
        loops: Animation.Infinite
        NumberAnimation { to: 1.10; duration: 800; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 1.00; duration: 800; easing.type: Easing.InOutQuad }
      }

      Canvas {
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          ctx.fillStyle = root.soulColor
          var px = 2.5
          var rows = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
          for (var y = 0; y < rows.length; y++) {
            for (var x = 0; x < rows[y].length; x++) {
              if (rows[y][x] === "1") ctx.fillRect(x * px, y * px, px, px)
            }
          }
        }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "LV 20  ·  DETERMINED"
      color: bar ? bar.barForeground : "#f2f3ff"
      font.family: bar ? bar.fontFamily : "monospace"
      font.pixelSize: 12
      font.bold: true
      font.letterSpacing: 0.7
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: if (bar) bar.showTooltip(root, "Chara · Void — The True Path")
    onExited: if (bar) bar.hideTooltip(root)
  }
}
