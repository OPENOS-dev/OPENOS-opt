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

/* openos-opt — Pacman GUI 前端 (C++ 后端实现) */
#include "pacmanbridge.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QRegularExpression>
#include <QDebug>

PacmanBridge::PacmanBridge(QObject* parent)
    : QObject(parent)
{
    m_process = new QProcess(this);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &PacmanBridge::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred,
            this, &PacmanBridge::onProcessError);
    connect(m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        // 从 pacman 输出解析进度信息
        QString line = QString::fromUtf8(m_process->readLine()).trimmed();
        static QRegularExpression progressRe(R"(\((\d+)/(\d+)\))");
        auto match = progressRe.match(line);
        if (match.hasMatch()) {
            int cur = match.captured(1).toInt();
            int total = match.captured(2).toInt();
            if (total > 0) setProgress(line, cur * 100 / total);
        }
    });
}

void PacmanBridge::setBusy(bool b) {
    if (m_busy != b) {
        m_busy = b;
        emit busyChanged();
    }
}

void PacmanBridge::setProgress(const QString& text, int percent) {
    m_progressText = text;
    m_progressPercent = percent;
    emit progressChanged();
}

void PacmanBridge::runPacman(const QStringList& args, const QString& callbackId) {
    if (m_busy) {
        emit error(tr("操作正在进行中，请等待完成"));
        return;
    }
    m_callbackId = callbackId;
    setProgress(tr("正在执行 pacman %1...").arg(args.join(' ')), 0);
    setBusy(true);
    // 使用 pkexec 或 sudo 获取 root 权限 (写入操作)
    bool needsRoot = args.contains("-S") || args.contains("-R") || args.contains("-U") || args.contains("-Sy");
    QStringList cmd;
    if (needsRoot) {
        cmd << "pkexec" << "pacman";
    } else {
        cmd << "pacman";
    }
    m_process->start(cmd.first(), cmd.mid(1) + args);
}

void PacmanBridge::onProcessFinished() {
    setBusy(false);
    QString output = QString::fromUtf8(m_process->readAllStandardOutput());
    QString errOutput = QString::fromUtf8(m_process->readAllStandardError());
    int exitCode = m_process->exitCode();

    if (exitCode != 0 && !errOutput.isEmpty()) {
        // 即使失败, 收集已有输出用于显示
    }

    if (m_callbackId == "refresh") {
        // pacman -Q: 列出已安装包
        // 输出格式: "name version"
        QJsonArray list;
        for (const QString& line : output.split('\n', Qt::SkipEmptyParts)) {
            QString trimmed = line.trimmed();
            if (trimmed.isEmpty()) continue;
            int space = trimmed.indexOf(' ');
            QJsonObject pkg;
            if (space > 0) {
                pkg["name"] = trimmed.left(space);
                pkg["version"] = trimmed.mid(space + 1).trimmed();
            } else {
                pkg["name"] = trimmed;
                pkg["version"] = "";
            }
            list.append(pkg);
        }
        emit installedListReady(list);
        emit operationFinished(exitCode == 0,
            exitCode == 0 ? tr("已加载 %1 个包").arg(list.size()) : tr("加载失败"));
    }
    else if (m_callbackId == "search") {
        // pacman -Ss <query>: 搜索包
        QJsonArray results;
        QString name, version, desc;
        for (const QString& line : output.split('\n', Qt::SkipEmptyParts)) {
            QString trimmed = line.trimmed();
            if (trimmed.isEmpty()) continue;
            if (!trimmed.startsWith(' ')) {
                // 包名行: "repo/name version\n    description"
                if (!name.isEmpty()) {
                    QJsonObject pkg;
                    pkg["name"] = name;
                    pkg["version"] = version;
                    pkg["description"] = desc.trimmed();
                    results.append(pkg);
                }
                int slash = trimmed.indexOf('/');
                int space = trimmed.indexOf(' ', slash + 1);
                if (slash > 0) {
                    // 格式: "repo/pkgname version"
                    int versionStart = space > 0 ? space + 1 : trimmed.length();
                    // 跳过 repo/ 前缀
                    int pkgNameStart = slash + 1;
                    // 版本号可能在空格后或行尾
                    name = trimmed.mid(pkgNameStart, (space > 0 ? space : trimmed.length()) - pkgNameStart).trimmed();
                    // 实际版本号在空格后
                    name = trimmed.mid(slash + 1, (space > 0 ? space : trimmed.length()) - slash - 1).trimmed();
                    version = space > 0 ? trimmed.mid(space + 1).trimmed() : "";
                    // 去掉可能的版本号中的仓库名
                    int vspace = name.indexOf(' ');
                    if (vspace > 0) {
                        version = name.mid(vspace + 1).trimmed();
                        name = name.left(vspace).trimmed();
                    }
                }
                desc = "";
            } else {
                desc += trimmed + " ";
            }
        }
        if (!name.isEmpty()) {
            QJsonObject pkg;
            pkg["name"] = name;
            pkg["version"] = version;
            pkg["description"] = desc.trimmed();
            results.append(pkg);
        }
        emit searchResultsReady(results);
        emit operationFinished(exitCode == 0,
            exitCode == 0 ? tr("找到 %1 个包").arg(results.size()) : tr("搜索失败"));
    }
    else if (m_callbackId == "info") {
        // pacman -Qi <name>: 包信息
        QJsonObject info;
        // 解析 pacman -Qi 输出: "Key : Value"
        for (const QString& line : output.split('\n', Qt::SkipEmptyParts)) {
            int colon = line.indexOf(':');
            if (colon > 0) {
                QString key = line.left(colon).trimmed();
                QString val = line.mid(colon + 1).trimmed();
                // 转小写作为 JSON key
                info[key.toLower().replace(' ', '_')] = val;
            }
        }
        emit packageInfoReady(info);
        emit operationFinished(exitCode == 0, exitCode == 0 ? "" : tr("获取信息失败"));
    }
    else if (m_callbackId == "checkupdates") {
        // pacman -Qu: 检查可用更新
        QJsonArray updates;
        for (const QString& line : output.split('\n', Qt::SkipEmptyParts)) {
            QString trimmed = line.trimmed();
            if (trimmed.isEmpty()) continue;
            // 格式: "name oldver -> newver"
            int arrow = trimmed.indexOf(" -> ");
            QJsonObject pkg;
            if (arrow > 0) {
                pkg["name"] = trimmed.left(arrow).trimmed();
                QString rest = trimmed.mid(arrow + 4).trimmed();
                pkg["old_version"] = "";
                pkg["new_version"] = rest;
            } else {
                pkg["name"] = trimmed;
                pkg["old_version"] = "";
                pkg["new_version"] = "";
            }
            updates.append(pkg);
        }
        emit updatesAvailable(updates);
        emit operationFinished(exitCode == 0,
            exitCode == 0 ? tr("有 %1 个更新可用").arg(updates.size()) : tr("检查更新失败"));
    }
    else if (m_callbackId == "install" || m_callbackId == "remove" || m_callbackId == "update") {
        QString action = m_callbackId == "install" ? tr("安装") :
                         m_callbackId == "remove"  ? tr("卸载") : tr("更新");
        emit operationFinished(exitCode == 0,
            exitCode == 0 ? tr("%1完成").arg(action) : tr("%1失败").arg(action));
    }

    m_callbackId.clear();
    setProgress("", 0);
}

void PacmanBridge::onProcessError(QProcess::ProcessError err) {
    setBusy(false);
    QString msg;
    switch (err) {
        case QProcess::FailedToStart: msg = tr("无法启动 pacman，请确认已安装"); break;
        case QProcess::Crashed:       msg = tr("pacman 进程异常退出"); break;
        case QProcess::Timedout:      msg = tr("操作超时"); break;
        default:                      msg = tr("未知错误"); break;
    }
    emit error(msg);
    m_callbackId.clear();
    setProgress("", 0);
}

// ---- 公开接口 ----

void PacmanBridge::refreshInstalled() {
    runPacman({"-Q"}, "refresh");
}

void PacmanBridge::searchPackages(const QString& query) {
    runPacman({"-Ss", query}, "search");
}

void PacmanBridge::installPackage(const QString& name) {
    runPacman({"-S", "--noconfirm", name}, "install");
}

void PacmanBridge::removePackage(const QString& name) {
    runPacman({"-R", "--noconfirm", name}, "remove");
}

void PacmanBridge::updateSystem() {
    runPacman({"-Syu", "--noconfirm"}, "update");
}

void PacmanBridge::getPackageInfo(const QString& name) {
    runPacman({"-Qi", name}, "info");
}

void PacmanBridge::checkUpdates() {
    runPacman({"-Qu"}, "checkupdates");
}