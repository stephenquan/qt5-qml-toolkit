import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQml.Models 2.12

DelegateModel {
    property var filter: null
    readonly property bool running: !filtered
    readonly property bool filtered: updateIndex >= allItems.count
    readonly property int progress: filtered ? 100 : Math.floor(100 * updateIndex / allItems.count)
    property int updateIndex: 0
    onFilterChanged: Qt.callLater(update)
    groups: [
        DelegateModelGroup {
            id: allItems
            name: "all"
            includeByDefault: true
            onCountChanged: {
                if (updateIndex > allItems.count) updateIndex = allItems.count;
                if (updateIndex < allItems.count) Qt.callLater(update, updateIndex);
            }
        },
        DelegateModelGroup {
            id: visibleItems
            name: "visible"
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
            allItems.setGroups(0, allItems.count, [ "all" ] );
        }
        for (let ts = Date.now(); updateIndex < allItems.count && Date.now() < ts + 50; updateIndex++) {
            let visible = !filter || filter(allItems.get(updateIndex).model);
            if (!visible) continue;
            allItems.setGroups(updateIndex, 1, [ "all", "visible" ]);
        }
        if (updateIndex < allItems.count) Qt.callLater(update, updateIndex);
    }

    Component.onCompleted: Qt.callLater(update)
}
