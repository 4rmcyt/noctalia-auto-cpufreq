import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root
    property var pluginApi: null

    readonly property var main: pluginApi?.mainInstance
    readonly property var geometryPlaceholder: panelContainer

    property real contentPreferredWidth:  360 * Style.uiScaleRatio
    property real contentPreferredHeight: (mainCol.implicitHeight + Style.marginL * 4) * Style.uiScaleRatio

    readonly property bool allowAttach: true

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: mainCol
            anchors { fill: parent; margins: Style.marginL }
            spacing: Style.marginM

            // ── Header ────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: headerRow.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant
                radius: Style.radiusM

                RowLayout {
                    id: headerRow
                    anchors { fill: parent; margins: Style.marginM }
                    spacing: Style.marginM

                    NIcon {
                        icon: "cpu"
                        pointSize: Style.fontSizeXL
                        color: root.main?.daemonRunning ? Color.mPrimary : Color.mError
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        NText {
                            text: "auto-cpufreq"
                            pointSize: Style.fontSizeM
                            font.weight: Font.Bold
                            color: Color.mOnSurface
                        }
                        NText {
                            text: root.main?.daemonRunning
                                ? pluginApi?.tr("panel.daemon-running")
                                : pluginApi?.tr("panel.daemon-stopped")
                            pointSize: Style.fontSizeXS
                            color: root.main?.daemonRunning ? Color.mOnSurfaceVariant : Color.mError
                        }
                    }

                    NIconButton {
                        icon: "refresh"
                        onClicked: root.main?.refreshAll()
                    }
                }
            }

            // ── CPU stats ─────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statsRow.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant
                radius: Style.radiusM

                RowLayout {
                    id: statsRow
                    anchors { fill: parent; margins: Style.marginM }
                    spacing: Style.marginL

                    StatCell {
                        icon: "activity"
                        label: pluginApi?.tr("panel.cpu-usage")
                        value: (root.main?.cpuUsage ?? 0) + "%"
                        valueColor: {
                            let u = root.main?.cpuUsage ?? 0
                            if (u >= 90) return Color.mError
                            if (u >= 70) return Color.mTertiary
                            return Color.mOnSurface
                        }
                    }

                    StatCell {
                        icon: "cpu"
                        label: pluginApi?.tr("panel.cpu-freq")
                        value: (root.main?.cpuFreqMhz ?? 0) > 0
                            ? Math.round(root.main.cpuFreqMhz) + " MHz"
                            : "—"
                    }

                    StatCell {
                        icon: "thermometer"
                        label: pluginApi?.tr("panel.cpu-temp")
                        value: root.main?.cpuTemp ?? "—"
                        valueColor: {
                            let t = parseInt(root.main?.cpuTemp ?? "0")
                            if (t >= 90) return Color.mError
                            if (t >= 75) return Color.mTertiary
                            return Color.mOnSurface
                        }
                    }
                }
            }

            // ── Battery ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: batRow.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant
                radius: Style.radiusM
                visible: (root.main?.batCapacity ?? -1) >= 0

                RowLayout {
                    id: batRow
                    anchors { fill: parent; margins: Style.marginM }
                    spacing: Style.marginM

                    NIcon {
                        icon: {
                            let s = root.main?.batStatus ?? ""
                            if (s === "Charging") return "battery-charging"
                            let c = root.main?.batCapacity ?? 0
                            if (c >= 80) return "battery-4"
                            if (c >= 60) return "battery-3"
                            if (c >= 40) return "battery-2"
                            if (c >= 20) return "battery-1"
                            return "battery"
                        }
                        color: {
                            let s = root.main?.batStatus ?? ""
                            if (s === "Charging") return Color.mTertiary
                            let c = root.main?.batCapacity ?? 100
                            if (c <= 20) return Color.mError
                            return Color.mOnSurface
                        }
                        pointSize: Style.fontSizeXL
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        NText {
                            text: (root.main?.batCapacity ?? 0) + "%  ·  " + (root.main?.batStatus ?? "—")
                            pointSize: Style.fontSizeM
                            font.weight: Font.Bold
                            color: Color.mOnSurface
                        }

                        NText {
                            visible: (root.main?.batWatts ?? 0) > 0
                            text: {
                                let s = root.main?.batStatus ?? ""
                                let w = root.main?.batWatts ?? 0
                                if (s === "Charging") return "+" + w.toFixed(1) + " W"
                                return "−" + w.toFixed(1) + " W"
                            }
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                        }
                    }
                }
            }

            // ── Governor & turbo ──────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: govCol.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant
                radius: Style.radiusM

                ColumnLayout {
                    id: govCol
                    anchors { fill: parent; margins: Style.marginM }
                    spacing: Style.marginS

                    NText {
                        text: pluginApi?.tr("panel.section-governor")
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        font.weight: Font.Medium
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NIcon {
                            icon: {
                                let g = root.main?.governor ?? ""
                                if (g === "performance") return "gauge"
                                if (g === "powersave")   return "leaf"
                                return "cpu"
                            }
                            color: {
                                let g = root.main?.governor ?? ""
                                if (g === "performance") return Color.mTertiary
                                if (g === "powersave")   return Color.mPrimary
                                return Color.mOnSurface
                            }
                        }

                        NText {
                            text: root.main?.governor ?? "—"
                            pointSize: Style.fontSizeM
                            font.weight: Font.Bold
                            font.family: Settings.data?.ui?.fontFixed ?? "monospace"
                            color: Color.mOnSurface
                            Layout.fillWidth: true
                        }

                        NText {
                            visible: (root.main?.forceOverride ?? "default") !== "default"
                            text: pluginApi?.tr("panel.forced")
                            pointSize: Style.fontSizeXS
                            color: Color.mTertiary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NIcon {
                            icon: "bolt"
                            color: (root.main?.turboState ?? "") === "on"
                                ? Color.mTertiary : Color.mOnSurfaceVariant
                        }

                        NText {
                            text: pluginApi?.tr("panel.turbo") + ": " + (root.main?.turboState ?? "—")
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurface
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // ── pkexec error banner ───────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: errorRow.implicitHeight + Style.marginM * 2
                color: Qt.rgba(Color.mError.r, Color.mError.g, Color.mError.b, 0.15)
                radius: Style.radiusM
                visible: root.main?.pkexecFailed ?? false

                RowLayout {
                    id: errorRow
                    anchors { fill: parent; margins: Style.marginM }
                    spacing: Style.marginM

                    NIcon {
                        icon: "alert-triangle"
                        color: Color.mError
                        pointSize: Style.fontSizeM
                    }

                    NText {
                        text: pluginApi?.tr("panel.pkexec-error")
                        pointSize: Style.fontSizeXS
                        color: Color.mError
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // ── Force override — segmented control ────────────────────────────
            SegmentedControl {
                Layout.fillWidth: true
                enabled: root.main?.daemonRunning ?? false
                label: pluginApi?.tr("panel.section-force")
                segments: [
                    { icon: "leaf",  text: pluginApi?.tr("panel.powersave"),   active: (root.main?.forceOverride ?? "") === "powersave",  action: function() { root.main?.setForce("powersave") } },
                    { icon: "scale", text: pluginApi?.tr("panel.auto"),         active: (root.main?.forceOverride ?? "default") === "default", action: function() { root.main?.setForce("reset") } },
                    { icon: "gauge", text: pluginApi?.tr("panel.performance"),  active: (root.main?.forceOverride ?? "") === "performance", action: function() { root.main?.setForce("performance") } }
                ]
            }

            // ── Turbo boost — segmented control ───────────────────────────────
            SegmentedControl {
                Layout.fillWidth: true
                enabled: (root.main?.daemonRunning ?? false) && (root.main?.turboState ?? "n/a") !== "n/a"
                label: pluginApi?.tr("panel.section-turbo")
                segments: [
                    { icon: "bolt-off", text: pluginApi?.tr("panel.turbo-never"),  active: (root.main?.turboState ?? "") === "off", action: function() { root.main?.setTurbo("never") } },
                    { icon: "cpu",      text: pluginApi?.tr("panel.turbo-auto"),    active: false,                                   action: function() { root.main?.setTurbo("auto") } },
                    { icon: "bolt",     text: pluginApi?.tr("panel.turbo-always"),  active: (root.main?.turboState ?? "") === "on",  action: function() { root.main?.setTurbo("always") } }
                ]
            }
        }
    }

    component StatCell: ColumnLayout {
        property string icon: ""
        property string label: ""
        property string value: "—"
        property color  valueColor: Color.mOnSurface
        spacing: 2
        Layout.fillWidth: true
        NIcon {
            icon: parent.icon
            pointSize: Style.fontSizeM
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }
        NText {
            text: parent.value
            pointSize: Style.fontSizeM
            font.weight: Font.Bold
            color: parent.valueColor
            Layout.alignment: Qt.AlignHCenter
        }
        NText {
            text: parent.label
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }
    }

    component SegmentedControl: Item {
        property string    label:    ""
        property var       segments: []
        property bool      enabled:  true

        implicitHeight: segCol.implicitHeight

        ColumnLayout {
            id: segCol
            anchors { left: parent.left; right: parent.right }
            spacing: Style.marginS

            NText {
                text: parent.label
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                font.weight: Font.Medium
            }

            // Single pill container with dividers
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40 * Style.uiScaleRatio
                color: Color.mSurface
                radius: Style.radiusM
                border.color: Color.mOutline
                border.width: 1
                opacity: parent.parent.enabled ? 1.0 : 0.4
                clip: true

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: parent.parent.parent.parent.segments

                        delegate: Item {
                            width: parent.width / parent.parent.parent.parent.parent.segments.length
                            height: parent.height

                            // Active background pill
                            Rectangle {
                                anchors { fill: parent; margins: 3 }
                                radius: Style.radiusS
                                color: modelData.active ? Color.mPrimary : "transparent"
                            }

                            // Divider (not on last item)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                height: parent.height * 0.5
                                color: Color.mOutline
                                visible: index < parent.parent.parent.parent.parent.segments.length - 1
                                opacity: 0.5
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1

                                NIcon {
                                    icon: modelData.icon
                                    pointSize: Style.fontSizeS
                                    color: modelData.active ? Color.mOnPrimary : Color.mOnSurfaceVariant
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                NText {
                                    text: modelData.text
                                    pointSize: Style.fontSizeXS - 1
                                    color: modelData.active ? Color.mOnPrimary : Color.mOnSurfaceVariant
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: parent.parent.parent.parent.parent.enabled
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: modelData.action()
                            }
                        }
                    }
                }
            }
        }
    }
}
