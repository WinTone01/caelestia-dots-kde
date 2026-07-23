import QtQuick

Item {
    id: manager

    property bool isGlobalDragging: false
    property string globalDragSourceList: ""
    property int globalDragSourceIndex: -1
    property string globalDragHoveredList: ""

    property var models: ({})
    property Item dragParent: null

    function getModel(name) {
        return models[name];
    }

    function clearPlaceholders() {
        for (let key in models) {
            let model = models[key];
            for (let i = model.count - 1; i >= 0; i--) {
                if (model.get(i).isPlaceholder) {
                    model.remove(i);
                }
            }
        }
    }
}
