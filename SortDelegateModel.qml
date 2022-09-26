import QtQuick 2.15
import QtQml.Models 2.15

DelegateModel {
    id: delegateModel
    readonly property bool running: sortHelper ? sortHelper.running : false
    readonly property int progress: sortHelper ? sortHelper.progress : 100
    property int sortOrder: Qt.AscendingOrder
    property int sortCaseSensitivity: Qt.CaseInsensitive
    property var sortRole: ""
    property var sortOps: [ ]
    property var sortCompare: null
    property int sortIndex: 0
    readonly property bool sorted: sortHelper ? sortHelper.sorted : true
    property SortHelper sortHelper: SortHelper {
        sortOrder: delegateModel.sortOrder
        sortCaseSensitivity: delegateModel.sortCaseSensitivity
        sortRole: delegateModel.sortRole
        sortCompare: delegateModel.sortCompare
        getFunc: index => _visibleItems.get(index).model
        countFunc: () => _visibleItems.count
        moveFunc: (from, to, n) => _visibleItems.move(from, to, n)
    }
    groups: [
        DelegateModelGroup {
            id: _visibleItems
            name: "visible"
            includeByDefault: true
            onCountChanged: {
                if (!sortHelper) return;
                if (!_visibleItems.count) Qt.callLater(sortHelper.sort, 0);
                if (_visibleItems.count) Qt.callLater(sortHelper.sort);
            }
        }
    ]
    filterOnGroup: "visible"

    function sort(sortIndex) {
        if (!sortHelper) return;
        sortHelper.sort(sortIndex);
    }

    Component.onCompleted: Qt.callLater(sort)
}
