import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property date now: new Date()

  readonly property color soulRed: "#A45D68"
  readonly property color soulRedBright: "#D76872"
  readonly property color ink: "#10090b"
  readonly property color coldWhite: "#F4EFF4"
  readonly property color mutedWhite: "#C2BAC5"
  readonly property bool errorState: failureMessage.length > 0
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && !errorState
  readonly property int titleSize: Math.max(24, Math.min(42, Math.round(width / 46)))
  readonly property int bodySize: Math.max(16, Math.min(25, Math.round(width / 74)))
  readonly property int smallSize: Math.max(12, Math.min(17, Math.round(width / 108)))
  readonly property int fieldHeight: Math.max(58, Math.min(72, Math.round(height / 13)))
  readonly property var inputBorderSpec: Border.surfaceSpec(
    "lock",
    errorState ? "border-error" : "border-active",
    errorState ? Color.lock.borderError : root.soulRed,
    3,
    "border-alpha"
  )

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  function timeText() {
    return Qt.formatDateTime(now, "HH:mm")
  }

  function dateText() {
    return Qt.formatDateTime(now, "dddd, d MMMM")
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: if (inputEnabled) Qt.callLater(forcePasswordFocus)

  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  Rectangle {
    anchors.fill: parent
    color: root.ink

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 0.68
      blurMax: 96
      blurMultiplier: 1.0
      saturation: -0.20
      contrast: 0.08
      brightness: -0.18
    }

    Rectangle {
      anchors.fill: parent
      color: "#b80e080a"
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: Math.max(3, parent.height * 0.006)
      color: root.soulRed
      opacity: 0.85
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Item {
      id: savePanel
      width: Math.min(parent.width - 72, 960)
      height: Math.min(parent.height - 72, 650)
      anchors.centerIn: parent

      Text {
        id: determined
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        text: "*  STAY DETERMINED."
        color: root.soulRedBright
        font.family: Style.font.family
        font.pixelSize: root.bodySize
        font.bold: true
        font.letterSpacing: 1.5
      }

      Column {
        id: saveInfo
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: determined.bottom
        anchors.topMargin: Math.max(28, parent.height * 0.08)
        spacing: Math.max(10, parent.height * 0.018)

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Math.max(34, savePanel.width * 0.08)

          Text {
            text: "Chara"
            color: root.coldWhite
            font.family: Style.font.family
            font.pixelSize: root.titleSize
            font.bold: true
          }

          Text {
            text: "LV 20"
            color: root.coldWhite
            font.family: Style.font.family
            font.pixelSize: root.titleSize
            font.bold: true
          }

          Text {
            text: root.timeText()
            color: root.coldWhite
            font.family: Style.font.family
            font.pixelSize: root.titleSize
            font.bold: true
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Void — The True Path"
          color: root.coldWhite
          font.family: Style.font.family
          font.pixelSize: root.bodySize
          font.bold: true
          font.letterSpacing: 0.8
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.dateText()
          color: root.mutedWhite
          opacity: 0.86
          font.family: Style.font.family
          font.pixelSize: root.smallSize
          font.letterSpacing: 1.0
        }
      }

      Item {
        id: soul
        width: 42
        height: 38
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: saveInfo.bottom
        anchors.topMargin: Math.max(28, parent.height * 0.075)

        scale: 1.0
        SequentialAnimation on scale {
          running: true
          loops: Animation.Infinite
          NumberAnimation { to: 1.10; duration: 700; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1.00; duration: 700; easing.type: Easing.InOutQuad }
        }

        Canvas {
          anchors.fill: parent
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.soulRedBright
            var px = 6
            var rows = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
            for (var y = 0; y < rows.length; y++) {
              for (var x = 0; x < rows[y].length; x++) {
                if (rows[y][x] === "1") ctx.fillRect(x * px, y * px, px, px)
              }
            }
          }
        }
      }

      BorderSurface {
        id: battleBox
        width: Math.min(savePanel.width, 580)
        height: root.fieldHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: soul.bottom
        anchors.topMargin: Math.max(20, parent.height * 0.045)
        color: "#e60e080a"
        borderSpec: root.inputBorderSpec
        radius: 0
        clip: true

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.margins: 10
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignHCenter
          activeFocusOnPress: true
          clip: true
          enabled: root.inputEnabled && !root.authenticatingPassword
          readOnly: root.authenticatingPassword
          echoMode: TextInput.Password
          passwordCharacter: "♥"
          passwordMaskDelay: 0
          color: root.coldWhite
          selectionColor: root.soulRed
          selectedTextColor: root.coldWhite
          font.family: Style.font.family
          font.pixelSize: root.bodySize
          font.letterSpacing: 5
          cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
          cursorDelegate: Rectangle { width: 3; color: root.soulRedBright }

          onTextChanged: {
            if (!root.syncingPasswordText) root.passwordTextEdited(text)
            if (text.length > 0) root.wakeRequested()
            if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
          }

          onAccepted: {
            var submitted = root.passwordText
            root.passwordTextEdited("")
            if (submitted.length > 0) root.submitPassword(submitted)
          }

          Keys.onPressed: function(event) {
            root.wakeRequested()
            if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
              root.passwordTextEdited("")
              event.accepted = true
            }
          }
        }

        Text {
          anchors.fill: passwordInput
          text: root.authenticatingPassword
            ? "* CHECKING..."
            : (root.failureMessage.length > 0 ? "* WRONG PASSWORD. TRY AGAIN." : "* ENTER PASSWORD")
          visible: passwordInput.text.length === 0
          color: root.errorState ? root.soulRedBright : root.coldWhite
          font.family: Style.font.family
          font.pixelSize: root.bodySize
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }

        Text {
          anchors.right: parent.right
          anchors.rightMargin: 18
          anchors.verticalCenter: parent.verticalCenter
          visible: root.fingerprintConfigured
          text: "󰈷"
          color: root.soulRedBright
          font.family: Style.font.family
          font.pixelSize: root.bodySize + 3
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: battleBox.bottom
        anchors.topMargin: 18
        text: "[ENTER] CONTINUE    [ESC] CLEAR"
        color: root.mutedWhite
        opacity: 0.72
        font.family: Style.font.family
        font.pixelSize: root.smallSize
        font.letterSpacing: 1.0
      }
    }
  }
}
