import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQml.Models 2.12

DelegateModel {
    property var filter: null
    readonly property bool running: updating || sorting
    readonly property int updateIndex: internal.updateIndex
    readonly property bool updated: internal.updateIndex >= allItems.count
    readonly property bool updating: !updated
    readonly property int progress: updating
    ? Math.floor(50 * internal.updateIndex / allItems.count)
    : sorting ? Math.floor(50 + 50 * internal.sortIndex / _visibleItems.count)
              : 0
    property int sortOrder: Qt.AscendingOrder
    property int sortCaseSensitivity: Qt.CaseInsensitive
    property var sortRole: ""
    property var sortCompare: null
    readonly property  int sortIndex: internal.sortIndex
    readonly property bool sorted: internal.sortIndex >= _visibleItems.count
    readonly property bool sorting: !sorted
    readonly property alias visibleItems: _visibleItems
    property QtObject internal: QtObject {
        property int updateIndex: 0
        property int sortIndex: 0
        property var sortOps: [ ]
    }
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
                if (internal.updateIndex > allItems.count) internal.updateIndex = allItems.count;
                if (internal.updateIndex < allItems.count) Qt.callLater(update);
            }
        },
        DelegateModelGroup {
            id: _visibleItems
            name: "visible"
            onCountChanged: {
                if (internal.sortIndex > _visibleItems.count) internal.sortIndex = 0;
                if (internal.sortIndex < _visibleItems.count) Qt.callLater(sort);
            }
        }
    ]
    filterOnGroup: "visible"

    function update(startIndex) {
        startIndex = startIndex ?? 0;
        if (startIndex < 0) startIndex = 0;
        if (startIndex >= allItems.count) {
            internal.updateIndex = allItems.count;
            return;
        }
        internal.updateIndex = startIndex;
        if (internal.updateIndex === 0) {
            internal.sortIndex = 0;
            compileSortRole();
            allItems.setGroups(0, allItems.count, [ "all" ] );
        }
        for (let ts = Date.now(); internal.updateIndex < allItems.count && Date.now() < ts + 50; internal.updateIndex++) {
            let visible = !filter || filter(allItems.get(internal.updateIndex).model);
            if (!visible) continue;
            allItems.setGroups(internal.updateIndex, 1, [ "all", "visible" ]);
        }
        if (internal.updateIndex < allItems.count) Qt.callLater(update, internal.updateIndex);
    }

    function compileSortRole() {
        internal.sortOps = [ ];
        if (typeof(sortRole) === 'string') {
            if (sortRole) {
                internal.sortOps.push( {
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
                internal.sortOps.push( _op );
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
            internal.sortOps.push( _op );
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
            internal.sortIndex = _visibleItems.count;
            return;
        }
        internal.sortIndex = startIndex;
        if (internal.sortIndex === 0) {
            compileSortRole();
        }
        if (!internal.sortOps.length) {
            internal.sortIndex = _visibleItems.count;
            return;
        }
        for (let ts = Date.now(); internal.sortIndex < _visibleItems.count && Date.now() < ts + 50; internal.sortIndex++) {
            if (!internal.sortIndex) continue;
            let newIndex = findInsertIndex(_visibleItems.get(internal.sortIndex).model, 0, internal.sortIndex - 1, sortCompare || defaultSortCompare);
            if (newIndex === internal.sortIndex) continue;
            _visibleItems.move(internal.sortIndex, newIndex, 1);
        }
        if (internal.sortIndex < _visibleItems.count) Qt.callLater(sort, internal.sortIndex);
    }

    function naturalExpand(str) {
        return str.replace(/\d+/g, n => n.padStart(8, "0"));
    }

    function naturalCompare(a, b) {
        return naturalExpand(a).localeCompare(naturalExpand(b));
    }

    function defaultSortCompare(a, b) {
        let cmp = 0;
        for (let sortOp of internal.sortOps) {
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
