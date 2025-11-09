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

#ifndef __RENDERENGINE_WEBKIT_HH__
#define __RENDERENGINE_WEBKIT_HH__

#ifdef WKHTMLTOPDF_USE_WEBKIT

#include "renderengine.hh"

#if QT_VERSION >= 0x050000
#include <QtWebKitWidgets>
#else
#include <QWebPage>
#include <QWebFrame>
#include <QWebElement>
#include <QWebSettings>
#endif

#include <QPrinter>
#include <QPainter>

#include <dllbegin.inc>

namespace wkhtmltopdf {

/*!
 * \brief WebKit implementation of RenderFrame
 */
class DLL_LOCAL WebKitRenderFrame : public RenderFrame {
	Q_OBJECT
public:
	WebKitRenderFrame(QWebFrame * frame);
	virtual ~WebKitRenderFrame();

	// RenderFrame interface
	virtual QString title() const override;
	virtual QUrl url() const override;
	virtual QSize contentsSize() const override;
	virtual void render(QPainter * painter, const QRect & clip = QRect()) override;
	virtual void evaluateJavaScript(const QString & script, JavaScriptCallback callback) override;
	virtual void findAllElements(const QString & selector, ElementsCallback callback) override;
	virtual void findFirstElement(const QString & selector, ElementCallback callback) override;

	// Get the underlying QWebFrame (for legacy code compatibility)
	QWebFrame * webFrame() const { return m_frame; }

private:
	ElementInfo convertWebElement(const QWebElement & element) const;

	QWebFrame * m_frame;
};

/*!
 * \brief WebKit implementation of RenderPage
 */
class DLL_LOCAL WebKitRenderPage : public RenderPage {
	Q_OBJECT
public:
	WebKitRenderPage(const settings::Web & webSettings);
	virtual ~WebKitRenderPage();

	// RenderPage interface
	virtual void load(const QUrl & url, LoadCallback callback) override;
	virtual void setContent(const QString & html, const QUrl & baseUrl, LoadCallback callback) override;
	virtual QString title() const override;
	virtual QUrl url() const override;
	virtual RenderFrame * mainFrame() override;
	virtual void applySettings(const settings::Web & settings) override;
	virtual void renderToPrinter(QPrinter * printer, std::function<void(bool)> callback) override;
	virtual QImage renderToImage(const QSize & size) override;
	virtual void setViewportSize(const QSize & size) override;
	virtual QSize viewportSize() const override;
	virtual void evaluateJavaScript(const QString & script, JavaScriptCallback callback) override;
	virtual void setNetworkAccessManager(QNetworkAccessManager * manager) override;
	virtual void setJavaScriptAlertHandler(std::function<void(const QString &)> handler) override;
	virtual void setJavaScriptConfirmHandler(std::function<bool(const QString &)> handler) override;
	virtual void setJavaScriptPromptHandler(std::function<bool(const QString &, const QString &, QString *)> handler) override;

	// Get the underlying QWebPage (for legacy code compatibility)
	QWebPage * webPage() const { return m_page; }

private slots:
	void onLoadStarted();
	void onLoadProgress(int progress);
	void onLoadFinished(bool ok);
	void onPrintRequested(QWebFrame * frame);

private:
	QWebPage * m_page;
	WebKitRenderFrame * m_mainFrame;
	LoadCallback m_loadCallback;

	// JavaScript handler callbacks
	std::function<void(const QString &)> m_jsAlertHandler;
	std::function<bool(const QString &)> m_jsConfirmHandler;
	std::function<bool(const QString &, const QString &, QString *)> m_jsPromptHandler;

	friend class WebKitRenderPagePrivate;
};

}

#include <dllend.inc>

#endif // WKHTMLTOPDF_USE_WEBKIT
#endif //__RENDERENGINE_WEBKIT_HH__
