############################################################
## Pothos SDR environment build sub-script
##
## This script builds gr-qtgui dependecies
##
## * qt4
## * qwt5
## * qwt6
## * python2_sip
## * python2_pyqt4
## * python2_pyqwt5
############################################################

############################################################
## Build Qt4
##
## Don't install the entire build to the INSTALL_PREFIX
## only the required DLLs are copied to the INSTALL_PREFIX
############################################################
execute_process(COMMAND ${PYTHON2_ROOT}/Scripts/pip.exe install patch OUTPUT_QUIET)

ExternalProject_Add(qt4
    URL https://download.qt.io/archive/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz
    URL_MD5 d990ee66bf7ab0c785589776f35ba6ad
    PATCH_COMMAND ${PYTHON2_EXECUTABLE} -m patch -d <SOURCE_DIR>
        ${PROJECT_SOURCE_DIR}/patches/qt-4.8.7-msvc2015.diff
    CONFIGURE_COMMAND <SOURCE_DIR>/configure
        -make nmake -release -shared -platform win32-msvc2015
        -prefix <BINARY_DIR>/qt-4.8.7 -opensource -confirm-license
        -opengl desktop -graphicssystem opengl -nomake examples -nomake network
        -nomake demos -nomake tools -nomake sql -no-script -no-scripttools
        -no-qt3support -qt-libpng -qt-libjpeg -no-webkit
    BUILD_COMMAND nmake
    INSTALL_COMMAND nmake install
)

ExternalProject_Get_Property(qt4 SOURCE_DIR)
ExternalProject_Get_Property(qt4 BINARY_DIR)
set(QT4_ROOT ${BINARY_DIR}/qt-4.8.7)
message(STATUS "QT4_ROOT: ${QT4_ROOT}")

install(FILES
    ${SOURCE_DIR}/LGPL_EXCEPTION.txt
    ${SOURCE_DIR}/LICENSE.FDL
    ${SOURCE_DIR}/LICENSE.GPL3
    ${SOURCE_DIR}/LICENSE.LGPL
    ${SOURCE_DIR}/LICENSE.LGPLv21
    ${SOURCE_DIR}/LICENSE.LGPLv3
    DESTINATION licenses/qt4
)

install(FILES
    "${QT4_ROOT}/bin/QtCore4.dll"
    "${QT4_ROOT}/bin/QtGui4.dll"
    "${QT4_ROOT}/bin/QtSvg4.dll"
    "${QT4_ROOT}/bin/QtOpenGL4.dll"
    DESTINATION bin
)

############################################################
## Build Qwt5
############################################################
MyExternalProject_Add(qwt5
    URL https://sourceforge.net/projects/qwt/files/qwt/5.2.3/qwt-5.2.3.zip
    URL_MD5 310a1c8ab831f4b2219505dcb7691cf1
    PATCH_COMMAND ${PYTHON2_EXECUTABLE} -m patch -d <SOURCE_DIR>
        ${PROJECT_SOURCE_DIR}/patches/qwt5_project_files.diff
    CONFIGURE_COMMAND ${QT4_ROOT}/bin/qmake.exe <SOURCE_DIR>/qwt.pro
        CONFIG+=release
        PREFIX=<INSTALL_DIR>
        MAKEDLL=NO AVX2=NO
    BUILD_COMMAND nmake
    INSTALL_COMMAND nmake install
    LICENSE_FILES COPYING
)

ExternalProject_Get_Property(qwt5 INSTALL_DIR)
set(QWT5_INSTALL_PREFIX ${INSTALL_DIR})

############################################################
## Build Qwt6
############################################################
MyExternalProject_Add(qwt6
    DEPENDS qt4
    URL https://sourceforge.net/projects/qwt/files/qwt/6.1.3/qwt-6.1.3.zip
    URL_MD5 558911df37aee4c0c3049860e967401c
    PATCH_COMMAND ${PYTHON2_EXECUTABLE} -m patch -d <SOURCE_DIR>
        ${PROJECT_SOURCE_DIR}/patches/qwt6_project_files.diff
    CONFIGURE_COMMAND ${QT4_ROOT}/bin/qmake.exe <SOURCE_DIR>/qwt.pro
        CONFIG+=release
        PREFIX=${CMAKE_INSTALL_PREFIX}
        MAKEDLL=YES AVX2=NO QT_DLL=YES &&
        # Avoid too long commands
        nmake "src\\Makefile" &&
        powershell -Command "(gc src\\Makefile.release) -replace '= @echo compiling', '= cl #' | Out-File src\\Makefile.release" &&
        # Avoid debug build
        powershell -Command "(gc src\\Makefile) -replace 'install: release-install debug-install', 'install: release-install' | Out-File src\\Makefile" &&
        powershell -Command "(gc src\\Makefile) -replace 'all: release-all debug-all', 'all: release-all' | Out-File src\\Makefile"
    BUILD_COMMAND nmake
    INSTALL_COMMAND
        nmake install &&
        ${CMAKE_COMMAND} -E remove -f ${CMAKE_INSTALL_PREFIX}/bin/qwt6.dll &&
        ${CMAKE_COMMAND} -E rename ${CMAKE_INSTALL_PREFIX}/lib/qwt6.dll ${CMAKE_INSTALL_PREFIX}/bin/qwt6.dll
    LICENSE_FILES COPYING
)

############################################################
## Build Python2-SIP
############################################################
MyExternalProject_Add(python2_sip
    URL https://sourceforge.net/projects/pyqt/files/sip/sip-4.19.7/sip-4.19.7.zip
    URL_MD5 f8856b709eb92dfb9820d4234854922c
    CONFIGURE_COMMAND cd <SOURCE_DIR> &&
        ${PYTHON2_EXECUTABLE} configure.py --platform win32-msvc2015
        -b ${CMAKE_INSTALL_PREFIX}/bin
        -d ${CMAKE_INSTALL_PREFIX}/${PYTHON2_INSTALL_DIR}
        -e ${CMAKE_INSTALL_PREFIX}/include
        -v ${CMAKE_INSTALL_PREFIX}/sip
        --stubsdir=${CMAKE_INSTALL_PREFIX}/${PYTHON2_INSTALL_DIR}
    BUILD_COMMAND cd <SOURCE_DIR> && nmake
    INSTALL_COMMAND cd <SOURCE_DIR> && nmake install
    LICENSE_FILES LICENSE LICENSE-GPL2 LICENSE-GPL3
)

############################################################
## Build Python2-PyQt4
############################################################
MyExternalProject_Add(python2_pyqt4
    DEPENDS qt4 python2_sip
    URL http://sourceforge.net/projects/pyqt/files/PyQt4/PyQt-4.12.1/PyQt4_gpl_win-4.12.1.zip
    URL_MD5 88cde389b151572aa22dd0147cd325b6
    CONFIGURE_COMMAND cd <SOURCE_DIR> &&
        powershell -ExecutionPolicy ByPass
        -File ${PROJECT_SOURCE_DIR}/Scripts/python2_pyqt4_configure.ps1
        -InstallPrefix ${CMAKE_INSTALL_PREFIX}
        -Qt4Root ${QT4_ROOT}
        -Python2Executable ${PYTHON2_EXECUTABLE}
    BUILD_COMMAND cd <SOURCE_DIR> && nmake
    INSTALL_COMMAND cd <SOURCE_DIR> && nmake install
    LICENSE_FILES LICENSE
)

############################################################
## Build Python2-PyQwt5
############################################################
MyExternalProject_Add(python2_pyqwt5
    DEPENDS qt4 qwt5 python2_sip python2_pyqt4
    GIT_REPOSITORY https://github.com/PyQwt/PyQwt5.git
    GIT_TAG master
    CONFIGURE_COMMAND cd <SOURCE_DIR>/configure &&
        powershell -ExecutionPolicy ByPass
        -File ${PROJECT_SOURCE_DIR}/Scripts/python2_pyqwt5_configure.ps1
        -InstallPrefix ${CMAKE_INSTALL_PREFIX}
        -QwtInstallPrefix ${QWT5_INSTALL_PREFIX}
        -Qt4Root ${QT4_ROOT}
        -Python2Executable ${PYTHON2_EXECUTABLE}
    BUILD_COMMAND cd <SOURCE_DIR>/configure && nmake
    INSTALL_COMMAND cd <SOURCE_DIR>/configure && nmake install
    LICENSE_FILES COPYING COPYING.GSE COPYING.INTES COPYING.PyQwt
)
