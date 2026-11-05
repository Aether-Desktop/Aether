import QtQuick
import "../../shell/Aether"

// Line chart for a bounded history of percentage values. Renders real samples
// only; an empty history draws nothing rather than a fake baseline.
Item {
    id: root

    property var values: []
    property color stroke: Theme.primary
    property color fill: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
    property real maximum: 100

    implicitHeight: 92

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        Connections {
            target: root
            function onValuesChanged() { canvas.requestPaint(); }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const values = root.values || [];
            const w = width;
            const h = height;
            if (w < 2 || h < 2) return;
            if (values.length < 2) return;

            const step = w / Math.max(1, values.length - 1);
            const max = Math.max(1, root.maximum);
            const point = (i) => {
                const v = Math.max(0, Math.min(max, Number(values[i]) || 0));
                return { x: i * step, y: h - (v / max) * (h - 4) - 2 };
            };

            ctx.beginPath();
            const first = point(0);
            ctx.moveTo(first.x, first.y);
            for (let i = 1; i < values.length; i++) {
                const p = point(i);
                ctx.lineTo(p.x, p.y);
            }
            const last = point(values.length - 1);
            ctx.lineTo(last.x, h);
            ctx.lineTo(first.x, h);
            ctx.closePath();
            ctx.fillStyle = root.fill;
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(first.x, first.y);
            for (let i = 1; i < values.length; i++) {
                const p = point(i);
                ctx.lineTo(p.x, p.y);
            }
            ctx.strokeStyle = root.stroke;
            ctx.lineWidth = 2;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }
}
