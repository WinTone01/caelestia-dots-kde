// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QVariant>
#include <QHash>
#include <QList>
#include <QTimer>
#include "globalshortcut.hpp"

namespace caelestia::services {

class KeybindsModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        KeyRole,
        DefaultKeyRole,
        DescriptionRole,
        IsOverriddenRole,
    };

    explicit KeybindsModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void setKey(const QString& name, const QString& newKey);
    Q_INVOKABLE void resetKey(const QString& name);
    Q_INVOKABLE QVariantList query(const QString& searchText) const;

signals:
    void keybindsChanged();

private slots:
    void onShortcutRegistered(GlobalShortcut* sc);
    void onShortcutUnregistered(GlobalShortcut* sc);
    void flushOverridesToDisk();

private:
    QList<GlobalShortcut*> m_rows;
    QHash<QString, QString> m_overrides;
    QTimer* m_saveTimer = nullptr;

    QString overridesPath() const;
    void loadOverrides();
    void saveOverrides();
};

} // namespace caelestia::services
