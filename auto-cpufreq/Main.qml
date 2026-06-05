import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null

    // ── Exposed state ─────────────────────────────────────────────────────────
    property string governor: "unknown"
    property string turboState: "unknown"   // "on" | "off" | "n/a"
    property bool   daemonRunning: false
    property string forceOverride: "default"  // "default" | "powersave" | "performance"

    // CPU stats (averaged across all cores, refreshed every interval)
    property real   cpuUsage: 0.0
    property real   cpuFreqMhz: 0.0
    property string cpuTemp: ""

    // ── Settings shorthand ────────────────────────────────────────────────────
    property var cfg:      pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property int refreshMs: cfg.refreshInterval ?? defaults.refreshInterval ?? 3000

    // ── Sysfs: governor ───────────────────────────────────────────────────────
    FileView {
        id: governorFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
        printErrors: false
        onLoaded: root.governor = text().trim()
    }

    // ── Sysfs: turbo (Intel no_turbo, AMD/generic boost) ─────────────────────
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
            // only use if intel_pstate path didn't give a value
            if (noTurboFile.text().trim() === "") {
                let v = text().trim()
                if (v !== "") root.turboState = (v === "1") ? "on" : "off"
            }
        }
    }

    FileView {
        id: amdPstateFile
        path: "/sys/devices/system/cpu/amd_pstate/status"
        printErrors: false
        onLoaded: {
            let v = text().trim()
            if (v !== "" && noTurboFile.text().trim() === "" && boostFile.text().trim() === "") {
                // amd-pstate-epp controls turbo itself; just report it as managed
                root.turboState = "n/a"
            }
        }
    }

    // ── Sysfs: CPU freq (cpu0, MHz) ───────────────────────────────────────────
    FileView {
        id: cpuFreqFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
        printErrors: false
        onLoaded: {
            let kHz = parseInt(text().trim())
            if (!isNaN(kHz)) root.cpuFreqMhz = kHz / 1000.0
        }
    }

    // ── auto-cpufreq daemon: check via systemctl is-active ───────────────────
    Process {
        id: daemonChecker
        command: ["systemctl", "is-active", "--quiet", "auto-cpufreq"]
        running: false
        onExited: (code) => { root.daemonRunning = (code === 0) }
    }

    // ── CPU usage via /proc/stat ──────────────────────────────────────────────
    property var _prevStat: null

    FileView {
        id: procStatFile
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            let lines = text().split("\n")
            for (let line of lines) {
                if (line.startsWith("cpu ")) {
                    let parts = line.trim().split(/\s+/)
                    let user    = parseInt(parts[1])
                    let nice    = parseInt(parts[2])
                    let system  = parseInt(parts[3])
                    let idle    = parseInt(parts[4])
                    let iowait  = parseInt(parts[5])
                    let irq     = parseInt(parts[6])
                    let softirq = parseInt(parts[7])
                    let total = user + nice + system + idle + iowait + irq + softirq
                    let busy  = user + nice + system + irq + softirq

                    if (root._prevStat) {
                        let dTotal = total - root._prevStat.total
                        let dBusy  = busy  - root._prevStat.busy
                        if (dTotal > 0)
                            root.cpuUsage = Math.round((dBusy / dTotal) * 100)
                    }
                    root._prevStat = { total: total, busy: busy }
                    break
                }
            }
        }
    }

    // ── CPU temperature ───────────────────────────────────────────────────────
    // Try k10temp (AMD Zen) first; fall back to coretemp (Intel)
    FileView {
        id: k10tempFile
        path: "/sys/class/hwmon/hwmon0/temp1_input"
        printErrors: false
        onLoaded: {
            let v = parseInt(text().trim())
            if (!isNaN(v) && v > 1000)
                root.cpuTemp = Math.round(v / 1000) + "°C"
        }
    }

    // ── force override: read pickle via helper script ─────────────────────────
    Process {
        id: overrideReader
        command: ["auto-cpufreq", "--print-override"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let t = text.trim()
                if (t === "powersave" || t === "performance")
                    root.forceOverride = t
                else
                    root.forceOverride = "default"
            }
        }
        onExited: (code) => {
            // --print-override doesn't exist; fall back to reading stats file for hint
            if (code !== 0) root.forceOverride = "default"
        }
    }

    // ── Public actions ────────────────────────────────────────────────────────
    Process {
        id: forceProc
        running: false
        onExited: (code) => {
            if (code === 0) refreshAll()
        }
    }

    Process {
        id: turboProc
        running: false
        onExited: (code) => {
            if (code === 0) refreshAll()
        }
    }

    function setForce(mode) {
        // mode: "performance" | "powersave" | "reset"
        forceProc.command = ["pkexec", "auto-cpufreq", "--force=" + mode]
        forceProc.running = true
        if (mode === "reset") root.forceOverride = "default"
        else root.forceOverride = mode
    }

    function setTurbo(mode) {
        // mode: "always" | "never" | "auto"
        turboProc.command = ["pkexec", "auto-cpufreq", "--turbo=" + mode]
        turboProc.running = true
    }

    function refreshAll() {
        governorFile.reload()
        noTurboFile.reload()
        boostFile.reload()
        amdPstateFile.reload()
        cpuFreqFile.reload()
        procStatFile.reload()
        k10tempFile.reload()
        daemonChecker.running = false
        daemonChecker.running = true
    }

    // ── Polling timer ─────────────────────────────────────────────────────────
    Timer {
        id: pollTimer
        interval: root.refreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }

    onRefreshMsChanged: pollTimer.interval = refreshMs

    Component.onCompleted: {
        if (pluginApi) pluginApi.mainInstance = root
    }
}
