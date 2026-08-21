#pragma once
/* SVG 图标 ImageProvider — 加载 SVG -> 着色 -> 返回光栅
 *
 * QML 用法:
 *   Image { source: OpenUI.icon.url("audio-volume-high", 24, "Panel", "#00BCD4") }
 *
 * 实现细节:
 *   - 用 QSvgRenderer 渲染 SVG (QtSvg 模块)
 *   - color 非空时用 CompositionMode_SourceIn 把 SVG alpha 当 mask 着色
 *     (符合 NUI 单色线条风, 任意语义色即时变色)
 *   - color 为空时保留 SVG 原始填色 (应用彩色 logo)
 */
#include <QQuickAsyncImageProvider>
#include <QImage>

class IconProvider : public QQuickAsyncImageProvider {
public:
    QImage requestImage(const QString& id, QSize* size,
                        const QSize& requestedSize,
                        const QUrlQuery& query) override;
};
