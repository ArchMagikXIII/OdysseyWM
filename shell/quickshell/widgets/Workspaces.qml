import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.I3._Ipc

Row {

    spacing: 8

    Repeater {

        model: I3.workspaces

Rectangle {
    width: modelData.focused ? 34 : 26
    height: 26

    radius: 13

    color: modelData.focused
        ? "#5AA9FF"
        : "#161B26"

    border.width: 1
    border.color: "#5AA9FF"

    Behavior on width {
        NumberAnimation {
            duration: 150
        }
    }

    Text {
        anchors.centerIn: parent
        text: modelData.name
        color: "#FFFFFF"
        font.pixelSize: 12
      }
    
    }
 
  }

}
