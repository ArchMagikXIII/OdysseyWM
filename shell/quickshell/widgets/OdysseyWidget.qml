import QtQuick

Rectangle {

    id: root

    property alias content: contentRow

    radius: 8

    color: "#161B26"

    height: 24

    width: contentRow.implicitWidth + 16


    Row {

        id: contentRow

        anchors.centerIn: parent

        spacing: 6
    }
}
