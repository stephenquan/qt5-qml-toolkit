import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

ListView {
    clip: true

    model: ListModel {
        id: listModel

        function appendMessage(message, messageColor) {
            let timestamp = Qt.formatDateTime(new Date(), "hh:mm:ss.zzz");
            listModel.append( { timestamp, message, messageColor } );
            currentIndex = listModel.count - 1;
        }
    }

    ScrollBar.vertical: ScrollBar {
        width: 20
    }

    delegate: Frame {
        width: ListView.view.width - 20

        background: Rectangle {
            color: (index & 1) ? "#f0f0f0" : "#e0e0e0"
        }

        RowLayout {
            width: parent.width

            Text {
                Layout.fillWidth: true

                text: message
                color: messageColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Text {
                text: timestamp
                color: "#808080"
            }
        }
    }

    function clear() {
        listModel.clear();
    }

    function log(...params) {
        console.log(...params);
        listModel.appendMessage(params.join(" "), "black");
    }

    function error(...params) {
        console.error(...params);
        listModel.appendMessage(params.join(" "), "red");
    }
}
