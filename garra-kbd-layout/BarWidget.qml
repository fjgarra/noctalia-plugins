import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.Compositor
import qs.Services.Keyboard
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"

    readonly property bool showText: cfg.showText ?? defaults.showText ?? true
    readonly property string iconMode: cfg.iconMode ?? defaults.iconMode ?? "generic"
    readonly property var customLabels: cfg.customLabels ?? defaults.customLabels ?? ({})

    // Check altgr BEFORE intl: "English (intl., with AltGr dead keys)" → "AltGr", not "Intl".
    function extractCode(fullName) {
        const s = fullName.toLowerCase();
        if (s.includes("altgr"))                             return "AltGr";
        if (s.includes("dead keys"))                         return "Dead";
        if (s.includes("intl"))                              return "Intl";
        if (s.includes("spanish") || s.includes("español")) return "ES";
        const m = s.match(/\(([a-z]{2,3})\)/i);
        if (m) return m[1].toUpperCase();
        const w = s.match(/^([a-z]{2,3})/);
        return w ? w[1].toUpperCase() : fullName.substring(0, 3).toUpperCase();
    }

    // ISO country code → flag emoji via regional indicator letters
    function isoToFlag(iso) {
        if (!iso || iso.length !== 2) return "🌐";
        const base = 0x1F1E6 - 65;
        const c = iso.toUpperCase();
        return String.fromCodePoint(base + c.charCodeAt(0)) +
               String.fromCodePoint(base + c.charCodeAt(1));
    }

    function flagEmoji(fullName) {
        const s = fullName.toLowerCase();
        if (s.includes("spanish") || s.includes("español")) return isoToFlag("es");
        if (s.includes("german")  || s.includes("deutsch")) return isoToFlag("de");
        if (s.includes("french")  || s.includes("français"))return isoToFlag("fr");
        if (s.includes("portuguese"))                        return isoToFlag("pt");
        if (s.includes("italian") || s.includes("italiano"))return isoToFlag("it");
        if (s.includes("russian") || s.includes("русский")) return isoToFlag("ru");
        if (s.includes("japanese")|| s.includes("日本語"))  return isoToFlag("jp");
        if (s.includes("chinese") || s.includes("中文"))    return isoToFlag("cn");
        if (s.includes("british") || s.includes("united kingdom")) return isoToFlag("gb");
        return isoToFlag("us");
    }

    readonly property string layoutCode: extractCode(KeyboardLayoutService.fullLayoutName)
    readonly property string currentFlag: flagEmoji(KeyboardLayoutService.fullLayoutName)
    readonly property string displayText: customLabels[KeyboardLayoutService.fullLayoutName] || layoutCode
    readonly property string visibleText: isBarVertical ? displayText.substring(0, 3) : displayText

    implicitWidth: barLoader.item ? barLoader.item.implicitWidth : 0
    implicitHeight: barLoader.item ? barLoader.item.implicitHeight : 0

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

    Loader {
        id: barLoader
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: iconMode === "flag" ? flagPillComponent : standardPillComponent
    }

    // Generic mode: native BarPill with the "keyboard" icon
    Component {
        id: standardPillComponent
        BarPill {
            screen: root.screen
            oppositeDirection: BarService.getPillDirection(root)
            icon: "keyboard"
            text: root.showText ? root.visibleText : ""
            tooltipText: KeyboardLayoutService.fullLayoutName
            forceOpen: true
            autoHide: false
            onClicked: CompositorService.cycleKeyboardLayout()
            onRightClicked: PanelService.showContextMenu(contextMenu, this, root.screen)
        }
    }

    // Flag mode: custom capsule with a larger emoji and the label at normal size
    Component {
        id: flagPillComponent
        Item {
            id: flagPill

            readonly property real pillHeight: Style.getCapsuleHeightForScreen(root.screenName)
            readonly property real labelSize: Style.getBarFontSizeForScreen(root.screenName)
            readonly property real flagSize: Math.max(labelSize * 1.6, pillHeight * 0.55)
            readonly property bool isHovered: mouseArea.containsMouse

            implicitWidth: bg.width
            implicitHeight: pillHeight

            Rectangle {
                id: bg
                anchors.verticalCenter: parent.verticalCenter
                height: pillHeight
                width: row.width + Style.marginM * 2
                radius: Style.radiusM
                color: flagPill.isHovered ? Color.mHover : Style.capsuleColor
                border.color: Style.capsuleBorderColor
                border.width: Style.capsuleBorderWidth

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: root.showText && root.visibleText.length > 0 ? Style.marginXS : 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentFlag
                        font.pointSize: flagPill.flagSize
                        font.family: Settings.data.ui.fontDefault
                        color: flagPill.isHovered ? Color.mOnHover : Color.mOnSurface
                    }

                    NText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.visibleText
                        visible: root.showText && text.length > 0
                        pointSize: flagPill.labelSize
                        applyUiScale: false
                        family: Settings.data.ui.fontFixed
                        color: flagPill.isHovered ? Color.mOnHover : Color.mOnSurface
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: bg
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onEntered: TooltipService.show(flagPill, KeyboardLayoutService.fullLayoutName,
                                               BarService.getTooltipDirection(root.screenName),
                                               Style.tooltipDelay)
                onExited: TooltipService.hide()
                onClicked: mouse => {
                    TooltipService.hide();
                    if (mouse.button === Qt.LeftButton)
                        CompositorService.cycleKeyboardLayout();
                    else if (mouse.button === Qt.RightButton)
                        PanelService.showContextMenu(contextMenu, flagPill, root.screen);
                }
            }
        }
    }
}
