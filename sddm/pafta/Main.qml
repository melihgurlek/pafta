// Pafta login. The sheet under the sun of the hour (dawn, day, dusk or night print, chosen by
// computing where the sun is), and in its corner the legend box of the desktop with two rows
// more: who, and the password. Logging in folds the rows away, so the box that is left is the
// one the desktop puts in the same place. A wrong password knocks the magenta plate out of
// register, like a misprinted sheet.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Rectangle {
    id: root
    width: 1920
    height: 1080

    readonly property bool demo: config.demo === "true"
    readonly property real lat: Number(config.lat) || 41.01
    readonly property real lon: Number(config.lon) || 28.98
    property date now: new Date()
    readonly property real sunAlt: altitude(now)
    // theme.conf phase=dawn|day|dusk|night pins one (previews); otherwise the sun decides
    readonly property string phase: config.phase ? config.phase
        : sunAlt < -6 ? "night" : sunAlt < 8 ? (now.getHours() < 12 ? "dawn" : "dusk") : "day"
    readonly property bool night: config.phase ? config.phase === "night" : sunAlt < -2

    readonly property color paper: night ? "#141A1F" : "#F3F1EA"
    readonly property color view: night ? "#0F1418" : "#FBFAF6"
    readonly property color ink3: night ? "#5F676C" : "#8F918C"
    readonly property color ink: night ? "#C3C7C0" : "#24282D"
    readonly property color ink2: night ? "#8C9296" : "#5E6266"
    readonly property color over: night ? "#CF6A9E" : "#A8336F"
    readonly property color road: night ? "#D0705A" : "#B5452F"
    readonly property string sans: "IBM Plex Sans"
    readonly property string mono: "IBM Plex Mono"
    readonly property var days: ["PAZAR", "PAZARTESİ", "SALI", "ÇARŞAMBA", "PERŞEMBE", "CUMA", "CUMARTESİ"]
    readonly property var months: ["OCAK", "ŞUBAT", "MART", "NİSAN", "MAYIS", "HAZİRAN", "TEMMUZ",
                                   "AĞUSTOS", "EYLÜL", "EKİM", "KASIM", "ARALIK"]

    property string userName: userModel.lastUser
    property string realName: ""
    property int session: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property var sessionNames: []
    property string message: ""
    property bool leaving: false

    color: paper

    FontLoader { source: "fonts/IBMPlexSans-Light.otf" }
    FontLoader { source: "fonts/IBMPlexSans-Regular.otf" }
    FontLoader { source: "fonts/IBMPlexSans-Medium.otf" }
    FontLoader { source: "fonts/IBMPlexSans-SemiBold.otf" }
    FontLoader { source: "fonts/IBMPlexMono-Regular.otf" }

    // the sun over home, low-precision almanac (same as pafta-print)
    function altitude(d) {
        const rad = Math.PI / 180, n = d.getTime() / 86400000 + 2440587.5 - 2451545.0
        const g = ((357.528 + 0.9856003 * n) % 360) * rad
        const lam = (((280.460 + 0.9856474 * n) % 360) + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g)) * rad
        const eps = (23.439 - 0.0000004 * n) * rad
        const ra = Math.atan2(Math.cos(eps) * Math.sin(lam), Math.cos(lam))
        const dec = Math.asin(Math.sin(eps) * Math.sin(lam))
        const ha = (((280.46061837 + 360.98564736629 * n) % 360) + lon) * rad - ra
        const la = lat * rad
        return Math.asin(Math.sin(la) * Math.sin(dec) + Math.cos(la) * Math.cos(dec) * Math.cos(ha)) / rad
    }
    function pad(n) { return (n < 10 ? "0" : "") + n }

    Repeater {  // userModel.lastUser can be empty (first boot, test mode): take the first user
        model: userModel
        delegate: Item {
            Component.onCompleted: {
                if (!root.userName && index === 0) root.userName = model.name
                if (model.name === root.userName || (!root.userName && index === 0)) root.realName = model.realName || model.name
            }
        }
    }
    Repeater {
        model: sessionModel
        delegate: Item { Component.onCompleted: { const s = root.sessionNames.slice(); s[index] = model.name; root.sessionNames = s } }
    }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }
    property bool blink: true
    Timer { interval: 530; running: true; repeat: true; onTriggered: root.blink = !root.blink }
    Component.onCompleted: password.forceActiveFocus()

    function login() {
        if (root.demo) {
            if (password.text.length) loggedIn.start(); else failed()
            return
        }
        sddm.login(root.userName, password.text, root.session)
    }
    function failed() {
        root.message = "WRONG PASSWORD"
        password.text = ""
        misregister.restart()
    }
    Connections {
        target: sddm
        function onLoginFailed() { root.failed() }
        function onLoginSucceeded() { loggedIn.start() }
    }

    Image {
        anchors.fill: parent
        source: "prints/" + root.phase + ".jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }

    // ---------------------------------------------------------------- the legend box
    Item {
        id: box
        width: 340
        height: content.implicitHeight + 30
        clip: true
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 54; bottomMargin: 54 }

        Rectangle {
            anchors.fill: parent
            color: root.paper
            border { width: 1; color: Qt.alpha(root.ink, 0.85) }
            Rectangle { anchors { fill: parent; margins: 4 } color: "transparent"; border { width: 1; color: Qt.alpha(root.ink, 0.3) } }
        }
        Rectangle { id: plate; width: parent.width; height: parent.height; color: "transparent"; border { width: 2; color: root.over } opacity: 0 }
        SequentialAnimation {
            id: misregister
            ParallelAnimation {
                NumberAnimation { target: plate; property: "opacity"; to: 0.9; duration: 60 }
                NumberAnimation { target: plate; property: "x"; from: 0; to: 5; duration: 60 }
                NumberAnimation { target: plate; property: "y"; from: 0; to: -3; duration: 60 }
            }
            PauseAnimation { duration: 260 }
            ParallelAnimation {
                NumberAnimation { target: plate; property: "opacity"; to: 0; duration: 380 }
                NumberAnimation { target: plate; property: "x"; to: 0; duration: 380; easing.type: Easing.OutCubic }
                NumberAnimation { target: plate; property: "y"; to: 0; duration: 380; easing.type: Easing.OutCubic }
            }
        }
        // logging in folds the login rows away; what is left is the desktop's legend
        SequentialAnimation {
            id: loggedIn
            ScriptAction { script: root.leaving = true }
            PauseAnimation { duration: 700 }
            ScriptAction { script: if (root.demo) { root.leaving = false; password.text = ""; root.message = "" } }
        }

        Shape {
            id: arrow
            anchors { right: parent.right; top: parent.top; rightMargin: 22; topMargin: 18 }
            width: 14; height: 30
            preferredRendererType: Shape.CurveRenderer
            ShapePath { fillColor: root.ink; strokeColor: root.ink; strokeWidth: 1; startX: 7; startY: 0
                PathLine { x: 0; y: 30 } PathLine { x: 7; y: 23 } PathLine { x: 7; y: 0 } }
            ShapePath { fillColor: "transparent"; strokeColor: root.ink; strokeWidth: 1; startX: 7; startY: 0
                PathLine { x: 14; y: 30 } PathLine { x: 7; y: 23 } }
        }
        Text { anchors { horizontalCenter: arrow.horizontalCenter; bottom: arrow.top; bottomMargin: 1 }
               text: "K"; font { family: root.sans; pixelSize: 9; weight: Font.DemiBold } color: root.ink }

        component Caps: Text { font { family: root.sans; pixelSize: 10; weight: Font.Medium; letterSpacing: 1.3 } color: root.ink }
        component Rule: Rectangle { Layout.fillWidth: true; height: 1; color: root.ink; opacity: 0.35 }
        component Link: Caps {
            id: link
            signal activated()
            color: area.containsMouse ? root.over : root.ink2
            MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: link.activated() }
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 20; rightMargin: 20; topMargin: 16 }
            spacing: 0

            Text { text: config.sheetName || "PAFTA"; font { family: root.sans; pixelSize: 21; weight: Font.DemiBold; letterSpacing: 3 } color: root.ink }
            Text { Layout.topMargin: 2; text: (config.sheetRegion || "") + "   " + (config.sheetCoords || "")
                   font { family: root.sans; pixelSize: 12 } color: root.ink2 }
            RowLayout {
                Layout.topMargin: 12; Layout.fillWidth: true; spacing: 0
                Repeater { model: 5
                    Rectangle { width: Number(config.segPx) || Number(config.pxPerKm) || 34; height: 5
                        color: index % 2 === 0 ? root.ink : "transparent"; border { width: 1; color: root.ink } } }
                Text { Layout.leftMargin: 8; text: (config.barKm || 5) + " km"; font { family: root.mono; pixelSize: 10 } color: root.ink2 }
                Item { Layout.fillWidth: true }
                Text { text: config.sheetScale || ""; font { family: root.mono; pixelSize: 10 } color: root.ink }
            }
            Caps { Layout.topMargin: 10; text: config.note || ("EŞ YÜKSELTİ ARALIĞI " + (config.contour || 50) + " M"); color: root.ink2 }
            Rule { Layout.topMargin: 10 }
            RowLayout {
                Layout.topMargin: 6; Layout.fillWidth: true
                Text { text: root.pad(root.now.getHours()) + ":" + root.pad(root.now.getMinutes())
                       font { family: root.sans; pixelSize: 40; weight: Font.Light } color: root.ink }
                Item { Layout.fillWidth: true }
                ColumnLayout { spacing: 2
                    Caps { Layout.alignment: Qt.AlignRight; text: root.days[root.now.getDay()]; font.weight: Font.DemiBold }
                    Caps { Layout.alignment: Qt.AlignRight; color: root.ink2
                           text: root.now.getDate() + " " + root.months[root.now.getMonth()] + " " + root.now.getFullYear() } }
            }

            // ------------------------------------------------ the login rows (fold away on login)
            ColumnLayout {
                id: rows
                Layout.fillWidth: true
                spacing: 0
                Layout.preferredHeight: root.leaving ? 0 : implicitHeight
                opacity: root.leaving ? 0 : 1
                clip: true
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
                Behavior on opacity { NumberAnimation { duration: 250 } }

                Rule { Layout.topMargin: 4 }
                Caps { Layout.topMargin: 12; text: (root.realName || root.userName).toLocaleUpperCase(Qt.locale("tr_TR")); color: root.ink2; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.topMargin: 6; Layout.fillWidth: true
                    height: 36
                    color: root.view
                    border { width: 1; color: password.activeFocus ? root.ink : Qt.alpha(root.ink, 0.55) }
                    Rectangle { width: 3; height: parent.height; color: root.over; visible: password.activeFocus }
                    TextInput {
                        id: password
                        anchors { left: parent.left; right: go.left; verticalCenter: parent.verticalCenter; leftMargin: 13; rightMargin: 6 }
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        focus: true
                        clip: true
                        color: root.ink
                        selectionColor: root.over
                        font { family: root.mono; pixelSize: 14; letterSpacing: 2 }
                        cursorDelegate: Rectangle { width: 2; color: root.over; visible: password.activeFocus && root.blink }
                        onAccepted: root.login()
                        onTextChanged: if (text.length) root.message = ""
                        Text { visible: !password.text.length; text: "Password"; color: root.ink3
                               anchors.verticalCenter: parent.verticalCenter; x: 4
                               font { family: root.mono; pixelSize: 14; letterSpacing: 2 } }
                    }
                    Rectangle {
                        id: go
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 4 }
                        width: height
                        color: password.text.length ? root.over : Qt.alpha(root.ink, 0.08)
                        Text { anchors.centerIn: parent; text: "→"; font { family: root.sans; pixelSize: 15; weight: Font.Medium }
                               color: password.text.length ? root.view : root.ink2 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.login() }
                    }
                }
                Caps {
                    Layout.topMargin: 8
                    text: root.message || (keyboard.capsLock ? "CAPS LOCK IS ON" : "TYPE YOUR PASSWORD, THEN ENTER")
                    color: root.message || keyboard.capsLock ? root.road : root.ink2
                }
                Rule { Layout.topMargin: 10 }
                RowLayout {
                    Layout.topMargin: 8; Layout.fillWidth: true; spacing: 14
                    Link {
                        text: "SESSION  " + (root.sessionNames[root.session] || "").toLocaleUpperCase(Qt.locale("tr_TR"))
                        onActivated: root.session = (root.session + 1) % Math.max(sessionModel.count, 1)
                    }
                    Item { Layout.fillWidth: true }
                }
                RowLayout {
                    Layout.topMargin: 5; Layout.fillWidth: true; spacing: 14
                    Link { text: "SLEEP"; visible: root.demo || sddm.canSuspend; onActivated: sddm.suspend() }
                    Link { text: "RESTART"; visible: root.demo || sddm.canReboot; onActivated: sddm.reboot() }
                    Link { text: "SHUT DOWN"; visible: root.demo || sddm.canPowerOff; onActivated: sddm.powerOff() }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
