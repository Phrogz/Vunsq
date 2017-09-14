import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.4

Rectangle {
    width: 200
    color:'#FF333333'

    property var effectsArray: []
    onEffectsArrayChanged: {
        effectNames.clear()
        effectsArray.forEach(newEffect);
    }

    Header {
        id: header
        name:'Effects'
        Button {
            id: addEffect
            text: "+";
            anchors { verticalCenter:parent.verticalCenter; right:parent.right; rightMargin:5 }
            width: 20; height:18
            onClicked: newEffect()
        }
    }

    SplitView {
        anchors { top:header.bottom; bottom:parent.bottom; left:parent.left; right:parent.right }
        orientation: Qt.Vertical

        ListView {
            id: effectNameList
            height:parent.height/3
            Layout.minimumHeight: parent.height/3
            model: ListModel { id:effectNames }
            delegate: Rectangle {
                color:index===effectNameList.currentIndex ? Qt.hsva(60/360,0.5,1) : 'white'
                width:parent.width
                height:20
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        effectNameList.currentIndex = index;
                        editor.loadFunction( effectsArray[index+1] );
                    }
                }
                Rectangle {
                    id:effectColor
                    color:colorsByEffect[index]
                    height:parent.height*0.8; width:height
                    anchors { verticalCenter:parent.verticalCenter; left:parent.left; leftMargin:parent.height-height }
                    border { color:'#cc000000' }
                }
                Text {
                    text:effectName
                    height:parent.height
                    verticalAlignment: Text.AlignVCenter
                    anchors{ left:effectColor.right; leftMargin:effectColor.anchors.leftMargin }
                }
            }
        }

        CodeEditor {
            id: editor
            readOnly: effectNameList.currentIndex < 0
            onTextChanged: effectsArray[ effectNameList.currentIndex+1 ].code = text;
        }

    }


    function newEffect(a,b) {
        effectNames.append({effectName:'Effect #'+(effectNames.count+1), index:effectNames.count})
        if (!a) effectsArray.push({index:effectNames.count+1, code:""});
    }
}

