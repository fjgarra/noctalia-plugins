#!/usr/bin/env bash
# new-plugin.sh — scaffold a new noctalia plugin in this repo.
# Usage: ./new-plugin.sh <plugin-id> "<Plugin Name>"
# Example: ./new-plugin.sh my-widget "My Widget"
set -euo pipefail

PLUGIN_ID="${1:-}"
PLUGIN_NAME="${2:-}"

if [[ -z "$PLUGIN_ID" || -z "$PLUGIN_NAME" ]]; then
  echo "Usage: $0 <plugin-id> \"<Plugin Name>\"" >&2
  exit 1
fi

if [[ -d "$PLUGIN_ID" ]]; then
  echo "ERROR: directory '$PLUGIN_ID' already exists" >&2
  exit 1
fi

mkdir -p "$PLUGIN_ID/i18n"

cat > "$PLUGIN_ID/manifest.json" << EOF
{
    "id": "${PLUGIN_ID}",
    "name": "${PLUGIN_NAME}",
    "version": "1.0.0",
    "minNoctaliaVersion": "4.7.0",
    "author": "garra",
    "license": "MIT",
    "description": "TODO: describe what this plugin does.",
    "tags": ["Bar"],
    "entryPoints": {
        "barWidget": "BarWidget.qml"
    },
    "dependencies": {
        "plugins": []
    },
    "metadata": {
        "defaultSettings": {}
    }
}
EOF

cat > "$PLUGIN_ID/BarWidget.qml" << 'EOF'
import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
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
        icon: "star"           // TODO: cambia el icono
        text: "TODO"           // TODO: texto dinámico
        tooltipText: pluginApi?.tr("widget.tooltip")
        forceOpen: true
        autoHide: false
        onClicked: Logger.i("Plugin", "clicked")
        onRightClicked: PanelService.showContextMenu(contextMenu, pill, screen)
    }
}
EOF

cat > "$PLUGIN_ID/i18n/en.json" << 'EOF'
{
    "widget": {
        "tooltip": "TODO: tooltip text"
    },
    "menu": {
        "settings": "Widget settings"
    }
}
EOF

echo "Created: $PLUGIN_ID/"
echo "  manifest.json  — ajusta description y tags"
echo "  BarWidget.qml  — reemplaza icon, text y lógica"
echo "  i18n/en.json   — ajusta tooltip"
echo ""
echo "Siguiente paso:"
echo "  bash .claude/skills/run-noctalia-plugins/driver.sh ${PLUGIN_ID}"
