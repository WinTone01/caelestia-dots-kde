qml_module(caelestia-core
    URI Caelestia
    SOURCES
        cutils.cpp
        qalculator.cpp
        appdb.cpp
        requests.cpp
        toaster.cpp
        imageanalyser.cpp
        translations.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Sql
        PkgConfig::Qalculate
        KF6::WindowSystem
        KF6::GuiAddons
)

# Bake the installed translations dir in so Translations can find catalogues
# even when the shell is launched from outside its install tree.
if(IS_ABSOLUTE "${INSTALL_QSCONFDIR}")
    set(_CAELESTIA_QSCONFDIR "${INSTALL_QSCONFDIR}")
else()
    set(_CAELESTIA_QSCONFDIR "${CMAKE_INSTALL_PREFIX}/${INSTALL_QSCONFDIR}")
endif()
target_compile_definitions(caelestia-core PRIVATE CAELESTIA_TRANSLATIONS_DIR="${_CAELESTIA_QSCONFDIR}/translations")

# Bake the shell version in so CUtils can expose it without spawning a process
target_compile_definitions(caelestia-core PRIVATE CAELESTIA_VERSION="${DISPLAY_VERSION}")

add_subdirectory(Components)
add_subdirectory(Config)
add_subdirectory(Internal)
add_subdirectory(Models)
add_subdirectory(Services)
add_subdirectory(Blobs)
add_subdirectory(Images)
add_subdirectory(Layouts)
