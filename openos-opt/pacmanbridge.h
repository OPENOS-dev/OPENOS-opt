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

/* openos-opt — Pacman GUI 前端 (C++ 后端)
 * 通过 QProcess 调用 pacman 命令, 向 QML 暴露操作接口。 */
#ifndef PACMANBRIDGE_H
#define PACMANBRIDGE_H

#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QJsonArray>
#include <QJsonObject>
#include <QTimer>

class PacmanBridge : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString progressText READ progressText NOTIFY progressChanged)
    Q_PROPERTY(int progressPercent READ progressPercent NOTIFY progressChanged)

public:
    explicit PacmanBridge(QObject* parent = nullptr);

    bool busy() const { return m_busy; }
    QString progressText() const { return m_progressText; }
    int progressPercent() const { return m_progressPercent; }

    Q_INVOKABLE void refreshInstalled();
    Q_INVOKABLE void searchPackages(const QString& query);
    Q_INVOKABLE void installPackage(const QString& name);
    Q_INVOKABLE void removePackage(const QString& name);
    Q_INVOKABLE void updateSystem();
    Q_INVOKABLE void getPackageInfo(const QString& name);
    Q_INVOKABLE void checkUpdates();

signals:
    void busyChanged();
    void progressChanged();
    void installedListReady(const QJsonArray& packages);
    void searchResultsReady(const QJsonArray& packages);
    void packageInfoReady(const QJsonObject& info);
    void updatesAvailable(const QJsonArray& updates);
    void operationFinished(bool success, const QString& message);
    void error(const QString& message);

private slots:
    void onProcessFinished();
    void onProcessError(QProcess::ProcessError err);

private:
    void runPacman(const QStringList& args, const QString& callbackId);
    void setBusy(bool b);
    void setProgress(const QString& text, int percent);

    QProcess* m_process = nullptr;
    bool m_busy = false;
    QString m_progressText;
    int m_progressPercent = 0;
    QString m_callbackId;  // 标记当前操作类型
};

#endif // PACMANBRIDGE_H