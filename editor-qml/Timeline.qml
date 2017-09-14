import QtQuick 2.7

Item {
    id: root
    property real bpm: 110.28
    property int strands: 24
    property int msPerPixel: 16
    property int startMS: 0
    property real currentMS: 9000
    property var strandData: []
    property var eventPainter: []
    property var activeRows: []
    property int overRow: -1
    property real endTime: 1000

    property real pxPerSecond: 1000/msPerPixel
    property real pxPerBeat: 60 * pxPerSecond / bpm
    property real msPerBeat: 1000 * 60 / bpm

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
        width:height/(strandData.length || 20)
        height:parent.height-ruler.height
        anchors.bottom: parent.bottom
        Repeater {
            id: selectionBoxen
            anchors.fill:parent
            model: timelinerows.count
            delegate: Rectangle {
                color: activeRows[index] ? (overRow===index ? '#FFffffcc' : '#FFcccccc') : (overRow===index ? '#FF666622' : '#FF222222')
                height: header.width
                width: header.width
                y: index * height
                clip: true
                Rectangle {
                    anchors { fill:parent; leftMargin:active?-1:0; topMargin:active?-1:0; rightMargin:active?0:-1; bottomMargin:active?0:-1 }
                    color:'transparent'; border.color:'#33ffffff'
                }
                Rectangle {
                    anchors { fill:parent; leftMargin:active?0:-1; topMargin:active?0:-1; rightMargin:active?-1:0; bottomMargin:active?-1:0 }
                    color:'transparent'; border.color:'#66000000'
                }
                MouseArea {
                    anchors.fill:parent
                    hoverEnabled:true
                    onEntered:overRow = index
                    onClicked:activeRows[index] = !activeRows[index]
                }
            }
        }
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
                context.clearRect(0,0,width,height);
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
                    for (x=zeroOffset; x<=width; x+=stepSize) {
                        context.fillRect(x,0,1,height*0.25);
                    }
                }

                stepSize = pxPerBeat;
                if (stepSize<10) stepSize*=4;
                context.fillStyle = '#9900FF00';
                for (x=zeroOffset; x<=width; x+=stepSize) {
                    context.fillRect(x,0,1,height*0.5);
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: currentMS = mouseX * msPerPixel + startMS;
            }
        }

        ListView {
            id: rows
            anchors { top:ruler.bottom; left:parent.left; right:parent.right; bottom:parent.bottom }
            contentX: startMS / msPerPixel
            model: ListModel { id:timelinerows }
            interactive: false
            delegate: ListView {
                orientation: ListView.Horizontal
                height:rows.height / timelinerows.count
                width:rows.width
                model: events
                delegate: Rectangle {
                    property real endTime: (index < modelData.count-1) ? modelData.get(index+1).start : root.endTime
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
                scrollGestureEnabled: true
                onEntered: parent.forceActiveFocus()
                onPositionChanged: {
                    overRow = (strandData.length * mouseY/header.height) << 0;
                    var exactMS = mouseX * msPerPixel + startMS;
                    if (mouse.modifiers & Qt.ShiftModifier) currentMS = exactMS;
                    else { // Round to the nearest beats MS
                        currentMS = Math.round(exactMS / msPerBeat) * msPerBeat
                    }
                }
                onWheel: {
                    if (wheel.modifiers & Qt.AltModifier) {
                        if (lastUpdate && (new Date)-lastUpdate < 100) return;
                        if (wheel.angleDelta.y>0 && msPerPixel<256) msPerPixel*=2;
                        if (wheel.angleDelta.y<0 && msPerPixel>1)   msPerPixel/=2;
                        lastUpdate = new Date;
                    } else startMS = Math.max(0, startMS + wheel.angleDelta.y * msPerPixel);
                }
            }

            Keys.onPressed: {
                switch(event.key) {
                    case Qt.Key_Space:
                        if (event.modifiers & Qt.ControlModifier) for (var i=strandData.length;i--;) activeRows[i] = !activeRows[i];
                        else if (event.modifiers & Qt.ShiftModifier) {
                            var active = !activeRows[overRow];
                            for (var i=strandData.length;i--;) activeRows[i] = active;
                        } else activeRows[overRow] = !activeRows[overRow];
                    break;

                    case Qt.Key_Minus: if (msPerPixel<256) msPerPixel *= 2; break;
                    case Qt.Key_Equal: if (msPerPixel>1)   msPerPixel /= 2; break;

                    case Qt.Key_0:
                    case Qt.Key_1:
                    case Qt.Key_2:
                    case Qt.Key_3:
                    case Qt.Key_4:
                    case Qt.Key_5:
                    case Qt.Key_6:
                    case Qt.Key_7:
                    case Qt.Key_8:
                    case Qt.Key_9:
                        var keyNum = event.key-48;
                        if (event.modifiers & Qt.ControlModifier) {
                            var preset = eventPainter[keyNum];
                            if (!preset) preset=eventPainter[keyNum]=[];
                            for (var i=strandData.length;i--;) {
                                preset[i] = activeRows[i] ? effectAt(i, currentMS) : null;
                            }
                            console.log('slurp!',JSON.stringify(preset))
                        } else if (event.modifiers & Qt.AltModifier) {
                            var preset = eventPainter[keyNum];
                            if (!preset) preset=eventPainter[keyNum]=[];
                            for (var i=strandData.length;i--;) {
                                if (preset[i]!=null) setEffect(preset[i], i, currentMS);
                            }
                            console.log('splat!');
                        } else {
                            for (var i=strandData.length;i--;) {
                                if (activeRows[i]) setEffect(keyNum, i, currentMS);
                            }
                        }
                        strandData = strandData;
                    break;

                    case Qt.Key_Delete:
                    case Qt.Key_Backspace:
                        for (var i=strandData.length;i--;) {
                            if (activeRows[i]) deleteEffectAt(i, currentMS);
                        }
                        strandData = strandData;
                    break;

                    case Qt.Key_J:
                        app.saveJSON();
                    break;

                    case Qt.Key_F1:
                    case Qt.Key_F2:
                    case Qt.Key_F3:
                    case Qt.Key_F4:
                    case Qt.Key_F5:
                    case Qt.Key_F6:
                    case Qt.Key_F7:
                    case Qt.Key_F8:
                    case Qt.Key_F9:
                        var presetNum = event.key - 16777263;
                        var preset = eventPainter[presetNum];
                        if (!preset) preset=eventPainter[presetNum]=[];
                        console.log(presetNum,JSON.stringify(preset))
                        if (event.modifers & Qt.ShiftModifier & Qt.ControlModifier) {
                            for (var i=strandData.length;i--;) {
                                preset[i] = activeRows[i] ? effectAt(strandIndex, startTime) : null;
                            }
                        } else {
                            for (var i=strandData.length;i--;) {
                                if (preset[i]!=null) setEffect(preset[i], i, currentMS);
                            }
                        }
                    break;

                }
            }

            function effectAt(strandIndex, intersectingTime) {
                var strand = strandData[strandIndex];
                for (var i=0;i<strand.length;++i) {
                    var e1=strand[i], e2=strand[i+1];
                    if (e1.start<=intersectingTime && (!e2 || e2.start>intersectingTime)) return e1.effect;
                }
            }

            function setEffect(effectId, strandIndex, startTime) {
                startTime = Math.round(startTime);
                var strand = strandData[strandIndex];
                var injected = false;
                for (var i=0;i<strand.length;++i) {
                    var evt = strand[i];
                    if (evt.start===startTime) return evt.effect = effectId;
                    else if (evt.start>startTime) return strand.splice(i,0,{effect:effectId, start:startTime, speed:1});
                }
                strand.push({effect:effectId, start:startTime});
            }

            function deleteEffectAt(strandIndex, startTime) {
                var strand = strandData[strandIndex];
                for (var i=1;i<strand.length-1;++i) {
                    var e1=strand[i], e2=strand[i+1];
                    if (e1.start<=startTime && e2.start>startTime) return strand.splice(i,1);
                }
            }
        }

        Rectangle {
            id: playhead
            color:'orange'
            width:1; height:parent.height
            x: (currentMS - startMS) / msPerPixel
        }
    }
}
