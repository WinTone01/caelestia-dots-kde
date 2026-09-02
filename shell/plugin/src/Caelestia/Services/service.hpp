#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qset.h>

namespace caelestia::services {

class Service : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    // Whether this service may run at all. A disabled service holds no
    // resources even while consumers are referencing it, and picks up again
    // when it is re-enabled - which is how the audio capture is turned off
    // without every consumer having to know about the setting.
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)

public:
    explicit Service(QObject* parent = nullptr);

    void ref(QObject* sender);
    void unref(QObject* sender);

    [[nodiscard]] bool enabled() const;
    void setEnabled(bool enabled);

signals:
    void enabledChanged();

protected:
    [[nodiscard]] bool referenced() const;

private:
    QSet<QObject*> m_refs;
    bool m_enabled = true;

    virtual void start() = 0;
    virtual void stop() = 0;
};

} // namespace caelestia::services
