import Quickshell
import Quickshell.Wayland
import QtQuick
import "widgets" 

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
    }

    height: 28

    color: "#0B0F17"

    Row {
        anchors.fill: parent

        anchors.leftMargin: 12
        anchors.rightMargin: 12

        spacing: 20

        Text {
            width: 200

            text: "ODYSSEY"
            color: "#FFFFFF"

            font.pixelSize: 14
            font.bold: true

            verticalAlignment: Text.AlignVCenter
        }


Item {
    anchors.verticalCenter: parent.verticalCenter

    width: 400
    height: parent.height

    Workspaces {
        anchors.centerIn: parent
    }
}

        Item {
    width: 250
    height: parent.height

    anchors.verticalCenter: parent.verticalCenter

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        spacing: 8

        
    }
}
    }
}
