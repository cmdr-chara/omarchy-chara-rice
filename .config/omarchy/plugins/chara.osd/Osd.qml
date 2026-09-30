import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "OsdModel.js" as OsdModel

Item {
  id: root

  property bool opened: false
  property string icon: ""
  property string message: ""
  property string iconKey: ""
  property int value: 0
  property int maxValue: 100
  property bool hasProgress: true
  property int duration: 1200
  property int brightnessPercent: 50
  property string brightnessDevice: "intel_backlight"

  readonly property var audioSink: Pipewire.defaultAudioSink

  readonly property bool mediaOsd: iconKey.indexOf("media") === 0 || iconKey.indexOf("player") === 0
  readonly property string semanticText: (iconKey + " " + message).toLowerCase()
  readonly property string displayTitle: {
    var key = iconKey.toLowerCase()
    if (key.indexOf("volume") >= 0) return "Volume"
    if (key.indexOf("microphone") >= 0 || key.indexOf("mic") >= 0) return "Microphone"
    if (key.indexOf("brightness") >= 0 || key.indexOf("display") >= 0) return "Brightness"
    if (key.indexOf("touchpad") >= 0) return "Touchpad"
    if (key.indexOf("touch") >= 0) return "Touchscreen"
    if (key.indexOf("media") >= 0 || key.indexOf("player") >= 0) return "Media"
    if (key.indexOf("keyboard") >= 0) return "Keyboard"
    if (key.indexOf("reboot") >= 0 || key.indexOf("restart") >= 0) return "Restart"
    if (key.indexOf("shutdown") >= 0 || key.indexOf("power") >= 0) return "Power"
    if (key.indexOf("logout") >= 0 || key.indexOf("sign-out") >= 0) return "Log out"
    return "System"
  }
  readonly property color soulColor: {
    if (semanticText.indexOf("shutdown") >= 0 || semanticText.indexOf("error") >= 0 || semanticText.indexOf("failed") >= 0) return "#EF5261"
    if (semanticText.indexOf("power") >= 0 || semanticText.indexOf("reboot") >= 0 || semanticText.indexOf("restart") >= 0) return "#DE9369"
    if (semanticText.indexOf("capture") >= 0 || semanticText.indexOf("screenshot") >= 0) return "#88A9DB"
    if (semanticText.indexOf("brightness") >= 0 || semanticText.indexOf("display") >= 0) return "#E9C079"
    if (semanticText.indexOf("volume") >= 0 || semanticText.indexOf("audio") >= 0 || semanticText.indexOf("media") >= 0 || semanticText.indexOf("player") >= 0) return Color.accent
    if (semanticText.indexOf("touch") >= 0 || semanticText.indexOf("network") >= 0 || semanticText.indexOf("bluetooth") >= 0) return "#7EC5C8"
    if (semanticText.indexOf("keyboard") >= 0 || semanticText.indexOf("info") >= 0) return "#88A9DB"
    if (semanticText.indexOf("success") >= 0 || semanticText.indexOf("complete") >= 0) return "#9BC28D"
    return Color.accent
  }

  // The card is built out of measured columns instead of fixed widths, so it
  // keeps exactly `pad` between border and content on every side whatever
  // glyph or message it carries. Messages grow with their text up to
  // `maxMessageWidth` and elide beyond it.
  readonly property color risePillBorder: Color.popups.border
  readonly property int pad: Style.space(12)
  readonly property int gap: Style.space(10)
  // A glyph next to a message reads airier than it measures: the icon outline
  // and the letterforms both fall away from their ink extremes, so the space
  // between them opens up well past the nominal gap. Text takes two thirds of
  // it; the progress bar's hard edge keeps the full gap.
  readonly property int messageGap: Style.space(8)
  readonly property int barWidth: Style.space(130)
  readonly property int maxMessageWidth: root.mediaOsd ? Style.space(325) : Style.space(190)
  readonly property int soulWidth: Style.space(22)
  readonly property int rowHeight: Style.space(28)

  // Nerd Font glyphs draw well outside their monospace cell, so the icon
  // column is measured by ink rather than by advance width. Progress OSDs pin
  // it to the widest glyph the model can return, so the bar doesn't shift when
  // volume crosses an icon threshold.
  readonly property int iconInkWidth: Math.ceil(iconMetrics.tightBoundingRect.width)
  readonly property int iconWidth: root.hasProgress
    ? Math.max(root.iconInkWidth, Math.ceil(widestIconMetrics.tightBoundingRect.width))
    : root.iconInkWidth
  // Same idea for the readout: it is as wide as the longest percentage so the
  // digits don't jitter between 9% and 100%.
  readonly property int valueWidth: Math.ceil(Math.max(valueMetrics.advanceWidth, messageMetrics.advanceWidth))
  readonly property int messageWidth: Math.min(Math.ceil(messageMetrics.advanceWidth), root.maxMessageWidth)
  readonly property int contentWidth: root.soulWidth + root.gap + (root.hasProgress
    ? root.iconWidth + root.gap + root.barWidth + root.gap + root.valueWidth
    : (root.message === "" ? root.iconWidth : root.iconWidth + root.messageGap + root.messageWidth))

  function iconFor(name, percent) {
    return OsdModel.iconFor(name, percent)
  }

  function show(iconName, rawMessage, rawValue, rawMax, rawProgressText, rawDuration) {
    var next = OsdModel.stateForShow(iconName, rawMessage, rawValue, rawMax, rawProgressText, rawDuration)
    // Update before opening so a fresh OSD starts at its new value; only
    // subsequent updates while it remains open animate the progress bar.
    iconKey = next.iconKey
    maxValue = next.maxValue
    hasProgress = next.hasProgress
    value = next.value
    message = next.message
    icon = next.icon
    duration = next.duration
    opened = true
    if (duration > 0) hideTimer.restart()
    else hideTimer.stop()
  }

  function open(payloadJson) {
    try {
      var p = JSON.parse(payloadJson || "{}")
      show(p.icon || "", p.message || "", p.value === undefined ? "" : String(p.value), p.max === undefined ? "100" : String(p.max), p.progressText || "", p.duration === undefined ? "1200" : String(p.duration))
    } catch (e) {}
  }

  function close() { opened = false }

  // Media keys use these IPC methods instead of launching the complete
  // pactl/awk/jq/omarchy-osd process chain on every key repeat. PipeWire is
  // already resident in Quickshell, so both the value and the OSD update in
  // the same event-loop turn.
  function volumeStep(delta) {
    if (!audioSink || !audioSink.audio) return "unavailable"
    var next = Math.max(0, Math.min(1, audioSink.audio.volume + Number(delta) / 100))
    audioSink.audio.muted = false
    audioSink.audio.volume = next
    var percent = Math.round(next * 100)
    show("volume", "", String(percent), "100", percent + "%", "1200")
    return "ok"
  }

  function volumeMuteToggle() {
    if (!audioSink || !audioSink.audio) return "unavailable"
    audioSink.audio.muted = !audioSink.audio.muted
    var percent = Math.round(audioSink.audio.volume * 100)
    show(audioSink.audio.muted ? "volume-muted" : "volume", "", String(percent), "100", percent + "%", "1200")
    return "ok"
  }

  function brightnessStep(delta) {
    return setBrightness(brightnessPercent + Number(delta))
  }

  function setBrightness(percent) {
    brightnessPercent = Math.max(1, Math.min(100, Math.round(Number(percent))))
    show("brightness", "", String(brightnessPercent), "100", brightnessPercent + "%", "1200")
    applyBrightness()
    return "ok"
  }

  function applyBrightness() {
    if (brightnessApply.running) return
    brightnessApply.appliedPercent = brightnessPercent
    brightnessApply.command = ["brightnessctl", "-d", brightnessDevice, "set", brightnessApply.appliedPercent + "%"]
    brightnessApply.running = true
  }

  Process {
    id: brightnessProbe
    command: ["brightnessctl", "-d", root.brightnessDevice, "-m"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var fields = text.trim().split(",")
        if (fields.length >= 4) {
          var parsed = parseInt(fields[3].replace("%", ""), 10)
          if (!isNaN(parsed)) root.brightnessPercent = parsed
        }
      }
    }
  }

  Process {
    id: brightnessApply
    property int appliedPercent: 0
    onExited: function() {
      // A held brightness key may update the requested value while the
      // previous hardware write is running. Apply only the newest value next.
      if (appliedPercent !== root.brightnessPercent) root.applyBrightness()
    }
  }

  Component.onCompleted: brightnessProbe.running = true

  // Hyprland delivers these shortcuts straight to the already-running shell.
  // No qs, bash, pactl, jq or other process is started on a key press.
  GlobalShortcut {
    appid: "chara-osd"
    name: "volume-up"
    description: "Chara OSD volume up"
    onPressed: root.volumeStep(5)
  }

  GlobalShortcut {
    appid: "chara-osd"
    name: "volume-down"
    description: "Chara OSD volume down"
    onPressed: root.volumeStep(-5)
  }

  GlobalShortcut {
    appid: "chara-osd"
    name: "volume-mute"
    description: "Chara OSD mute"
    onPressed: root.volumeMuteToggle()
  }

  GlobalShortcut {
    appid: "chara-osd"
    name: "brightness-up"
    description: "Chara OSD brightness up"
    onPressed: root.brightnessStep(5)
  }

  GlobalShortcut {
    appid: "chara-osd"
    name: "brightness-down"
    description: "Chara OSD brightness down"
    onPressed: root.brightnessStep(-5)
  }

  GlobalShortcut {
    appid: "chara-osd"
    name: "brightness-max"
    description: "Chara OSD brightness maximum"
    onPressed: root.setBrightness(100)
  }

  GlobalShortcut {
    appid: "chara-osd"
    name: "brightness-min"
    description: "Chara OSD brightness minimum"
    onPressed: root.setBrightness(1)
  }

  GlobalShortcut {
    appid: "chara-osd"
    name: "brightness-fine-up"
    description: "Chara OSD brightness fine up"
    onPressed: root.brightnessStep(1)
  }

  GlobalShortcut {
    appid: "chara-osd"
    name: "brightness-fine-down"
    description: "Chara OSD brightness fine down"
    onPressed: root.brightnessStep(-1)
  }

  Timer {
    id: hideTimer
    interval: root.duration
    onTriggered: root.opened = false
  }

  TextMetrics {
    id: messageMetrics
    font.family: Style.font.family
    font.bold: true
    font.pixelSize: Style.font.title
    text: root.message
  }

  TextMetrics {
    id: valueMetrics
    font: messageMetrics.font
    text: "100%"
  }

  TextMetrics {
    id: iconMetrics
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge
    text: root.icon
  }

  TextMetrics {
    id: widestIconMetrics
    font: iconMetrics.font
    text: OsdModel.widestIcon
  }

  IpcHandler {
    target: "osd"
    function show(payloadJson: string): string {
      root.open(payloadJson)
      return "ok"
    }
    function close(): string { root.close(); return "ok" }
    function state(): string { return root.opened ? "open" : "closed" }
    function ping(): string { return "ok" }
    function volumeStep(delta: int): string { return root.volumeStep(delta) }
    function volumeMuteToggle(): string { return root.volumeMuteToggle() }
    function brightnessStep(delta: int): string { return root.brightnessStep(delta) }
    function brightnessSet(percent: int): string { return root.setBrightness(percent) }
  }

  PanelWindow {
    id: panel
    // Keep the transparent Wayland surface alive so the first volume or
    // brightness event does not wait for a new layer-shell window.
    visible: true
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Visual-only surface: keep the layer-shell input region empty so the OSD
    // never blocks clicks to the desktop below it.
    mask: Region {}

    BorderSurface {
      id: card
      visible: root.opened
      width: Style.space(380)
      height: Style.space(68)
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(67)
      color: Color.popups.background
      borderSpec: Border.flat(root.risePillBorder, 1)
      radius: 2
      clip: true
      opacity: root.opened ? 1 : 0

      Rectangle {
        anchors.left: parent.left; anchors.top: parent.top
        width: Style.space(22); height: Style.space(2)
        color: Color.accent
      }
      Rectangle {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        width: Style.space(22); height: Style.space(2)
        color: Color.accent
      }

      Row {
        id: contentRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: card.borderTop + Style.space(8)
        anchors.leftMargin: card.borderLeft + Style.space(12)
        anchors.rightMargin: card.borderRight + Style.space(12)
        height: Style.space(46)
        spacing: Style.space(10)

        Item {
          id: soulSlot
          width: root.soulWidth
          height: parent.height

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
          width: Style.space(30)
          height: parent.height
          Text {
            anchors.centerIn: parent
            text: root.icon
            font: iconMetrics.font
            color: Color.notifications.text
          }
        }

        Column {
          width: contentRow.width - soulSlot.width - Style.space(30) - contentRow.spacing * 2
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Text {
            width: parent.width
            text: root.displayTitle
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            color: Color.notifications.text
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          Text {
            width: parent.width
            visible: root.message !== ""
            text: root.message
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            color: Qt.darker(Color.notifications.text, 1.15)
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: card.borderLeft + Style.space(10)
        anchors.rightMargin: card.borderRight + Style.space(10)
        anchors.bottomMargin: card.borderBottom + Style.space(5)
        height: 2
        radius: 1
        color: Util.alpha(root.soulColor, 0.10)
        clip: true

        Rectangle {
          height: parent.height
          width: parent.width * (root.hasProgress ? root.value / root.maxValue : 1)
          radius: 1
          color: Util.alpha(root.soulColor, 0.68)

        }
      }
    }
  }

  onSoulColorChanged: soulCanvas.requestPaint()
}
