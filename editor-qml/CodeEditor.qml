import QtQuick 2.0
import QtQuick.Controls 1.4

TextArea {
    id: editor
    font { family:mono.name }
    function loadFunction(funcData) {
        editor.text = funcData.code;
    }
    textMargin:20
    FontLoader { id:mono; source:'AndaleMono' }

    Text {
        id: prefix
        text:"function (effectTime, strandIndex, strandLength, bpm, data, args) {"
        opacity:0.5; height:20
        font { family:mono.name }
        anchors { top:parent.top }
    }

    Text {
        id: suffix
        text:"}"
        opacity:0.5; height:20
        font { family:mono.name }
        anchors { bottom:parent.bottom }
    }
}

