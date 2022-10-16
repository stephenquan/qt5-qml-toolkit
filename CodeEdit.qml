import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    property alias text: textEdit.text
    property alias textDocument: textEdit.textDocument
    property alias font: textEdit.font
    property string errorMessage: ""

    property TextMetrics textMetrics: TextMetrics {
        text: "#####"
        font.family: textEdit.font.family
        font.pointSize: textEdit.font.pointSize
    }

    RowLayout {
        anchors.fill: parent

        Rectangle {
            id: listView
            Layout.preferredWidth: textMetrics.width
            Layout.fillHeight: true
            color: "#e0e0e0"
            clip: true
            Column {
                width: parent.width
                y: -flickable.contentY
                Repeater {
                    model: textEdit.text.split("\n")
                    Item {
                        width: parent.width
                        height: metric.height
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (index + 1)
                            font.family: textEdit.font.family
                            font.pointSize: textEdit.font.pointSize
                        }
                        property Text metric: Text {
                            width: textEdit.width
                            text: modelData
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.family: textEdit.font.family
                            font.pointSize: textEdit.font.pointSize
                        }
                    }
                }
            }
        }

        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: textEdit.width
            contentHeight: textEdit.height
            clip: true
            flickableDirection: Flickable.VerticalFlick
            Frame {
                padding: 0
                width: flickable.contentWidth
                background: Rectangle { color: "#ffffe0" }
                TextEdit {
                    id: textEdit
                    width: flickable.width - 20
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font.family: "Courier"
                    font.pointSize: 10
                    selectByMouse: true
                    property real cursorPositionY: positionToRectangle(cursorPosition).y
                    onCursorPositionYChanged: {
                       if (cursorPositionY < flickable.contentY) {
                           flickable.contentY = cursorPositionY;
                        } else if (cursorPositionY > flickable.contentY + flickable.height - 50) {
                            flickable.contentY = cursorPositionY - (flickable.height - 50);
                        }
                    }
                }
            }
            ScrollBar.vertical: ScrollBar {
                width: 20
            }
        }
    }
}
