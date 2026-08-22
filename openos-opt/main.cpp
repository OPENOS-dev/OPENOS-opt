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

/* openos-opt — Pacman GUI 前端 (独立 App, 自包含) */
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QUrl>
#include "iconloader.h"
#include "iconprovider.h"
#include "pacmanbridge.h"

int main(int argc, char** argv) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("openos-opt");
    app.setQuitOnLastWindowClosed(true);

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("icons"), new IconProvider);

    IconLoader iconLoader(&app);
    engine.rootContext()->setContextProperty("_iconLoader", &iconLoader);

    PacmanBridge pacman;
    engine.rootContext()->setContextProperty("PacmanBridge", &pacman);

    QQmlComponent token(&engine, QUrl(QStringLiteral("qrc:/qml/OpenUI.qml")));
    QObject* openUI = token.create();
    engine.rootContext()->setContextProperty("OpenUI", openUI);

    engine.load(QUrl(QStringLiteral("qrc:/qml/Opt.qml")));
    return engine.rootObjects().isEmpty() ? 1 : app.exec();
}