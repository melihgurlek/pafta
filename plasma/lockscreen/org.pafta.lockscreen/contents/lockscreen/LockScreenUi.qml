/*
    Pafta lock screen. Locking changes almost nothing: the sheet stays on screen and the legend
    box in its corner (the desktop's org.pafta.legend, same place, same type) gains one row, a
    password line. A wrong password knocks the magenta plate out of register for a moment.

    Auth plumbing follows Plasma's own LockScreenUi.qml (GPL-2.0-or-later).
*/
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.sessions
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

Item {
    id: ui

    readonly property bool night: config.paftaNight === true || config.paftaNight === "true"
    // the printing plates (palette.toml)
    readonly property color paper: night ? "#141A1F" : "#F3F1EA"
    readonly property color ink: night ? "#C3C7C0" : "#24282D"
    readonly property color ink2: night ? "#8C9296" : "#5E6266"
    readonly property color over: night ? "#CF6A9E" : "#A8336F"
    readonly property color road: night ? "#D0705A" : "#B5452F"
    readonly property string sans: "IBM Plex Sans"
    readonly property string mono: "IBM Plex Mono"
    readonly property var days: ["PAZAR", "PAZARTESİ", "SALI", "ÇARŞAMBA", "PERŞEMBE", "CUMA", "CUMARTESİ"]
    readonly property var months: ["OCAK", "ŞUBAT", "MART", "NİSAN", "MAYIS", "HAZİRAN", "TEMMUZ",
                                   "AĞUSTOS", "EYLÜL", "EKİM", "KASIM", "ARALIK"]
    property date now: new Date()
    property string message: ""
    property bool awake: false

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function wake() {
        awake = true
        password.forceActiveFocus()
        authenticator.startAuthenticating()
    }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: ui.now = new Date() }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) return
            ui.message = "PAROLA YANLIŞ"
            password.text = ""
            misregister.restart()
            graceLock.restart()
        }
        function onSucceeded() {
            if (authenticator.hadPrompt) Qt.quit()
            else ui.message = "PAROLA GEREKMİYOR · ENTER İLE AÇ"
        }
        function onErrorMessageChanged() { if (authenticator.errorMessage) ui.message = authenticator.errorMessage.toUpperCase() }
        function onPromptForSecretChanged() { password.forceActiveFocus() }
    }
    Connections {
        target: root
        function onClearPassword() { password.text = "" }
    }

    SessionManagement { id: sessions }
    KeyboardIndicator.KeyState { id: capsLock; key: Qt.Key_CapsLock }
    Timer { id: graceLock; interval: 3000; onTriggered: { ui.message = ""; authenticator.startAuthenticating() } }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: ui.awake ? Qt.ArrowCursor : Qt.BlankCursor
        property int moves: 0
        onPositionChanged: if (++moves > 1) ui.wake()
        onPressed: ui.wake()
    }
    Keys.onPressed: event => { if (!ui.awake) ui.wake() }
    focus: true

    // ---------------------------------------------------------------- the legend box
    Item {
        id: box
        width: 340
        height: content.implicitHeight + 30
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 54; bottomMargin: 54 }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: ui.paper
            border { width: 1; color: Qt.alpha(ui.ink, 0.85) }
            Rectangle { anchors { fill: parent; margins: 4 } color: "transparent"; border { width: 1; color: Qt.alpha(ui.ink, 0.3) } }
        }
        // the magenta plate, slipping out of register on a wrong password
        Rectangle {
            id: plate
            width: parent.width; height: parent.height
            color: "transparent"
            border { width: 2; color: ui.over }
            opacity: 0
        }
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

        Shape {  // north arrow
            id: arrow
            anchors { right: parent.right; top: parent.top; rightMargin: 22; topMargin: 18 }
            width: 14; height: 30
            preferredRendererType: Shape.CurveRenderer
            ShapePath { fillColor: ui.ink; strokeColor: ui.ink; strokeWidth: 1; startX: 7; startY: 0
                PathLine { x: 0; y: 30 } PathLine { x: 7; y: 23 } PathLine { x: 7; y: 0 } }
            ShapePath { fillColor: "transparent"; strokeColor: ui.ink; strokeWidth: 1; startX: 7; startY: 0
                PathLine { x: 14; y: 30 } PathLine { x: 7; y: 23 } }
        }
        Text { anchors { horizontalCenter: arrow.horizontalCenter; bottom: arrow.top; bottomMargin: 1 }
               text: "K"; font { family: ui.sans; pixelSize: 9; weight: Font.DemiBold } color: ui.ink }

        component Caps: Text { font { family: ui.sans; pixelSize: 10; weight: Font.Medium; letterSpacing: 1.3 } color: ui.ink }
        component Rule: Rectangle { Layout.fillWidth: true; height: 1; color: ui.ink; opacity: 0.35 }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 20; rightMargin: 20; topMargin: 16 }
            spacing: 0

            Text { text: config.paftaName || "PAFTA"; font { family: ui.sans; pixelSize: 21; weight: Font.DemiBold; letterSpacing: 3 } color: ui.ink }
            Text { Layout.topMargin: 2; text: (config.paftaRegion || "") + "   " + (config.paftaCoords || "")
                   font { family: ui.sans; pixelSize: 12 } color: ui.ink2 }
            RowLayout {
                Layout.topMargin: 12; Layout.fillWidth: true; spacing: 0
                Repeater { model: 5
                    Rectangle { width: Number(config.paftaPxPerKm) || 34; height: 5
                        color: index % 2 === 0 ? ui.ink : "transparent"; border { width: 1; color: ui.ink } } }
                Text { Layout.leftMargin: 8; text: "5 km"; font { family: ui.mono; pixelSize: 10 } color: ui.ink2 }
                Item { Layout.fillWidth: true }
                Text { text: config.paftaScale || ""; font { family: ui.mono; pixelSize: 10 } color: ui.ink }
            }
            Caps { Layout.topMargin: 10; text: "EŞ YÜKSELTİ ARALIĞI " + (config.paftaContour || 50) + " M"; color: ui.ink2 }
            Rule { Layout.topMargin: 10 }
            RowLayout {
                Layout.topMargin: 6; Layout.fillWidth: true
                Text { text: ui.pad(ui.now.getHours()) + ":" + ui.pad(ui.now.getMinutes())
                       font { family: ui.sans; pixelSize: 40; weight: Font.Light } color: ui.ink }
                Item { Layout.fillWidth: true }
                ColumnLayout { spacing: 2
                    Caps { Layout.alignment: Qt.AlignRight; text: ui.days[ui.now.getDay()]; font.weight: Font.DemiBold }
                    Caps { Layout.alignment: Qt.AlignRight; color: ui.ink2
                           text: ui.now.getDate() + " " + ui.months[ui.now.getMonth()] + " " + ui.now.getFullYear() } }
            }
            Rule { Layout.topMargin: 4 }

            // the one new row: who, and the password as a ruled line
            RowLayout {
                Layout.topMargin: 12; Layout.fillWidth: true; spacing: 12
                Caps { text: kscreenlocker_userName.toLocaleUpperCase(); color: ui.ink2; font.weight: Font.DemiBold }
                QQC2.TextField {
                    id: password
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    enabled: !graceLock.running
                    focus: true
                    color: ui.ink
                    font { family: ui.mono; pixelSize: 13; letterSpacing: 2 }
                    leftPadding: 0; rightPadding: 0; topPadding: 2; bottomPadding: 5
                    placeholderText: ui.awake ? "" : "PAROLA"
                    placeholderTextColor: Qt.alpha(ui.ink2, 0.7)
                    selectionColor: ui.over
                    background: Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: password.activeFocus ? 2 : 1
                        color: password.activeFocus ? ui.ink : Qt.alpha(ui.ink, 0.5)
                    }
                    onAccepted: if (text.length || !authenticator.hadPrompt) authenticator.respond(text)
                    Keys.onEscapePressed: { text = ""; ui.awake = false }
                }
                Text { text: "→"; font { family: ui.sans; pixelSize: 16 } color: password.text.length ? ui.over : "transparent"
                       MouseArea { anchors.fill: parent; onClicked: password.accepted() } }
            }
            Caps {
                Layout.topMargin: 10
                text: ui.message || (capsLock.locked ? "BÜYÜK HARF KİLİDİ AÇIK" : (config.paftaSky || ""))
                color: ui.message || capsLock.locked ? ui.road : ui.ink
            }
            RowLayout {
                Layout.topMargin: 5; Layout.fillWidth: true; spacing: 14
                Caps { text: "UYKU"; color: sleepArea.containsMouse ? ui.over : ui.ink2; visible: sessions.canSuspend
                       MouseArea { id: sleepArea; anchors.fill: parent; hoverEnabled: true; onClicked: sessions.suspend() } }
                Caps { text: "KULLANICI DEĞİŞTİR"; color: switchArea.containsMouse ? ui.over : ui.ink2; visible: sessions.canSwitchUser
                       MouseArea { id: switchArea; anchors.fill: parent; hoverEnabled: true; onClicked: sessions.switchUser() } }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
