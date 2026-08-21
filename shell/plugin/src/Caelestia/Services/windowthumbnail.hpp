#pragma once

// A still capture of one window, produced inside KWin.
//
// The predecessor, ScreencastManager.qml, kept a JS dictionary of refcounted
// live PipeWire streams and asked for one from Component.onCompleted. Two things
// went wrong with that. Requesting a stream while QML was still building the
// caller ran object creation inside QQmlObjectCreator::finalize and crashed the
// V4 engine; and the protocol behind it, zkde_screencast_unstable_v1, is
// privileged, so it needed a standing KWin capability grant to work at all.
//
// This replaces both. The capture happens in the workspace-tracker KWin effect,
// which is already inside the compositor and needs no permission from it, and is
// fetched over a plain session-bus call. The bookkeeping lives here in C++
// rather than in JS, and the object is declarative: a consumer states which
// window it wants and binds to source, instead of calling into a manager and
// remembering to release afterwards. Nothing has to be deferred out of
// incubation, because setting a property only arms a timer.

#include <QDBusPendingCallWatcher>
#include <QObject>
#include <QQmlEngine>
#include <QTimer>
#include <QUrl>

namespace caelestia::services {

class WindowThumbnail : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(int maxSize READ maxSize WRITE setMaxSize NOTIFY maxSizeChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(QUrl source READ source NOTIFY sourceChanged)
    Q_PROPERTY(bool available READ available NOTIFY sourceChanged)
    QML_ELEMENT

public:
    explicit WindowThumbnail(QObject* parent = nullptr);
    ~WindowThumbnail() override;

    QString address() const;
    void setAddress(const QString& address);

    int maxSize() const;
    void setMaxSize(int maxSize);

    // Lets a consumer that is scrolled out of view, or on a workspace nobody is
    // looking at, stop paying for captures without tearing the object down.
    bool active() const;
    void setActive(bool active);

    QUrl source() const;
    bool available() const;

    /// Discards any cached frame for this window and captures a fresh one.
    Q_INVOKABLE void refresh();

Q_SIGNALS:
    void addressChanged();
    void maxSizeChanged();
    void activeChanged();
    void sourceChanged();

private:
    void schedule();
    void capture();
    void setSource(const QUrl& source);

    QString m_address;
    int m_maxSize = 512;
    bool m_active = true;
    QUrl m_source;
    QTimer* m_debounce;
    QDBusPendingCallWatcher* m_pending = nullptr;
};

} // namespace caelestia::services
