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

#ifndef __RENDERENGINE_WEBENGINE_HH__
#define __RENDERENGINE_WEBENGINE_HH__

#ifdef WKHTMLTOPDF_USE_WEBENGINE

#include "renderengine.hh"

#include <QWebEnginePage>
#include <QWebEngineSettings>
#include <QWebEngineProfile>
#include <QPrinter>
#include <QPainter>
#include <QEventLoop>

#include <dllbegin.inc>

namespace wkhtmltopdf {

/*!
 * \brief WebEngine implementation of RenderFrame
 *
 * Note: Qt WebEngine doesn't provide direct frame access like WebKit did.
 * Frame operations are emulated via JavaScript execution.
 */
class DLL_LOCAL WebEngineRenderFrame : public RenderFrame {
	Q_OBJECT
public:
	WebEngineRenderFrame(QWebEnginePage * page);
	virtual ~WebEngineRenderFrame();

	// RenderFrame interface
	virtual QString title() const override;
	virtual QUrl url() const override;
	virtual QSize contentsSize() const override;
	virtual void render(QPainter * painter, const QRect & clip = QRect()) override;
	virtual void evaluateJavaScript(const QString & script, JavaScriptCallback callback) override;
	virtual void findAllElements(const QString & selector, ElementsCallback callback) override;
	virtual void findFirstElement(const QString & selector, ElementCallback callback) override;

private:
	QWebEnginePage * m_page;
	mutable QSize m_contentsSize;
};

/*!
 * \brief Custom QWebEnginePage subclass to handle JavaScript dialogs
 */
class DLL_LOCAL CustomWebEnginePage : public QWebEnginePage {
	Q_OBJECT
public:
	CustomWebEnginePage(QWebEngineProfile * profile, QObject * parent = nullptr);

	void setJavaScriptAlertHandler(std::function<void(const QString &)> handler);
	void setJavaScriptConfirmHandler(std::function<bool(const QString &)> handler);
	void setJavaScriptPromptHandler(std::function<bool(const QString &, const QString &, QString *)> handler);

protected:
	virtual void javaScriptAlert(const QUrl & securityOrigin, const QString & msg) override;
	virtual bool javaScriptConfirm(const QUrl & securityOrigin, const QString & msg) override;
	virtual bool javaScriptPrompt(const QUrl & securityOrigin, const QString & msg,
	                               const QString & defaultValue, QString * result) override;

private:
	std::function<void(const QString &)> m_jsAlertHandler;
	std::function<bool(const QString &)> m_jsConfirmHandler;
	std::function<bool(const QString &, const QString &, QString *)> m_jsPromptHandler;
};

/*!
 * \brief WebEngine implementation of RenderPage
 */
class DLL_LOCAL WebEngineRenderPage : public RenderPage {
	Q_OBJECT
public:
	WebEngineRenderPage(const settings::Web & webSettings);
	virtual ~WebEngineRenderPage();

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

	// Get the underlying QWebEnginePage (for debugging/advanced usage)
	CustomWebEnginePage * webEnginePage() const { return m_page; }

private slots:
	void onLoadStarted();
	void onLoadProgress(int progress);
	void onLoadFinished(bool ok);
	void onPrintingFinished(const QString & filePath, bool success);

private:
	QWebEngineProfile * m_profile;
	CustomWebEnginePage * m_page;
	WebEngineRenderFrame * m_mainFrame;
	LoadCallback m_loadCallback;
	std::function<void(bool)> m_printCallback;
	QSize m_viewportSize;
};

}

#include <dllend.inc>

#endif // WKHTMLTOPDF_USE_WEBENGINE
#endif //__RENDERENGINE_WEBENGINE_HH__
