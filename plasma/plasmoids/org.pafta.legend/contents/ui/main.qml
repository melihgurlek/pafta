import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// The title block of the sheet, set like the cartouche in the corner of a printed topo map:
// name, region and coordinates, an honest scale bar for this screen, the contour interval,
// then what a paper map can't have: the time, the sun over you and the weather.
PlasmoidItem {
    id: root

    readonly property string sans: "IBM Plex Sans"
    readonly property string mono: "IBM Plex Mono"
    readonly property color ink: Kirigami.Theme.textColor
    readonly property color ink2: Kirigami.Theme.disabledTextColor
    readonly property color over: Kirigami.Theme.activeTextColor   // the magenta overprint
    readonly property var days: ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
    readonly property var months: ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY",
                                   "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
    readonly property var winds: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    property date now: new Date()
    property var sheet: ({})
    property string weather: ""

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    P5Support.DataSource {
        id: shell
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            try { root.sheet = JSON.parse(data["stdout"]) } catch (e) {}
            disconnectSource(source)
        }
    }
    function readState() { shell.connectSource("cat \"${XDG_CACHE_HOME:-$HOME/.cache}/pafta/state.json\"") }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.readState() }

    function fetchWeather() {
        const lat = root.sheet.home ? root.sheet.home.lat : 41.01
        const lon = root.sheet.home ? root.sheet.home.lon : 28.98
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            try {
                const c = JSON.parse(xhr.responseText).current
                const dir = root.winds[Math.round(c.wind_direction_10m / 45) % 8]
                root.weather = root.sky(c.weather_code) + "  " + Math.round(c.temperature_2m) + "°  ·  WIND " + dir + " " + Math.round(c.wind_speed_10m) + " KM/H"
                weatherTimer.interval = 20 * 60 * 1000
            } catch (e) {
                weatherTimer.interval = 3 * 60 * 1000
            }
        }
        xhr.open("GET", "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
                 + "&current=temperature_2m,weather_code,wind_speed_10m,wind_direction_10m&timezone=auto")
        xhr.send()
    }
    Timer { id: weatherTimer; interval: 20 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.fetchWeather() }

    function sky(code) {  // WMO weather codes, in a word
        if (code === 0) return "CLEAR"
        if (code <= 2) return "PARTLY CLOUDY"
        if (code === 3) return "OVERCAST"
        if (code <= 48) return "FOG"
        if (code <= 57) return "DRIZZLE"
        if (code <= 67) return "RAIN"
        if (code <= 77) return "SNOW"
        if (code <= 82) return "SHOWERS"
        if (code <= 86) return "SNOW SHOWERS"
        return "THUNDERSTORM"
    }
    function pad(n) { return (n < 10 ? "0" : "") + n }
    function skyLine() {
        const s = root.sheet
        if (!s.sun) return ""
        if (s.sun.alt > -1) return "SUN  " + s.sun.az + "°  " + s.sun.alt + "°  ·  SETS " + s.sun.set
        if (s.moon && s.moon.alt > 0) return "MOON  " + s.moon.az + "°  " + s.moon.alt + "°  ·  " + s.moon.lit + "% LIT  ·  SUNRISE " + s.sun.rise
        return "NIGHT  ·  SUNRISE " + s.sun.rise
    }

    component Caps: Text {
        font { family: root.sans; pixelSize: 10; weight: Font.Medium; letterSpacing: 1.3 }
        color: root.ink
    }
    component Rule: Rectangle { Layout.fillWidth: true; height: 1; color: root.ink; opacity: 0.35 }

    fullRepresentation: Item {
        Layout.preferredWidth: 340
        Layout.preferredHeight: 256
        Layout.minimumWidth: 340
        Layout.minimumHeight: 256

        Rectangle {  // the box: paper, a keyline and a thin inner rule
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            border { width: 1; color: Qt.alpha(root.ink, 0.85) }
            Rectangle {
                anchors { fill: parent; margins: 4 }
                color: "transparent"
                border { width: 1; color: Qt.alpha(root.ink, 0.3) }
            }
        }

        // north arrow, half filled like the one in the margin of the sheet
        Shape {
            id: arrow
            anchors { right: parent.right; top: parent.top; rightMargin: 22; topMargin: 18 }
            width: 14; height: 30
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.ink; strokeColor: root.ink; strokeWidth: 1
                startX: 7; startY: 0
                PathLine { x: 0; y: 30 } PathLine { x: 7; y: 23 } PathLine { x: 7; y: 0 }
            }
            ShapePath {
                fillColor: "transparent"; strokeColor: root.ink; strokeWidth: 1
                startX: 7; startY: 0
                PathLine { x: 14; y: 30 } PathLine { x: 7; y: 23 }
            }
        }
        Text {
            anchors { horizontalCenter: arrow.horizontalCenter; bottom: arrow.top; bottomMargin: 1 }
            text: "N"
            font { family: root.sans; pixelSize: 9; weight: Font.DemiBold }
            color: root.ink
        }

        ColumnLayout {
            anchors { fill: parent; leftMargin: 20; rightMargin: 20; topMargin: 16; bottomMargin: 14 }
            spacing: 0

            Text {
                id: title
                text: root.sheet.name || "PAFTA"
                font { family: root.sans; pixelSize: 21; weight: Font.DemiBold; letterSpacing: 3 }
                color: root.ink
            }
            Text {
                Layout.topMargin: 2
                text: (root.sheet.region || "") + "   " + (root.sheet.coords || "")
                font { family: root.sans; pixelSize: 12 }
                color: root.ink2
            }

            RowLayout {  // scale bar in five segments, true to this screen; its length follows the zoom
                Layout.topMargin: 12
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: 5
                    Rectangle {
                        width: root.sheet.seg_px || root.sheet.px_per_km || 34; height: 5
                        color: index % 2 === 0 ? root.ink : "transparent"
                        border { width: 1; color: root.ink }
                    }
                }
                Text {
                    Layout.leftMargin: 8
                    text: (root.sheet.bar_km || 5) + " km"
                    font { family: root.mono; pixelSize: 10 }
                    color: root.ink2
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.sheet.scale || ""
                    font { family: root.mono; pixelSize: 10 }
                    color: root.ink
                }
            }
            Caps {
                Layout.topMargin: 10
                text: root.sheet.note || ""
                visible: text !== ""
                color: root.ink2
            }

            Rule { Layout.topMargin: 10 }

            RowLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                Text {
                    text: root.pad(root.now.getHours()) + ":" + root.pad(root.now.getMinutes())
                    font { family: root.sans; pixelSize: 40; weight: Font.Light }
                    color: root.ink
                }
                Item { Layout.fillWidth: true }
                ColumnLayout {
                    spacing: 2
                    Caps {
                        Layout.alignment: Qt.AlignRight
                        text: root.days[root.now.getDay()]
                        font.weight: Font.DemiBold
                    }
                    Caps {
                        Layout.alignment: Qt.AlignRight
                        text: root.now.getDate() + " " + root.months[root.now.getMonth()] + " " + root.now.getFullYear()
                        color: root.ink2
                    }
                }
            }

            Rule { Layout.topMargin: 4 }

            Caps { Layout.topMargin: 10; text: root.skyLine() }
            Caps { Layout.topMargin: 5; text: root.weather; visible: text !== "" }
            Item { Layout.fillHeight: true }
        }
    }
}
