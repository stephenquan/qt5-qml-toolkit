import QtQuick 2.15
import QtQml.Models 2.15

DelegateModel {
    property var filter: null
    readonly property bool running: updating || sorting
    property int updateIndex: 0
    readonly property bool updated: updateIndex >= allItems.count
    readonly property bool updating: !updated
    readonly property int progress: updating
    ? Math.floor(50 * updateIndex / allItems.count)
    : sorting ? Math.floor(50 + 50 * sortIndex / _visibleItems.count)
              : 0
    property int sortOrder: Qt.AscendingOrder
    property int sortCaseSensitivity: Qt.CaseInsensitive
    property var sortRole: ""
    property var sortOps: [ ]
    property var sortCompare: null
    property int sortIndex: sortIndex
    readonly property bool sorted: sortIndex >= _visibleItems.count
    readonly property bool sorting: !sorted
    readonly property alias visibleItems: _visibleItems
    onFilterChanged: Qt.callLater(update)
    onSortOrderChanged: Qt.callLater(sort)
    onSortCaseSensitivityChanged: Qt.callLater(sort)
    onSortRoleChanged: Qt.callLater(sort)
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
                if (sortIndex > _visibleItems.count) sortIndex = 0;
                if (sortIndex < _visibleItems.count) Qt.callLater(sort);
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
            sortIndex = 0;
            compileSortRole();
            allItems.setGroups(0, allItems.count, [ "all" ] );
        }
        for (let ts = Date.now(); updateIndex < allItems.count && Date.now() < ts + 50; updateIndex++) {
            let visible = !filter || filter(allItems.get(updateIndex).model);
            if (!visible) continue;
            allItems.setGroups(updateIndex, 1, [ "all", "visible" ]);
        }
        if (updateIndex < allItems.count) Qt.callLater(update, updateIndex);
    }

    function compileSortRole() {
        sortOps = [ ];
        if (typeof(sortRole) === 'string') {
            if (sortRole) {
                sortOps.push( {
                        sortRole: sortRole,
                        sortOrder: sortOrder,
                        sortCaseSensitivity: sortCaseSensitivity
                     } );

                return;
            }
        }

        if (!sortRole.length) {
            console.warn("sortRole needs to be a string or an array");
            return;
        }

        for (let _sortRole of sortRole ) {
            if (typeof(_sortRole) === 'string') {
                let _op = {
                    sortRole: _sortRole,
                    sortOrder: sortOrder,
                    sortCaseSensitivity: sortCaseSensitivity
                };
                sortOps.push( _op );
                continue;
            }
            let op = _sortRole;
            _sortRole = op.sortRole;
            if (!_sortRole) continue;
            let _op = {
                sortRole: _sortRole,
                sortOrder: ("sortOrder" in op) ? op.sortOrder : sortOrder,
                sortCaseSensitivity: ("sortCaseSensitivity" in op) ? op.sortCaseSensitivity : sortCaseSensitivity
            };
            sortOps.push( _op );
        }
    }

    function findInsertIndex(item, head, tail, compareFunc) {
        if (head >= count) return head;
        let cmp = compareFunc(item, _visibleItems.get(head).model);
        if (cmp <= 0) return head;
        cmp = compareFunc(item, _visibleItems.get(tail).model);
        if (cmp === 0) return tail;
        if (cmp > 0) return tail + 1;
        while (head + 1 < tail) {
            let mid = (head + tail) >> 1;
            cmp = compareFunc(item, _visibleItems.get(mid).model);
            if (cmp === 0) return mid;
            if (cmp > 0) head = mid; else tail = mid;
        }
        return tail;
    }

    function sort(startIndex) {
        startIndex = startIndex ?? 0;
        if (startIndex < 0) return;
        if (startIndex >= _visibleItems.count) {
            sortIndex = _visibleItems.count;
            return;
        }
        sortIndex = startIndex;
        if (sortIndex === 0) {
            compileSortRole();
        }
        if (!sortOps.length) {
            sortIndex = _visibleItems.count;
            return;
        }
        for (let ts = Date.now(); sortIndex < _visibleItems.count && Date.now() < ts + 50; sortIndex++) {
            if (!sortIndex) continue;
            let newIndex = findInsertIndex(_visibleItems.get(sortIndex).model, 0, sortIndex - 1, sortCompare || defaultSortCompare);
            if (newIndex === sortIndex) continue;
            _visibleItems.move(sortIndex, newIndex, 1);
        }
        if (sortIndex < _visibleItems.count) Qt.callLater(sort, sortIndex);
    }

    function naturalExpand(str) {
        return str.replace(/\d+/g, n => n.padStart(8, "0"));
    }

    function naturalCompare(a, b) {
        return naturalExpand(a).localeCompare(naturalExpand(b));
    }

    function defaultSortCompare(a, b) {
        let cmp = 0;
        for (let sortOp of sortOps) {
            let sortRole = sortOp.sortRole;
            let sortCaseSensitivity = sortOp.sortCaseSensitivity;
            let valueA = a[sortRole];
            let valueB = b[sortRole];
            if (typeof(valueA) === 'string' && typeof(valueB) === 'string') {
                if (sortCaseSensitivity === Qt.CaseInsensitive) {
                    cmp = naturalCompare(valueA.toLowerCase(), valueB.toLowerCase());
                } else {
                    let expandA = naturalExpand(valueA);
                    let expandB = naturalExpand(valueB);
                    cmp = (expandA === expandB)  ? 0 : (expandA < expandB) ? -1 : 1;
                }
            } else {
                cmp = valueA - valueB;
            }
            if (cmp) return sortOp.sortOrder === Qt.DescendingOrder ? -cmp : cmp;
        }
        return 0;
    }

    Component.onCompleted: Qt.callLater(update)
}
