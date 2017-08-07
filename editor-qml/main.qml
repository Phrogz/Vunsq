import QtQuick 2.8
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0

Window {
   visible: true
   width: 1280
   height: 800
   title: "Vunsq Editor"

   SplitView {
       anchors.fill: parent
       orientation: Qt.Vertical

       SplitView {
           orientation: Qt.Horizontal
           Layout.fillHeight: true
           EffectEditor  { Layout.minimumWidth: 200 }
           PreviewCanvas { Layout.fillWidth: true   }
           PatternEditor { Layout.minimumWidth: 200 }
       }
       Timeline { Layout.minimumHeight: 200 }
   }
}
