import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: runView
    property var obj: null

    clip: true

    function compile(code, filePath) {
        if (obj) {
            obj.destroy();
            obj = null;
        }

        if (!code) {
            return;
        }

        obj = Qt.createQmlObject(code, runView, filePath ?? "dynamic");
        obj.width = Qt.binding( () => runView.width );
        obj.height = Qt.binding( () => runView.height );
    }
}
