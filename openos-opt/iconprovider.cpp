#include "iconprovider.h"

#include <QFile>
#include <QPainter>
#include <QSvgRenderer>
#include <QUrlQuery>

/* id 是 QUrl.path() 已 decode, 形如:
 *   /usr/share/icons/OpenOS/scalable/panel/audio-volume-high.svg
 * QUrl 可能前导 '/' 丢失 (取决于 host 解析), 兜底补 '/' */
QImage IconProvider::requestImage(const QString& id, QSize* size,
                                  const QSize& requestedSize,
                                  const QUrlQuery& query) {
    QString p = id;
    if (!p.startsWith(QLatin1Char('/'))) p.prepend(QLatin1Char('/'));

    QFile f(p);
    if (!f.open(QIODevice::ReadOnly)) return {};
    QSvgRenderer renderer(f.readAll());
    if (!renderer.isValid()) return {};

    /* 优先 query.size, 否则 requestedSize, 否则默认 24 */
    int req = 24;
    bool ok = false;
    int qsize = query.queryItemValue(QStringLiteral("size")).toInt(&ok);
    if (ok && qsize > 0) req = qsize;
    else if (requestedSize.isValid() && requestedSize.width() > 0)
        req = requestedSize.width();

    QImage img(req, req, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    QPainter painter(&img);
    painter.setRenderHint(QPainter::Antialiasing, true);
    renderer.render(&painter);
    painter.end();

    /* 着色: SVG alpha 当 mask, 用 color 整体替换
     * color 为空则保留 SVG 原色 (彩色 logo 等) */
    const QString color = query.queryItemValue(QStringLiteral("color"));
    if (!color.isEmpty()) {
        const QColor c(color);
        if (c.isValid()) {
            QPainter p2(&img);
            p2.setCompositionMode(QPainter::CompositionMode_SourceIn);
            p2.fillRect(img.rect(), c);
        }
    }

    if (size) *size = img.size();
    return img;
}
