import QtQuick

// A static, font-independent Undertale soul. Empty hearts keep a one-pixel
// contour; state changes recolor rectangles without an idle paint timer.
Item {
    id: soul
    property color color: "#F13B45"
    property bool filled: true
    property real pixelSize: 2
    readonly property var rows: ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
    readonly property var pixels: {
        var out = []
        function solid(x, y) {
            return y >= 0 && y < rows.length && x >= 0 && x < 7 && rows[y][x] === "1"
        }
        for (var y = 0; y < rows.length; y++) {
            for (var x = 0; x < 7; x++) {
                if (solid(x, y) && (filled || !solid(x - 1, y) || !solid(x + 1, y)
                    || !solid(x, y - 1) || !solid(x, y + 1))) out.push({x: x, y: y})
            }
        }
        return out
    }
    implicitWidth: 7 * pixelSize
    implicitHeight: 6 * pixelSize
    width: implicitWidth
    height: implicitHeight
    Repeater {
        model: soul.pixels
        Rectangle {
            required property var modelData
            x: modelData.x * soul.pixelSize
            y: modelData.y * soul.pixelSize
            width: soul.pixelSize
            height: soul.pixelSize
            color: soul.color
            antialiasing: false
        }
    }
}
