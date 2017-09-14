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
    property var colorsByEffect: ['#FFb3aaf2', '#FFb2ff80', '#FFe5bf73', '#FFc5e6a1', '#FFfff780', '#FF6cc3d9',
                                  '#FFe6a1a1', '#FFf27999', '#FF7466cc', '#FFcca78f', '#FF79f2aa', '#FF669ccc',
                                  '#FF99ffdd', '#FFf29979', '#FFcc7abc', '#FFcf73e6']

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
                   vid.effect({index:3, code:"for (var y=strandLength;y--;) {\n\tvar o=y*4;\n\trgba[o+3]=255;\n}\n\nfunction hsv(h,s,v,data,offset) {\n\tvar r,g,b,i,f,p,q,t;\n\th = (h<0) h-Math.floor(h) : h%1;\n\ts=s>1?1:s<0?0:s;\n\tv=v>1?1:v<0?0:v;\n\n\tif (s==0) r=g=b=v;\n\telse {\n\t\th*=60;\n\t\tf=h-(i=Math.floor(h));\n\t\tp=v*(1-s);\n\t\tq=v*(1-s*f);\n\t\tt=v*(1-s*(1-f));\n\t\tswitch (i) {\n\t\t\tcase 0:r=v; g=t; b=p; break;\n\t\t\tcase 1:r=q; g=v; b=p; break;\n\t\t\tcase 2:r=p; g=v; b=t; break;\n\t\t\tcase 3:r=p; g=q; b=v; break;\n\t\t\tcase 4:r=t; g=p; b=v; break;\n\t\t\tcase 5:r=v; g=p; b=q; break;\n\t\t}\n\t}\n\tdata[offset+0]=r*255;\n\tdata[offset+1]=g*255;\n\tdata[offset+2]=b*255;\n}"});
                   vid.effect({index:4, code:"for (var y=strandLength;y--;) {\n\tvar o=y*4;\n\trgba[o+3]=255;\n}"});
                   vid.effect({index:5, code:"for (var y=strandLength;y--;) {\n\tvar o=y*4;\n\trgba[o+3]=255;\n}"});
                   vid.effect({index:6, code:"for (var y=strandLength;y--;) {\n\tvar o=y*4;\n\trgba[o+3]=255;\n}"});
                   vid.effect({index:7, code:"for (var y=strandLength;y--;) {\n\tvar o=y*4;\n\trgba[o+3]=255;\n}"});
                   vid.effect({index:8, code:"for (var y=strandLength;y--;) {\n\tvar o=y*4;\n\trgba[o+3]=255;\n}"});
                   vid.effect({index:9, code:"for (var y=strandLength;y--;) {\n\tvar o=y*4;\n\trgba[o+3]=255;\n}"});
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
        console.debug("Saved to",currentFile);
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
        title: "Save JSON Sequence As"
        selectExisting: false
        onAccepted: saveJSON(fileUrl)
    }
}
