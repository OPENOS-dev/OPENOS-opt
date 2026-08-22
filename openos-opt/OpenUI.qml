/*
 * Copyright (C) 2026 OPENOS-dev
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the OPENOS-PROJECT-LICENSE (OPL) v1.2.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * OPL for more details.
 *
 * You should have received a copy of the OPL along with this program.
 * If not, see <https://github.com/OPENOS-dev/OPL>.
 */

import QtQml 2.15

/* OPENUI 设计令牌 (QML 版) — 与 src/openui.h 一一对应
 * 合成器用 C 令牌渲染, 外壳用此 QML 令牌渲染, 保证视觉一致。
 * 由 main.cpp 实例化并注入为 context 属性 "OpenUI", 供各 QML 直接使用。
 */
QtObject {
    // ---- 中性色板 (20 层表面色) ----
    readonly property color neutral0:  "#090909"
    readonly property color neutral10: "#141414"
    readonly property color neutral20: "#1C1C1C"
    readonly property color neutral30: "#252525"
    readonly property color neutral40: "#2D2D2D"
    readonly property color neutral50: "#363636"
    readonly property color neutral60: "#3F3F3F"
    readonly property color neutral70: "#484848"
    readonly property color neutral80: "#515151"
    readonly property color neutral90: "#5B5B5B"
    readonly property color neutral200:"#F5F5F5"

    // ---- 语义色彩 (MD3) ----
    readonly property color primary:        "#00BCD4"
    readonly property color onPrimary:      "#001014"
    readonly property color primaryContainer:"#006A7A"
    readonly property color onPrimaryContainer: "#C9F5FF"
    readonly property color secondary:      "#6EB3C0"
    readonly property color tertiary:       "#9FC85F"
    readonly property color error:          "#F44336"
    readonly property color onError:        "#FFFFFF"

    // ---- 表面 / 背景 ----
    readonly property color background: "#090909"
    readonly property color surface:   "#141414"
    readonly property color surfaceDim: "#0F0F0F"
    readonly property color surfaceBright: "#1F1F1F"
    readonly property color surface6:   "#3F3F3F"

    // ---- 文本 ----
    readonly property color onSurface:        "#F5F5F5"
    readonly property color onSurfaceVariant: "#B0B0B0"
    readonly property color onSurfaceDisabled:"#707070"
    readonly property color outline:          "#8D8D8D"
    readonly property color outlineVariant:   "#484848"

    // ---- 形状 (px) ----
    // 圆角加大 (更柔和现代): 基础组件 8, 卡片/菜单 12, 对话框 16, 浮窗 24
    readonly property int shapeNone: 0
    readonly property int shapeXs: 8
    readonly property int shapeSm: 12
    readonly property int shapeMd: 16
    readonly property int shapeLg: 24
    readonly property int shapeFull: 9999

    // ---- 动效 (ms) ----
    readonly property int dur50: 50
    readonly property int dur100: 100
    readonly property int dur150: 150
    readonly property int dur200: 200
    readonly property int dur250: 250
    readonly property int dur300: 300
    readonly property int dur400: 400
    readonly property int dur500: 500

    // ---- 间距网格 (4dp) ----
    readonly property int sp1: 4
    readonly property int sp2: 8
    readonly property int sp3: 12
    readonly property int sp4: 16
    readonly property int sp6: 24
    readonly property int sp8: 32

    // ---- 排印 (px, MD3 type scale) ----
    readonly property int typeDisplayM: 45
    readonly property int typeHeadlineM: 28
    readonly property int typeTitle: 16
    readonly property int typeBodyM: 14
    readonly property int typeLabelL: 14
    readonly property int typeLabelM: 12
    readonly property int typeLabelS: 11

    // ---- 面板 ----
    readonly property int panelHeight: 32
    readonly property int taskButtonH: 24
    readonly property int wsCapsuleW: 16
    readonly property int wsCapsuleH: 4
    readonly property int wsGap: 4

    // ---- 状态层叠 alpha ----
    readonly property double hoverAlpha: 0.12
    readonly property double focusAlpha: 0.15
    readonly property double pressedAlpha: 0.15

    // ---- 毛玻璃透明度 (表面 alpha, 越高越透明, 让合成器模糊更明显) ----
    readonly property double glassPanelAlpha: 0.72
    readonly property double glassCardAlpha: 0.75
    readonly property double glassMenuAlpha: 0.78
    readonly property double glassTaskAlpha: 0.30
}
