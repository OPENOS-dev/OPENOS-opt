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

#include "iconloader.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>

size_t qHash(const IconLoader::CacheKey& k, size_t seed) noexcept {
    return qHashMulti(seed, k.name, k.size, k.ctx);
}

IconLoader::IconLoader(QObject* parent)
    : QObject(parent), m_searchPaths(defaultSearchPaths()) {}

QStringList IconLoader::defaultSearchPaths() {
    return {
        QStringLiteral("/usr/share/icons"),
        QStringLiteral("/usr/local/share/icons"),
        QDir::homePath() + QStringLiteral("/.local/share/icons"),
    };
}

void IconLoader::setTheme(const QString& t) {
    if (m_theme == t) return;
    m_theme = t;
    clearCache();
    emit themeChanged();
}

void IconLoader::clearCache() {
    m_cache.clear();
}

/* freedesktop 算法简化版:
 * 1. 优先 scalable/<ctx>/<name>.svg (矢量任意尺寸)
 * 2. 否则 <S>x<S>/<ctx>/<name>.svg, 找尺寸最接近的 */
QString IconLoader::findInTheme(const QString& theme, const QString& name,
                                int size, const QString& ctx) const {
    for (const QString& base : m_searchPaths) {
        const QString root = base + QLatin1Char('/') + theme;

        /* 1. scalable: 矢量优先 */
        if (ctx.isEmpty()) {
            QDir scalable(root + QStringLiteral("/scalable"));
            if (scalable.exists()) {
                for (const QString& sub :
                     scalable.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
                    const QString p = scalable.filePath(sub) + QLatin1Char('/')
                                      + name + QStringLiteral(".svg");
                    if (QFile::exists(p)) return p;
                }
            }
        } else {
            const QString p = root + QStringLiteral("/scalable/") + ctx
                              + QLatin1Char('/') + name + QStringLiteral(".svg");
            if (QFile::exists(p)) return p;
        }

        /* 2. 固定尺寸目录 */
        QDir d(root);
        if (!d.exists()) continue;
        const QStringList dirs = d.entryList(QStringList() << QStringLiteral("*x*"),
                                             QDir::Dirs | QDir::NoDotAndDotDot);
        int bestDelta = INT_MAX;
        QString best;
        for (const QString& sdir : dirs) {
            const QStringList parts = sdir.split(QLatin1Char('x'));
            if (parts.size() != 2) continue;
            bool ok = false;
            int s = parts[0].toInt(&ok);
            if (!ok || s <= 0) continue;
            int delta = qAbs(s - size);
            if (delta > bestDelta) continue;
            QString p = root + QLatin1Char('/') + sdir + QLatin1Char('/');
            if (!ctx.isEmpty()) p += ctx + QLatin1Char('/');
            p += name + QStringLiteral(".svg");
            if (QFile::exists(p)) {
                bestDelta = delta;
                best = p;
            }
        }
        if (!best.isEmpty()) return best;
    }
    return {};
}

QStringList IconLoader::inheritsChain(const QString& theme) const {
    QStringList chain;
    for (const QString& base : m_searchPaths) {
        const QString idx = base + QLatin1Char('/') + theme
                            + QStringLiteral("/index.theme");
        if (!QFile::exists(idx)) continue;
        QSettings s(idx, QSettings::IniFormat);
        s.beginGroup(QStringLiteral("Icon Theme"));
        const QStringList inh = s.value(QStringLiteral("Inherits"))
                                    .toString()
                                    .split(QLatin1Char(','),
                                           Qt::SkipEmptyParts);
        for (const QString& t : inh) {
            if (!chain.contains(t)) chain << t;
        }
        s.endGroup();
        break;
    }
    return chain;
}

QString IconLoader::path(const QString& name, int size,
                         const QString& ctx) const {
    if (name.isEmpty()) return {};

    const CacheKey key{name, size, ctx};
    auto it = m_cache.constFind(key);
    if (it != m_cache.cend()) return it.value();

    QString result = findInTheme(m_theme, name, size, ctx);
    if (result.isEmpty()) {
        for (const QString& t : inheritsChain(m_theme)) {
            result = findInTheme(t, name, size, ctx);
            if (!result.isEmpty()) break;
        }
    }
    m_cache.insert(key, result);
    return result;
}

QUrl IconLoader::url(const QString& name, int size, const QString& ctx,
                     const QString& color) const {
    const QString p = path(name, size, ctx);
    if (p.isEmpty()) return {};
    /* image://icons/<absolute-path>?size=&color=
     * IconProvider 接管 SVG 渲染 + 着色 */
    QUrl u;
    u.setScheme(QStringLiteral("image"));
    u.setHost(QStringLiteral("icons"));
    u.setPath(p);
    QUrlQuery q;
    q.addQueryItem(QStringLiteral("size"), QString::number(size));
    if (!color.isEmpty()) q.addQueryItem(QStringLiteral("color"), color);
    u.setQuery(q);
    return u;
}

QString IconLoader::resolve(const QString& desktopIcon) const {
    if (desktopIcon.isEmpty()) return {};
    if (desktopIcon.startsWith(QLatin1Char('/'))) {
        /* 绝对路径: 取 basename 去扩展名作为图标名 */
        QFileInfo fi(desktopIcon);
        return fi.completeBaseName();
    }
    return desktopIcon;
}
