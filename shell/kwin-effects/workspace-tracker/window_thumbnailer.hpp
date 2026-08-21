#pragma once

// Renders a window's own scene item into an offscreen framebuffer and hands the
// result back as a PNG on disk.
//
// This exists so the shell can draw window thumbnails without holding a
// privileged Wayland protocol. It used to ask KWin for a live PipeWire feed over
// zkde_screencast_unstable_v1, which KWin only offers to clients that declare it
// in an installed .desktop file -- a standing capability grant that outlived the
// feature and was implicated in both crashes and screen-sharing conflicts.
//
// Running the capture inside a KWin effect sidesteps that entirely: this code is
// already part of the compositor, so it reaches the scene graph directly and
// needs no permission from it. The only channel out is a D-Bus object registered
// on the service KWin already owns, which any session client may call. Note that
// KWin's own org.kde.KWin.ScreenShot2 is NOT an alternative here -- it gates
// callers on X-KDE-DBUS-Restricted-Interfaces, i.e. exactly the kind of grant
// this replaces.
//
// Captures are queued and performed from postPaintScreen rather than straight
// out of the D-Bus call. Reading the scene needs a current GL context and a
// consistent frame; touching it from an arbitrary event-loop callback can hand
// back a black or half-drawn texture. KWin's own screenshot effect defers to the
// paint cycle for the same reason, so callers get a delayed D-Bus reply.
//
// The trade against the old path is live video for a still frame. Callers ask
// again when they want a fresher one.

#include <QDBusContext>
#include <QDBusMessage>
#include <QImage>
#include <QList>
#include <QObject>
#include <QString>

namespace KWin {
class EffectWindow;
}

namespace caelestia {

class WindowThumbnailer : public QObject, protected QDBusContext
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.caelestia.WindowThumbnails")

public:
    explicit WindowThumbnailer(QObject* parent = nullptr);

    /// Drains the queue. Must be called from the effect's postPaintScreen.
    void processQueue();

    bool hasPending() const;

public Q_SLOTS:
    /**
     * Captures the window whose EffectWindow::internalId() matches @p uuid and
     * writes it to a PNG under $XDG_RUNTIME_DIR, replying with the absolute
     * path.
     *
     * @p maxSize bounds the longer edge; the aspect ratio is kept. Replies with
     * an empty string if the window is gone, minimised, or otherwise has
     * nothing drawable -- all routine, and the caller's icon fallback is the
     * right answer in each case.
     */
    QString Capture(const QString& uuid, int maxSize);

private:
    struct Request {
        QDBusMessage message;
        QString uuid;
        int maxSize;
    };

    static KWin::EffectWindow* findWindow(const QString& uuid);
    QImage render(KWin::EffectWindow* window, int maxSize) const;
    QString writeImage(const QString& uuid, const QImage& image) const;

    QString m_dir;
    QList<Request> m_queue;
};

} // namespace caelestia
