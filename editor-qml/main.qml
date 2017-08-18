import QtQuick 2.8
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0
import "vunsq.js" as V

Window {
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
                   vid = new V.Vunsq(mainContext, tmpContext)

                   vid.effect(1, fallingStripe);

                   vid.loadFromObject({
                     length:60000,
                     bpm:100.28,
                     timeline:[[{effect:1}], [{effect:0}, {effect:1, start:500, args:[255, 0, 0]}], [{effect:0}, {effect:1, start:1000}], [{effect:0}, {effect:1, start:1500}],
                               [{effect:2}, {effect:3, start:2700}], [{effect:1}], [{effect:1}], [{effect:1}],
                               [{effect:1}], [{effect:1}], [{effect:1}], [{effect:1}],
                               [{effect:1}], [{effect:1}], [{effect:1}], [{effect:1}],
                               [{effect:1}], [{effect:1}], [{effect:1}], [{effect:1}], [{effect:1}], [{effect:1}], [{effect:1}], [{effect:1}]]
                   });

                   timeline.strandData = vid.timeline;
                   timeline.endTime = vid.length;

                   function fallingStripe(t, x, h, args, data, bpm) {
                       var finish = Math.round(t / 10) % h
                       var length = args && args[3] || 25
                       for (var y = finish - length; y <= finish; ++y) {
                           var offset = y * 4
                           data[offset + 0] = args ? args[0] : 255
                           data[offset + 1] = args ? args[1] : 255
                           data[offset + 2] = args ? args[2] : 255
                           data[offset + 3] = (y - finish + length) / length * 255
                       }
                   }

               }
               onUpdate: vid.update(timeline.currentMS);
           }

           EffectEditor  {
               Layout.fillWidth: true
               
           }
       }
       Timeline { id:timeline; Layout.minimumHeight: 200 }
   }

   Component.onCompleted: {

   }

   Item {
       focus:true
       Keys.onPressed: {
           switch(event.key) {
           case Qt.Key_Minus: if (timeline.msPerPixel<256) timeline.msPerPixel *= 2; break;
           case Qt.Key_Equal: if (timeline.msPerPixel>1)   timeline.msPerPixel /= 2; break;
           }
       }
   }
}
