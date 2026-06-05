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
    property real contentPreferredHeight: implicitPanelHeight * Style.uiScaleRatio
    readonly property real implicitPanelHeight: mainCol.implicitHeight + Style.marginL * 4

    readonly property bool allowAttach: true

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: mainCol
            anchors {
                fill: parent
                margins: Style.marginL
            }
            spacing: Style.marginM

            // ── Header: daemon status ─────────────────────────────────────────
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
                            text: pluginApi?.tr("panel.title")
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

                    // Refresh button
                    NIconButton {
                        icon: "refresh"
                        onClicked: root.main?.refreshAll()
                    }
                }
            }

            // ── CPU stats row ─────────────────────────────────────────────────
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
                        icon: "speed"
                        label: pluginApi?.tr("panel.cpu-freq")
                        value: root.main?.cpuFreqMhz > 0
                            ? Math.round(root.main.cpuFreqMhz) + " MHz"
                            : "—"
                    }

                    StatCell {
                        icon: "thermometer"
                        label: pluginApi?.tr("panel.cpu-temp")
                        value: root.main?.cpuTemp || "—"
                        valueColor: {
                            let t = parseInt(root.main?.cpuTemp ?? "0")
                            if (t >= 90) return Color.mError
                            if (t >= 75) return Color.mTertiary
                            return Color.mOnSurface
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

                    // Turbo row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NIcon {
                            icon: "bolt"
                            color: {
                                let t = root.main?.turboState ?? "unknown"
                                if (t === "on")  return Color.mTertiary
                                if (t === "off") return Color.mOnSurfaceVariant
                                return Color.mOnSurfaceVariant
                            }
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

            // ── Force override buttons ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: forceCol.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant
                radius: Style.radiusM

                ColumnLayout {
                    id: forceCol
                    anchors { fill: parent; margins: Style.marginM }
                    spacing: Style.marginS

                    NText {
                        text: pluginApi?.tr("panel.section-force")
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        font.weight: Font.Medium
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        ForceButton {
                            icon: "leaf"
                            label: pluginApi?.tr("panel.powersave")
                            active: (root.main?.forceOverride ?? "") === "powersave"
                            enabled: root.main?.daemonRunning ?? false
                            Layout.fillWidth: true
                            onClicked: root.main?.setForce("powersave")
                        }

                        ForceButton {
                            icon: "scale"
                            label: pluginApi?.tr("panel.auto")
                            active: (root.main?.forceOverride ?? "default") === "default"
                            enabled: root.main?.daemonRunning ?? false
                            Layout.fillWidth: true
                            onClicked: root.main?.setForce("reset")
                        }

                        ForceButton {
                            icon: "gauge"
                            label: pluginApi?.tr("panel.performance")
                            active: (root.main?.forceOverride ?? "") === "performance"
                            enabled: root.main?.daemonRunning ?? false
                            Layout.fillWidth: true
                            onClicked: root.main?.setForce("performance")
                        }
                    }
                }
            }

            // ── Turbo override buttons ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: turboCol.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant
                radius: Style.radiusM

                ColumnLayout {
                    id: turboCol
                    anchors { fill: parent; margins: Style.marginM }
                    spacing: Style.marginS

                    NText {
                        text: pluginApi?.tr("panel.section-turbo")
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        font.weight: Font.Medium
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        ForceButton {
                            icon: "bolt-off"
                            label: pluginApi?.tr("panel.turbo-never")
                            active: (root.main?.turboState ?? "") === "off"
                            enabled: (root.main?.daemonRunning ?? false) && (root.main?.turboState ?? "unknown") !== "n/a"
                            Layout.fillWidth: true
                            onClicked: root.main?.setTurbo("never")
                        }

                        ForceButton {
                            icon: "cpu"
                            label: pluginApi?.tr("panel.turbo-auto")
                            active: false
                            enabled: (root.main?.daemonRunning ?? false) && (root.main?.turboState ?? "unknown") !== "n/a"
                            Layout.fillWidth: true
                            onClicked: root.main?.setTurbo("auto")
                        }

                        ForceButton {
                            icon: "bolt"
                            label: pluginApi?.tr("panel.turbo-always")
                            active: (root.main?.turboState ?? "") === "on"
                            enabled: (root.main?.daemonRunning ?? false) && (root.main?.turboState ?? "unknown") !== "n/a"
                            Layout.fillWidth: true
                            onClicked: root.main?.setTurbo("always")
                        }
                    }
                }
            }
        }
    }

    // ── Reusable inline components ────────────────────────────────────────────

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

    component ForceButton: MouseArea {
        property string icon: ""
        property string label: ""
        property bool   active: false

        implicitHeight: 48 * Style.uiScaleRatio
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: Style.radiusS
            color: parent.active
                ? Color.mPrimary
                : (parent.containsMouse ? Color.mSurfaceContainerHigh : Color.mSurface)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            NIcon {
                icon: parent.icon
                pointSize: Style.fontSizeM
                color: parent.active ? Color.mOnPrimary : Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }
            NText {
                text: parent.label
                pointSize: Style.fontSizeXS
                color: parent.active ? Color.mOnPrimary : Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
