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

#include "renderengine.hh"

#ifdef WKHTMLTOPDF_USE_WEBENGINE
#include "renderengine_webengine.hh"
#endif

#include <dllbegin.inc>
using namespace wkhtmltopdf;

// Static default backend - will be set to best available on first access
static RenderBackend s_defaultBackend = RenderBackend::WebEngine;  // Placeholder, will be auto-detected
static bool s_defaultBackendInitialized = false;

// ElementInfo implementation
QString ElementInfo::attribute(const QString & name) const {
	return attributes.value(name);
}

void ElementInfo::setAttribute(const QString & name, const QString & value) {
	attributes[name] = value;
}

// RenderPage factory method
RenderPage * RenderPage::create(RenderBackend backend, const settings::Web & webSettings) {
        if (backend == RenderBackend::WebEngine) {
#ifdef WKHTMLTOPDF_USE_WEBENGINE
                return new WebEngineRenderPage(webSettings);
#else
                return nullptr;
#endif
        }
        return nullptr;
}

// RenderEngineFactory implementation
RenderBackend RenderEngineFactory::getBestAvailableBackend() {
        // Only WebEngine is supported
        if (isBackendAvailable(RenderBackend::WebEngine)) {
                return RenderBackend::WebEngine;
        }
        // Should never happen if the backend is compiled in
        return RenderBackend::WebEngine;
}

RenderBackend RenderEngineFactory::defaultBackend() {
	// Auto-detect best backend on first access
	if (!s_defaultBackendInitialized) {
		s_defaultBackend = getBestAvailableBackend();
		s_defaultBackendInitialized = true;
	}
	return s_defaultBackend;
}

void RenderEngineFactory::setDefaultBackend(RenderBackend backend) {
	if (isBackendAvailable(backend)) {
		s_defaultBackend = backend;
		s_defaultBackendInitialized = true;
	}
}

QList<RenderBackend> RenderEngineFactory::availableBackends() {
        QList<RenderBackend> backends;
        if (isBackendAvailable(RenderBackend::WebEngine)) {
                backends.append(RenderBackend::WebEngine);
        }
        return backends;
}

bool RenderEngineFactory::isBackendAvailable(RenderBackend backend) {
        switch (backend) {
        case RenderBackend::WebEngine:
#ifdef WKHTMLTOPDF_USE_WEBENGINE
                return true;
#else
                return false;
#endif
        }
        return false;
}

QString RenderEngineFactory::backendName(RenderBackend backend) {
        switch (backend) {
        case RenderBackend::WebEngine:
                return "Qt WebEngine (Chromium)";
        default:
		return "Unknown";
	}
}

QString RenderEngineFactory::backendCapabilities(RenderBackend backend) {
        switch (backend) {
        case RenderBackend::WebEngine:
                return "Qt WebEngine based on Chromium (Blink). "
                       "Full modern CSS3 support including flexbox, grid, transforms, animations. "
		       "Recommended for modern HTML/CSS.";

	default:
		return "Unknown backend";
	}
}

#include <dllend.inc>
