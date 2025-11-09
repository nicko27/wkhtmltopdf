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

#ifdef WKHTMLTOPDF_USE_WEBENGINE

#include "renderengine_webengine.hh"
#include <QTemporaryFile>
#include <QBuffer>

#include <dllbegin.inc>
using namespace wkhtmltopdf;

// ==================== WebEngineRenderFrame ====================

WebEngineRenderFrame::WebEngineRenderFrame(QWebEnginePage * page)
	: m_page(page)
	, m_contentsSize(1024, 768) { // Default size
}

WebEngineRenderFrame::~WebEngineRenderFrame() {
	// Note: QWebEnginePage is owned by parent, don't delete
}

QString WebEngineRenderFrame::title() const {
	return m_page ? m_page->title() : QString();
}

QUrl WebEngineRenderFrame::url() const {
	return m_page ? m_page->url() : QUrl();
}

QSize WebEngineRenderFrame::contentsSize() const {
	// WebEngine doesn't provide direct access to content size
	// We need to query it via JavaScript
	if (m_page) {
		// This is a simplification - in real usage, this should be async
		// For now, return the last known size
		return m_contentsSize;
	}
	return QSize();
}

void WebEngineRenderFrame::render(QPainter * painter, const QRect & clip) {
	// WebEngine doesn't support direct rendering to a painter
	// This is a limitation - rendering must be done via printToPdf or grab
	Q_UNUSED(painter);
	Q_UNUSED(clip);
	// TODO: Implement via screenshot if needed for image conversion
}

void WebEngineRenderFrame::evaluateJavaScript(const QString & script, JavaScriptCallback callback) {
	if (!m_page) {
		if (callback) callback(QString());
		return;
	}

	m_page->runJavaScript(script, [callback](const QVariant & result) {
		if (callback) {
			callback(result.toString());
		}
	});
}

void WebEngineRenderFrame::findAllElements(const QString & selector, ElementsCallback callback) {
	if (!m_page || !callback) return;

	// Use JavaScript to query elements and extract their properties
	QString script = QString(
		"(function() {"
		"  var elements = document.querySelectorAll('%1');"
		"  var results = [];"
		"  for (var i = 0; i < elements.length; i++) {"
		"    var el = elements[i];"
		"    var rect = el.getBoundingClientRect();"
		"    var attrs = {};"
		"    for (var j = 0; j < el.attributes.length; j++) {"
		"      var attr = el.attributes[j];"
		"      attrs[attr.name] = attr.value;"
		"    }"
		"    results.push({"
		"      tagName: el.tagName,"
		"      attributes: attrs,"
		"      x: rect.left,"
		"      y: rect.top,"
		"      width: rect.width,"
		"      height: rect.height"
		"    });"
		"  }"
		"  return JSON.stringify(results);"
		"})();"
	).arg(selector);

	m_page->runJavaScript(script, [callback](const QVariant & result) {
		// Parse JSON result and convert to ElementInfo list
		// This is a simplified implementation
		QList<ElementInfo> elements;
		// TODO: Parse JSON result properly
		callback(elements);
	});
}

void WebEngineRenderFrame::findFirstElement(const QString & selector, ElementCallback callback) {
	if (!m_page || !callback) return;

	// Similar to findAllElements but for single element
	QString script = QString(
		"(function() {"
		"  var el = document.querySelector('%1');"
		"  if (!el) return null;"
		"  var rect = el.getBoundingClientRect();"
		"  var attrs = {};"
		"  for (var i = 0; i < el.attributes.length; i++) {"
		"    var attr = el.attributes[i];"
		"    attrs[attr.name] = attr.value;"
		"  }"
		"  return JSON.stringify({"
		"    tagName: el.tagName,"
		"    attributes: attrs,"
		"    x: rect.left,"
		"    y: rect.top,"
		"    width: rect.width,"
		"    height: rect.height"
		"  });"
		"})();"
	).arg(selector);

	m_page->runJavaScript(script, [callback](const QVariant & result) {
		// Parse JSON result and convert to ElementInfo
		ElementInfo element;
		// TODO: Parse JSON result properly
		callback(element);
	});
}

// ==================== CustomWebEnginePage ====================

CustomWebEnginePage::CustomWebEnginePage(QWebEngineProfile * profile, QObject * parent)
	: QWebEnginePage(profile, parent) {
}

void CustomWebEnginePage::setJavaScriptAlertHandler(std::function<void(const QString &)> handler) {
	m_jsAlertHandler = handler;
}

void CustomWebEnginePage::setJavaScriptConfirmHandler(std::function<bool(const QString &)> handler) {
	m_jsConfirmHandler = handler;
}

void CustomWebEnginePage::setJavaScriptPromptHandler(std::function<bool(const QString &, const QString &, QString *)> handler) {
	m_jsPromptHandler = handler;
}

void CustomWebEnginePage::javaScriptAlert(const QUrl & securityOrigin, const QString & msg) {
	Q_UNUSED(securityOrigin);
	if (m_jsAlertHandler) {
		m_jsAlertHandler(msg);
	} else {
		QWebEnginePage::javaScriptAlert(securityOrigin, msg);
	}
}

bool CustomWebEnginePage::javaScriptConfirm(const QUrl & securityOrigin, const QString & msg) {
	Q_UNUSED(securityOrigin);
	if (m_jsConfirmHandler) {
		return m_jsConfirmHandler(msg);
	} else {
		return QWebEnginePage::javaScriptConfirm(securityOrigin, msg);
	}
}

bool CustomWebEnginePage::javaScriptPrompt(const QUrl & securityOrigin, const QString & msg,
                                            const QString & defaultValue, QString * result) {
	Q_UNUSED(securityOrigin);
	if (m_jsPromptHandler) {
		return m_jsPromptHandler(msg, defaultValue, result);
	} else {
		return QWebEnginePage::javaScriptPrompt(securityOrigin, msg, defaultValue, result);
	}
}

// ==================== WebEngineRenderPage ====================

WebEngineRenderPage::WebEngineRenderPage(const settings::Web & webSettings)
	: m_profile(new QWebEngineProfile())
	, m_page(nullptr)
	, m_mainFrame(nullptr)
	, m_loadCallback(nullptr)
	, m_printCallback(nullptr)
	, m_viewportSize(1024, 768) {

	// Create custom page
	m_page = new CustomWebEnginePage(m_profile, this);

	// Connect signals
	connect(m_page, &QWebEnginePage::loadStarted, this, &WebEngineRenderPage::onLoadStarted);
	connect(m_page, &QWebEnginePage::loadProgress, this, &WebEngineRenderPage::onLoadProgress);
	connect(m_page, &QWebEnginePage::loadFinished, this, &WebEngineRenderPage::onLoadFinished);
	connect(m_page, &QWebEnginePage::pdfPrintingFinished, this, &WebEngineRenderPage::onPrintingFinished);

	// Create main frame wrapper
	m_mainFrame = new WebEngineRenderFrame(m_page);

	// Apply settings
	applySettings(webSettings);
}

WebEngineRenderPage::~WebEngineRenderPage() {
	delete m_mainFrame;
	delete m_page;
	delete m_profile;
}

void WebEngineRenderPage::load(const QUrl & url, LoadCallback callback) {
	m_loadCallback = callback;
	m_page->load(url);
}

void WebEngineRenderPage::setContent(const QString & html, const QUrl & baseUrl, LoadCallback callback) {
	m_loadCallback = callback;
	m_page->setHtml(html, baseUrl);
}

QString WebEngineRenderPage::title() const {
	return m_page ? m_page->title() : QString();
}

QUrl WebEngineRenderPage::url() const {
	return m_page ? m_page->url() : QUrl();
}

RenderFrame * WebEngineRenderPage::mainFrame() {
	return m_mainFrame;
}

void WebEngineRenderPage::applySettings(const settings::Web & settings) {
	if (!m_page) return;

	QWebEngineSettings * webSettings = m_page->settings();

	// Map wkhtmltopdf settings to QWebEngineSettings
	webSettings->setAttribute(QWebEngineSettings::AutoLoadImages, settings.loadImages);
	webSettings->setAttribute(QWebEngineSettings::JavascriptEnabled, settings.enableJavascript);
	webSettings->setAttribute(QWebEngineSettings::PluginsEnabled, settings.enablePlugins);

	if (settings.minimumFontSize > 0) {
		webSettings->setFontSize(QWebEngineSettings::MinimumFontSize, settings.minimumFontSize);
	}

	if (!settings.defaultEncoding.isEmpty()) {
		webSettings->setDefaultTextEncoding(settings.defaultEncoding);
	}

	// Note: WebEngine doesn't support user stylesheets in the same way
	// This would need to be injected via JavaScript if needed
}

void WebEngineRenderPage::renderToPrinter(QPrinter * printer, std::function<void(bool)> callback) {
	if (!m_page || !printer) {
		if (callback) callback(false);
		return;
	}

	m_printCallback = callback;

	// WebEngine uses printToPdf which is asynchronous and outputs to a file
	// We need to create a temporary file and then convert to QPrinter
	QTemporaryFile tempFile;
	if (!tempFile.open()) {
		if (callback) callback(false);
		return;
	}

	QString tempPath = tempFile.fileName();
	tempFile.close();

	// Set up page layout to match printer settings
	QPageLayout layout = printer->pageLayout();
	m_page->printToPdf(tempPath, layout);

	// Result will be handled in onPrintingFinished slot
}

QImage WebEngineRenderPage::renderToImage(const QSize & size) {
	// WebEngine doesn't support direct rendering to QImage
	// Would need to use QWebEngineView and grab() for this
	// This is a limitation of the WebEngine API
	Q_UNUSED(size);
	return QImage();
}

void WebEngineRenderPage::setViewportSize(const QSize & size) {
	m_viewportSize = size;
	// WebEngine doesn't have a direct viewport size setting
	// This would typically be handled by the view widget
}

QSize WebEngineRenderPage::viewportSize() const {
	return m_viewportSize;
}

void WebEngineRenderPage::evaluateJavaScript(const QString & script, JavaScriptCallback callback) {
	if (m_page) {
		m_page->runJavaScript(script, [callback](const QVariant & result) {
			if (callback) {
				callback(result.toString());
			}
		});
	}
}

void WebEngineRenderPage::setNetworkAccessManager(QNetworkAccessManager * manager) {
	// WebEngine doesn't use QNetworkAccessManager
	// Network access is handled through QWebEngineUrlRequestInterceptor
	// This would need a different approach
	Q_UNUSED(manager);
}

void WebEngineRenderPage::setJavaScriptAlertHandler(std::function<void(const QString &)> handler) {
	if (m_page) {
		m_page->setJavaScriptAlertHandler(handler);
	}
}

void WebEngineRenderPage::setJavaScriptConfirmHandler(std::function<bool(const QString &)> handler) {
	if (m_page) {
		m_page->setJavaScriptConfirmHandler(handler);
	}
}

void WebEngineRenderPage::setJavaScriptPromptHandler(std::function<bool(const QString &, const QString &, QString *)> handler) {
	if (m_page) {
		m_page->setJavaScriptPromptHandler(handler);
	}
}

// Slots
void WebEngineRenderPage::onLoadStarted() {
	emit loadStarted();
}

void WebEngineRenderPage::onLoadProgress(int progress) {
	emit loadProgress(progress);
}

void WebEngineRenderPage::onLoadFinished(bool ok) {
	emit loadFinished(ok);

	if (m_loadCallback) {
		m_loadCallback(ok);
		m_loadCallback = nullptr;
	}
}

void WebEngineRenderPage::onPrintingFinished(const QString & filePath, bool success) {
	// PDF has been saved to file
	// If we needed to output to QPrinter, we would need to read the file
	// and write it to the printer's output stream
	if (m_printCallback) {
		m_printCallback(success);
		m_printCallback = nullptr;
	}
}

#include <dllend.inc>

#endif // WKHTMLTOPDF_USE_WEBENGINE
