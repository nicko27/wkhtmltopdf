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

#ifndef __RENDERENGINE_HH__
#define __RENDERENGINE_HH__

#include <QObject>
#include <QString>
#include <QUrl>
#include <QSize>
#include <QHash>
#include <QList>
#include <QPair>
#include <QRect>
#include <QImage>
#include <functional>

// Forward declarations for Qt classes
class QPainter;
class QPrinter;
class QNetworkAccessManager;

#include "websettings.hh"
#include "loadsettings.hh"

#include <dllbegin.inc>

namespace wkhtmltopdf {

// Forward declarations
class RenderEngine;
class RenderPage;
class RenderFrame;
class RenderElement;

/*!
 * \brief Rendering backend options (WebEngine only)
 */
enum class RenderBackend {
        WebEngine  // Qt WebEngine (modern, full Chromium CSS support)
};

/*!
 * \brief Structure representing a DOM element's properties
 *
 * Used to abstract away QWebElement for cross-backend compatibility.
 * WebEngine doesn't have direct DOM access, so we extract properties
 * via JavaScript and store them in this structure.
 */
struct DLL_PUBLIC ElementInfo {
	QString tagName;
	QString id;
	QString attribute(const QString & name) const;
	void setAttribute(const QString & name, const QString & value);
	QHash<QString, QString> attributes;
	QList<ElementInfo> children;

	// Bounding box information
	int x, y, width, height;
};

/*!
 * \brief Callback types for asynchronous operations
 */
using LoadCallback = std::function<void(bool success)>;
using ElementCallback = std::function<void(const ElementInfo & element)>;
using ElementsCallback = std::function<void(const QList<ElementInfo> & elements)>;
using JavaScriptCallback = std::function<void(const QString & result)>;

/*!
 * \brief Abstract interface for a rendered frame
 *
 * Represents a frame within a page. WebEngine frame access is more limited
 * and done via JavaScript.
 */
class DLL_PUBLIC RenderFrame : public QObject {
	Q_OBJECT
public:
	virtual ~RenderFrame() {}

	// Content access
	virtual QString title() const = 0;
	virtual QUrl url() const = 0;
	virtual QSize contentsSize() const = 0;

	// Rendering
	virtual void render(QPainter * painter, const QRect & clip = QRect()) = 0;

	// JavaScript execution
	virtual void evaluateJavaScript(const QString & script, JavaScriptCallback callback) = 0;

	// DOM access (async for WebEngine compatibility)
	virtual void findAllElements(const QString & selector, ElementsCallback callback) = 0;
	virtual void findFirstElement(const QString & selector, ElementCallback callback) = 0;

signals:
	void loadFinished(bool ok);
};

/*!
 * \brief Abstract interface for a web page
 *
 * This is the main abstraction over QWebEnginePage.
 * All operations that need to work with the backend go through this interface.
 */
class DLL_PUBLIC RenderPage : public QObject {
	Q_OBJECT
public:
	virtual ~RenderPage() {}

	// Factory method to create the appropriate implementation
	static RenderPage * create(RenderBackend backend, const settings::Web & webSettings);

	// Page loading
	virtual void load(const QUrl & url, LoadCallback callback) = 0;
	virtual void setContent(const QString & html, const QUrl & baseUrl, LoadCallback callback) = 0;

	// Page properties
	virtual QString title() const = 0;
	virtual QUrl url() const = 0;
	virtual RenderFrame * mainFrame() = 0;

	// Web settings
	virtual void applySettings(const settings::Web & settings) = 0;

	// Rendering - PDF
	virtual void renderToPrinter(QPrinter * printer, std::function<void(bool)> callback) = 0;

	// Rendering - Image
	virtual QImage renderToImage(const QSize & size) = 0;

	// Viewport
	virtual void setViewportSize(const QSize & size) = 0;
	virtual QSize viewportSize() const = 0;

	// JavaScript
	virtual void evaluateJavaScript(const QString & script, JavaScriptCallback callback) = 0;

	// Network
	virtual void setNetworkAccessManager(QNetworkAccessManager * manager) = 0;

	// Callbacks for JavaScript alerts/confirms/prompts
	virtual void setJavaScriptAlertHandler(std::function<void(const QString &)> handler) = 0;
	virtual void setJavaScriptConfirmHandler(std::function<bool(const QString &)> handler) = 0;
	virtual void setJavaScriptPromptHandler(std::function<bool(const QString &, const QString &, QString *)> handler) = 0;

signals:
	void loadStarted();
	void loadProgress(int progress);
	void loadFinished(bool ok);
	void printRequested();

protected:
	RenderPage() {}
};

/*!
 * \brief Factory class for creating rendering backends
 */
class DLL_PUBLIC RenderEngineFactory {
public:
	// Get the default backend (can be configured at build time or runtime)
	static RenderBackend defaultBackend();

	// Set the default backend (useful for testing or runtime switching)
	static void setDefaultBackend(RenderBackend backend);

        // Get the best available backend (WebEngine only)
	static RenderBackend getBestAvailableBackend();

	// Check if a backend is available (compiled in)
	static bool isBackendAvailable(RenderBackend backend);

	// Get list of all available backends
	static QList<RenderBackend> availableBackends();

	// Get backend name as string
	static QString backendName(RenderBackend backend);

	// Get backend CSS capabilities description
	static QString backendCapabilities(RenderBackend backend);
};

}

#include <dllend.inc>
#endif //__RENDERENGINE_HH__
