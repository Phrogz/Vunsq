import QtQuick 2.0
import QtQuick.Controls 1.4

TextArea {
    id: editor
    font { family:mono.name }
    function loadFunction(funcData) {
        editor.text = funcData.code;
    }
    tabChangesFocus: false
    textMargin:20
    FontLoader { id:mono; source:'AndaleMono' }

    Text {
        id: prefix
        text:"function (effectTime, strandIndex, strandLength, bpm, rgba, args) {"
        opacity:0.5; height:20
        font { family:mono.name }
        anchors { top:parent.top; left:parent.left; leftMargin:4 }
    }

    Text {
        id: suffix
        text:"}"
        opacity:0.5; height:20
        font { family:mono.name }
        anchors { bottom:parent.bottom; left:parent.left; leftMargin:4 }
    }

    // Workaround QTBUG-39102
    Keys.onPressed: {
        if (Qt.Key_Tab === event.key) {
            insert(cursorPosition, "\t");
            event.accepted = true;
        }
    }
}

