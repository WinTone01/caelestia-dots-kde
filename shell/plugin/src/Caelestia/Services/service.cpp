#include "service.hpp"

#include <qpointer.h>

namespace caelestia::services {

Service::Service(QObject* parent)
    : QObject(parent) {}

void Service::ref(QObject* sender) {
    if (m_refs.isEmpty() && m_enabled) {
        start();
    }

    QObject::connect(sender, &QObject::destroyed, this, &Service::unref);
    m_refs << sender;
}

void Service::unref(QObject* sender) {
    if (m_refs.remove(sender) && m_refs.isEmpty() && m_enabled) {
        stop();
    }
}

bool Service::enabled() const {
    return m_enabled;
}

void Service::setEnabled(bool enabled) {
    if (m_enabled == enabled) {
        return;
    }

    m_enabled = enabled;
    emit enabledChanged();

    if (m_refs.isEmpty()) {
        return;
    }

    if (m_enabled) {
        start();
    } else {
        stop();
    }
}

bool Service::referenced() const {
    return !m_refs.isEmpty() && m_enabled;
}

} // namespace caelestia::services
