#include "globalshortcut.hpp"

#include <KGlobalAccel>
#include <QKeySequence>
#include <QDebug>
#include <QProcess>
#include <cstdlib>
#include "../Config/config.hpp"
#include "../Config/generalconfig.hpp"

Q_GLOBAL_STATIC(GlobalShortcutDispatcher, s_dispatcher)

GlobalShortcutDispatcher* GlobalShortcutDispatcher::instance() {
    return s_dispatcher;
}

QHash<QString, GlobalShortcut*> GlobalShortcut::s_registry;

GlobalShortcut::GlobalShortcut(QObject *parent)
    : QObject(parent), m_action(new QAction(this))
{
    connect(m_action, &QAction::triggered, this, &GlobalShortcut::activated);
}

GlobalShortcut::~GlobalShortcut()
{
    if (!m_name.isEmpty()) {
        s_registry.remove(m_name);
        emit GlobalShortcutDispatcher::instance()->shortcutUnregistered(this);
    }

    // Restore any KDE shortcuts we stole on startup
    for (const auto &stolen : m_stolenShortcuts) {
        QStringList seqStrings;
        for (const QKeySequence &seq : stolen.keys) {
            int k1 = seq.count() > 0 ? seq[0].toCombined() : 0;
            int k2 = seq.count() > 1 ? seq[1].toCombined() : 0;
            int k3 = seq.count() > 2 ? seq[2].toCombined() : 0;
            int k4 = seq.count() > 3 ? seq[3].toCombined() : 0;
            seqStrings.append(QString("([%1, %2, %3, %4],)").arg(k1).arg(k2).arg(k3).arg(k4));
        }
        
        QString arrayStr = "[" + seqStrings.join(", ") + "]";
        if (seqStrings.isEmpty()) {
            arrayStr = "[([0, 0, 0, 0],)]";
        }
        
        QString cmd = QString("gdbus call --session --dest org.kde.kglobalaccel "
                              "--object-path /kglobalaccel "
                              "--method org.kde.KGlobalAccel.setShortcutKeys "
                              "\"['%1', '%2', '', '']\" \"%3\" 4 > /dev/null 2>&1")
                              .arg(stolen.component)
                              .arg(stolen.action)
                              .arg(arrayStr);
        QProcess::startDetached("bash", {"-c", cmd});
    }
}

QString GlobalShortcut::name() const
{
    return m_name;
}

void GlobalShortcut::setName(const QString &name)
{
    if (m_name == name)
        return;

    if (!m_name.isEmpty()) {
        s_registry.remove(m_name);
    }

    m_name = name;
    m_action->setObjectName("caelestia-shortcut-" + m_name);
    
    if (!m_name.isEmpty()) {
        s_registry.insert(m_name, this);
    }

    emit nameChanged();
    emit GlobalShortcutDispatcher::instance()->shortcutRegistered(this);
    
    updateShortcut();
}

QString GlobalShortcut::key() const
{
    return m_key;
}

void GlobalShortcut::setKey(const QString &key)
{
    if (m_key == key)
        return;

    if (m_defaultKey.isEmpty()) {
        m_defaultKey = key;
    }

    m_key = key;
    emit keyChanged();
    updateShortcut();
}

void GlobalShortcut::setKeyOverride(const QString &key)
{
    // Like setKey(), but intentionally does NOT modify m_defaultKey.
    // This preserves the QML-assigned default even for shortcuts with no `key:` property.
    if (m_key == key)
        return;
    m_key = key;
    emit keyChanged();
    updateShortcut();
}

QString GlobalShortcut::defaultKey() const
{
    return m_defaultKey;
}

QString GlobalShortcut::description() const
{
    return m_description;
}

void GlobalShortcut::setDescription(const QString &description)
{
    if (m_description == description)
        return;

    m_description = description;
    emit descriptionChanged();
    updateShortcut();
}

GlobalShortcut* GlobalShortcut::findByName(const QString& name)
{
    return s_registry.value(name, nullptr);
}

QList<GlobalShortcut*> GlobalShortcut::allShortcuts()
{
    return s_registry.values();
}

void GlobalShortcut::updateShortcut()
{
    if (m_name.isEmpty()) {
        return;
    }

    if (m_key.isEmpty()) {
        KGlobalAccel::self()->setShortcut(m_action, QList<QKeySequence>(), KGlobalAccel::NoAutoloading);
        return;
    }

    m_action->setText(m_description.isEmpty() ? "Caelestia Action" : m_description);

    QList<QKeySequence> seqs;
    QStringList parts = m_key.split(";");
    for (const QString &part : parts) {
        QString trimmed = part.trimmed();
        if (!trimmed.isEmpty()) {
            seqs.append(QKeySequence(trimmed));
        }
    }

    if (seqs.isEmpty()) {
        KGlobalAccel::self()->setShortcut(m_action, QList<QKeySequence>(), KGlobalAccel::NoAutoloading);
        return;
    }

    const int myGeneration = ++m_registerGeneration;
    QList<QString> stealCmds;

    // 1. Find system-wide collisions for all sequences
    for (const QKeySequence &seq : seqs) {
        QList<KGlobalShortcutInfo> conflicts = KGlobalAccel::globalShortcutsByKey(seq);
        for (const auto &info : conflicts) {
            if (info.componentUniqueName() != "caelestia") {
                // Store it to restore on destruction
                m_stolenShortcuts.append({info.componentUniqueName(), info.uniqueName(), info.keys()});
                
                if (caelestia::config::GlobalConfig::instance()->general()->debugLogs()) {
                    qDebug() << "[Caelestia] Unbinding shortcut" << seq.toString() << "from component:" << info.componentUniqueName();
                }

                // 2. Prepare gdbus steal command
                QString cmd = QString("gdbus call --session --dest org.kde.kglobalaccel "
                                      "--object-path /kglobalaccel "
                                      "--method org.kde.KGlobalAccel.setShortcutKeys "
                                      "\"['%1', '%2', '', '']\" \"[([0, 0, 0, 0],)]\" 4")
                                      .arg(info.componentUniqueName())
                                      .arg(info.uniqueName());
                stealCmds.append(cmd);
            }
        }
    }

    if (stealCmds.isEmpty()) {
        KGlobalAccel::self()->setShortcut(m_action, seqs, KGlobalAccel::NoAutoloading);
        return;
    }

    // 3. Run all steal commands concurrently and wait for the last one
    auto pending = std::make_shared<QAtomicInt>(stealCmds.size());
    for (const QString &cmd : stealCmds) {
        auto *proc = new QProcess();
        connect(proc, &QProcess::finished, proc,
            [this, pending, seqs, myGeneration, proc](int, QProcess::ExitStatus) {
                proc->deleteLater();
                if (pending->fetchAndSubRelaxed(1) == 1) {
                    if (m_registerGeneration == myGeneration) {
                        KGlobalAccel::self()->setShortcut(m_action, seqs, KGlobalAccel::NoAutoloading);
                    }
                }
            });
        proc->start("bash", {"-c", cmd + " > /dev/null 2>&1"});
    }
}
