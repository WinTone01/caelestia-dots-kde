#include "window_thumbnailer.hpp"

#include <effect/effecthandler.h>
#include <effect/effectwindow.h>
#include <scene/item.h>
#include <scene/itemrenderer.h>
#include <scene/scene.h>
#include <scene/windowitem.h>
#include <core/rendertarget.h>
#include <core/renderviewport.h>
#include <opengl/glframebuffer.h>
#include <opengl/gltexture.h>
#include <opengl/glutils.h>

#include <QDBusConnection>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QUuid>
#include <QtMath>

namespace caelestia {

namespace {
constexpr int kMaxQueued = 8;
}

WindowThumbnailer::WindowThumbnailer(QObject* parent)
    : QObject(parent)
{
    m_dir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation)
        + QStringLiteral("/caelestia-window-thumbnails");
    QDir().mkpath(m_dir);

    // Registered on whatever service this process already owns, which is
    // org.kde.KWin. No new bus name, no policy file, nothing to grant. Logged
    // either way: if this fails the shell silently gets no thumbnails, and the
    // journal is the only place that would say why.
    const bool registered = QDBusConnection::sessionBus().registerObject(
        QStringLiteral("/Caelestia/WindowThumbnails"), this, QDBusConnection::ExportAllSlots);
    if (registered) {
        qInfo() << "CaelestiaThumbnailer: registered at /Caelestia/WindowThumbnails, writing to" << m_dir;
    } else {
        qWarning() << "CaelestiaThumbnailer: FAILED to register D-Bus object at /Caelestia/WindowThumbnails:"
                   << QDBusConnection::sessionBus().lastError().message();
    }
}

bool WindowThumbnailer::hasPending() const
{
    return !m_queue.isEmpty();
}

KWin::EffectWindow* WindowThumbnailer::findWindow(const QString& uuid)
{
    const QUuid wanted(uuid);
    if (wanted.isNull()) {
        return nullptr;
    }

    const auto windows = KWin::effects->stackingOrder();
    for (KWin::EffectWindow* window : windows) {
        if (window && window->internalId() == wanted) {
            return window;
        }
    }
    return nullptr;
}

QImage WindowThumbnailer::render(KWin::EffectWindow* window, int maxSize) const
{
    // A minimised or deleted window has no drawable content; rendering it would
    // succeed and produce a fully transparent image, which the shell cannot tell
    // apart from a real capture. Refuse here so it falls back to the icon.
    if (window->isDeleted() || window->isMinimized() || window->isHidden()) {
        return {};
    }

    KWin::WindowItem* item = window->windowItem();
    if (!item || !item->scene()) {
        return {};
    }

    const KWin::RectF geometry = window->frameGeometry();
    if (geometry.width() < 1 || geometry.height() < 1) {
        return {};
    }

    // Fit the longer edge to maxSize, and never upscale -- a 200px dialog
    // rendered into a 512px texture is just wasted readback.
    const qreal longest = qMax(geometry.width(), geometry.height());
    const qreal scale = qMin(1.0, static_cast<qreal>(maxSize) / longest);
    const QSize size(qMax(1, qRound(geometry.width() * scale)), qMax(1, qRound(geometry.height() * scale)));

    if (!KWin::effects->makeOpenGLContextCurrent()) {
        qWarning() << "CaelestiaThumbnailer: no GL context";
        return {};
    }

    auto texture = KWin::GLTexture::allocate(GL_RGBA8, size);
    if (!texture) {
        qWarning() << "CaelestiaThumbnailer: could not allocate a" << size << "texture";
        return {};
    }

    KWin::GLFramebuffer framebuffer(texture.get());
    if (!framebuffer.valid()) {
        qWarning() << "CaelestiaThumbnailer: framebuffer invalid";
        return {};
    }

    const KWin::RenderTarget target(&framebuffer);
    const KWin::RenderViewport viewport(geometry, scale, target, QPoint(0, 0));

    KWin::GLFramebuffer::pushFramebuffer(&framebuffer);
    // Transparent ground: windows are not always rectangular once their shape
    // and corner rounding are applied, and the shell composites these over its
    // own surface.
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    KWin::ItemRenderer* renderer = item->scene()->renderer();
    const KWin::WindowPaintData data;
    renderer->beginFrame(target, viewport);
    renderer->renderItem(target, viewport, item, 0,
        KWin::Region(KWin::Rect(0, 0, size.width(), size.height())), data, {}, {});
    renderer->endFrame();
    KWin::GLFramebuffer::popFramebuffer();

    QImage image = texture->toImage();
    if (image.isNull()) {
        return {};
    }

    // Framebuffer origin is bottom-left, QImage's is top-left.
    return image.flipped(Qt::Vertical);
}

QString WindowThumbnailer::writeImage(const QString& uuid, const QImage& image) const
{
    const QString stem = QString(uuid).remove(u'{').remove(u'}');

    // Written to a fresh name each time and the previous one dropped, so a
    // caller still reading the old file is never pulled out from under, and
    // QML's image cache -- which keys on the URL -- cannot serve a stale frame
    // for a URL it has already seen.
    const QString path = QStringLiteral("%1/%2-%3.png")
                             .arg(m_dir, stem, QString::number(QDateTime::currentMSecsSinceEpoch()));
    if (!image.save(path, "PNG")) {
        qWarning() << "CaelestiaThumbnailer: could not write" << path;
        return {};
    }

    const QFileInfo written(path);
    const auto stale = QDir(m_dir).entryInfoList({ stem + QStringLiteral("-*.png") }, QDir::Files);
    for (const QFileInfo& info : stale) {
        if (info.fileName() != written.fileName()) {
            QFile::remove(info.absoluteFilePath());
        }
    }

    return path;
}

QString WindowThumbnailer::Capture(const QString& uuid, int maxSize)
{
    // Answered from processQueue() once the compositor is in a paint cycle.
    if (calledFromDBus()) {
        if (m_queue.size() >= kMaxQueued) {
            // Shedding load rather than growing an unbounded queue: the caller
            // treats an empty path as "no thumbnail available" and shows an
            // icon, which is the correct outcome when the compositor is already
            // saturated with capture requests.
            return {};
        }
        setDelayedReply(true);
        m_queue.append({ message().createReply(), uuid, maxSize > 0 ? maxSize : 512 });
        KWin::effects->addRepaintFull();
        return {};
    }

    // Direct in-process call (there is no such caller today, but the slot must
    // still behave if one appears).
    KWin::EffectWindow* window = findWindow(uuid);
    if (!window) {
        return {};
    }
    const QImage image = render(window, maxSize > 0 ? maxSize : 512);
    return image.isNull() ? QString() : writeImage(uuid, image);
}

void WindowThumbnailer::processQueue()
{
    if (m_queue.isEmpty()) {
        return;
    }

    const QList<Request> requests = std::move(m_queue);
    m_queue.clear();

    for (const Request& request : requests) {
        QString path;
        if (KWin::EffectWindow* window = findWindow(request.uuid)) {
            const QImage image = render(window, request.maxSize);
            if (!image.isNull()) {
                path = writeImage(request.uuid, image);
            }
        }

        QDBusMessage reply = request.message;
        reply << path;
        QDBusConnection::sessionBus().send(reply);
    }
}

} // namespace caelestia
