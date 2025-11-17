// -*- mode: c++; tab-width: 4; indent-tabs-mode: t; eval: (progn (c-set-style "stroustrup") (c-set-offset 'innamespace 0)); -*-
// vi:set ts=4 sts=4 sw=4 noet :
//
// Copyright 2010-2020 wkhtmltopdf authors
//
// This file is part of wkhtmltopdf.
//
// wkhtmltopdf is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// wkhtmltopdf is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with wkhtmltopdf.  If not, see <http://www.gnu.org/licenses/>.


#include "imageconverter_p.hh"
#include "imagesettings.hh"
#include <QBuffer>
#include <QDebug>
#include <QEventLoop>
#include <QFileInfo>
#include <QImage>
#include <QObject>
#include <QObject>
#include <QPainter>
#include <QSvgGenerator>
#include <QUrl>
#include <qapplication.h>

#ifdef Q_OS_WIN32
#include <fcntl.h>
#include <io.h>
#endif

namespace wkhtmltopdf {

ImageConverterPrivate::ImageConverterPrivate(ImageConverter & o, wkhtmltopdf::settings::ImageGlobal & s, const QString * data):
	settings(s),
	loader(s.loadGlobal, 96, true),
	out(o) {
	out.emitCheckboxSvgs(s.loadPage);
	if (data) inputData = *data;

	phaseDescriptions.push_back("Loading page");
	phaseDescriptions.push_back("Rendering");
	phaseDescriptions.push_back("Done");

	connect(&loader, SIGNAL(loadProgress(int)), this, SLOT(loadProgress(int)));
	connect(&loader, SIGNAL(loadFinished(bool)), this, SLOT(pagesLoaded(bool)));
	connect(&loader, SIGNAL(error(QString)), this, SLOT(forwardError(QString)));
	connect(&loader, SIGNAL(warning(QString)), this, SLOT(forwardWarning(QString)));
	connect(&loader, SIGNAL(info(QString)), this, SLOT(forwardInfo(QString)));
	connect(&loader, SIGNAL(debug(QString)), this, SLOT(forwardDebug(QString)));
}

void ImageConverterPrivate::beginConvert() {
        error = false;
        conversionDone = false;
        errorCode = 0;
        progressString = "0%";
#ifndef WKHTMLTOPDF_USE_WEBKIT
        emit out.error("Image conversion requires the legacy WebKit backend, which is no longer available in WebEngine-only builds.");
        fail();
        return;
#else
        loaderObject = loader.addResource(settings.in, settings.loadPage, &inputData);
        updateWebSettings(loaderObject->page.settings(), settings.web);
        currentPhase=0;
        emit out. phaseChanged();
        loadProgress(0);
        loader.load();
#endif
}


void ImageConverterPrivate::clearResources() {
	loader.clearResources();
}

void ImageConverterPrivate::pagesLoaded(bool ok) {
        Q_UNUSED(ok);
        emit out.error("Image conversion requires the legacy WebKit backend, which is no longer available in WebEngine-only builds.");
        fail();
        return;
}

}

Converter & ImageConverterPrivate::outer() {
	return out;
}

ImageConverter::~ImageConverter() {
	delete d;
}

ConverterPrivate & ImageConverter::priv() {
	return *d;
}


ImageConverter::ImageConverter(wkhtmltopdf::settings::ImageGlobal & s, const QString * data) {
	d = new ImageConverterPrivate(*this, s, data);
}

const QByteArray & ImageConverter::output() {
	return d->outputData;
}

}
