import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.Compositor
import qs.Services.Keyboard
import qs.Services.UI
import qs.Widgets

// Bar widget that displays the active keyboard layout code.
// Replaces the native KeyboardLayout widget to fix the bug where
// us/intl and us/altgr-intl both render as "Intl" (the native
// variantMap checks "intl" before "altgr-intl" via str.includes()).
Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"

    // Custom extraction: check altgr BEFORE intl so
    // "English (intl., with AltGr dead keys)" → "AltGr", not "Intl".
    function extractCode(fullName) {
        const s = fullName.toLowerCase();
        if (s.includes("altgr"))                             return "AltGr";
        if (s.includes("intl"))                              return "Intl";
        if (s.includes("spanish") || s.includes("español")) return "ES";
        const m = s.match(/\(([a-z]{2,3})\)/i);
        if (m) return m[1].toUpperCase();
        const w = s.match(/^([a-z]{2,3})/);
        return w ? w[1].toUpperCase() : fullName.substring(0, 3).toUpperCase();
    }

    readonly property string layoutCode: extractCode(KeyboardLayoutService.fullLayoutName)

    implicitWidth: pill.width
    implicitHeight: pill.height

    NPopupContextMenu {
        id: contextMenu
        model: [
            { "label": pluginApi?.tr("menu.settings"), "action": "settings", "icon": "settings" }
        ]
        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);
            if (action === "settings") {
                BarService.openPluginSettings(screen, pluginApi?.manifest);
            }
        }
    }

    BarPill {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        screen: root.screen
        oppositeDirection: BarService.getPillDirection(root)
        icon: "keyboard"
        text: isBarVertical ? layoutCode.substring(0, 3) : layoutCode
        tooltipText: KeyboardLayoutService.fullLayoutName
        forceOpen: true
        autoHide: false
        onClicked: CompositorService.cycleKeyboardLayout()
        onRightClicked: PanelService.showContextMenu(contextMenu, pill, screen)
    }
}
