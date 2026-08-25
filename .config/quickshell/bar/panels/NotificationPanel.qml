import QtQuick
import "../modules"
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: notifPanel
    required property var root

    screen: root.activePopupScreen

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-notifications"

    readonly property int barBottom: 35
    readonly property int gap: 8

    // ── notification history ─────────────────────────────────────────────────
    // The live Omarchy shell owns org.freedesktop.Notifications on this
    // machine. Its Chara clone persists popups in
    // ~/.local/state/omarchy/notifications/{,history}/. Rise used to poll
    // makoctl here, which left the badge and history panel empty because Mako
    // is not installed. Read the central store first; retain a Mako fallback
    // for machines that still run that daemon.

    property var recent: []             // [{key,id,appName,summary,body,firstSeen,active}]
    property var dismissed: ({})         // stable filename -> true (persisted)
    property string sessionToken: ""
    property int generation: 0           // retained for the legacy Mako cache
    property int seq: 0                  // monotonic first-seen counter (ordering)
    property bool useMako: false
    property bool cacheLoaded: false
    property string lastSaved: ""

    readonly property string centralStateDir: {
        var xdg = Quickshell.env("XDG_STATE_HOME")
        return (xdg !== "" ? xdg : Quickshell.env("HOME") + "/.local/state")
               + "/omarchy/notifications"
    }

    // pending = not dismissed → drives both the list and the badge
    readonly property var pending: {
        var out = []
        for (var i = 0; i < recent.length; i++)
            if (!dismissed[recent[i].key]) out.push(recent[i])
        return out
    }
    readonly property int unreadCount: pending.length
    // scrollable list height cap, clamped to the monitor
    readonly property int listCap: Math.max(120, Math.min(420, notifPanel.height - 220))

    function eventText(entry) {
        return String((entry && entry.appName) || "") + " "
             + String((entry && entry.summary) || "") + " "
             + String((entry && entry.body) || "")
    }

    function soulColor(entry) {
        var text = eventText(entry).toLowerCase()
        if (Number(entry && entry.urgency) === 2 || text.indexOf("error") >= 0
                || text.indexOf("failed") >= 0 || text.indexOf("critical") >= 0)
            return "#ff3030"
        if (text.indexOf("warning") >= 0 || text.indexOf("power") >= 0
                || text.indexOf("reboot") >= 0)
            return "#f47b20"
        if (text.indexOf("brightness") >= 0) return "#D6B06C"
        if (text.indexOf("screenshot") >= 0 || text.indexOf("capture") >= 0)
            return "#D535D9"
        if (text.indexOf("success") >= 0 || text.indexOf("complete") >= 0
                || text.indexOf("updated") >= 0 || text.indexOf("installed") >= 0)
            return "#30d158"
        if (text.indexOf("network") >= 0 || text.indexOf("wifi") >= 0
                || text.indexOf("bluetooth") >= 0)
            return "#52e5e7"
        if (text.indexOf("audio") >= 0 || text.indexOf("volume") >= 0
                || text.indexOf("media") >= 0 || text.indexOf("spotify") >= 0
                || text.indexOf("song") >= 0)
            return "#bf6cff"
        if (Number(entry && entry.urgency) === 0) return "#52e5e7"
        return "#A86B91"
    }

    function sourceLabel(entry) {
        var value = String((entry && entry.appName) || "").trim()
        if (value === "" || value === "notify-send") return "SYSTEM"
        if (value === "omarchy-action") return "OMARCHY"
        return value.toUpperCase()
    }

    function clockLabel(entry) {
        var stamp = Number((entry && entry.timestamp) || 0)
        return Qt.formatTime(new Date(stamp > 0 ? stamp : Date.now()), "HH:mm")
    }

    Binding { target: root; property: "notifCount"; value: notifPanel.unreadCount }

    // ── persistent cache (quickshell is the sole writer; write only on change) ──
    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/qs-rise-notifications.json"
    FileView {
        id: cacheFile
        path: notifPanel.cachePath
        onLoaded: {
            try {
                var j = JSON.parse(cacheFile.text())
                notifPanel.sessionToken = j.token || ""
                notifPanel.generation   = j.generation || 0
                notifPanel.seq          = j.seq || 0
                notifPanel.recent       = Array.isArray(j.recent) ? j.recent : []
                notifPanel.dismissed    = (j.dismissed && typeof j.dismissed === "object") ? j.dismissed : ({})
                notifPanel.lastSaved    = cacheFile.text()
            } catch (e) {
                notifPanel.recent = []; notifPanel.dismissed = ({})
            }
            notifPanel.cacheLoaded = true
            notifPanel.poll()
        }
        onLoadFailed: {                  // first run: no cache yet
            notifPanel.cacheLoaded = true
            notifPanel.poll()
        }
    }
    // force the initial load (don't rely on implicit auto-load) — the whole panel
    // is gated on cacheLoaded, so a missed load would mean no notifications ever
    Component.onCompleted: cacheFile.reload()

    function saveCache() {
        if (!notifPanel.cacheLoaded) return
        var state = JSON.stringify({
            token: notifPanel.sessionToken,
            generation: notifPanel.generation,
            seq: notifPanel.seq,
            recent: notifPanel.recent,
            dismissed: notifPanel.dismissed
        })
        if (state === notifPanel.lastSaved) return   // no real change → no write
        notifPanel.lastSaved = state
        cacheFile.setText(state)
    }

    // Prefer the central Chara store. If a real Mako process is present, keep
    // the old JSON protocol so an older Rise installation remains usable.
    readonly property string pollScript:
        "if command -v makoctl >/dev/null 2>&1 && pidof mako >/dev/null 2>&1; then " +
        "pid=$(pidof mako 2>/dev/null | awk '{print $1}'); " +
        "bid=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null); " +
        "st=$(awk '{print $22}' /proc/$pid/stat 2>/dev/null); " +
        "tok=\"$bid-$pid-$st\"; " +
        "lst=$(makoctl list -j 2>/dev/null); [ -z \"$lst\" ] && lst='[]'; " +
        "his=$(makoctl history -j 2>/dev/null); [ -z \"$his\" ] && his='[]'; " +
        "printf '{\"token\":\"%s\",\"list\":%s,\"history\":%s}' \"$tok\" \"$lst\" \"$his\"; " +
        "else " +
        "base=\"$1\"; " +
        "{ " +
        "find \"$base\" -maxdepth 1 -type f -name '*.json' -print0 2>/dev/null | " +
        "while IFS= read -r -d '' f; do " +
        "jq -c --arg key \"$(basename \"$f\")\" " +
        "'{key:$key,id:(.id // 0),appName:(.app // \"\"),summary:(.summary // \"\"),body:(.body // \"\"),glyph:(.glyph // \"\"),appIcon:(.appIcon // \"\"),image:(.image // \"\"),exec:(.exec // \"\"),urgency:(.urgency // 1),timestamp:(.timestamp // 0),active:true}' \"$f\"; done; " +
        "find \"$base/history\" -maxdepth 1 -type f -name '*.json' -print0 2>/dev/null | " +
        "while IFS= read -r -d '' f; do " +
        "jq -c --arg key \"$(basename \"$f\")\" " +
        "'{key:$key,id:(.id // 0),appName:(.app // \"\"),summary:(.summary // \"\"),body:(.body // \"\"),glyph:(.glyph // \"\"),appIcon:(.appIcon // \"\"),image:(.image // \"\"),exec:(.exec // \"\"),urgency:(.urgency // 1),timestamp:(.timestamp // 0),active:false}' \"$f\"; done; " +
        "} | jq -s -c .; fi"

    Process {
        id: pollProc
        command: ["bash", "-c", notifPanel.pollScript, "--", notifPanel.centralStateDir]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var d
                try { d = JSON.parse(this.text) } catch (e) { return }
                if (Array.isArray(d)) notifPanel.mergeCentral(d)
                else notifPanel.merge(d.token || "", d.list || [], d.history || [])
            }
        }
    }
    function poll() {
        if (!notifPanel.cacheLoaded) return
        pollProc.running = false; pollProc.running = true
    }

    // Merge a legacy Mako poll's active(list) + history into our retained history.
    function merge(token, listArr, histArr) {
        notifPanel.useMako = true
        // session / generation
        if (token !== "" && token !== notifPanel.sessionToken) {
            if (notifPanel.sessionToken !== "") notifPanel.generation += 1
            notifPanel.sessionToken = token
        }
        var gen = notifPanel.generation

        // incoming this poll (current generation), by bare id; active = in `list`
        var incoming = {}
        for (var i = 0; i < listArr.length; i++) {
            var n = listArr[i]
            incoming[n.id] = { appName: n.app_name || "", summary: n.summary || "", body: n.body || "", active: true }
        }
        for (var j = 0; j < histArr.length; j++) {
            var h = histArr[j]
            if (incoming[h.id] === undefined)
                incoming[h.id] = { appName: h.app_name || "", summary: h.summary || "", body: h.body || "", active: false }
        }

        // existing entries by composite key
        var byKey = {}
        for (var k = 0; k < notifPanel.recent.length; k++) byKey[notifPanel.recent[k].key] = notifPanel.recent[k]

        // update-or-create current-gen entries; oldest id first so newest gets the largest seq
        var ids = []
        for (var idk in incoming) ids.push(parseInt(idk))
        ids.sort(function(a, b) { return a - b })
        for (var m = 0; m < ids.length; m++) {
            var id = ids[m]
            var key = gen + ":" + id
            var src = incoming[id]
            if (byKey[key] !== undefined) {
                var e = byKey[key]
                e.appName = src.appName; e.summary = src.summary; e.body = src.body
            } else {
                byKey[key] = { key: key, id: id, gen: gen,
                    appName: src.appName, summary: src.summary, body: src.body,
                    firstSeen: (++notifPanel.seq) }
            }
        }

        // recompute the (transient) active flag for ALL entries, build a NEW array
        var out = []
        for (var ek in byKey) {
            var ee = byKey[ek]
            ee.active = (ee.gen === gen && incoming[ee.id] !== undefined && incoming[ee.id].active === true)
            out.push(ee)
        }
        out.sort(function(a, b) { return b.firstSeen - a.firstSeen })
        if (out.length > 50) out = out.slice(0, 50)

        // prune dismissed keys no longer present (bounds the set)
        var present = {}
        for (var o = 0; o < out.length; o++) present[out[o].key] = true
        var nd = {}, changed = false
        for (var dk in notifPanel.dismissed) {
            if (present[dk]) nd[dk] = true; else changed = true
        }

        notifPanel.recent = out                  // reassign → bindings fire
        if (changed) notifPanel.dismissed = nd
        notifPanel.saveCache()
    }

    // Merge the central Chara notification files. The same basename is used
    // for a popup and its eventual history file, so moving a toast into
    // history does not create a duplicate row in the Rise panel.
    function mergeCentral(entries) {
        notifPanel.useMako = false
        var incoming = {}
        for (var i = 0; i < entries.length; i++) {
            var n = entries[i] || ({})
            var key = String(n.key || "")
            if (key === "") continue
            var next = {
                key: key,
                id: Number(n.id || 0),
                gen: 0,
                appName: String(n.appName || ""),
                summary: String(n.summary || ""),
                body: String(n.body || ""),
                glyph: String(n.glyph || ""),
                appIcon: String(n.appIcon || ""),
                image: String(n.image || ""),
                exec: String(n.exec || ""),
                urgency: Number(n.urgency === undefined ? 1 : n.urgency),
                timestamp: Number(n.timestamp || 0),
                firstSeen: Number(n.timestamp || 0) || (++notifPanel.seq),
                active: !!n.active
            }
            // If a file is briefly visible in both directories, the live
            // popup wins over its older history copy.
            if (!incoming[key] || next.active) incoming[key] = next
        }

        var oldByKey = {}
        for (var j = 0; j < notifPanel.recent.length; j++) {
            var old = notifPanel.recent[j]
            if (old && old.key) oldByKey[old.key] = old
        }
        var byKey = {}
        for (var k in incoming) {
            var value = incoming[k]
            var previous = oldByKey[k]
            if (previous) {
                value.firstSeen = previous.firstSeen || value.firstSeen
                byKey[k] = value
            } else {
                byKey[k] = value
            }
        }

        var out = []
        for (var key2 in byKey) out.push(byKey[key2])
        out.sort(function(a, b) {
            return (Number(b.timestamp || 0) - Number(a.timestamp || 0))
                || (Number(b.firstSeen || 0) - Number(a.firstSeen || 0))
        })
        if (out.length > 50) out = out.slice(0, 50)

        var present = {}
        for (var p = 0; p < out.length; p++) present[out[p].key] = true
        var nd = {}, changed = false
        for (var dk in notifPanel.dismissed) {
            if (present[dk]) nd[dk] = true
            else changed = true
        }
        notifPanel.recent = out
        if (changed) notifPanel.dismissed = nd
        notifPanel.saveCache()
    }

    // ── actions ──
    Process { id: actionProc; command: ["bash", "-c", "true"] }
    function runMako(cmd) {
        actionProc.command = ["bash", "-c", cmd + " 2>/dev/null || true"]
        actionProc.running = false; actionProc.running = true
    }

    Process { id: centralActionProc; command: ["bash", "-c", "true"] }
    function runCentralDismiss(entry) {
        if (!entry || !entry.active || String(entry.summary || "") === "") return
        centralActionProc.command = ["bash", "-c",
            "OMARCHY_PATH=/usr/share/omarchy omarchy-shell notifications dismiss \"$1\" >/dev/null 2>&1 || true",
            "--", String(entry.summary)]
        centralActionProc.running = false; centralActionProc.running = true
    }
    function runCentralInvoke(entry) {
        if (!entry || !entry.active || String(entry.exec || "") === "") return
        centralActionProc.command = ["bash", "-c", "bash -c \"$1\" >/dev/null 2>&1 || true",
            "--", String(entry.exec)]
        centralActionProc.running = false; centralActionProc.running = true
    }
    function runCentralDismissAll() {
        centralActionProc.command = ["bash", "-c",
            "OMARCHY_PATH=/usr/share/omarchy omarchy-shell notifications dismissAll >/dev/null 2>&1 || true"]
        centralActionProc.running = false; centralActionProc.running = true
    }

    function dismissOne(entry) {
        var nd = {}
        for (var k in notifPanel.dismissed) nd[k] = true
        nd[entry.key] = true
        notifPanel.dismissed = nd                // reassign → bindings update
        var id = parseInt(entry.id)              // normalize before it touches a shell
        if (entry.active && id > 0) {
            if (notifPanel.useMako) notifPanel.runMako("makoctl dismiss -h -n " + id)
            else notifPanel.runCentralDismiss(entry)
        }
        notifPanel.saveCache()
    }

    function dismissAll() {
        var nd = {}
        for (var k in notifPanel.dismissed) nd[k] = true
        for (var i = 0; i < notifPanel.recent.length; i++) nd[notifPanel.recent[i].key] = true
        notifPanel.dismissed = nd
        notifPanel.recent = []                   // clear own history; re-merged entries stay dismissed-filtered
        if (notifPanel.useMako) notifPanel.runMako("makoctl dismiss -h --all")
        else notifPanel.runCentralDismissAll()
        notifPanel.saveCache()
    }

    function openNotification(entry) {
        var id = parseInt(entry.id)              // normalize before it touches a shell
        if (entry.active && id > 0) {
            if (notifPanel.useMako) notifPanel.runMako("makoctl invoke -n " + id)
            else notifPanel.runCentralInvoke(entry)
        }
        // history/cache-only entries are no longer active → do nothing (never `restore`)
        root.notifVisible = false
    }

    // ── poll cadence: fast while open, much slower when closed.
    // Opening the panel still triggers an immediate refresh below; the closed
    // cadence keeps the badge/history roughly warm without scanning the
    // central store every few seconds at an expensive rate.
    Timer {
        interval: notifPanel.visible ? 1500 : 10000
        running: notifPanel.cacheLoaded; repeat: true; triggeredOnStart: true
        onTriggered: notifPanel.poll()
    }

    property real reveal: root.notifVisible ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: root.notifVisible ? 160 : 120
            easing.type: root.notifVisible ? Easing.OutCubic : Easing.InCubic
        }
    }
    visible: reveal > 0.001
    WlrLayershell.keyboardFocus: root.notifVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: { if (visible) notifPanel.poll() }

    MouseArea {
        anchors.fill: parent
        onClicked: root.notifVisible = false
    }

    Rectangle {
        id: card
        width: 320
        height: col.implicitHeight + 24
        radius: reveal > 0.001 ? root.pillRadius : 0
        color: root.bg
        border.color: root.pillBorder
        border.width: root.pillBorderW
        PillShadow { theme: root }

        x: Math.round(Math.max(6, Math.min(root.notifBarX, parent.width - width - 6)))
        y: root.barPosition === "bottom" ? (parent.height - barBottom - gap - height) : (barBottom + gap)
        opacity: notifPanel.reveal
        focus: root.notifVisible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.notifVisible = false
                event.accepted = true
            }
        }

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: col
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── header ──
            Item {
                width: parent.width
                height: 24
                UiText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: notifPanel.unreadCount > 0 ? "Notifications · " + notifPanel.unreadCount : "Notifications"
                    color: root.ink
                    font.family: root.mono
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    font.weight: Font.Medium
                }
                UiText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    color: closeMa.containsMouse ? root.seal : root.sumi
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notifVisible = false
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.sep }

            // ── notification list (scrollable; each individually dismissable) ──
            Flickable {
                width: parent.width
                height: Math.min(listCol.implicitHeight, notifPanel.listCap)
                contentHeight: listCol.implicitHeight
                clip: true
                interactive: listCol.implicitHeight > notifPanel.listCap
                boundsBehavior: Flickable.StopAtBounds   // no overshoot/rebound at the top/bottom edge
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: listCol
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: notifPanel.pending

                        delegate: Rectangle {
                            required property var modelData
                            width: listCol.width
                            height: entryCol.implicitHeight + 16
                            // Match the live Soul toast: dark plum body, neutral
                            // Rise frame, and the event colour reserved for the
                            // heart/accent rather than the whole card.
                            radius: 14
                            color: entryMa.containsMouse ? root.fillHover : "#251517"
                            border.color: entryMa.containsMouse ? root.seal : "#493D43"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                id: entryRow
                                anchors { left: parent.left; right: parent.right; top: parent.top }
                                anchors.margins: 8
                                anchors.topMargin: 8
                                anchors.rightMargin: 26   // leave room for the ✕
                                spacing: 10

                                Item {
                                    width: 22
                                    height: entryCol.implicitHeight
                                    Text {
                                        anchors.centerIn: parent
                                        text: "♥"
                                        color: notifPanel.soulColor(modelData)
                                        font.family: root.mono
                                        font.pixelSize: 18
                                        font.bold: true
                                    }
                                }

                                Column {
                                id: entryCol
                                width: Math.max(0, entryRow.width - 32)
                                spacing: 3

                                    Row {
                                        width: parent.width
                                        spacing: 6
                                        UiText {
                                            text: notifPanel.sourceLabel(modelData)
                                            color: notifPanel.soulColor(modelData)
                                            font.family: root.mono
                                            font.pixelSize: 10
                                            font.letterSpacing: 0.5
                                            width: Math.max(0, parent.width - 38)
                                            elide: Text.ElideRight
                                        }
                                        UiText {
                                            text: notifPanel.clockLabel(modelData)
                                            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.55)
                                            font.family: root.mono
                                            font.pixelSize: 10
                                        }
                                    }
                                    UiText {
                                        text: modelData.summary || ""
                                        color: root.ink
                                        font.family: root.mono
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        width: parent.width
                                        elide: Text.ElideRight
                                        visible: text !== ""
                                    }
                                    UiText {
                                        text: modelData.body || ""
                                        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.68)
                                        font.family: root.mono
                                        font.pixelSize: 10
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        visible: text !== ""
                                    }
                                }
                            }

                            // Click body → invoke a stored central action, or the
                            // legacy Mako action when that backend is active.
                            MouseArea {
                                id: entryMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notifPanel.openNotification(modelData)
                            }

                            // per-item dismiss ✕ (on top, top-right corner)
                            Rectangle {
                                anchors.top: parent.top; anchors.right: parent.right
                                anchors.topMargin: 4; anchors.rightMargin: 4
                                width: 18; height: 18; radius: 9
                                color: "transparent"
                                UiText {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: xMa.containsMouse ? root.seal : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.45)
                                    font.pixelSize: 10
                                }
                                MouseArea {
                                    id: xMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notifPanel.dismissOne(modelData)
                                }
                            }
                        }
                    }

                    UiText {
                        visible: notifPanel.pending.length === 0
                        width: listCol.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "No notifications"
                        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.3)
                        font.family: root.mono
                        font.pixelSize: 11
                    }
                }
            }

            // ── clear all ──
            Rectangle {
                width: parent.width
                height: 28; radius: root.tileRadius
                visible: notifPanel.pending.length > 0
                readonly property bool hovered: clearMa.containsMouse
                color: hovered ? root.fillHover : root.fillIdle
                border.color: hovered ? root.seal : root.sep
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }
                UiText {
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: clearMa.containsMouse ? root.seal : root.sumi
                    font.family: root.mono; font.pixelSize: 11
                }
                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notifPanel.dismissAll()
                }
            }
        }
    }
}
