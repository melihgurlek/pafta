import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami

// Hours over minutes, set in Plex Mono like the coordinates in the sheet's margin, and the day
// underneath in small letter-spaced caps. Click: a legend box with the month and the sun.
PlasmoidItem {
    id: root

    readonly property string sans: "IBM Plex Sans"
    readonly property string mono: "IBM Plex Mono"
    readonly property var days: ["PAZ", "PZT", "SAL", "ÇAR", "PER", "CUM", "CMT"]
    readonly property var daysLong: ["PAZAR", "PAZARTESİ", "SALI", "ÇARŞAMBA", "PERŞEMBE", "CUMA", "CUMARTESİ"]
    readonly property var months: ["OCAK", "ŞUBAT", "MART", "NİSAN", "MAYIS", "HAZİRAN", "TEMMUZ",
                                   "AĞUSTOS", "EYLÜL", "EKİM", "KASIM", "ARALIK"]
    property date now: new Date()
    property var sheet: ({})

    function pad(n) { return (n < 10 ? "0" : "") + n }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    toolTipMainText: daysLong[now.getDay()] + " " + now.getDate() + " " + months[now.getMonth()]
    toolTipSubText: Qt.formatTime(now, "HH:mm")

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    // what the last print knows about the sun (written by pafta-sun)
    P5Support.DataSource {
        id: reader
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            try { root.sheet = JSON.parse(data["stdout"]) } catch (e) {}
            disconnectSource(source)
        }
    }
    function readState() { reader.connectSource("cat \"${XDG_CACHE_HOME:-$HOME/.cache}/pafta/state.json\"") }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.readState() }

    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumHeight: column.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.preferredHeight: Layout.minimumHeight
        Layout.minimumWidth: column.implicitWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Rectangle {  // the same raised wash as a hovered task
            anchors.fill: parent
            anchors.margins: 3
            color: Kirigami.Theme.textColor
            opacity: compact.containsMouse || root.expanded ? 0.07 : 0
        }

        ColumnLayout {
            id: column
            anchors.centerIn: parent
            spacing: 0
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.pad(root.now.getHours())
                font { family: root.mono; pixelSize: 17; weight: Font.Medium }
                color: Kirigami.Theme.textColor
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -3
                text: root.pad(root.now.getMinutes())
                font { family: root.mono; pixelSize: 17; weight: Font.Normal }
                color: Kirigami.Theme.textColor
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                width: 12; height: 1
                color: Kirigami.Theme.textColor
                opacity: 0.35
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.days[root.now.getDay()]
                font { family: root.sans; pixelSize: 9; weight: Font.DemiBold; letterSpacing: 1.2 }
                color: Kirigami.Theme.disabledTextColor
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.now.getDate()
                font { family: root.mono; pixelSize: 11 }
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 22
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            Text {
                text: Qt.formatTime(root.now, "HH:mm")
                font { family: root.sans; pixelSize: 34; weight: Font.Light }
                color: Kirigami.Theme.textColor
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 2
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: root.daysLong[root.now.getDay()]
                    font { family: root.sans; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 1.5 }
                    color: Kirigami.Theme.textColor
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: root.now.getDate() + " " + root.months[root.now.getMonth()] + " " + root.now.getFullYear()
                    font { family: root.sans; pixelSize: 11; letterSpacing: 1.2 }
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.leftMargin: Kirigami.Units.largeSpacing; Layout.rightMargin: Kirigami.Units.largeSpacing; height: 1; color: Kirigami.Theme.textColor; opacity: 0.25 }

        PlasmaCalendar.MonthView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            borderOpacity: 0.15
            today: root.now
            showWeekNumbers: false
        }

        Rectangle { Layout.fillWidth: true; Layout.leftMargin: Kirigami.Units.largeSpacing; Layout.rightMargin: Kirigami.Units.largeSpacing; height: 1; color: Kirigami.Theme.textColor; opacity: 0.25 }
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            visible: !!root.sheet.sun
            Text {
                text: root.sheet.sun ? "DOĞUŞ  " + root.sheet.sun.rise : ""
                font { family: root.sans; pixelSize: 10; weight: Font.Medium; letterSpacing: 1.3 }
                color: Kirigami.Theme.textColor
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.sheet.sun ? "BATIŞ  " + root.sheet.sun.set : ""
                font { family: root.sans; pixelSize: 10; weight: Font.Medium; letterSpacing: 1.3 }
                color: Kirigami.Theme.textColor
            }
        }
    }
}
