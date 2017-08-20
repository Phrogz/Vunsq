import QtQuick 2.8
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1
import "vunsq.js" as V

ApplicationWindow {
    id: app
    visible: true
    width: 1280
    height: 800
    title: "Vunsq Editor"
    color: 'gray'

    property var vid
    property string currentFile

    menuBar: MenuBar {
        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr("&Open…")
                shortcut: StandardKey.Open
                onTriggered: openDialog.open()
            }
            MenuItem {
                text: qsTr("&Save")
                shortcut: StandardKey.Save
                onTriggered: saveJSON()
            }
            MenuItem {
                text: qsTr("Save &As…")
                shortcut: StandardKey.SaveAs
                onTriggered: saveDialog.open()
            }
            MenuSeparator { }
            MenuItem {
                text: qsTr("Exit")
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit();
            }
        }
    }

    SplitView {
       anchors.fill: parent
       orientation: Qt.Vertical

       SplitView {
           orientation: Qt.Horizontal
           Layout.fillHeight: true
           PreviewCanvas {
               id:canvas;
               Layout.minimumWidth: 64
               onReady: {
                   vid = new V.Vunsq(mainContext, tmpContext);

                   vid.effect({index:1, name:'Falling Stripe', code:"var finish = Math.round(effectTime / 10) % strandLength;\nvar length = args && args[3] || 25;\nfor (var y = finish - length; y <= finish; ++y) {\n   var offset = y * 4;\n   rgba[offset + 0] = args ? args[0] : 255;\n   rgba[offset + 1] = args ? args[1] : 255;\n   rgba[offset + 2] = args ? args[2] : 255;\n   rgba[offset + 3] = (y - finish + length) / length * 255;\n}\n"});
                   vid.effect({index:2, name:'Pulse', code:"var msPerBeat = 60000 / bpm;\nvar brightness = effectTime<128 ? effectTime*2 : (1-(effectTime%msPerBeat)/msPerBeat)*255;\nfor (var y=0; y<rgba.length; y+=4){\n  rgba[y+0]=args ? args[0] : 255;\n  rgba[y+1]=args ? args[1] : 0;\n  rgba[y+2]=args ? args[2] : 0;\n  rgba[y+3]=brightness;\n}"});
                   vid.effect({index:3, code:"for (var y=strandLength;y--;) { var o=y*4; rgba[o+3]=255 }"});
                   vid.effect({index:4, code:"for (var y=strandLength;y--;) { var o=y*4; rgba[o+3]=255 }"});
                   vid.effect({index:5, code:"for (var y=strandLength;y--;) { var o=y*4; rgba[o+3]=255 }"});
                   vid.effect({index:6, code:"for (var y=strandLength;y--;) { var o=y*4; rgba[o+3]=255 }"});
                   vid.effect({index:7, code:"for (var y=strandLength;y--;) { var o=y*4; rgba[o+3]=255 }"});
                   vid.effect({index:8, code:"for (var y=strandLength;y--;) { var o=y*4; rgba[o+3]=255 }"});
                   vid.effect({index:9, code:"for (var y=strandLength;y--;) { var o=y*4; rgba[o+3]=255 }"});
                   vid.loadFromObject({
                     length:60000,
                     bpm:100.28,
                     timeline:[[{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}],
                               [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}],
                               [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}],
                               [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}], [{effect:0}]],
                   });

                   timeline.strandData = vid.timeline;
                   timeline.endTime = vid.length;
                   editor.effectsArray = vid.effects;
               }
               onUpdate: vid.update(timeline.currentMS);
           }

           EffectEditor  {
               id: editor
               Layout.fillWidth: true
           }
       }
       Timeline { id:timeline; Layout.minimumHeight: 200 }
    }

    function loadFromJSON(json) {
        var obj = JSON.parse(json);
        vid.loadFromObject(obj);
        if (obj.effects) obj.effects.forEach(function(effectData){ if(effectData) vid.effect(effectData) });
        timeline.strandData = vid.timeline;
        timeline.endTime    = vid.length;
        editor.effectsArray = vid.effects;
    }

    function saveJSON(fileURI) {
        if (fileURI) currentFile = fileURI;
        if (!currentFile) return saveDialog.open();
        var json = vid.toJSON(true);
        var xhr = new XMLHttpRequest();
        xhr.open("PUT", currentFile, false);
        xhr.send(json);
        console.log("Saved to",currentFile);
    }

    FileDialog {
        id: openDialog
        title: "Choose a Sequence"
        nameFilters: [ "Sequences (*.json *.vunsq)" ]
        selectedNameFilter: "Sequences (*.json *.vunsq)"
        onAccepted: {
            var xhr = new XMLHttpRequest;
            xhr.open("GET", fileUrl);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) loadFromJSON(xhr.responseText);
            };
            xhr.send();
        }
    }

    FileDialog {
        id: saveDialog
        title: "Save Sequence As"
        selectExisting: false
        onAccepted: saveJSON(fileUrl)
    }
}
