import QtQuick 2.15

QtObject {
    property int sortOrder: Qt.AscendingOrder
    property int sortCaseSensitivity: Qt.CaseInsensitive
    property var sortRole: ""
    property var sortCompare: null
    property var sortOps: [ ]
    property int sortIndex: 0
    readonly property bool sorted: countFunc ? sortIndex >= countFunc() : true
    readonly property bool running: !sorted
    readonly property int progress: countFunc && countFunc()
              ? Math.floor(100 * sortIndex / countFunc())
              : 100
    property var getFunc: null
    property var countFunc: null
    property var moveFunc: null
    onSortOrderChanged: Qt.calllater(sort)
    onSortCaseSensitivityChanged: Qt.callLater(sort)
    onSortRoleChanged: Qt.callLater(sort)
    onSortCompareChanged: Qt.callLater(sort)

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
        let cmp = compareFunc(item, getFunc(head));
        if (cmp <= 0) return head;
        cmp = compareFunc(item, getFunc(tail));
        if (cmp === 0) return tail;
        if (cmp > 0) return tail + 1;
        while (head + 1 < tail) {
            let mid = (head + tail) >> 1;
            cmp = compareFunc(item, getFunc(mid));
            if (cmp === 0) return mid;
            if (cmp > 0) head = mid; else tail = mid;
        }
        return tail;
    }

    function sort(startIndex) {
        if (!getFunc || !countFunc || !moveFunc) return;
        startIndex = startIndex ?? 0;
        if (startIndex < 0) return;
        if (startIndex >= countFunc()) {
            sortIndex = countFunc();
            return;
        }
        sortIndex = startIndex;
        if (sortIndex === 0) {
            compileSortRole();
        }
        if (!sortOps.length) {
            sortIndex = countFunc();
            return;
        }
        for (let ts = Date.now(); sortIndex < countFunc() && Date.now() < ts + 50; sortIndex++) {
            if (!sortIndex) continue;
            let newIndex = findInsertIndex(getFunc(sortIndex), 0, sortIndex - 1, sortCompare || defaultSortCompare);
            if (newIndex === sortIndex) continue;
            moveFunc(sortIndex, newIndex, 1);
        }
        if (sortIndex < countFunc()) Qt.callLater(sort, sortIndex);
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

    function sortArray(arr) {
        arr.sort(sortCompare || defaultSortCompare);
    }
}
