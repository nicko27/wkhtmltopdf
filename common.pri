# Copyright 2010-2020 wkhtmltopdf authors
#
# This file is part of wkhtmltopdf.
#
# wkhtmltopdf is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# wkhtmltopdf is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with wkhtmltopdf.  If not, see <http:#www.gnu.org/licenses/>.

CONFIG(static, shared|static):lessThan(QT_MAJOR_VERSION, 5) {
    DEFINES  += QT4_STATICPLUGIN_TEXTCODECS
    QTPLUGIN += qcncodecs qjpcodecs qkrcodecs qtwcodecs
}

INCLUDEPATH += ../../src/lib
RESOURCES    = $$PWD/wkhtmltopdf.qrc

win32:      CONFIG += console
win32-g++*: QMAKE_LFLAGS += -static -static-libgcc -static-libstdc++

# Installation base directory
isEmpty(INSTALLBASE): INSTALLBASE = /usr/local

# Backend selection - WebEngine ONLY (WebKit abandoned)
# WebEngine provides modern Chromium engine with full CSS3/HTML5 support
RENDER_BACKEND = $$(RENDER_BACKEND)
isEmpty(RENDER_BACKEND): RENDER_BACKEND = webengine

# WebEngine backend (Chromium with full CSS3 support)
contains(RENDER_BACKEND, webengine) {
    greaterThan(QT_MAJOR_VERSION, 4) {
        DEFINES += WKHTMLTOPDF_USE_WEBENGINE
        QT += webenginewidgets webengine network xmlpatterns svg printsupport
    } else {
        error("Qt WebEngine requires Qt 5 or later")
    }
} else {
    error("Only WebEngine backend is supported. WebKit has been abandoned. Set RENDER_BACKEND=webengine")
}

# version related information
VERSION_TEXT=$$(WKHTMLTOX_VERSION)
isEmpty(VERSION_TEXT): VERSION_TEXT=$$cat($$PWD/VERSION)
VERSION_LIST=$$split(VERSION_TEXT, "-")

count(VERSION_LIST, 1): VERSION=$$VERSION_TEXT
else:                   VERSION=$$member(VERSION_LIST, 0)

DEFINES += VERSION=$$VERSION FULL_VERSION=$$VERSION_TEXT BUILDING_WKHTMLTOX
