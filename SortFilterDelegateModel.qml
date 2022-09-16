import QtQuick 2.15
import QtQml.Models 2.15

DelegateModel {
    id: delegateModel
    property var filter: null
    readonly property bool running: updating || sortHelper.running
    property int updateIndex: 0
    readonly property bool updated: updateIndex >= allItems.count
    readonly property bool updating: !updated
    readonly property int progress: updating
    ? Math.floor(50 * updateIndex / allItems.count)
    : (50 + sortHelper.progress / 2)
    property int sortOrder: Qt.AscendingOrder
    property int sortCaseSensitivity: Qt.CaseInsensitive
    property var sortRole: ""
    property var sortOps: [ ]
    property var sortCompare: null
    property int sortIndex: 0
    readonly property bool sorted: sortHelper ? sortHelper.sorted : true
    readonly property alias visibleItems: _visibleItems
    onFilterChanged: Qt.callLater(update)
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
            id: allItems
            name: "all"
            includeByDefault: true
            onCountChanged: {
                if (updateIndex > allItems.count) updateIndex = allItems.count;
                if (updateIndex < allItems.count) Qt.callLater(update);
            }
        },
        DelegateModelGroup {
            id: _visibleItems
            name: "visible"
            onCountChanged: {
                if (sortIndex > _visibleItems.count) sortHelper.sortIndex = 0;
                if (sortIndex < _visibleItems.count) Qt.callLater(sortHelper.sort);
            }
        }
    ]
    filterOnGroup: "visible"

    function update(startIndex) {
        startIndex = startIndex ?? 0;
        if (startIndex < 0) startIndex = 0;
        if (startIndex >= allItems.count) {
            updateIndex = allItems.count;
            return;
        }
        updateIndex = startIndex;
        if (updateIndex === 0) {
            sortHelper.sortIndex = 0;
            allItems.setGroups(0, allItems.count, [ "all" ] );
        }
        for (let ts = Date.now(); updateIndex < allItems.count && Date.now() < ts + 50; updateIndex++) {
            let visible = !filter || filter(allItems.get(updateIndex).model);
            if (!visible) continue;
            allItems.setGroups(updateIndex, 1, [ "all", "visible" ]);
        }
        if (updateIndex < allItems.count) Qt.callLater(update, updateIndex);
    }

    function sort(sortIndex) {
        if (!sortHelper) return;
        sortHelper.sort(sortIndex);
    }

    Component.onCompleted: Qt.callLater(update)
}
