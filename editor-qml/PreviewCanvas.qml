import QtQuick 2.9

Item {
    id: root
    property int strands: 24
    property int lightsPerStrand: 240
    property bool initialized

    signal ready(var mainContext, var tmpContext)
    signal update
    function repaint() { previewCanvas.requestPaint() }

    Header {
        id: header
        name: 'Preview'
    }

    Item {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Canvas {
            scale: (width/height) > (parent.width / parent.height) ? (parent.width/width) : (parent.height/height);
            transformOrigin: Item.Top

            id: previewCanvas
            property real startTime
            property var idata
            property bool initialized

            contextType: '2d'
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            width: strands; height: lightsPerStrand
            Canvas {
                id: tmpCanvas
                width: 1; height: lightsPerStrand
                contextType: '2d'
                opacity: 0
                anchors { top: parent.top; left: parent.right; leftMargin: 10 }
            }

            onPaint: {
                if (available && tmpCanvas.available && !initialized) {
                    ready(context, fauxContext(tmpCanvas));
                    initialized = true;
                }
                root.update();
                requestAnimationFrame(requestPaint);
            }

            // Working around https://bugreports.qt.io/browse/QTBUG-62280
            function fauxContext(canvas) {
                return {
                    canvas: canvas,
                    getImageData: function () {
                        return {
                            width: canvas.width,
                            height: canvas.height,
                            data: Array.apply(
                                      null, Array(
                                          canvas.width * canvas.height * 4)).map(
                                      Number.prototype.valueOf, 0)
                        }
                    },
                    putImageData: function (imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) {
                        canvas.context.clearRect(0, 0, canvas.width,
                                                 canvas.height)
                        var x1 = dirtyX
                                || 0, x2 = x1 + (dirtyWidth
                                                 || canvas.width), y1 = dirtyY
                                || 0, y2 = y1 + (dirtyHeight || canvas.height)
                        for (var y = y1; y < y2; ++y) {
                            for (var x = x1; x < x2; ++x) {
                                var o = (y * imagedata.width + x) * 4
                                var a = imagedata.data[o + 3]
                                if (a > 0) {
                                    canvas.context.fillStyle = 'rgba(' + imagedata.data[o]
                                            + ',' + imagedata.data[o + 1] + ','
                                            + imagedata.data[o + 2] + ',' + a / 255 + ')'
                                    canvas.context.fillRect(x + dx,
                                                            y + dy, 1, 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
