// -*- mode: c++; tab-width: 4; indent-tabs-mode: t; eval: (progn (c-set-style "stroustrup") (c-set-offset 'innamespace 0)); -*-
// vi:set ts=4 sts=4 sw=4 noet :
//
// Copyright 2024-2025 wkhtmltopdf authors
//
// This file is part of wkhtmltopdf.
//
// wkhtmltopdf is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

#ifndef __VALIDATOR_HH__
#define __VALIDATOR_HH__

#include <QString>
#include <QStringList>
#include <QList>
#include "renderengine.hh"

namespace wkhtmltopdf {

/*!
 * \brief CSS Feature support levels
 */
enum class CSSFeature {
	Flexbox,
	Grid,
	Transforms,
	Animations,
	Gradients,
	CustomProperties,
	CalcFunction,
	MediaQueries,
	BackgroundBlendMode
};

/*!
 * \brief Validation message severity
 */
enum class MessageSeverity {
	Info,
	Warning,
	Error
};

/*!
 * \brief Single validation message
 */
struct ValidationMessage {
	MessageSeverity severity;
	QString message;
	QString suggestion;
	int line;
	int column;

	ValidationMessage(MessageSeverity sev, const QString& msg, const QString& suggest = QString(), int ln = -1, int col = -1)
		: severity(sev), message(msg), suggestion(suggest), line(ln), column(col) {}
};

/*!
 * \brief HTML/CSS Validator
 *
 * Validates HTML and CSS content and checks compatibility with rendering backends
 */
class Validator {
public:
	/*!
	 * \brief Validation result structure
	 */
	struct ValidationResult {
		bool isValid;
		QList<ValidationMessage> messages;
		QStringList detectedFeatures;

		ValidationResult() : isValid(true) {}

		bool hasErrors() const {
			for (const auto& msg : messages) {
				if (msg.severity == MessageSeverity::Error) return true;
			}
			return false;
		}

		bool hasWarnings() const {
			for (const auto& msg : messages) {
				if (msg.severity == MessageSeverity::Warning) return true;
			}
			return false;
		}

		int errorCount() const {
			int count = 0;
			for (const auto& msg : messages) {
				if (msg.severity == MessageSeverity::Error) count++;
			}
			return count;
		}

		int warningCount() const {
			int count = 0;
			for (const auto& msg : messages) {
				if (msg.severity == MessageSeverity::Warning) count++;
			}
			return count;
		}
	};

	/*!
	 * \brief Validate HTML content
	 * \param html HTML content to validate
	 * \return Validation result with messages
	 */
	static ValidationResult validateHTML(const QString& html);

	/*!
	 * \brief Validate CSS content
	 * \param css CSS content to validate
	 * \return Validation result with messages
	 */
	static ValidationResult validateCSS(const QString& css);

	/*!
	 * \brief Check CSS feature support for a backend
	 * \param css CSS content
	 * \param backend Rendering backend to check against
	 * \return Validation result with compatibility warnings
	 */
	static ValidationResult checkCSSCompatibility(const QString& css, RenderBackend backend);

	/*!
	 * \brief Check if a CSS feature is supported by backend
	 * \param feature CSS feature to check
	 * \param backend Rendering backend
	 * \return true if feature is supported
	 */
	static bool isFeatureSupported(CSSFeature feature, RenderBackend backend);

	/*!
	 * \brief Get human-readable name for CSS feature
	 * \param feature CSS feature
	 * \return Feature name
	 */
	static QString featureName(CSSFeature feature);

	/*!
	 * \brief Detect CSS features used in content
	 * \param css CSS content
	 * \return List of detected feature names
	 */
	static QStringList detectCSSFeatures(const QString& css);

	/*!
	 * \brief Get suggestion for using a feature with wrong backend
	 * \param feature CSS feature
	 * \param currentBackend Current backend
	 * \return Suggestion message
	 */
	static QString getSuggestion(CSSFeature feature, RenderBackend currentBackend);

private:
	// Helper methods
	static bool containsFlexbox(const QString& css);
	static bool containsGrid(const QString& css);
	static bool containsTransforms(const QString& css);
	static bool containsAnimations(const QString& css);
	static bool containsGradients(const QString& css);
	static bool containsCustomProperties(const QString& css);
	static bool containsCalc(const QString& css);
};

} // namespace wkhtmltopdf

#endif // __VALIDATOR_HH__
