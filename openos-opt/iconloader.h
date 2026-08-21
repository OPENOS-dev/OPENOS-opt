#pragma once
/* OpenUI 图标加载器 — freedesktop 图标主题查找 (C++)
 *
 * 查找顺序:
 *   1. 当前主题 (OpenOS) 按 Context + Size 匹配
 *   2. 主题 Inherits 链递归 (OpenOS -> hicolor)
 *   3. 用户 ~/.local/share/icons 同名主题
 *   4. 全失败 -> 返回空, QML 侧回退到 Unicode 字符 (NUI)
 *
 * QML 用法 (经 context property "OpenUI.icon"):
 *   OpenUI.icon.url("audio-volume-high", 24, "Panel", "#00BCD4")
 *   OpenUI.icon.path("system-power", 16, "Actions")
 *   OpenUI.icon.resolve(desktopIconField)
 */
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QHash>

class IconLoader : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QStringList searchPaths READ searchPaths NOTIFY themeChanged)
public:
    explicit IconLoader(QObject* parent = nullptr);

    QString theme() const { return m_theme; }
    void setTheme(const QString& t);
    QStringList searchPaths() const { return m_searchPaths; }

    /* 解析图标名 -> 文件绝对路径 (供 QML Image.source 直接用)
     * ctx: Apps/Actions/Devices/Panel/Places/Categories/Status/Navigation
     *      空则全 context 扫描 */
    Q_INVOKABLE QString path(const QString& name, int size = 24,
                             const QString& ctx = QString()) const;

    /* 解析图标名 -> image://icons/<path> URL, 支持运行时着色
     * color: 形如 "#00BCD4"; 空则保留 SVG 原色 (应用图标用) */
    Q_INVOKABLE QUrl url(const QString& name, int size = 24,
                         const QString& ctx = QString(),
                         const QString& color = QString()) const;

    /* 规范化 .desktop 的 Icon= 字段 (绝对路径去扩展名, 其他原样返回) */
    Q_INVOKABLE QString resolve(const QString& desktopIcon) const;

signals:
    void themeChanged();

private:
    struct CacheKey {
        QString name; int size; QString ctx;
        bool operator==(const CacheKey& o) const {
            return name == o.name && size == o.size && ctx == o.ctx;
        }
    };
    friend size_t qHash(const CacheKey& k, size_t seed) noexcept;

    QString findInTheme(const QString& theme, const QString& name,
                        int size, const QString& ctx) const;
    QStringList inheritsChain(const QString& theme) const;
    static QStringList defaultSearchPaths();
    void clearCache();

    QString m_theme = QStringLiteral("OpenOS");
    QStringList m_searchPaths;
    mutable QHash<CacheKey, QString> m_cache;
};
