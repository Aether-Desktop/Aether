import QtQuick

Text {
    id: root

    property int size: 14
    property color tone: Theme.onSurface
    property int weight: Font.Normal
    property bool secondary: false

    color: root.secondary ? Theme.onSurfaceVariant : root.tone
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fs(root.size)
    font.weight: root.weight
    font.hintingPreference: Font.PreferFullHinting
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
