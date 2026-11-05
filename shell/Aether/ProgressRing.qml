import QtQuick

// Circular progress indicator drawn on Canvas (antialiased, no shader cost).
Item {
    id: root

    property real value: 0
    property real lineWidth: 5
    property color color: Theme.primary
    property color trackColor: Theme.surfaceContainerHighest

    implicitWidth: 40
    implicitHeight: 40

    onValueChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Threaded
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const lw = root.lineWidth;
            const r = Math.min(width, height) / 2 - lw;
            const cx = width / 2;
            const cy = height / 2;
            ctx.lineWidth = lw;
            ctx.lineCap = "round";
            ctx.strokeStyle = root.trackColor;
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();
            ctx.strokeStyle = root.color;
            ctx.beginPath();
            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, root.value)));
            ctx.stroke();
        }
    }
}
