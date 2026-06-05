import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen: null
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property var cfg:      pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    // ── State ─────────────────────────────────────────────────────────────────
    property string governor:      "—"
    property string turboState:    "—"
    property bool   daemonRunning: false
    property string forceOverride: "default"
    property real   cpuUsage:      0.0
    property real   cpuFreqMhz:    0.0
    property string cpuTemp:       "—"
    property var    _prevStat:     null

    readonly property string screenName:    screen?.name ?? ""
    readonly property real   capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real   barFontSize:   Style.getBarFontSizeForScreen(screenName)
    readonly property string fixedFont:     Settings.data?.ui?.fontFixed ?? "monospace"
    readonly property bool   compact:       cfg.compactMode ?? defaults.compactMode ?? false

    readonly property color govColor: {
        if (governor === "performance") return Color.mTertiary
        if (governor === "powersave")   return Color.mPrimary
        return Color.mOnSurface
    }

    readonly property real contentWidth: compact
        ? capsuleHeight
        : (contentRow.implicitWidth + Style.marginM * 2)
    readonly property real contentHeight: capsuleHeight

    implicitWidth:  contentWidth
    implicitHeight: contentHeight

    Component.onCompleted: {
        if (pluginApi) pluginApi.mainInstance = root
    }

    // ── Sysfs readers ─────────────────────────────────────────────────────────
    FileView {
        id: governorFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
        printErrors: false
        onLoaded: root.governor = text().trim() || "—"
    }

    FileView {
        id: noTurboFile
        path: "/sys/devices/system/cpu/intel_pstate/no_turbo"
        printErrors: false
        onLoaded: {
            let v = text().trim()
            if (v !== "") root.turboState = (v === "0") ? "on" : "off"
        }
    }

    FileView {
        id: boostFile
        path: "/sys/devices/system/cpu/cpufreq/boost"
        printErrors: false
        onLoaded: {
            if (noTurboFile.text().trim() !== "") return
            let v = text().trim()
            if (v !== "") root.turboState = (v === "1") ? "on" : "off"
        }
    }

    FileView {
        id: cpuFreqFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
        printErrors: false
        onLoaded: {
            let kHz = parseInt(text().trim())
            if (!isNaN(kHz)) root.cpuFreqMhz = kHz / 1000.0
        }
    }

    FileView {
        id: procStatFile
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            let lines = text().split("\n")
            for (let line of lines) {
                if (!line.startsWith("cpu ")) continue
                let p = line.trim().split(/\s+/)
                let user = parseInt(p[1]), nice = parseInt(p[2]),
                    sys  = parseInt(p[3]), idle = parseInt(p[4]),
                    iow  = parseInt(p[5]), irq  = parseInt(p[6]),
                    sirq = parseInt(p[7])
                let total = user+nice+sys+idle+iow+irq+sirq
                let busy  = user+nice+sys+irq+sirq
                if (root._prevStat) {
                    let dt = total - root._prevStat.total
                    let db = busy  - root._prevStat.busy
                    if (dt > 0) root.cpuUsage = Math.round((db/dt)*100)
                }
                root._prevStat = {total: total, busy: busy}
                break
            }
        }
    }

    // k10temp (AMD) or coretemp (Intel) — find dynamically
    Process {
        id: tempReader
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*/name; do n=$(cat $d 2>/dev/null); if [ \"$n\" = \"k10temp\" ] || [ \"$n\" = \"coretemp\" ]; then dir=$(dirname $d); t=$(cat $dir/temp1_input 2>/dev/null); if [ -n \"$t\" ]; then echo $t; exit 0; fi; fi; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(text.trim())
                if (!isNaN(v) && v > 1000) root.cpuTemp = Math.round(v/1000) + "°C"
            }
        }
    }

    // ── Daemon check ──────────────────────────────────────────────────────────
    Process {
        id: daemonChecker
        command: ["systemctl", "is-active", "--quiet", "auto-cpufreq"]
        running: false
        onExited: (code) => { root.daemonRunning = (code === 0) }
    }

    // ── Actions ───────────────────────────────────────────────────────────────
    property bool pkexecFailed: false

    Process {
        id: forceProc
        running: false
        onExited: (code) => {
            if (code === 0) {
                root.pkexecFailed = false
                root.refreshAll()
            } else if (code === 127 || code === 126) {
                root.pkexecFailed = true
            }
        }
    }

    Process {
        id: turboProc
        running: false
        onExited: (code) => {
            if (code === 0) {
                root.pkexecFailed = false
                root.refreshAll()
            } else if (code === 127 || code === 126) {
                root.pkexecFailed = true
            }
        }
    }

    function setForce(mode) {
        root.pkexecFailed = false
        forceProc.command = ["pkexec", "auto-cpufreq", "--force=" + mode]
        forceProc.running = false
        forceProc.running = true
        root.forceOverride = (mode === "reset") ? "default" : mode
    }

    function setTurbo(mode) {
        root.pkexecFailed = false
        turboProc.command = ["pkexec", "auto-cpufreq", "--turbo=" + mode]
        turboProc.running = false
        turboProc.running = true
    }

    function refreshAll() {
        governorFile.reload()
        noTurboFile.reload()
        boostFile.reload()
        cpuFreqFile.reload()
        procStatFile.reload()
        tempReader.running = false
        tempReader.running = true
        daemonChecker.running = false
        daemonChecker.running = true
    }

    // ── Poll timer ────────────────────────────────────────────────────────────
    Timer {
        interval: root.cfg.refreshInterval ?? root.defaults.refreshInterval ?? 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }

    // ── Bar capsule ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width:  root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        color:  mouseArea.containsMouse ? Color.mHover : Style.capsuleColor

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: "cpu"
                color: mouseArea.containsMouse ? Color.mOnHover : root.govColor
                pointSize: Style.fontSizeM
                applyUiScale: false
            }

            ColumnLayout {
                visible: !root.compact
                spacing: 1
                Layout.rightMargin: Style.marginS

                NText {
                    text: root.governor
                    pointSize: root.barFontSize
                    font.family: root.fixedFont
                    font.weight: Font.Bold
                    color: mouseArea.containsMouse ? Color.mOnHover : root.govColor
                }

                NText {
                    visible: root.turboState !== "—"
                    text: "turbo: " + root.turboState
                    pointSize: root.barFontSize * 0.85
                    color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurfaceVariant
                }
            }
        }
    }

    // ── Context menu ──────────────────────────────────────────────────────────
    NPopupContextMenu {
        id: contextMenu
        model: [
            { "label": pluginApi?.tr("menu.force-performance"),  "action": "force-performance", "icon": "gauge",    "enabled": root.daemonRunning },
            { "label": pluginApi?.tr("menu.force-powersave"),    "action": "force-powersave",   "icon": "leaf",     "enabled": root.daemonRunning },
            { "label": pluginApi?.tr("menu.force-reset"),        "action": "force-reset",        "icon": "refresh",  "enabled": root.forceOverride !== "default" },
            { "label": pluginApi?.tr("menu.turbo-on"),           "action": "turbo-on",           "icon": "bolt",     "enabled": root.daemonRunning },
            { "label": pluginApi?.tr("menu.turbo-off"),          "action": "turbo-off",          "icon": "bolt",     "enabled": root.daemonRunning },
            { "label": pluginApi?.tr("menu.turbo-auto"),         "action": "turbo-auto",         "icon": "cpu",      "enabled": root.daemonRunning },
            { "label": pluginApi?.tr("actions.widget-settings"), "action": "widget-settings",    "icon": "settings" }
        ]
        onTriggered: action => {
            contextMenu.close()
            PanelService.closeContextMenu(screen)
            if      (action === "widget-settings")   BarService.openPluginSettings(screen, pluginApi.manifest)
            else if (action === "force-performance") root.setForce("performance")
            else if (action === "force-powersave")   root.setForce("powersave")
            else if (action === "force-reset")       root.setForce("reset")
            else if (action === "turbo-on")          root.setTurbo("always")
            else if (action === "turbo-off")         root.setTurbo("never")
            else if (action === "turbo-auto")        root.setTurbo("auto")
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                pluginApi?.togglePanel(root.screen, root)
            else
                PanelService.showContextMenu(contextMenu, root, screen)
        }
    }
}
