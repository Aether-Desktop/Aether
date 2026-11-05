import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../Aether"

// One notification, used both as a transient popup and inside the notification centre.
Item {
    id: root

    property var notification: null
    property bool popup: false
    property int popupKey: -1

    implicitHeight: card.implicitHeight

    function close() {
        if (root.popupKey >= 0) Notify.removePopup(root.popupKey);
        if (root.notification) root.notification.dismiss();
    }

    function invoke(action) {
        if (!action) return;
        if (root.popupKey >= 0) Notify.removePopup(root.popupKey);
        action.invoke();
    }

    readonly property bool critical: root.notification
        && root.notification.urgency === NotificationUrgency.Critical
    readonly property string imageSource: {
        if (!root.notification) return "";
        const i = root.notification.image || "";
        if (!i) return "";
        if (i.indexOf("file://") === 0 || i.indexOf("http") === 0) return i;
        return i.indexOf("/") === 0 ? "file://" + i : i;
    }

    Timer {
        running: root.popup && root.notification !== null && !root.critical
        interval: {
            if (!root.notification) return 6000;
            const t = Number(root.notification.expireTimeout);
            return t > 0 ? Math.max(2000, Math.round(t * 1000)) : Math.max(2000, Config.notifications.timeout || 6000);
        }
        onTriggered: {
            if (root.popupKey >= 0) Notify.removePopup(root.popupKey);
            if (root.notification) root.notification.expire();
        }
    }

    Connections {
        target: root.notification
        ignoreUnknownSignals: true
        function onClosed(reason) {
            if (root.popupKey >= 0) Notify.removePopup(root.popupKey);
        }
        function onTrackedChanged() {
            if (root.notification && !root.notification.tracked && root.popupKey >= 0)
                Notify.removePopup(root.popupKey);
        }
    }

    Surface {
        id: card
        width: root.width
        implicitHeight: content.implicitHeight + 24
        fill: Theme.glassHigh
        radius: Theme.radiusMd
        padding: 12
        shadow: root.popup
        shadowStrength: 0.25

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                AppIcon {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    iconName: root.notification ? (root.notification.appIcon || "") : ""
                    label: root.notification ? (root.notification.appName || "A") : "A"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: root.notification ? (root.notification.appName || "Notification") : "Notification"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.notification ? (root.notification.summary || "") : ""
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(12.5)
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                IconButton {
                    icon: "close"
                    iconSize: 12
                    buttonSize: 26
                    accessibleName: "Dismiss notification"
                    onClicked: root.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                visible: Config.notifications.showImage !== false
                    && root.imageSource.length > 0
                radius: Theme.radiusSm
                color: Theme.surfaceContainerHighest
                clip: true
                Image {
                    anchors.fill: parent
                    source: root.imageSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0 && Config.notifications.showBody !== false
                text: root.notification ? (root.notification.body || "") : ""
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(11)
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                maximumLineCount: root.popup ? 5 : 8
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: actionsRepeater.count > 0

                Repeater {
                    id: actionsRepeater
                    model: root.notification && root.notification.actions ? root.notification.actions : []
                    delegate: Button {
                        required property var modelData
                        label: modelData.text || "Open"
                        primary: false
                        implicitHeight: 28
                        onClicked: root.invoke(modelData)
                    }
                }
            }
        }
    }
}
