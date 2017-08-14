import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.4

Rectangle {
    width: 200
    color:'#FF333333'

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
            height:parent.height/3
            Layout.minimumHeight: parent.height/3
            model: ListModel { id:effectNames }
            delegate: Rectangle {
                color:'white'
                width:parent.width
                height:20
                Text { text: effectName; anchors{ fill:parent; margins:2 } }
                MouseArea { anchors.fill: parent }
            }
        }

        CodeEditor {

        }

    }


    function newEffect() {
        effectNames.append({effectName:'Effect #'+(effectNames.count+1), index:effectNames.count})
    }

}

