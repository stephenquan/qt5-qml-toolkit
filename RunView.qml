import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: runView
    property var obj: null

    function compile(code) {
        if (obj) {
            obj.destroy();
            obj = null;
        }

        if (!code) {
            return;
        }

        obj = Qt.createQmlObject(code, runView, "dynamic");
        obj.width = Qt.binding( () => runView.width );
        obj.height = Qt.binding( () => runView.height );
    }
}
