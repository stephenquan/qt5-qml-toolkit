import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: iconButton
    property alias source: button.icon.source
    property alias color: button.icon.color
    width: 32
    height: 32
    implicitWidth: width
    implicitHeight: height
    signal clicked()
    Button {
        id: button
        anchors.centerIn: parent
        background: Item { }
        icon.width: parent.width
        icon.height: parent.height
        onClicked: iconButton.clicked()
    }
}
