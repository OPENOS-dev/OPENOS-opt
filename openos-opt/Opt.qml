import QtQuick 2.15
import QtQuick.Window 2.15

/* openos-opt — 包管理 App (独立进程)
 * 后端列表 + 安装/卸载/更新 (生产: 调用 opt 命令)
 */
Window {
    id: optApp
    width: 560; height: 440
    flags: Qt.FramelessWindowHint
    title: "软件包管理"
    color: OpenUI.background

    Column {
        anchors.fill: parent; anchors.margins: OpenUI.sp4; spacing: OpenUI.sp3

        Row { width: parent.width
            Column { width: parent.width - 60
                Text { text: "软件包管理"; color: OpenUI.onSurface
                       font.pixelSize: OpenUI.typeHeadlineM; font.bold: true }
                Text { text: "opt 统一包管理前端"; color: OpenUI.onSurfaceVariant
                       font.pixelSize: OpenUI.typeLabelL }
            }
            Rectangle { width: 32; height: 32; radius: OpenUI.shapeXs
                color: hover.hovered ? Qt.rgba(OpenUI.error.r, OpenUI.error.g,
                                               OpenUI.error.b, 0.3) : "transparent"
                Text { anchors.centerIn: parent; text: "\u2715"; color: OpenUI.onSurface }
                MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true
                    onClicked: optApp.close() }
            }
        }

        // 后端卡片
        Rectangle { width: parent.width; height: 64; radius: OpenUI.shapeSm
            color: Qt.rgba(OpenUI.surfaceBright.r, OpenUI.surfaceBright.g,
                           OpenUI.surfaceBright.b, 0.4)
            Row { anchors.fill: parent; anchors.margins: OpenUI.sp3; spacing: OpenUI.sp2
                Text { width: 30; height: parent.height; verticalAlignment: Text.AlignVCenter
                       text: "\u2630"; color: OpenUI.primary; font.pixelSize: 18 }
                Column { width: parent.width - 130; height: parent.height; spacing: 2
                    verticalAlignment: Text.AlignVCenter
                    Text { text: "apt"; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeTitle; font.bold: true }
                    Text { text: "已安装 (内置)"; color: OpenUI.primary; font.pixelSize: OpenUI.typeLabelM }
                }
                Rectangle { width: 90; height: 30; radius: OpenUI.shapeXs; anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.2)
                    Text { anchors.centerIn: parent; text: "检查更新"; color: OpenUI.primary
                           font.pixelSize: OpenUI.typeLabelM }
                    MouseArea { anchors.fill: parent; hoverEnabled: true
                        onClicked: console.log("opt: update apt") }
                }
            }
        }

        Row { spacing: OpenUI.sp2
            Repeater { model: ListModel {
                ListElement { label: "安装软件"; icon: "\u2715" }
                ListElement { label: "卸载";     icon: "\u2212" }
                ListElement { label: "搜索";     icon: "\u2315" }
            }
            Rectangle { width: 110; height: 36; radius: OpenUI.shapeXs
                color: Qt.rgba(OpenUI.primary.r, OpenUI.primary.g, OpenUI.primary.b, 0.2)
                Row { anchors.centerIn: parent; spacing: 4
                    Text { text: model.icon; color: OpenUI.primary }
                    Text { text: model.label; color: OpenUI.primary; font.pixelSize: OpenUI.typeLabelM }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: {} }
            } }
        }

        Rectangle { width: parent.width; height: parent.height - 170; radius: OpenUI.shapeSm
            color: Qt.rgba(OpenUI.surfaceBright.r, OpenUI.surfaceBright.g,
                           OpenUI.surfaceBright.b, 0.3)
            Text { anchors.centerIn: parent; text: "软件列表\n(生产: 经 opt 查询已装包)"
                   color: OpenUI.onSurfaceDisabled; font.pixelSize: OpenUI.typeLabelM
                   horizontalAlignment: Text.AlignHCenter }
        }
    }
}
