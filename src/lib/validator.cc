// -*- mode: c++; tab-width: 4; indent-tabs-mode: t; eval: (progn (c-set-style "stroustrup") (c-set-offset 'innamespace 0)); -*-
// vi:set ts=4 sts=4 sw=4 noet :

#include "validator.hh"
#include <QRegularExpression>
#include <QtGlobal>

namespace wkhtmltopdf {

// Check if CSS contains flexbox
bool Validator::containsFlexbox(const QString& css) {
	QRegularExpression flexRe("display\\s*:\\s*flex");
	return flexRe.match(css).hasMatch();
}

// Check if CSS contains grid
bool Validator::containsGrid(const QString& css) {
	QRegularExpression gridRe("display\\s*:\\s*grid|grid-template");
	return gridRe.match(css).hasMatch();
}

// Check if CSS contains transforms
bool Validator::containsTransforms(const QString& css) {
	QRegularExpression transformRe("transform\\s*:");
	return transformRe.match(css).hasMatch();
}

// Check if CSS contains animations
bool Validator::containsAnimations(const QString& css) {
	QRegularExpression animRe("@keyframes|animation\\s*:");
	return animRe.match(css).hasMatch();
}

// Check if CSS contains gradients
bool Validator::containsGradients(const QString& css) {
	QRegularExpression gradRe("linear-gradient|radial-gradient|conic-gradient");
	return gradRe.match(css).hasMatch();
}

// Check if CSS contains custom properties
bool Validator::containsCustomProperties(const QString& css) {
	QRegularExpression varRe("var\\(--");
	return varRe.match(css).hasMatch();
}

// Check if CSS contains calc()
bool Validator::containsCalc(const QString& css) {
	QRegularExpression calcRe("calc\\(");
	return calcRe.match(css).hasMatch();
}

// Validate HTML content
Validator::ValidationResult Validator::validateHTML(const QString& html) {
	ValidationResult result;

	// Basic HTML validation
	if (html.trimmed().isEmpty()) {
		result.messages.append(ValidationMessage(
			MessageSeverity::Error,
			"HTML content is empty",
			"Provide valid HTML content"
		));
		result.isValid = false;
		return result;
	}

	// Check for DOCTYPE
	if (!html.contains("<!DOCTYPE", Qt::CaseInsensitive)) {
		result.messages.append(ValidationMessage(
			MessageSeverity::Warning,
			"No DOCTYPE declaration found",
			"Add <!DOCTYPE html> at the beginning of your HTML"
		));
	}

	// Check for basic structure
	if (!html.contains("<html", Qt::CaseInsensitive)) {
		result.messages.append(ValidationMessage(
			MessageSeverity::Warning,
			"No <html> tag found",
			"Use proper HTML structure with <html>, <head>, and <body> tags"
		));
	}

	return result;
}

// Validate CSS content
Validator::ValidationResult Validator::validateCSS(const QString& css) {
	ValidationResult result;

	if (css.trimmed().isEmpty()) {
		// Empty CSS is valid
		return result;
	}

	// Check for common CSS syntax errors
	int openBraces = css.count('{');
	int closeBraces = css.count('}');

	if (openBraces != closeBraces) {
		result.messages.append(ValidationMessage(
			MessageSeverity::Error,
			QString("Mismatched braces: %1 opening, %2 closing").arg(openBraces).arg(closeBraces),
			"Check your CSS syntax for missing or extra braces"
		));
		result.isValid = false;
	}

	return result;
}

// Check CSS compatibility with backend
Validator::ValidationResult Validator::checkCSSCompatibility(const QString& css, RenderBackend backend) {
	ValidationResult result;

	// Detect features
	QList<CSSFeature> unsupportedFeatures;

	if (containsFlexbox(css) && !isFeatureSupported(CSSFeature::Flexbox, backend)) {
		unsupportedFeatures.append(CSSFeature::Flexbox);
	}

	if (containsGrid(css) && !isFeatureSupported(CSSFeature::Grid, backend)) {
		unsupportedFeatures.append(CSSFeature::Grid);
	}

	if (containsTransforms(css) && !isFeatureSupported(CSSFeature::Transforms, backend)) {
		unsupportedFeatures.append(CSSFeature::Transforms);
	}

	if (containsAnimations(css) && !isFeatureSupported(CSSFeature::Animations, backend)) {
		unsupportedFeatures.append(CSSFeature::Animations);
	}

	if (containsGradients(css) && !isFeatureSupported(CSSFeature::Gradients, backend)) {
		unsupportedFeatures.append(CSSFeature::Gradients);
	}

	// Add warnings for unsupported features
	for (const auto& feature : unsupportedFeatures) {
		result.messages.append(ValidationMessage(
			MessageSeverity::Warning,
			QString("%1 detected but not fully supported by current backend").arg(featureName(feature)),
			getSuggestion(feature, backend)
		));
	}

	return result;
}

// Check if feature is supported
bool Validator::isFeatureSupported(CSSFeature feature, RenderBackend backend) {
        Q_UNUSED(backend);
        Q_UNUSED(feature);
        // WebEngine is the only supported backend and provides modern CSS support
        return true;
}

// Get feature name
QString Validator::featureName(CSSFeature feature) {
	switch (feature) {
	case CSSFeature::Flexbox:
		return "CSS Flexbox";
	case CSSFeature::Grid:
		return "CSS Grid Layout";
	case CSSFeature::Transforms:
		return "CSS Transforms";
	case CSSFeature::Animations:
		return "CSS Animations";
	case CSSFeature::Gradients:
		return "CSS Gradients";
	case CSSFeature::CustomProperties:
		return "CSS Custom Properties (Variables)";
	case CSSFeature::CalcFunction:
		return "CSS calc() function";
	case CSSFeature::MediaQueries:
		return "CSS Media Queries";
	case CSSFeature::BackgroundBlendMode:
		return "CSS Background Blend Modes";
	default:
		return "Unknown CSS feature";
	}
}

// Detect CSS features
QStringList Validator::detectCSSFeatures(const QString& css) {
	QStringList features;

	if (containsFlexbox(css)) features.append("Flexbox");
	if (containsGrid(css)) features.append("Grid");
	if (containsTransforms(css)) features.append("Transforms");
	if (containsAnimations(css)) features.append("Animations");
	if (containsGradients(css)) features.append("Gradients");
	if (containsCustomProperties(css)) features.append("Custom Properties");
	if (containsCalc(css)) features.append("calc()");

	return features;
}

// Get suggestion for feature
QString Validator::getSuggestion(CSSFeature feature, RenderBackend currentBackend) {
        Q_UNUSED(currentBackend);
        switch (feature) {
        case CSSFeature::Flexbox:
        case CSSFeature::Grid:
                return QString("%1 is supported by the WebEngine backend.").arg(featureName(feature));
        case CSSFeature::Transforms:
        case CSSFeature::Animations:
                return QString("%1 is supported by the WebEngine backend.").arg(featureName(feature));
        case CSSFeature::Gradients:
                return QString();
        case CSSFeature::CustomProperties:
                return "CSS Variables are supported in the WebEngine backend.";
        case CSSFeature::CalcFunction:
                return "calc() is supported in the WebEngine backend.";
        default:
                return QString();
        }
}

} // namespace wkhtmltopdf
