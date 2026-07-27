// SPDX-License-Identifier: GPL-3.0-only
#include "keybindsmodel.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcKeybinds, "caelestia.services.keybindsmodel", QtInfoMsg)

namespace caelestia::services {

KeybindsModel::KeybindsModel(QObject* parent)
    : QAbstractListModel(parent) {
    
    connect(GlobalShortcutDispatcher::instance(), &GlobalShortcutDispatcher::shortcutRegistered,
            this, &KeybindsModel::onShortcutRegistered);
    connect(GlobalShortcutDispatcher::instance(), &GlobalShortcutDispatcher::shortcutUnregistered,
            this, &KeybindsModel::onShortcutUnregistered);

    for (GlobalShortcut* sc : GlobalShortcut::allShortcuts()) {
        onShortcutRegistered(sc);
    }

    m_saveTimer = new QTimer(this);
    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(300);
    connect(m_saveTimer, &QTimer::timeout, this, &KeybindsModel::flushOverridesToDisk);
}

int KeybindsModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_rows.size();
}

QVariant KeybindsModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= m_rows.size()) return QVariant();

    GlobalShortcut* sc = m_rows.at(index.row());
    
    switch (role) {
    case NameRole: return sc->name();
    case KeyRole: return sc->key();
    case DefaultKeyRole: return sc->defaultKey();
    case DescriptionRole: return sc->description();
    case IsOverriddenRole: return m_overrides.contains(sc->name());
    }
    return QVariant();
}

QHash<int, QByteArray> KeybindsModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[KeyRole] = "key";
    roles[DefaultKeyRole] = "defaultKey";
    roles[DescriptionRole] = "description";
    roles[IsOverriddenRole] = "isOverridden";
    return roles;
}

void KeybindsModel::setKey(const QString& name, const QString& newKey) {
    GlobalShortcut* sc = GlobalShortcut::findByName(name);
    if (!sc)
        return;

    // CRITICAL: capture defaultKey BEFORE calling sc->setKey().
    // GlobalShortcut::setKey() sets m_defaultKey = newKey on the very first call when
    // m_defaultKey is empty. Shortcuts with no `key:` property in QML never receive a
    // QML-initiated setKey(), so m_defaultKey stays "". If we call sc->setKey(newKey)
    // first, newKey becomes the default, then `newKey == sc->defaultKey()` is trivially
    // true and the override is discarded instead of saved.
    const QString defaultKey = sc->defaultKey();
    sc->setKey(newKey);

    if (!defaultKey.isEmpty() && newKey == defaultKey) {
        // User restored the shortcut to its real default
        m_overrides.remove(name);
    } else {
        m_overrides.insert(name, newKey);
    }

    m_saveTimer->start();
    emit keybindsChanged();
}

void KeybindsModel::resetKey(const QString& name) {
    GlobalShortcut* sc = GlobalShortcut::findByName(name);
    if (!sc) return;
    setKey(name, sc->defaultKey());
}

QVariantList KeybindsModel::query(const QString& searchText) const {
    QVariantList result;
    const auto lower = searchText.toLower();
    
    for (GlobalShortcut* sc : m_rows) {
        if (searchText.isEmpty() ||
            sc->key().toLower().contains(lower) ||
            sc->description().toLower().contains(lower) ||
            sc->name().toLower().contains(lower)) {
            
            result.append(QVariantMap{
                { "bind", sc->key() },
                { "action", sc->name() },
                { "name", sc->name() },
                { "description", sc->description() },
                { "defaultKey", sc->defaultKey() },
                { "isOverridden", m_overrides.contains(sc->name()) }
            });
        }
    }
    return result;
}

void KeybindsModel::onShortcutRegistered(GlobalShortcut* sc) {
    if (m_rows.contains(sc))
        return;

    // Do NOT apply overrides here — m_defaultKey is not yet set by QML's `key` property.
    // Overrides are applied later via applyAllOverrides(), called from Component.onCompleted.

    const int row = m_rows.size();
    beginInsertRows(QModelIndex(), row, row);
    m_rows.append(sc);
    endInsertRows();
    
    emit keybindsChanged();

    connect(sc, &GlobalShortcut::keyChanged, this, [this, sc] {
        int idx = m_rows.indexOf(sc);
        if (idx >= 0) {
            emit dataChanged(index(idx), index(idx), {KeyRole, IsOverriddenRole});
        }
    });
}

void KeybindsModel::onShortcutUnregistered(GlobalShortcut* sc) {
    int idx = m_rows.indexOf(sc);
    if (idx >= 0) {
        beginRemoveRows(QModelIndex(), idx, idx);
        m_rows.removeAt(idx);
        endRemoveRows();
        emit keybindsChanged();
    }
}

QString KeybindsModel::overridesPath() const {
    return QDir::homePath() + "/.config/caelestia/keybinds.json";
}

void KeybindsModel::loadAndApplyOverrides() {
    // Read overrides synchronously from disk.
    // This is called from QML's Component.onCompleted, which fires after all
    // CustomShortcut children (and their inner GlobalShortcut objects) are fully
    // initialized — so m_defaultKey is already set on every shortcut before we apply.
    QString path = overridesPath();
    QFile file(path);
    if (file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        if (doc.isObject()) {
            m_overrides.clear();
            QJsonObject obj = doc.object();
            for (auto it = obj.begin(); it != obj.end(); ++it) {
                const QString val = it.value().toString();
                if (!val.isEmpty())
                    m_overrides.insert(it.key(), val);
            }
        }
    }

    // Apply every override. Use setKeyOverride() to leave m_defaultKey intact —
    // critical for shortcuts with no `key:` property in QML (m_defaultKey would
    // otherwise be set to the override value, breaking future modifications).
    for (auto it = m_overrides.begin(); it != m_overrides.end(); ++it) {
        GlobalShortcut* sc = GlobalShortcut::findByName(it.key());
        if (sc)
            sc->setKeyOverride(it.value());
    }

    emit keybindsChanged();
}


void KeybindsModel::saveOverrides() {
    QString path = overridesPath();
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning(lcKeybinds) << "Failed to save keybind overrides to" << path;
        return;
    }

    QJsonObject obj;
    for (auto it = m_overrides.begin(); it != m_overrides.end(); ++it) {
        obj.insert(it.key(), it.value());
    }

    QJsonDocument doc(obj);
    file.write(doc.toJson());
}

void KeybindsModel::flushOverridesToDisk() {
    saveOverrides();
}

} // namespace caelestia::services
