import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts

// The Lights tab: per-zone color editing wired live to the controller render,
// effect presets, brightness/speed, a keyframe animation editor, and the global
// power settings. Every edit is STAGED like the other pages: the render and the
// page show it at once. Color edits apply automatically; other lighting settings
// remain staged for Save. Profile selection and Play/Pause act immediately too.
Item {
    id: page

    property var sel: [0]                     // selected zones, all get the picker color
    property var frames: [bridge.lightColors.slice()]
    // Per-model: the Cyclone exposes four lights, the Kaleid two.
    readonly property int nZones: bridge.lightNames.length
    // A different light count arrives (controllerChanged) BEFORE the new
    // controller's lighting is read: drop a pending stage built for the old
    // count and re-seed now, so nothing indexes past the new zones.
    onNZonesChanged: syncFromBridge()
    property int curFrame: 0
    property bool playing: true
    property string sleepSel: "10 min"

    // When the viewport is too short to stack all the control cards on the left,
    // the Power card moves into the slack under the controller (centre) so the
    // empty middle space is used before falling back to scrolling.
    readonly property bool compact: scroller.availableHeight > 0
                                    && scroller.availableHeight < 700

    Component.onCompleted: syncFromBridge()

    // Pull the page in line with the controller's real lighting state. Runs at
    // startup and whenever the bridge reads a new active slot back.
    function syncFromBridge() {
        frames = bridge.loadedFrames.length > 0 ? bridge.loadedFrames
                                                : [bridge.lightColors.slice()]
        curFrame = 0
        audioSw.checked = bridge.audioReactive
        wakeSw.checked = bridge.pickupWake
        sleepSel = bridge.sleepLabel
        briSlider.value = bridge.brightness
        spdSlider.value = bridge.speed
        if (!sel.length || sel.some(function (z) { return z >= page.nZones })) sel = [0]
        selectZone(sel[sel.length - 1], false)
    }

    Connections {
        target: bridge
        function onLightingLoaded() { page.syncFromBridge() }
    }

    // ---- helpers -----------------------------------------------------------
    function _h2(x) { var s = Math.round(x * 255).toString(16); return s.length < 2 ? "0" + s : s }
    function colorToHex(c) { return "#" + _h2(c.r) + _h2(c.g) + _h2(c.b) }
    function hexToRgb(h) {
        h = ("" + h).replace("#", "")
        return [parseInt(h.substr(0, 2), 16), parseInt(h.substr(2, 2), 16), parseInt(h.substr(4, 2), 16)]
    }
    function randomVivid() { return colorToHex(Qt.hsva(Math.random(), 1, 1, 1)) }

    function isZoneSelected(z) { return sel.indexOf(z) >= 0 }
    function selectAllZones() {
        var all = []
        for (var i = 0; i < page.nZones; i++) all.push(i)
        sel = all
        if (all.length) picker.setColor(bridge.lightColors[all[all.length - 1]])
    }
    function selectZone(z, additive) {
        z = Math.max(0, Math.min(page.nZones - 1, z))
        var next = sel.slice()
        if (additive) {
            var at = next.indexOf(z)
            if (at >= 0) {
                if (next.length > 1) next.splice(at, 1)
            } else next.push(z)
        } else next = [z]
        sel = next
        var primary = next.indexOf(z) >= 0 ? z : next[next.length - 1]
        picker.setColor(bridge.lightColors[primary])
    }
    function onZoneEdited(c) {
        var hex = colorToHex(c)
        var frame = frames[curFrame].slice()
        for (var i = 0; i < sel.length; i++) frame[sel[i]] = hex
        var nextFrames = frames.slice(); nextFrames[curFrame] = frame; frames = nextFrames
        bridge.setLights(sel, hex)
        stageAnimation()
    }
    function loadFrame(i) {
        for (var z = 0; z < page.nZones; z++) bridge.setLight(z, frames[i][z])
        picker.setColor(bridge.lightColors[sel])
    }
    function addFrame() {
        if (frames.length >= 8) return
        var f = frames.slice(); f.push(bridge.lightColors.slice())
        frames = f; curFrame = frames.length - 1; loadFrame(curFrame)
        stageAnimation()
    }
    function removeFrame() {
        if (frames.length <= 1) return
        var f = frames.slice(); f.splice(curFrame, 1); frames = f
        if (curFrame >= f.length) curFrame = f.length - 1
        loadFrame(curFrame)
        stageAnimation()
    }
    function randomizeFrame() {
        var f = frames.slice(); var fr = f[curFrame].slice()
        for (var z = 0; z < page.nZones; z++) fr[z] = randomVivid()
        f[curFrame] = fr; frames = f; loadFrame(curFrame)
        stageAnimation()
    }
    function stageAnimation() {
        var rgb = []
        for (var i = 0; i < frames.length; i++) {
            var fr = []
            for (var z = 0; z < page.nZones; z++) fr.push(hexToRgb(frames[i][z]))
            rgb.push(fr)
        }
        bridge.applyKeyframes(rgb)
    }
    function togglePlay() { playing = !playing; bridge.setPlayback(playing, curFrame + 1) }

    // ---- small reusable button --------------------------------------------
    component TextButton: Rectangle {
        property string label: I18n.t("")
        property bool highlight: false
        signal clicked()
        implicitWidth: bt.implicitWidth + 22; implicitHeight: 30; radius: 7
        color: highlight ? Theme.accent : (hh.hovered ? Theme.cardHover : "#20232B")
        border.color: highlight ? Qt.lighter(Theme.accent, 1.2) : Theme.cardBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            id: bt; anchors.centerIn: parent; text: parent.label
            color: parent.highlight ? Theme.textOnAccent : Theme.text
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontM
        }
        HoverHandler { id: hh }
        TapHandler { onTapped: parent.clicked() }
    }

    // Scroll fallback: fills a tall window, scrolls once the cards no longer fit.
    FitScroll {
        id: scroller
        anchors.fill: parent
        anchors.bottomMargin: pbar.height + 10   // reserve the Save bar's space (no reflow)
        content: lightRow
        topPadding: 20; bottomPadding: 20; leftPadding: 20; rightPadding: 20

    RowLayout {
        id: lightRow
        width: scroller.availableWidth
        height: Math.max(implicitHeight, scroller.availableHeight)
        spacing: 16

        // ============================ LEFT ============================
        ColumnLayout {
            id: leftCol
            Layout.fillWidth: true
            Layout.minimumWidth: 230; Layout.preferredWidth: 260; Layout.maximumWidth: 320
            Layout.fillHeight: true
            spacing: 16

            Card {
                title: I18n.t("Lighting Profile"); Layout.fillWidth: true
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    // Two separate sets of "profiles" are easy to mix up: say so.
                    text: bridge.lightingSlotSelectable
                          ? "Lighting has its own four profiles, separate from the " +
                            "controller profiles (P1–P4) at the top: switching one " +
                            "doesn't change the other. Picking one here switches " +
                            "the controller's lights straight away."
                          : "Lighting has its own profiles, separate from the controller " +
                            "profiles at the top. Pick one on the controller with " +
                            "M + Y / B / A / X; whichever it shows is the one you're editing."
                    color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: Theme.fontS
                }
                Row {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: 4
                        delegate: TextButton {
                            required property int index
                            label: I18n.t("") + (index + 1)
                            implicitWidth: 44
                            highlight: bridge.ledSlot === index
                            // read-only indicator where the pad owns the selection
                            onClicked: if (bridge.lightingSlotSelectable) bridge.selectSlot(index)
                        }
                    }
                }
            }

            Card {
                title: I18n.t("Presets"); Layout.fillWidth: true
                Flow {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: bridge.presetNames
                        delegate: TextButton {
                            required property string modelData
                            label: I18n.t(modelData)
                            highlight: bridge.currentPreset === modelData
                            onClicked: bridge.applyPreset(modelData)
                        }
                    }
                    TextButton { label: I18n.t("Off"); highlight: bridge.currentPreset === "Off"
                                 onClicked: bridge.lightsOff() }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    visible: bridge.currentPreset === ""
                    text: I18n.t("Showing custom colours. Pick a preset to replace them.")
                    color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: Theme.fontS
                }
            }

            Card {
                title: I18n.t("Brightness & Speed"); Layout.fillWidth: true
                Row {
                    width: parent.width
                    Text { text: I18n.t("Brightness"); color: Theme.textDim
                           font.family: Theme.fontFamily; font.pixelSize: Theme.fontS }
                    Item { width: parent.width - briLbl.width - 70; height: 1 }
                    Text { id: briLbl; text: bridge.brightness + "%"; color: Theme.text
                           font.family: Theme.fontFamily; font.pixelSize: Theme.fontS }
                }
                AccentSlider {
                    id: briSlider
                    width: parent.width; from: 0; to: 100; value: bridge.brightness
                    onMoved: bridge.setBrightness(value)
                }
                Row {
                    width: parent.width
                    Text { text: I18n.t("Speed"); color: Theme.textDim
                           font.family: Theme.fontFamily; font.pixelSize: Theme.fontS }
                    Item { width: parent.width - spdLbl.width - 42; height: 1 }
                    Text { id: spdLbl; text: bridge.speed + ""; color: Theme.text
                           font.family: Theme.fontFamily; font.pixelSize: Theme.fontS }
                }
                AccentSlider {
                    id: spdSlider
                    width: parent.width; from: 1; to: 20; value: bridge.speed
                    onMoved: bridge.setSpeed(value)
                }
            }

            Card {
                title: I18n.t("Power"); Layout.fillWidth: true
                visible: bridge.lightingPowerSupported
                // Lives on the left normally; reparents into the centre column's
                // slack (under the controller) when the viewport is short.
                parent: page.compact ? centerColumn : leftCol
                Row {
                    width: parent.width
                    Text { text: I18n.t("Audio reactive"); color: Theme.text
                           font.family: Theme.fontFamily; font.pixelSize: Theme.fontM
                           anchors.verticalCenter: parent.verticalCenter }
                    Item { width: parent.width - 130 - audioSw.width; height: 1 }
                    ToggleSwitch { id: audioSw; onToggled: bridge.setAudioReactive(audioSw.checked) }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: I18n.t("Experimental — arms the device flag, but live reactivity ") +
                          "needs the host to stream audio (not yet implemented)."
                    color: Theme.textFaint
                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontS
                }
                Row {
                    width: parent.width
                    Text { text: I18n.t("Pick-up to wake"); color: Theme.text
                           font.family: Theme.fontFamily; font.pixelSize: Theme.fontM
                           anchors.verticalCenter: parent.verticalCenter }
                    Item { width: parent.width - 130 - wakeSw.width; height: 1 }
                    ToggleSwitch { id: wakeSw; onToggled: bridge.setPickupWake(wakeSw.checked) }
                }
                Text { text: I18n.t("Sleep timer"); color: Theme.textDim
                       font.family: Theme.fontFamily; font.pixelSize: Theme.fontS }
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: bridge.sleepOptions
                        delegate: TextButton {
                            required property string modelData
                            label: modelData
                            highlight: page.sleepSel === modelData
                            onClicked: { page.sleepSel = modelData; bridge.setSleepTimeout(modelData) }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ============================ CENTER ============================
        ColumnLayout {
            id: centerColumn
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.horizontalStretchFactor: 2   // controller render gets the extra room
            spacing: 16
            Item {
                id: centerArea
                Layout.fillWidth: true
                // Yield the vertical slack to the Power card when it reparents here.
                Layout.fillHeight: !page.compact
                // Report the render + zone-picker height so it can't overflow and
                // overlap the side columns; centred when there's spare room.
                implicitHeight: centerCol.implicitHeight
                Column {
                    id: centerCol
                    width: parent.width
                    y: Math.max(0, (parent.height - implicitHeight) / 2)
                    spacing: 14
                ControllerView {
                    anchors.horizontalCenter: parent.horizontalCenter
                    lightZoneSelectionEnabled: true
                    selectedLightZones: page.sel
                    onLightZoneTapped: function (zone, additive) { page.selectZone(zone, additive) }
                    // Cap the render when the viewport is short so the reparented
                    // Power card and side columns aren't pushed off the bottom.
                    width: Math.min(implicitWidth, centerArea.width - 24,
                                    page.compact ? 200 : 100000)
                    height: width / aspect
                }
                // Flow (not Row) so the zone chips wrap to a 2×2 block when the
                // center column is too narrow to hold them on one line, instead of
                // spilling over the neighbouring cards.
                Flow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(page.nZones * 96 + (page.nZones - 1) * 6, centerArea.width)
                    spacing: 6
                    Repeater {
                        model: page.nZones
                        delegate: Rectangle {
                            required property int index
                            width: 96; height: 40; radius: 8
                            color: page.isZoneSelected(index) ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) : "#1A1C22"
                            border.color: page.isZoneSelected(index) ? Theme.accent : Theme.cardBorder
                            border.width: page.isZoneSelected(index) ? 2 : 1
                            Row {
                                anchors.centerIn: parent; spacing: 6
                                Rectangle {
                                    width: 16; height: 16; radius: 4
                                    color: bridge.lightColors[index]
                                    border.color: "#555"; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: bridge.lightNames[index]; color: Theme.textDim
                                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontS
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.selectZone(index, (mouse.modifiers & Qt.ControlModifier) !== 0)
                            }
                        }
                    }
                    TextButton {
                        label: I18n.t("Select all")
                        highlight: page.sel.length === page.nZones
                        onClicked: page.selectAllZones()
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.t("Click a zone to select it; Ctrl-click to add or remove zones")
                    color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: Theme.fontS
                }
            }
            }
        }

        // ============================ RIGHT ============================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 270; Layout.preferredWidth: 300; Layout.maximumWidth: 360
            Layout.fillHeight: true
            spacing: 16

            Card {
                title: I18n.t("Color — ") + page.sel.map(function (i) { return bridge.lightNames[i] || "" }).join(", "); Layout.fillWidth: true
                ColorPicker {
                    id: picker; width: parent.width
                    onEdited: page.onZoneEdited(c)
                }
            }

            Card {
                title: I18n.t("Keyframes"); Layout.fillWidth: true
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: page.frames.length
                        delegate: TextButton {
                            required property int index
                            label: I18n.t("") + (index + 1)
                            implicitWidth: 32
                            highlight: page.curFrame === index
                            onClicked: { page.curFrame = index; page.loadFrame(index) }
                        }
                    }
                    TextButton { label: I18n.t("+"); implicitWidth: 32
                                 enabled: page.frames.length < 8
                                 opacity: page.frames.length < 8 ? 1 : 0.4
                                 onClicked: page.addFrame() }
                    TextButton { label: I18n.t("−"); implicitWidth: 32
                                 enabled: page.frames.length > 1
                                 opacity: page.frames.length > 1 ? 1 : 0.4
                                 onClicked: page.removeFrame() }
                }
                Text {
                    width: parent.width
                    text: page.frames.length + " / 8 " + I18n.t("Keyframes — color changes apply automatically")
                    color: Theme.textFaint; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontS; wrapMode: Text.WordWrap
                }
                Row {
                    width: parent.width; spacing: 8
                    TextButton { label: I18n.t("Randomize"); onClicked: page.randomizeFrame() }
                    TextButton { label: page.playing ? I18n.t("Pause") : I18n.t("Play")
                                 visible: bridge.lightingPlaybackSupported
                                 onClicked: page.togglePlay() }
                }
            }

            // Rewrites the keyframe records from the factory baseline. Destructive,
            // so it confirms first.
            ConfirmButton {
                label: I18n.t("Restore default lighting")
                confirmLabel: "Restore default lighting?"
                visible: bridge.lightingRestorable
                onConfirmed: bridge.restoreLighting()
            }

            Item { Layout.fillHeight: true }
        }
    }
    }

    PendingBar {
        id: pbar
        anchors.left: parent.left; anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.bottomMargin: 20
    }
}
