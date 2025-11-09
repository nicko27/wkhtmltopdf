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

#ifdef WKHTMLTOPDF_USE_WEBKIT

#include "renderengine_webkit.hh"
#include <QWebElementCollection>

#include <dllbegin.inc>
using namespace wkhtmltopdf;

// ==================== WebKitRenderFrame ====================

WebKitRenderFrame::WebKitRenderFrame(QWebFrame * frame)
	: m_frame(frame) {
}

WebKitRenderFrame::~WebKitRenderFrame() {
	// Note: QWebFrame is owned by QWebPage, don't delete
}

QString WebKitRenderFrame::title() const {
	return m_frame ? m_frame->title() : QString();
}

QUrl WebKitRenderFrame::url() const {
	return m_frame ? m_frame->url() : QUrl();
}

QSize WebKitRenderFrame::contentsSize() const {
	return m_frame ? m_frame->contentsSize() : QSize();
}

void WebKitRenderFrame::render(QPainter * painter, const QRect & clip) {
	if (m_frame) {
		m_frame->render(painter, clip);
	}
}

void WebKitRenderFrame::evaluateJavaScript(const QString & script, JavaScriptCallback callback) {
	if (m_frame && callback) {
		QVariant result = m_frame->evaluateJavaScript(script);
		callback(result.toString());
	}
}

ElementInfo WebKitRenderFrame::convertWebElement(const QWebElement & element) const {
	ElementInfo info;
	info.tagName = element.tagName();

	// Copy all attributes
	foreach (const QString & attr, element.attributeNames()) {
		info.setAttribute(attr, element.attribute(attr));
	}

	// Get bounding box
	QRect geometry = element.geometry();
	info.x = geometry.x();
	info.y = geometry.y();
	info.width = geometry.width();
	info.height = geometry.height();

	return info;
}

void WebKitRenderFrame::findAllElements(const QString & selector, ElementsCallback callback) {
	if (!m_frame || !callback) return;

	QList<ElementInfo> results;
	QWebElementCollection elements = m_frame->findAllElements(selector);

	foreach (const QWebElement & element, elements) {
		results.append(convertWebElement(element));
	}

	callback(results);
}

void WebKitRenderFrame::findFirstElement(const QString & selector, ElementCallback callback) {
	if (!m_frame || !callback) return;

	QWebElement element = m_frame->findFirstElement(selector);
	if (!element.isNull()) {
		callback(convertWebElement(element));
	}
}

// ==================== WebKitRenderPage ====================

WebKitRenderPage::WebKitRenderPage(const settings::Web & webSettings)
	: m_page(new QWebPage())
	, m_mainFrame(nullptr)
	, m_loadCallback(nullptr) {

	// Connect signals
	connect(m_page, SIGNAL(loadStarted()), this, SLOT(onLoadStarted()));
	connect(m_page, SIGNAL(loadProgress(int)), this, SLOT(onLoadProgress(int)));
	connect(m_page, SIGNAL(loadFinished(bool)), this, SLOT(onLoadFinished(bool)));
	connect(m_page->mainFrame(), SIGNAL(printRequested(QWebFrame*)),
	        this, SLOT(onPrintRequested(QWebFrame*)));

	// Create main frame wrapper
	m_mainFrame = new WebKitRenderFrame(m_page->mainFrame());

	// Apply settings
	applySettings(webSettings);
}

WebKitRenderPage::~WebKitRenderPage() {
	delete m_mainFrame;
	delete m_page;
}

void WebKitRenderPage::load(const QUrl & url, LoadCallback callback) {
	m_loadCallback = callback;
	m_page->mainFrame()->load(url);
}

void WebKitRenderPage::setContent(const QString & html, const QUrl & baseUrl, LoadCallback callback) {
	m_loadCallback = callback;
	m_page->mainFrame()->setContent(html.toUtf8(), "text/html", baseUrl);
}

QString WebKitRenderPage::title() const {
	return m_page ? m_page->mainFrame()->title() : QString();
}

QUrl WebKitRenderPage::url() const {
	return m_page ? m_page->mainFrame()->url() : QUrl();
}

RenderFrame * WebKitRenderPage::mainFrame() {
	return m_mainFrame;
}

void WebKitRenderPage::applySettings(const settings::Web & settings) {
	if (!m_page) return;

	QWebSettings * webSettings = m_page->settings();

	webSettings->setAttribute(QWebSettings::PrintElementBackgrounds, settings.background);
	webSettings->setAttribute(QWebSettings::AutoLoadImages, settings.loadImages);
	webSettings->setAttribute(QWebSettings::JavascriptEnabled, settings.enableJavascript);
	webSettings->setAttribute(QWebSettings::PluginsEnabled, settings.enablePlugins);

	if (settings.minimumFontSize > 0) {
		webSettings->setFontSize(QWebSettings::MinimumFontSize, settings.minimumFontSize);
	}

	if (!settings.defaultEncoding.isEmpty()) {
		webSettings->setDefaultTextEncoding(settings.defaultEncoding);
	}

	if (!settings.userStyleSheet.isEmpty()) {
		webSettings->setUserStyleSheetUrl(QUrl::fromLocalFile(settings.userStyleSheet));
	}
}

void WebKitRenderPage::renderToPrinter(QPrinter * printer, std::function<void(bool)> callback) {
	if (!m_page || !printer) {
		if (callback) callback(false);
		return;
	}

	// WebKit rendering is synchronous
	m_page->mainFrame()->print(printer);

	if (callback) {
		callback(true);
	}
}

QImage WebKitRenderPage::renderToImage(const QSize & size) {
	if (!m_page) return QImage();

	QImage image(size, QImage::Format_ARGB32);
	image.fill(Qt::transparent);

	QPainter painter(&image);
	m_page->mainFrame()->render(&painter);
	painter.end();

	return image;
}

void WebKitRenderPage::setViewportSize(const QSize & size) {
	if (m_page) {
		m_page->setViewportSize(size);
	}
}

QSize WebKitRenderPage::viewportSize() const {
	return m_page ? m_page->viewportSize() : QSize();
}

void WebKitRenderPage::evaluateJavaScript(const QString & script, JavaScriptCallback callback) {
	if (m_page && m_page->mainFrame()) {
		QVariant result = m_page->mainFrame()->evaluateJavaScript(script);
		if (callback) {
			callback(result.toString());
		}
	}
}

void WebKitRenderPage::setNetworkAccessManager(QNetworkAccessManager * manager) {
	if (m_page) {
		m_page->setNetworkAccessManager(manager);
	}
}

void WebKitRenderPage::setJavaScriptAlertHandler(std::function<void(const QString &)> handler) {
	m_jsAlertHandler = handler;
}

void WebKitRenderPage::setJavaScriptConfirmHandler(std::function<bool(const QString &)> handler) {
	m_jsConfirmHandler = handler;
}

void WebKitRenderPage::setJavaScriptPromptHandler(std::function<bool(const QString &, const QString &, QString *)> handler) {
	m_jsPromptHandler = handler;
}

// Slots
void WebKitRenderPage::onLoadStarted() {
	emit loadStarted();
}

void WebKitRenderPage::onLoadProgress(int progress) {
	emit loadProgress(progress);
}

void WebKitRenderPage::onLoadFinished(bool ok) {
	emit loadFinished(ok);

	if (m_loadCallback) {
		m_loadCallback(ok);
		m_loadCallback = nullptr;
	}
}

void WebKitRenderPage::onPrintRequested(QWebFrame * frame) {
	Q_UNUSED(frame);
	emit printRequested();
}

#include <dllend.inc>

#endif // WKHTMLTOPDF_USE_WEBKIT
