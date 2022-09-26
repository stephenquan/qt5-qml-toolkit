import QtQuick 2.15

ListModel {
    id: listModel
    readonly property bool running: sortHelper ? sortHelper.running : false
    readonly property int progress: sortHelper ? sortHelper.progress : 100
    property int sortOrder: Qt.AscendingOrder
    property int sortCaseSensitivity: Qt.CaseInsensitive
    property var sortRole: ""
    property var sortCompare: null
    readonly property bool sorted: sortHelper ? sortHelper.sorted : true
    property SortHelper sortHelper: SortHelper {
        sortOrder: listModel.sortOrder
        sortCaseSensitivity: listModel.sortCaseSensitivity
        sortRole: listModel.sortRole
        sortCompare: listModel.sortCompare
        getFunc: index => get(index)
        countFunc: () => count
        moveFunc: (from, to, n) => move(from, to, n)
    }
    onCountChanged: {
        if (!sortHelper) return;
        if (count === 0) Qt.callLater(sortHelper.sort, 0)
        if (count > 0) Qt.callLater(sortHelper.sort)
    }
    function sort(sortIndex) {
        if (!sortHelper) return;
        sortHelper.sort(sortIndex);
    }
}
