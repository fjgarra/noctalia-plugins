import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    width: parent ? parent.width : implicitWidth
    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property bool editShowText: cfg.showText ?? defaults.showText ?? true
    property string editIconMode: cfg.iconMode ?? defaults.iconMode ?? "generic"
    property var editLabels: JSON.parse(JSON.stringify(cfg.customLabels ?? defaults.customLabels ?? ({})))

    // [{index, name, active}] populated by niri msg keyboard-layouts
    property var layoutList: []

    spacing: Style.marginM

    Process {
        id: layoutsProcess
        command: ["niri", "msg", "keyboard-layouts"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parsed = [];
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var m = lines[i].match(/^\s*(\*)?\s*(\d+)\s+(.+)$/);
                    if (m) parsed.push({ index: parseInt(m[2]), name: m[3].trim(), active: m[1] === "*" });
                }
                root.layoutList = parsed;
            }
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.showText.label")
        description: pluginApi?.tr("settings.showText.desc")
        checked: root.editShowText
        onToggled: checked => { root.editShowText = checked; }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.useFlag.label")
        description: pluginApi?.tr("settings.useFlag.desc")
        checked: root.editIconMode === "flag"
        onToggled: checked => { root.editIconMode = checked ? "flag" : "generic"; }
    }

    NText {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        text: pluginApi?.tr("settings.labels.title")
        color: Color.mOnSurface
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
    }

    NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.labels.desc")
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: root.layoutList
        delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: Style.marginXS

            NText {
                Layout.fillWidth: true
                text: (modelData.active ? "▶ " : "   ") + modelData.name
                color: modelData.active ? Color.mPrimary : Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                elide: Text.ElideRight
            }

            NTextInput {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.baseWidgetSize
                placeholderText: pluginApi?.tr("settings.labels.placeholder")
                text: root.editLabels[modelData.name] ?? ""
                onTextChanged: {
                    var copy = Object.assign({}, root.editLabels);
                    if (text.length > 0) copy[modelData.name] = text;
                    else delete copy[modelData.name];
                    root.editLabels = copy;
                }
            }
        }
    }

    // Bottom breathing room so the last NTextInput's border isn't clipped by NScrollView
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.marginM
    }

    function saveSettings() {
        if (!pluginApi) return;
        pluginApi.pluginSettings.showText = root.editShowText;
        pluginApi.pluginSettings.iconMode = root.editIconMode;
        pluginApi.pluginSettings.customLabels = root.editLabels;
        pluginApi.saveSettings();
    }
}
