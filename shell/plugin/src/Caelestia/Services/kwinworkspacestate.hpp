#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>
#include <QDBusArgument>

class QLocalServer;

namespace caelestia::services {

struct KWinDesktopData {
    int position;
    QString id;
    QString name;
};

QDBusArgument &operator<<(QDBusArgument &argument, const KWinDesktopData &data);
const QDBusArgument &operator>>(const QDBusArgument &argument, KWinDesktopData &data);

class KWinWorkspaceState : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int activeId READ activeId NOTIFY activeIdChanged)
    Q_PROPERTY(QVariantList workspaces READ workspaces NOTIFY workspacesChanged)
    Q_PROPERTY(uint rows READ rows NOTIFY rowsChanged)
    Q_PROPERTY(double swipeOffset READ swipeOffset NOTIFY swipeOffsetChanged)
    Q_PROPERTY(bool showingDesktop READ showingDesktop NOTIFY showingDesktopChanged)
    QML_ELEMENT
    QML_SINGLETON

public:
    static KWinWorkspaceState* instance();
    int indexForId(const QString& id) const;
    QString uuidForIndex(int index) const;

    explicit KWinWorkspaceState(QObject *parent = nullptr);
    ~KWinWorkspaceState() override;

    int activeId() const;
    QVariantList workspaces() const;
    uint rows() const;
    double swipeOffset() const;
    bool showingDesktop() const;

    Q_INVOKABLE void switchTo(const QString& id);
    Q_INVOKABLE void createWorkspace(const QString& name = QString());
    Q_INVOKABLE void removeWorkspace(const QString& id);

    Q_INVOKABLE void setDesktop(int desktopId);
    Q_INVOKABLE void nextDesktop();
    Q_INVOKABLE void previousDesktop();

signals:
    void activeIdChanged();
    void workspacesChanged();
    void rowsChanged();
    void swipeOffsetChanged();
    void showingDesktopChanged();

private slots:
    void onDesktopCreated(const QString& id, const caelestia::services::KWinDesktopData& desktopData);
    void onDesktopRemoved(const QString& id);
    void onDesktopDataChanged(const QString& id, const caelestia::services::KWinDesktopData& desktopData);
    void onCurrentChanged(const QString& id);
    void onCountChanged(uint count);
    void onRowsChanged(uint rows);
    void onShowingDesktopChanged(bool showing);
    void onKWinPropertiesChanged(const QString& interface, const QVariantMap& changedProps, const QStringList& invalidatedProps);

private:
    void fetchInitialState();
    void updateActiveId();
    void setupTrackerServer();
    void updateShowingDesktop(bool showing);

    QList<KWinDesktopData> m_desktops;
    QString m_currentUuid;
    int m_activeId = 0;
    uint m_rows = 1;
    double m_swipeOffset = 0.0;
    bool m_showingDesktop = false;
    ::QLocalServer* m_trackerServer = nullptr;
};

} // namespace caelestia::services

Q_DECLARE_METATYPE(caelestia::services::KWinDesktopData)

