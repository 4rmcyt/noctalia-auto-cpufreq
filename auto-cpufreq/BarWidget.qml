import QtQuick
import QtQuick.Layouts
import Quickshell
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

    readonly property var main: pluginApi?.mainInstance
    readonly property string screenName: screen?.name ?? ""
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize:   Style.getBarFontSizeForScreen(screenName)
    readonly property string fixedFont:   Settings.data?.ui?.fontFixed ?? "monospace"

    readonly property bool compact: cfg.compactMode ?? defaults.compactMode ?? false

    // Governor color hint
    readonly property color govColor: {
        let g = main?.governor ?? ""
        if (g === "performance")  return Color.mTertiary
        if (g === "powersave")    return Color.mPrimary
        return Color.mOnSurface
    }

    readonly property real contentWidth: compact
        ? capsuleHeight
        : (contentRow.implicitWidth + Style.marginM * 2)
    readonly property real contentHeight: capsuleHeight

    implicitWidth:  contentWidth
    implicitHeight: contentHeight

    // ── Capsule ───────────────────────────────────────────────────────────────
    Rectangle {
        id: capsule
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
                    text: main?.governor ?? "—"
                    pointSize: root.barFontSize
                    font.family: root.fixedFont
                    font.weight: Font.Bold
                    color: mouseArea.containsMouse ? Color.mOnHover : root.govColor
                }

                NText {
                    visible: (cfg.showTurbo ?? defaults.showTurbo ?? true) && (main?.turboState ?? "unknown") !== "unknown"
                    text: {
                        let t = main?.turboState ?? "unknown"
                        if (t === "n/a") return "turbo: managed"
                        return "turbo: " + t
                    }
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
            {
                "label": pluginApi?.tr("menu.force-performance"),
                "action": "force-performance",
                "icon": "gauge",
                "enabled": main?.daemonRunning ?? false
            },
            {
                "label": pluginApi?.tr("menu.force-powersave"),
                "action": "force-powersave",
                "icon": "leaf",
                "enabled": main?.daemonRunning ?? false
            },
            {
                "label": pluginApi?.tr("menu.force-reset"),
                "action": "force-reset",
                "icon": "refresh",
                "enabled": (main?.forceOverride ?? "default") !== "default"
            },
            {
                "label": pluginApi?.tr("menu.turbo-on"),
                "action": "turbo-on",
                "icon": "bolt",
                "enabled": main?.daemonRunning ?? false
            },
            {
                "label": pluginApi?.tr("menu.turbo-off"),
                "action": "turbo-off",
                "icon": "bolt-off",
                "enabled": main?.daemonRunning ?? false
            },
            {
                "label": pluginApi?.tr("menu.turbo-auto"),
                "action": "turbo-auto",
                "icon": "cpu",
                "enabled": main?.daemonRunning ?? false
            },
            {
                "label": pluginApi?.tr("actions.widget-settings"),
                "action": "widget-settings",
                "icon": "settings"
            }
        ]
        onTriggered: action => {
            contextMenu.close()
            PanelService.closeContextMenu(screen)

            if (action === "widget-settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest)
            } else if (action === "force-performance") {
                main?.setForce("performance")
            } else if (action === "force-powersave") {
                main?.setForce("powersave")
            } else if (action === "force-reset") {
                main?.setForce("reset")
            } else if (action === "turbo-on") {
                main?.setTurbo("always")
            } else if (action === "turbo-off") {
                main?.setTurbo("never")
            } else if (action === "turbo-auto") {
                main?.setTurbo("auto")
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (pluginApi) pluginApi.togglePanel(root.screen, root)
            } else if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen)
            }
        }
    }
}
