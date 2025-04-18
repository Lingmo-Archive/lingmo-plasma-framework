add_subdirectory(accessdenied)
add_subdirectory(core)
add_subdirectory(plasmacomponents)
add_subdirectory(plasmaextracomponents)
add_subdirectory(platformcomponents)
add_subdirectory(calendar)

install(DIRECTORY plasmastyle/ DESTINATION ${KDE_INSTALL_QMLDIR}/QtQuick/Controls/Styles/Plasma)

install(DIRECTORY kirigamiplasmastyle/ DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/kirigami.2/styles/Plasma)

install(DIRECTORY kirigamiplasmadesktopstyle/ DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/kirigami.2/styles/org.kde.desktop.plasma)


set(QQC2_VERSION "2.${Qt5QuickControls2_VERSION_MINOR}")

if (Qt5Qml_VERSION_STRING VERSION_GREATER_EQUAL 5.14)
    set(DISABLE_UNDER_QT_5_14 "")
    set(DISABLE_AT_QT_5_14 "//Disabled since Qt 5.14 ")
else()
    set(DISABLE_UNDER_QT_5_14 "//Needs Qt 5.14 ")
    set(DISABLE_AT_QT_5_14 "")
endif()

# Find all the source qml files
FILE(GLOB_RECURSE inFiles RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/plasmacomponents3/*")

    #for each file, replace @QQC2_VERSION@ with the version we found
FOREACH(infileName ${inFiles})
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/${infileName}"
        "${CMAKE_CURRENT_BINARY_DIR}/${infileName}"
        @ONLY
    )
ENDFOREACH(infileName)

#install the components as a QQC2 Style, as style for applications (mainly for Plasma Mobile)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/plasmacomponents3/ DESTINATION ${KDE_INSTALL_QMLDIR}/QtQuick/Controls.2/Plasma)

#install some of the componets as a separate import, to be used in plasmoids (some of them like ApplicationWindow are of no use for plasmoids)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/plasmacomponents3/
    DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/components.3)



