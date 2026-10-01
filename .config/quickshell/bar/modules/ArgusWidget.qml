import QtQuick
import Quickshell
import Quickshell.Io

// Small Rise bridge for the optional Omarchy Argus plugin. Argus owns the
// detailed panel and history; this widget only asks its IPC endpoint for the
// health snapshot that belongs beside the network pill.
Item {
    id: rootMod
    required property var root
    property bool standaloneSurface: false
    property bool badgeOnly: false

    property bool ready: false
    property real cpuPct: 0
    property real memPct: 0
    property real cpuTempC: -1

    readonly property bool urgent: cpuPct >= 90 || memPct >= 90 || cpuTempC >= 85
    readonly property string cpuLabel: String(Math.round(cpuPct)).padStart(2, "0")
    readonly property string memLabel: String(Math.round(memPct)).padStart(2, "0")
    readonly property string tempLabel: cpuTempC >= 0 ? Math.round(cpuTempC) + "°" : "--"
    readonly property string tooltipText: "Argus · CPU " + cpuLabel + "% · RAM "
        + memLabel + "% · CPU temp " + tempLabel + "C · click for panel"

    visible: ready
    implicitWidth: ready ? row.implicitWidth + (standaloneSurface ? 18 : 0) : 0
    implicitHeight: 28
    opacity: ready ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    function consume(text) {
        var raw = String(text || "").trim()
        if (raw === "") {
            ready = false
            return
        }

        try {
            var data = JSON.parse(raw)
            var cpu = Number(data.cpuPct)
            var mem = Number(data.memPct)
            var temp = Number(data.cpuTempC)
            if (!isFinite(cpu) || !isFinite(mem)) {
                ready = false
                return
            }
            cpuPct = Math.max(0, Math.min(100, cpu))
            memPct = Math.max(0, Math.min(100, mem))
            cpuTempC = isFinite(temp) ? temp : -1
            ready = true
        } catch (error) {
            ready = false
        }
    }

    function poll() {
        if (metricsProc.running) return
        metricsProc.running = true
    }

    function togglePanel() {
        Quickshell.execDetached(["omarchy-shell", "io.github.diegopluna.argus", "toggle"])
    }

    function refreshArgus() {
        Quickshell.execDetached(["omarchy-shell", "io.github.diegopluna.argus", "refresh"])
        poll()
    }

    Rectangle {
        visible: rootMod.standaloneSurface
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: row.implicitWidth + 18
        height: root.pillH
        radius: root.pillRadius
        color: root.pill
        border.color: root.pillBorder
        border.width: root.pillBorderW
        PillShadow { theme: root }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3

        IconText {
            anchors.verticalCenter: parent.verticalCenter
            visible: rootMod.badgeOnly
            text: "visibility"
            color: root.seal
            font.pixelSize: 14
            fill: 1
        }

        UiText {
            anchors.verticalCenter: parent.verticalCenter
            text: "ARG"
            color: root.seal
            font.family: root.mono
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }

        UiText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !rootMod.badgeOnly
            text: "C" + rootMod.cpuLabel
            color: rootMod.cpuPct >= 90 ? root.seal : root.ink
            font.family: root.mono
            font.pixelSize: 10
        }

        UiText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !rootMod.badgeOnly
            text: "R" + rootMod.memLabel
            color: rootMod.memPct >= 90 ? root.seal : root.ink
            font.family: root.mono
            font.pixelSize: 10
        }

        UiText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !rootMod.badgeOnly
            text: "T" + rootMod.tempLabel
            color: rootMod.cpuTempC >= 85 ? root.seal : root.ink
            font.family: root.mono
            font.pixelSize: 10
        }
    }

    Process {
        id: metricsProc
        command: ["bash", "-c",
            "manifest=\"$HOME/.config/omarchy/plugins/io.github.diegopluna.argus/manifest.json\"; " +
            "[[ -f \"$manifest\" ]] && command -v omarchy-shell >/dev/null 2>&1 && " +
            "omarchy-shell io.github.diegopluna.argus metrics 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: rootMod.consume(this.text)
        }
    }

    Timer {
        interval: rootMod.ready ? 2000 : 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: rootMod.poll()
    }

    TooltipMixin {
        id: tip
        root: rootMod.root
        owner: rootMod
        text: rootMod.tooltipText
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tip.show()
        onExited: tip.hide()
        onClicked: function(mouse) {
            tip.hide()
            if (mouse.button === Qt.MiddleButton) rootMod.refreshArgus()
            else rootMod.togglePanel()
        }
    }
}
