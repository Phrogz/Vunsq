import QtQuick 2.0

Item {
    id: root
    property real bpm: 110.28
    property int strands: 24
    property int msPerPixel: 16
    property int startMS: 0
    property real currentMS: 9000
    property var strandData: []

    property real pxPerSecond: 1000/msPerPixel
    property real pxPerBeat: 60 * pxPerSecond / bpm
    property real msPerBeat: 1000 * 60 / bpm

    property var colorsByEffect: ['#FFb3aaf2', '#FFb2ff80', '#FFe5bf73', '#FFc5e6a1', '#FFfff780', '#FF6cc3d9',
                                  '#FFe6a1a1', '#FFf27999', '#FF7466cc', '#FFcca78f', '#FF79f2aa', '#FF669ccc',
                                  '#FF99ffdd', '#FFf29979', '#FFcc7abc', '#FFcf73e6']

    onMsPerPixelChanged: ruler.requestPaint();
    onStartMSChanged: ruler.requestPaint();

    clip: true

    onStrandDataChanged: {
        timelinerows.clear();
        strandData.forEach(function(events){
            timelinerows.append({events:events});
        });
    }

    Rectangle {
        id: header
        width:30
        color:'#ff333333'
        height:parent.height
    }

    Item {
        clip: true
        height: parent.height
        anchors { left:header.right; right:parent.right }
        Canvas {
            id: ruler
            width: parent.width
            height: 20
            contextType: '2d'
            onPaint: {
                context.fillStyle = '#ff333333';
                context.fillRect(0, 0, width, height);

                context.textAlign = 'center';
                context.textBaseline = 'bottom';
                context.font = '9px sans-serif'

                var stepSize = pxPerSecond;
                while (stepSize<20) stepSize*=10;
                var zeroOffset = stepSize - ((startMS / msPerPixel) % stepSize || stepSize);
                for (var x=zeroOffset; x<=width; x+=stepSize) {
                    context.fillStyle = '#66FFFFFF';
                    context.fillRect(x,0,1,height*0.4);

                    var seconds = x/pxPerSecond + startMS/1000;
                    if (seconds) {
                        context.fillStyle = '#99FFFFFF';
                        var ss = seconds%60;
                        if (ss<10) ss="0"+ss.toFixed(0);
                        var mmss = Math.floor(seconds/60)+":"+ss;
                        context.fillText(mmss, x, height);
                    }
                }

                stepSize /= 10;
                if (stepSize>=10) {
                    context.fillStyle = '#33FFFFFF';
                    for (var x=zeroOffset;x<=width;x+=stepSize) {
                        context.fillRect(x,0,1,height*0.25);
                    }
                }

                stepSize = pxPerBeat;
                if (stepSize<10) stepSize*=4;
                context.fillStyle = '#9900FF00';
                for (var x=zeroOffset;x<=width;x+=stepSize) {
                    context.fillRect(x,0,1,height*0.5);
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: currentMS = mouseX * msPerPixel
            }
        }

        ListView {
            id: rows
            anchors { top:ruler.bottom; left:parent.left; right:parent.right; bottom:parent.bottom }
            model: ListModel { id:timelinerows }
            delegate: ListView {
                orientation: ListView.Horizontal
                height:rows.height / timelinerows.count
                width:rows.width
                model: events
                delegate: Rectangle {
                    property real endTime: (index < modelData.count-1) ? modelData.get(index+1).start : start + 4*msPerBeat
                    width: (endTime - start) / msPerPixel
                    height: rows.height / timelinerows.count
                    color: effect ? colorsByEffect[effect-1] : 'red'
                    opacity: effect ? 1 : 0
                    Rectangle { width:1; height:parent.height; color:'#33000000'; anchors.right:parent.right }
                    Rectangle { height:1; width:parent.width; color:'#33000000'; anchors.bottom:parent.bottom }
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: {
//                    console.log("Mouse over ",mouseX*msPerPixel)
                }
            }
        }

        Rectangle {
            id: playhead
            color:'orange'
            width:1; height:parent.height
            x: currentMS / msPerPixel
        }
    }
}
