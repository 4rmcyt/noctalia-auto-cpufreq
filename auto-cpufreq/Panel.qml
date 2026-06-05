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

            // ── Force override ────────────────────────────────────────────────
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

            // ── Turbo boost ───────────────────────────────────────────────────
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

                        property bool turboAvailable: (root.main?.turboState ?? "n/a") !== "n/a"

                        ForceButton {
                            icon: "bolt-off"
                            label: pluginApi?.tr("panel.turbo-never")
                            active: (root.main?.turboState ?? "") === "off"
                            enabled: (root.main?.daemonRunning ?? false) && parent.turboAvailable
                            Layout.fillWidth: true
                            onClicked: root.main?.setTurbo("never")
                        }
                        ForceButton {
                            icon: "cpu"
                            label: pluginApi?.tr("panel.turbo-auto")
                            active: false
                            enabled: (root.main?.daemonRunning ?? false) && parent.turboAvailable
                            Layout.fillWidth: true
                            onClicked: root.main?.setTurbo("auto")
                        }
                        ForceButton {
                            icon: "bolt"
                            label: pluginApi?.tr("panel.turbo-always")
                            active: (root.main?.turboState ?? "") === "on"
                            enabled: (root.main?.daemonRunning ?? false) && parent.turboAvailable
                            Layout.fillWidth: true
                            onClicked: root.main?.setTurbo("always")
                        }
                    }
                }
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
            color: parent.active ? Color.mPrimary : Color.mSurface
            border.color: parent.active ? "transparent" : Color.mOutline
            border.width: parent.active ? 0 : 1
            opacity: parent.enabled ? 1.0 : 0.35
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
