import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    property alias text: textEdit.text
    property alias textDocument: textEdit.textDocument
    property string errorMessage: ""

    property TextMetrics textMetrics: TextMetrics {
        text: "#####"
        font.family: textEdit.font.family
    }

    RowLayout {
        anchors.fill: parent

        ListView {
            id: listView
            Layout.preferredWidth: textMetrics.width
            Layout.fillHeight: true
            model: textEdit.text.split("\n")
            clip: true
            delegate: Rectangle {
                width: ListView.view.width
                height: metric.height
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (index + 1)
                }

                property Text metric: Text {
                    width: textEdit.width
                    text: modelData
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font.family: textEdit.font.family
                }
            }

            onContentYChanged: Qt.callLater( () => {
                                                if (!flickable.moving) {
                                                    flickable.contentY = contentY;
                                                }
                                            } )
        }

        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: textEdit.width
            contentHeight: textEdit.height
            clip: true
            flickableDirection: Flickable.VerticalFlick
            TextEdit {
                id: textEdit
                width: flickable.width - 20
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.family: "Courier"
                selectByMouse: true
            }
            ScrollBar.vertical: ScrollBar {
                width: 20
            }

            onContentYChanged: Qt.callLater( () => {
                                                if (!listView.moving) {
                                                    listView.contentY = contentY;
                                                }
                                            } )
        }
    }
}
