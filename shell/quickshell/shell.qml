import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
    }

    height: 24

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

            Text {
                anchors.centerIn: parent

                text: "1   2   3   4   5"

                color: "#AAB2C0"

                font.pixelSize: 13
            }
        }


        Item {
            anchors.fill: parent

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                text: "CPU  RAM  GPU  WiFi  🔋"

                color: "#AAB2C0"

                font.pixelSize: 13
            }
        }
    }
}
