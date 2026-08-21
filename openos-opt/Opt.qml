import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/* openos-opt — Pacman GUI 前端
 * 提供已安装包列表、搜索、更新检查、包详情等功能的图形化 pacman 前端。 */
Window {
    id: app
    width: 720; height: 520
    flags: Qt.FramelessWindowHint
    title: "软件包管理器"
    color: OpenUI.background

    // ---- 状态 ----
    property string currentTab: "installed"
    property string selectedPkg: ""
    property bool showDetails: false
    property bool showConfirm: false
    property string confirmAction: ""
    property string confirmPkg: ""

    // ---- 组件 ----
    PacmanBridge { id: pacman }

    // ---- 信号连接 ----
    Connections {
        target: pacman
        function onInstalledListReady(pkgs) { installedModel.clear(); for (var i=0; i<pkgs.length; i++) installedModel.append(pkgs[i]); }
        function onSearchResultsReady(pkgs) { searchModel.clear(); for (var i=0; i<pkgs.length; i++) searchModel.append(pkgs[i]); }
        function onUpdatesAvailable(updates) { updateModel.clear(); for (var i=0; i<updates.length; i++) updateModel.append(updates[i]); }
        function onPackageInfoReady(info) { detailModel.clear(); for (var key in info) detailModel.append({key: key, value: info[key]}); }
        function onOperationFinished(success, msg) { statusText = msg; statusColor = success ? "#4CAF50" : "#F44336"; if (success) { showDetails = false; showConfirm = false; } }
        function onError(msg) { statusText = "错误: " + msg; statusColor = "#F44336"; }
    }

    // ---- 数据模型 ----
    ListModel { id: installedModel }
    ListModel { id: searchModel }
    ListModel { id: updateModel }
    ListModel { id: detailModel }

    // ---- 状态文本 ----
    property string statusText: "就绪"
    property color statusColor: OpenUI.onSurfaceVariant

    Component.onCompleted: pacman.refreshInstalled()

    // ---- 主布局 ----
    Rectangle { anchors.fill: parent; color: OpenUI.background; clip: true

        ColumnLayout { anchors.fill: parent; spacing: 0

            // ---- 标题栏 ----
            Rectangle { Layout.fillWidth: true; height: 48; color: OpenUI.surface
                RowLayout { anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 8; spacing: 8
                    Text { text: "软件包管理器"; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeHeadlineM; font.bold: true }
                    Item { Layout.fillWidth: true }
                    // 进度指示
                    BusyIndicator { running: pacman.busy; visible: pacman.busy; Layout.preferredWidth: 20; Layout.preferredHeight: 20 }
                    Text { text: pacman.progressText; visible: pacman.busy; color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelM }
                    // 关闭按钮
                    Rectangle { width: 32; height: 32; radius: OpenUI.shapeXs
                        color: closeBtn.hovered ? Qt.rgba(OpenUI.error.r, OpenUI.error.g, OpenUI.error.b, 0.2) : "transparent"
                        Text { anchors.centerIn: parent; text: "\u2715"; color: OpenUI.onSurface }
                        MouseArea { id: closeBtn; anchors.fill: parent; hoverEnabled: true; onClicked: app.close() }
                    }
                }
            }

            // ---- 标签栏 ----
            Rectangle { Layout.fillWidth: true; height: 40; color: OpenUI.surfaceDim
                Row { anchors.centerIn: parent; spacing: 4
                    Repeater { model: [
                        { label: "已安装", key: "installed" },
                        { label: "搜索", key: "search" },
                        { label: "更新", key: "updates" }
                    ]
                    Rectangle { width: 100; height: 32; radius: OpenUI.shapeXs
                        color: currentTab == model.key ? Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.25) : "transparent"
                        Text { anchors.centerIn: parent; text: model.label; color: currentTab == model.key ? OpenUI.primary : OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelL }
                        MouseArea { anchors.fill: parent; onClicked: { currentTab = model.key; showDetails = false; } }
                    } }
                }
            }

            // ---- 内容区 ----
            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: OpenUI.background
                RowLayout { anchors.fill: parent; spacing: 0; visible: !showDetails || !selectedPkg

                    // 包列表
                    Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: OpenUI.background; Layout.rightMargin: showDetails ? 1 : 0
                        ColumnLayout { anchors.fill: parent; spacing: 4; anchors.margins: 8
                            // 搜索/筛选栏
                            Rectangle { Layout.fillWidth: true; height: 36; radius: OpenUI.shapeXs; color: OpenUI.surface
                                RowLayout { anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 4; spacing: 4
                                    Text { text: "\u2315"; color: OpenUI.onSurfaceVariant; font.pixelSize: 16 }
                                    TextInput { id: filterInput; Layout.fillWidth: true; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeBodyM
                                        placeholderText: currentTab == "installed" ? "筛选已安装包..." : "搜索包名..."
                                        onTextChanged: { if (currentTab == "search" && text.length >= 2) pacman.searchPackages(text); }
                                    }
                                    // 操作按钮
                                    Rectangle { width: 80; height: 28; radius: OpenUI.shapeXs; visible: currentTab == "installed"
                                        color: refreshBtn.hovered ? Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.3) : Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.15)
                                        Text { anchors.centerIn: parent; text: "刷新"; color: OpenUI.primary; font.pixelSize: OpenUI.typeLabelM }
                                        MouseArea { id: refreshBtn; anchors.fill: parent; hoverEnabled: true; onClicked: pacman.refreshInstalled() }
                                    }
                                    Rectangle { width: 80; height: 28; radius: OpenUI.shapeXs; visible: currentTab == "updates"
                                        color: updateBtn.hovered ? Qt.rgba(OpenUI.error.r, OpenUI.error.g, OpenUI.error.b, 0.3) : Qt.rgba(OpenUI.error.r, OpenUI.error.g, OpenUI.error.b, 0.15)
                                        Text { anchors.centerIn: parent; text: "全部更新"; color: OpenUI.error; font.pixelSize: OpenUI.typeLabelM }
                                        MouseArea { id: updateBtn; anchors.fill: parent; hoverEnabled: true; onClicked: { confirmAction = "update"; confirmPkg = ""; showConfirm = true; } }
                                    }
                                    Rectangle { width: 40; height: 28; radius: OpenUI.shapeXs; visible: currentTab == "search"
                                        color: searchBtn.hovered ? Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.3) : Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.15)
                                        Text { anchors.centerIn: parent; text: "\u2315"; color: OpenUI.primary; font.pixelSize: 16 }
                                        MouseArea { id: searchBtn; anchors.fill: parent; hoverEnabled: true; onClicked: { if (filterInput.text.length >= 2) pacman.searchPackages(filterInput.text); } }
                                    }
                                }
                            }

                            // 包列表视图
                            ListView { id: pkgList; Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                model: currentTab == "installed" ? installedModel : currentTab == "search" ? searchModel : updateModel
                                boundsBehavior: Flickable.StopAtBounds
                                delegate: Rectangle { width: pkgList.width; height: 44; radius: OpenUI.shapeXs
                                    color: ListView.isCurrentItem ? Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.15) : "transparent"
                                    border.color: "transparent"
                                    RowLayout { anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 4; spacing: 8
                                        ColumnLayout { Layout.fillWidth: true; spacing: 2
                                            Text { text: model.name; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeTitle; font.bold: true; elide: Text.ElideRight }
                                            Text { text: model.version || model.description || ""; color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelS; elide: Text.ElideRight }
                                        }
                                        Text { text: model.new_version ? model.new_version : ""; visible: model.new_version; color: OpenUI.primary; font.pixelSize: OpenUI.typeLabelM }
                                        Rectangle { width: 64; height: 28; radius: OpenUI.shapeXs; visible: currentTab == "installed" && !pacman.busy
                                            color: delBtn.hovered ? Qt.rgba(OpenUI.error.r, OpenUI.error.g, OpenUI.error.b, 0.3) : Qt.rgba(OpenUI.error.r, OpenUI.error.g, OpenUI.error.b, 0.15)
                                            Text { anchors.centerIn: parent; text: "卸载"; color: OpenUI.error; font.pixelSize: OpenUI.typeLabelS }
                                            MouseArea { id: delBtn; anchors.fill: parent; hoverEnabled: true
                                                onClicked: { confirmAction = "remove"; confirmPkg = model.name; showConfirm = true; } }
                                        }
                                        Rectangle { width: 64; height: 28; radius: OpenUI.shapeXs; visible: currentTab == "search" && !pacman.busy
                                            color: instBtn.hovered ? Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.3) : Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.15)
                                            Text { anchors.centerIn: parent; text: "安装"; color: OpenUI.primary; font.pixelSize: OpenUI.typeLabelS }
                                            MouseArea { id: instBtn; anchors.fill: parent; hoverEnabled: true
                                                onClicked: { confirmAction = "install"; confirmPkg = model.name; showConfirm = true; } }
                                        }
                                        Rectangle { width: 64; height: 28; radius: OpenUI.shapeXs; visible: currentTab == "updates" && !pacman.busy
                                            color: upBtn.hovered ? Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.3) : Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.15)
                                            Text { anchors.centerIn: parent; text: "更新"; color: OpenUI.primary; font.pixelSize: OpenUI.typeLabelS }
                                            MouseArea { id: upBtn; anchors.fill: parent; hoverEnabled: true
                                                onClicked: { confirmAction = "install"; confirmPkg = model.name; showConfirm = true; } }
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton
                                        onClicked: { pkgList.currentIndex = index; selectedPkg = model.name; pacman.getPackageInfo(model.name); showDetails = true; }
                                    }
                                }
                                Text { anchors.centerIn: parent; visible: pkgList.count == 0 && !pacman.busy
                                    text: currentTab == "installed" ? "暂无已安装包" : currentTab == "search" ? "输入包名搜索" : "没有可用更新"
                                    color: OpenUI.onSurfaceDisabled; font.pixelSize: OpenUI.typeBodyM }
                            }
                        }
                    }

                    // 详情面板分隔线
                    Rectangle { width: 1; Layout.fillHeight: true; visible: showDetails; color: OpenUI.outlineVariant }
                }

                // ---- 详情面板 ----
                Rectangle { x: showDetails ? parent.width * 0.55 : parent.width; width: parent.width * 0.45; height: parent.height; color: OpenUI.surface
                    Behavior on x { NumberAnimation { duration: OpenUI.dur200; easing.type: Easing.OutCubic } }
                    clip: true
                    ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
                        Text { text: selectedPkg; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeHeadlineM; font.bold: true }
                        Rectangle { Layout.fillWidth: true; height: 1; color: OpenUI.outlineVariant }
                        ListView { Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: detailModel
                            delegate: RowLayout { width: parent.width; spacing: 8; height: 28
                                Text { text: model.key; Layout.preferredWidth: 120; color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelM; elide: Text.ElideRight }
                                Text { text: model.value; Layout.fillWidth: true; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeLabelM; wrapMode: Text.WordWrap }
                            }
                        }
                        Text { visible: detailModel.count == 0; text: "加载中..."; color: OpenUI.onSurfaceDisabled; font.pixelSize: OpenUI.typeBodyM; Layout.alignment: Qt.AlignHCenter }
                        // 操作按钮
                        RowLayout { Layout.fillWidth: true; spacing: 8; visible: !pacman.busy
                            Rectangle { Layout.fillWidth: true; height: 36; radius: OpenUI.shapeXs
                                color: instBtn2.hovered ? Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.3) : Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.15)
                                Text { anchors.centerIn: parent; text: "安装"; color: OpenUI.primary; font.pixelSize: OpenUI.typeLabelM }
                                MouseArea { id: instBtn2; anchors.fill: parent; hoverEnabled: true; onClicked: { confirmAction = "install"; confirmPkg = selectedPkg; showConfirm = true; } }
                            }
                            Rectangle { Layout.fillWidth: true; height: 36; radius: OpenUI.shapeXs
                                color: delBtn2.hovered ? Qt.rgba(OpenUI.error.r, OpenUI.error.g, OpenUI.error.b, 0.3) : Qt.rgba(OpenUI.error.r, OpenUI.error.g, OpenUI.error.b, 0.15)
                                Text { anchors.centerIn: parent; text: "卸载"; color: OpenUI.error; font.pixelSize: OpenUI.typeLabelM }
                                MouseArea { id: delBtn2; anchors.fill: parent; hoverEnabled: true; onClicked: { confirmAction = "remove"; confirmPkg = selectedPkg; showConfirm = true; } }
                            }
                            Rectangle { width: 32; height: 36; radius: OpenUI.shapeXs
                                color: closeDetail.hovered ? Qt.rgba(OpenUI.onSurface.r, OpenUI.onSurface.g, OpenUI.onSurface.b, 0.15) : "transparent"
                                Text { anchors.centerIn: parent; text: "\u2715"; color: OpenUI.onSurface; font.pixelSize: 14 }
                                MouseArea { id: closeDetail; anchors.fill: parent; hoverEnabled: true; onClicked: showDetails = false; }
                            }
                        }
                    }
                }

                // ---- 确认对话框 ----
                Rectangle { visible: showConfirm; anchors.fill: parent; color: Qt.rgba(0,0,0,0.6)
                    Rectangle { anchors.centerIn: parent; width: 320; height: 160; radius: OpenUI.shapeMd; color: OpenUI.surface; border.color: OpenUI.outlineVariant; border.width: 1
                        ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 16
                            Text { text: confirmAction == "install" ? "确认安装" : confirmAction == "remove" ? "确认卸载" : "确认更新"
                                color: confirmAction == "remove" ? OpenUI.error : OpenUI.onSurface; font.pixelSize: OpenUI.typeTitle; font.bold: true }
                            Text { text: confirmAction == "update" ? "将更新所有可用软件包" : ("将" + (confirmAction == "install" ? "安装" : "卸载") + " " + confirmPkg); color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeBodyM; wrapMode: Text.WordWrap }
                            RowLayout { spacing: 12; Layout.alignment: Qt.AlignRight
                                Rectangle { width: 90; height: 36; radius: OpenUI.shapeXs; color: "transparent"; border.color: OpenUI.outlineVariant; border.width: 1
                                    Text { anchors.centerIn: parent; text: "取消"; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeLabelM }
                                    MouseArea { anchors.fill: parent; onClicked: showConfirm = false; }
                                }
                                Rectangle { width: 90; height: 36; radius: OpenUI.shapeXs; color: confirmAction == "remove" ? Qt.rgba(OpenUI.error.r, OpenUI.error.g, OpenUI.error.b, 0.8) : Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.8)
                                    Text { anchors.centerIn: parent; text: "确认"; color: "white"; font.pixelSize: OpenUI.typeLabelM }
                                    MouseArea { anchors.fill: parent; onClicked: {
                                        showConfirm = false;
                                        if (confirmAction == "install") pacman.installPackage(confirmPkg);
                                        else if (confirmAction == "remove") pacman.removePackage(confirmPkg);
                                        else if (confirmAction == "update") pacman.updateSystem();
                                    } }
                                }
                            }
                        }
                    }
                }
            }

            // ---- 状态栏 ----
            Rectangle { Layout.fillWidth: true; height: 28; color: OpenUI.surface
                Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    text: statusText; color: statusColor; font.pixelSize: OpenUI.typeLabelS }
            }
        }
    }
}