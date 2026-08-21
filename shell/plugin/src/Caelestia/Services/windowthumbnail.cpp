#include "windowthumbnail.hpp"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingReply>
#include <QDateTime>
#include <QFileInfo>
#include <QHash>

namespace caelestia::services {

namespace {

constexpr auto kService = "org.kde.KWin";
constexpr auto kPath = "/Caelestia/WindowThumbnails";
constexpr auto kInterface = "org.caelestia.WindowThumbnails";

// Several surfaces can show the same window at once -- the dock hover popup and
// the overview, say -- and each capture is a GPU readback inside the
// compositor. A short shared TTL means opening a second surface reuses the frame
// the first one just paid for, while still going stale fast enough that a
// thumbnail is never visibly out of date once the user looks again.
constexpr qint64 kCacheTtlMs = 2000;

struct CacheEntry {
    QUrl source;
    qint64 capturedAt;
};

QHash<QString, CacheEntry>& cache() {
    static QHash<QString, CacheEntry> s_cache;
    return s_cache;
}

QString cacheKey(const QString& address, int maxSize) {
    return address + u'@' + QString::number(maxSize);
}

} // namespace

WindowThumbnail::WindowThumbnail(QObject* parent)
    : QObject(parent)
    , m_debounce(new QTimer(this)) {
    // Coalesces the burst of property writes that a delegate performs while it
    // is being set up into one capture, and keeps that capture off the stack
    // that created this object.
    m_debounce->setSingleShot(true);
    m_debounce->setInterval(0);
    connect(m_debounce, &QTimer::timeout, this, &WindowThumbnail::capture);
}

WindowThumbnail::~WindowThumbnail() = default;

QString WindowThumbnail::address() const {
    return m_address;
}

void WindowThumbnail::setAddress(const QString& address) {
    if (m_address == address) {
        return;
    }
    m_address = address;
    setSource(QUrl());
    Q_EMIT addressChanged();
    schedule();
}

int WindowThumbnail::maxSize() const {
    return m_maxSize;
}

void WindowThumbnail::setMaxSize(int maxSize) {
    if (m_maxSize == maxSize || maxSize <= 0) {
        return;
    }
    m_maxSize = maxSize;
    Q_EMIT maxSizeChanged();
    schedule();
}

bool WindowThumbnail::active() const {
    return m_active;
}

void WindowThumbnail::setActive(bool active) {
    if (m_active == active) {
        return;
    }
    m_active = active;
    Q_EMIT activeChanged();
    if (m_active) {
        schedule();
    }
}

QUrl WindowThumbnail::source() const {
    return m_source;
}

bool WindowThumbnail::available() const {
    return !m_source.isEmpty();
}

void WindowThumbnail::setSource(const QUrl& source) {
    if (m_source == source) {
        return;
    }
    m_source = source;
    Q_EMIT sourceChanged();
}

void WindowThumbnail::refresh() {
    cache().remove(cacheKey(m_address, m_maxSize));
    schedule();
}

void WindowThumbnail::schedule() {
    if (!m_active || m_address.isEmpty()) {
        return;
    }
    m_debounce->start();
}

void WindowThumbnail::capture() {
    if (!m_active || m_address.isEmpty()) {
        return;
    }

    const QString key = cacheKey(m_address, m_maxSize);
    const auto cached = cache().constFind(key);
    if (cached != cache().constEnd()
        && QDateTime::currentMSecsSinceEpoch() - cached->capturedAt < kCacheTtlMs
        && QFileInfo::exists(cached->source.toLocalFile())) {
        setSource(cached->source);
        return;
    }

    // One request in flight at a time. A second one would race the first to
    // assign source, and the loser could be the newer frame.
    if (m_pending) {
        return;
    }

    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kService), QLatin1String(kPath), QLatin1String(kInterface), QStringLiteral("Capture"));
    call << m_address << m_maxSize;

    const QString requestedAddress = m_address;
    m_pending = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(call), this);
    connect(m_pending, &QDBusPendingCallWatcher::finished, this, [this, requestedAddress, key](QDBusPendingCallWatcher* watcher) {
        watcher->deleteLater();
        m_pending = nullptr;

        const QDBusPendingReply<QString> reply = *watcher;
        // A failure is not worth reporting: the effect returns an empty path for
        // a window that is minimised or already gone, which is routine, and the
        // caller's icon fallback is the correct answer in every such case.
        if (reply.isError() || reply.value().isEmpty()) {
            return;
        }
        // The address may have moved on while this was in flight.
        if (requestedAddress != m_address) {
            return;
        }

        const QUrl source = QUrl::fromLocalFile(reply.value());
        cache().insert(key, { source, QDateTime::currentMSecsSinceEpoch() });
        setSource(source);
    });
}

} // namespace caelestia::services
