#pragma once

#include <effect/effect.h>
#include <effect/effecthandler.h>
#include <QLocalSocket>

#include "window_thumbnailer.hpp"
#include <QPointer>
#include <QObject>
#include <QPointF>
#include <kwin/virtualdesktops.h>

namespace caelestia {

struct DesktopTransition {
    int desktop;
    float x;
    float y;
};

class WorkspaceTrackerEffect : public KWin::Effect
{
    Q_OBJECT
public:
    WorkspaceTrackerEffect();
    ~WorkspaceTrackerEffect() override;

public:
    // Captures need a live GL context and a settled frame, so the thumbnailer
    // drains its queue here rather than from the D-Bus callback it arrived on.
    void postPaintScreen() override;

private Q_SLOTS:
    void onDesktopChanging(KWin::VirtualDesktop* desktop, QPointF offset);
    void onDesktopChangingCancelled();
    void onDesktopChanged(KWin::VirtualDesktop* oldDesktop, KWin::VirtualDesktop* newDesktop);
    void connectSocket();

private:
    void sendPayload(int desktop, float x, float y);

    QLocalSocket* m_socket;
    WindowThumbnailer* m_thumbnailer;
};

} // namespace caelestia
