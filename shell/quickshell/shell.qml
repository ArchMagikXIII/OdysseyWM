import Quickshell
import Quickshell.Wayland
import QtQuick
import "widgets"

PanelWindow {

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 28

    color: "#0B0F17"


    // LEFT
    Row {

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 12
        }

        spacing: 10


        Text {

            text: "ODYSSEY"

            color: "#FFFFFF"

            font.pixelSize: 14
            font.bold: true
        }
    }


    // CENTER
    Row {

        anchors.centerIn: parent

        Workspaces {}
    }


    // RIGHT
    Row {

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 12
        }

        spacing: 8


        Text {

            text: "CPU  RAM  GPU  WiFi  🔋"

            color: "#AAB2C0"

            font.pixelSize: 13
        }
    }
}
