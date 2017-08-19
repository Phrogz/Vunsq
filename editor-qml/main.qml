import QtQuick 2.8
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0
import "vunsq.js" as V

Window {
    id: app
    visible: true
    width: 1280
    height: 800
    title: "Vunsq Editor"
    color: 'gray'

    property var vid

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

                   vid.effect({index:1, name:'Falling Stripe', code:"var finish = Math.round(effectTime / 10) % strandLength;\nvar length = args && args[3] || 25;\nfor (var y = finish - length; y <= finish; ++y) {\n   var offset = y * 4;\n   data[offset + 0] = args ? args[0] : 255;\n   data[offset + 1] = args ? args[1] : 255;\n   data[offset + 2] = args ? args[2] : 255;\n   data[offset + 3] = (y - finish + length) / length * 255;\n}\n"});
                   vid.effect({index:2, code:"for (var y=strandLength;y--;) { var o=y*4; data[o+3]=255 }"});
                   vid.effect({index:3, code:"for (var y=strandLength;y--;) { var o=y*4; data[o+3]=255 }"});
                   vid.effect({index:4, code:"for (var y=strandLength;y--;) { var o=y*4; data[o+3]=255 }"});
                   vid.effect({index:5, code:"for (var y=strandLength;y--;) { var o=y*4; data[o+3]=255 }"});
                   vid.effect({index:6, code:"for (var y=strandLength;y--;) { var o=y*4; data[o+3]=255 }"});
                   vid.effect({index:7, code:"for (var y=strandLength;y--;) { var o=y*4; data[o+3]=255 }"});
                   vid.effect({index:8, code:"for (var y=strandLength;y--;) { var o=y*4; data[o+3]=255 }"});
                   vid.effect({index:9, code:"for (var y=strandLength;y--;) { var o=y*4; data[o+3]=255 }"});
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
    function saveJSON(){
        console.log(vid.toJSON());
        vid.effects.forEach(function(d,i){
           if (i) {
               console.log("Effect #"+i);
               console.log(d.code);
           }
        });
    }
}
