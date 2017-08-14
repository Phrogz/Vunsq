import QtQuick 2.9
import QtQuick.Layouts 1.0

Rectangle {
    height: 24
    Layout.minimumHeight: 24
    anchors { top:parent.top; left:parent.left; right:parent.right }
    color: 'black'
    property alias name: label.text
    Text {
        id: label
        color: 'white'
        anchors { top:parent.top; bottom:parent.bottom; left:parent.left; margins:4 }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
    }
}
