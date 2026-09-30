// Notification card. Pure presentational — no service, Notification, or
// ListModel references. The popup container drives lifetime; the history
// panel drives static rendering. Both use the same component.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "../NotificationLogic.js" as NotificationLogic

BorderSurface {
  id: root

  property string app: ""
  property string appIcon: ""
  property string summary: ""
  property string body: ""
  property string image: ""
  // Nerd Font glyph rendered in the icon slot when no real icon is set.
  // Used by omarchy-notification-send so user-action toasts (`Silenced
  // notifications` etc.) show their bell/lock/etc. glyph without leaking
  // into the summary text.
  property string glyph: ""
  // NotificationUrgency: Low=0, Normal=1, Critical=2 (upstream).
  property int urgency: 1
  property double timestamp: 0
  property int cornerRadius: 0
  property real progress: 1.0

  // System monospace font injected by the container.
  property string fontFamily: ""

  readonly property bool hovered: hoverTracker.hovered

  signal closeRequested()
  signal cardClicked()
  // Prefer per-notification media/avatar data, then fall back to the app icon.
  // The `check` flag avoids Qt's missing-texture placeholder for unknown names.
  readonly property string smallIconSource: image.length > 0 ? image : iconSource(appIcon)
  readonly property bool hasGlyph: glyph.length > 0
  readonly property bool compactGlyph: NotificationLogic.shouldRenderCompactGlyph(glyph, smallIconSource, singleLineToast)
  readonly property bool hasSmallIcon: smallIconSource.length > 0
  readonly property bool summaryStartsWithGlyph: NotificationLogic.summaryStartsWithGlyph(summary)
  readonly property bool singleLineToast: sanitizedBody.length === 0
  readonly property bool collapseRedundantIcon: singleLineToast && !hasGlyph && summaryStartsWithGlyph
  readonly property string sanitizedBody: sanitizeBody(body)
  readonly property string styledBody: sanitizedBody.replace(/\r\n|\r|\n/g, "<br/>")
  readonly property string sourceLabel: {
    var value = String(app || "").trim()
    if (value === "" || value === "notify-send") return "SYSTEM"
    if (value === "omarchy-action") return "OMARCHY"
    return value.toUpperCase()
  }
  readonly property string clockLabel: {
    var date = new Date(timestamp > 0 ? timestamp : Date.now())
    return Qt.formatTime(date, "HH:mm")
  }

  readonly property color dimColor: Qt.darker(Color.notifications.text, 1.4)
  readonly property color bodyColor: Qt.darker(Color.notifications.text, 1.15)
  readonly property string eventText: (app + " " + summary + " " + body).toLowerCase()
  readonly property color soulColor: {
    if (urgency === 2 || eventText.indexOf("error") >= 0 || eventText.indexOf("failed") >= 0 || eventText.indexOf("critical") >= 0) return "#EF5261"
    if (eventText.indexOf("warning") >= 0 || eventText.indexOf("power") >= 0 || eventText.indexOf("reboot") >= 0) return "#DE9369"
    if (eventText.indexOf("brightness") >= 0) return "#E9C079"
    if (eventText.indexOf("screenshot") >= 0 || eventText.indexOf("capture") >= 0) return "#88A9DB"
    if (eventText.indexOf("success") >= 0 || eventText.indexOf("complete") >= 0 || eventText.indexOf("updated") >= 0 || eventText.indexOf("installed") >= 0) return "#9BC28D"
    if (eventText.indexOf("network") >= 0 || eventText.indexOf("wifi") >= 0 || eventText.indexOf("bluetooth") >= 0 || eventText.indexOf("touchpad") >= 0) return "#7EC5C8"
    if (eventText.indexOf("audio") >= 0 || eventText.indexOf("volume") >= 0 || eventText.indexOf("media") >= 0 || eventText.indexOf("spotify") >= 0 || eventText.indexOf("song") >= 0) return "#C998CF"
    if (urgency === 0) return "#7EC5C8"
    return Color.accent
  }
  readonly property color accentColor: soulColor
  // The shared surface frame stays quiet; soul color communicates the event.
  readonly property color risePillBorder: Color.notifications.border
  readonly property var cardBorderSpec: Border.flat(
    urgency === 2 ? Util.alpha(soulColor, 0.82) : risePillBorder,
    urgency === 2 ? Math.max(2, Style.space(2)) : 1
  )

  function sanitizeBody(s) {
    return NotificationLogic.sanitizeBody(s, app, appIcon)
  }

  function iconSource(icon) {
    var value = String(icon || "")
    if (value.length === 0) return ""
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return Util.fileUrl(value)
    return Quickshell.iconPath(value, true)
  }

  implicitWidth: Style.space(380)
  // Add vertical border insets so mainColumn (inset by border on top/left/right)
  // doesn't push content under the bottom edge.
  implicitHeight: mainColumn.implicitHeight + borderTop + borderBottom
  radius: 2
  color: Color.notifications.background
  borderSpec: cardBorderSpec
  clip: true

  HoverHandler { id: hoverTracker }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        root.closeRequested()
      } else {
        root.cardClicked()
      }
    }
  }

  ColumnLayout {
    id: mainColumn
    // Inset by the card border so the content doesn't paint over the card's
    // outer border.
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: root.borderTop
    anchors.leftMargin: root.borderLeft
    anchors.rightMargin: root.borderRight
    spacing: 0

    // Text content.
    RowLayout {
      Layout.fillWidth: true
      Layout.leftMargin: Style.space(12)
      Layout.rightMargin: Style.space(12)
      Layout.topMargin: root.singleLineToast ? Style.space(7) : Style.space(10)
      Layout.bottomMargin: root.singleLineToast ? Style.space(7) : Style.space(10)
      spacing: root.collapseRedundantIcon ? 0 : (root.compactGlyph ? Style.space(8) : Style.space(12))

      Item {
        id: soulSlot
        Layout.preferredWidth: Style.space(22)
        Layout.preferredHeight: Style.space(26)
        Layout.alignment: Qt.AlignVCenter

        scale: 1.0
        SequentialAnimation on scale {
          running: root.urgency === 2
          loops: Animation.Infinite
          NumberAnimation { to: 1.12; duration: 520; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1.00; duration: 520; easing.type: Easing.InOutQuad }
        }

        Canvas {
          id: soulCanvas
          anchors.centerIn: parent
          width: 21
          height: 18
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.soulColor
            var px = 3
            var rows = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
            for (var y = 0; y < rows.length; y++) {
              for (var x = 0; x < rows[y].length; x++) {
                if (rows[y][x] === "1") ctx.fillRect(x * px, y * px, px, px)
              }
            }
          }
        }
      }

      Item {
        id: smallIconSlot
        Layout.preferredWidth: visible ? Style.space(40) : 0
        Layout.preferredHeight: visible ? Style.space(40) : 0
        Layout.alignment: Qt.AlignVCenter
        // Hide the slot when the icon failed to resolve (themed-icon name
        // not in the user's icon theme) AND we don't have a glyph fallback
        // — prevents rendering Qt's pink broken-image placeholder.
        visible: !root.collapseRedundantIcon && !root.compactGlyph && (root.hasSmallIcon || root.hasGlyph) && (root.hasGlyph || smallIconImage.status !== Image.Error)

        Image {
          id: smallIconImage
          anchors.fill: parent
          source: root.smallIconSource
          sourceSize.width: smallIconSlot.width * Screen.devicePixelRatio
          sourceSize.height: smallIconSlot.height * Screen.devicePixelRatio
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          visible: !root.hasGlyph || smallIconImage.status === Image.Ready
        }

        // Glyph fallback (Nerd Font character) when no image icon is
        // available. Used by omarchy-notification-send's `-g` flag.
        Text {
          anchors.centerIn: parent
          visible: root.hasGlyph && smallIconImage.status !== Image.Ready
          text: root.glyph
          color: Color.notifications.text
          font.family: root.fontFamily
          font.pixelSize: Style.font.displayLarge
        }
      }

      Text {
        Layout.alignment: Qt.AlignVCenter
        visible: root.compactGlyph
        text: root.glyph
        color: Color.notifications.text
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: Style.space(2)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            Layout.fillWidth: true
            text: root.sourceLabel
            color: root.soulColor
            font.family: "Determination Mono Web"
            font.pixelSize: 15
            font.bold: true
            font.letterSpacing: 0.8
            elide: Text.ElideRight
          }

          Text {
            text: root.clockLabel
            color: root.dimColor
            font.family: root.fontFamily || Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Text {
          Layout.fillWidth: true
          visible: root.summary.length > 0
          text: root.summary
          font.family: root.fontFamily || Style.font.family
          color: Color.notifications.text
          font.pixelSize: Style.font.title
          font.bold: true
          wrapMode: Text.WordWrap
          elide: Text.ElideRight
          maximumLineCount: 2
        }

        Text {
          Layout.fillWidth: true
          Layout.topMargin: Style.space(2)
          visible: root.sanitizedBody.length > 0
          text: root.styledBody
          textFormat: Text.StyledText
          font.family: root.fontFamily || Style.font.family
          color: root.bodyColor
          font.pixelSize: Style.font.title
          wrapMode: Text.WordWrap
          elide: Text.ElideRight
          maximumLineCount: 3
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.leftMargin: Style.space(10)
      Layout.rightMargin: Style.space(10)
      Layout.bottomMargin: Style.space(5)
      Layout.preferredHeight: 2
      radius: 1
      color: Util.alpha(root.soulColor, 0.10)
      clip: true

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.progress))
        height: parent.height
        radius: 1
        color: Util.alpha(root.soulColor, 0.68)

        Behavior on width {
          NumberAnimation { duration: 50; easing.type: Easing.Linear }
        }
      }
    }
  }

  onSoulColorChanged: soulCanvas.requestPaint()

}
