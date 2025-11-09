// -*- mode: c++; tab-width: 4; indent-tabs-mode: t; eval: (progn (c-set-style "stroustrup") (c-set-offset 'innamespace 0)); -*-
// vi:set ts=4 sts=4 sw=4 noet :

#include "errors.hh"
#include <QTextStream>

namespace wkhtmltopdf {

// Format error message
QString ConversionError::formatError() const {
	QString result;
	QTextStream stream(&result);

	stream << "Error: " << message;
	if (!file.isEmpty()) {
		stream << "\n  File: " << file;
		if (line >= 0) {
			stream << " (line " << line;
			if (column >= 0) {
				stream << ", column " << column;
			}
			stream << ")";
		}
	}
	if (!suggestion.isEmpty()) {
		stream << "\n  Suggestion: " << suggestion;
	}
	if (!possibleCauses.isEmpty()) {
		stream << "\n  Possible causes:";
		for (const auto& cause : possibleCauses) {
			stream << "\n    • " << cause;
		}
	}

	return result;
}

// Format for CLI with colors
QString ConversionError::formatForCLI() const {
	QString result;
	QTextStream stream(&result);

	// Error header
	stream << "❌ Error: " << message << " (" << ErrorHandler::errorCodeString(code) << ")";

	// File info
	if (!file.isEmpty()) {
		stream << "\n   File: " << file;
		if (line >= 0) {
			stream << " (line " << line;
			if (column >= 0) {
				stream << ", column " << column;
			}
			stream << ")";
		}
	}

	// Suggestion
	if (!suggestion.isEmpty()) {
		stream << "\n\n   💡 Suggestion: " << suggestion;
	}

	// Possible causes
	if (!possibleCauses.isEmpty()) {
		stream << "\n\n   Possible causes:";
		for (const auto& cause : possibleCauses) {
			stream << "\n   • " << cause;
		}
	}

	stream << "\n\n   For help, run: wkhtmltopdf --help";

	return result;
}

// Create file not found error
ConversionError ErrorHandler::fileNotFound(const QString& filename) {
	ConversionError error(ErrorCode::FILE_NOT_FOUND, "File not found");
	error.file = filename;
	error.suggestion = "Check the file path and ensure you have read permissions";
	error.possibleCauses << "File does not exist"
	                     << "Incorrect file path"
	                     << "Missing read permissions"
	                     << "File is in a different directory";
	return error;
}

// Create backend not available error
ConversionError ErrorHandler::backendNotAvailable(const QString& backendName) {
	ConversionError error(
		ErrorCode::BACKEND_NOT_AVAILABLE,
		QString("Backend '%1' is not available").arg(backendName)
	);

	if (backendName == "webengine" || backendName == "WebEngine") {
		error.suggestion = "Install Qt WebEngine: sudo apt-get install qtwebengine5-dev libqt5webenginecore5";
		error.possibleCauses << "Qt WebEngine not installed"
		                     << "Qt WebEngine libraries not found"
		                     << "wkhtmltopdf compiled without WebEngine support";
	} else if (backendName == "webkit" || backendName == "WebKit") {
		error.suggestion = "Install Qt WebKit: sudo apt-get install libqt5webkit5-dev";
		error.possibleCauses << "Qt WebKit not installed"
		                     << "wkhtmltopdf compiled without WebKit support";
	} else {
		error.suggestion = QString("Valid backends: webkit, webengine. Use --render-backend to specify.");
	}

	return error;
}

// Create invalid HTML error
ConversionError ErrorHandler::invalidHTML(const QString& details) {
	ConversionError error(ErrorCode::INVALID_HTML, "Invalid HTML");
	if (!details.isEmpty()) {
		error.message += ": " + details;
	}
	error.suggestion = "Validate your HTML using a validator like validator.w3.org";
	error.possibleCauses << "Malformed HTML tags"
	                     << "Missing closing tags"
	                     << "Invalid HTML structure";
	return error;
}

// Create rendering failed error
ConversionError ErrorHandler::renderingFailed(const QString& reason) {
	ConversionError error(ErrorCode::RENDERING_FAILED, "Rendering failed");
	if (!reason.isEmpty()) {
		error.message += ": " + reason;
	}
	error.suggestion = "Check your HTML/CSS for errors and ensure the backend supports your CSS features";
	error.possibleCauses << "Unsupported CSS features for current backend"
	                     << "JavaScript errors in the page"
	                     << "Resource loading failures"
	                     << "Memory limit exceeded";
	return error;
}

// Create permission denied error
ConversionError ErrorHandler::permissionDenied(const QString& filename) {
	ConversionError error(ErrorCode::PERMISSION_DENIED, "Permission denied");
	error.file = filename;
	error.suggestion = "Check file permissions and ensure you have read/write access";
	error.possibleCauses << "File is read-only"
	                     << "Directory is not writable"
	                     << "File is locked by another process";
	return error;
}

// Create network error
ConversionError ErrorHandler::networkError(const QString& url, const QString& details) {
	ConversionError error(ErrorCode::NETWORK_ERROR, "Network error");
	error.file = url;
	if (!details.isEmpty()) {
		error.message += ": " + details;
	}
	error.suggestion = "Check your internet connection and ensure the URL is accessible";
	error.possibleCauses << "No internet connection"
	                     << "URL is not accessible"
	                     << "DNS resolution failed"
	                     << "Firewall blocking connection";
	return error;
}

// Get error code name
QString ErrorHandler::errorCodeName(ErrorCode code) {
	switch (code) {
	case ErrorCode::SUCCESS:
		return "Success";
	case ErrorCode::FILE_NOT_FOUND:
		return "File Not Found";
	case ErrorCode::FILE_READ_ERROR:
		return "File Read Error";
	case ErrorCode::FILE_WRITE_ERROR:
		return "File Write Error";
	case ErrorCode::PERMISSION_DENIED:
		return "Permission Denied";
	case ErrorCode::INVALID_HTML:
		return "Invalid HTML";
	case ErrorCode::CSS_PARSE_ERROR:
		return "CSS Parse Error";
	case ErrorCode::MALFORMED_URL:
		return "Malformed URL";
	case ErrorCode::BACKEND_NOT_AVAILABLE:
		return "Backend Not Available";
	case ErrorCode::BACKEND_INIT_FAILED:
		return "Backend Initialization Failed";
	case ErrorCode::RENDERING_FAILED:
		return "Rendering Failed";
	case ErrorCode::RESOURCE_NOT_FOUND:
		return "Resource Not Found";
	case ErrorCode::NETWORK_ERROR:
		return "Network Error";
	case ErrorCode::TIMEOUT:
		return "Timeout";
	case ErrorCode::MEMORY_ERROR:
		return "Memory Error";
	case ErrorCode::OUT_OF_DISK_SPACE:
		return "Out of Disk Space";
	case ErrorCode::SYSTEM_ERROR:
		return "System Error";
	case ErrorCode::INVALID_OPTION:
		return "Invalid Option";
	case ErrorCode::INVALID_PAGE_SIZE:
		return "Invalid Page Size";
	case ErrorCode::INVALID_ORIENTATION:
		return "Invalid Orientation";
	default:
		return "Unknown Error";
	}
}

// Get error code as string (ERR_001 format)
QString ErrorHandler::errorCodeString(ErrorCode code) {
	return QString("ERR_%1").arg(static_cast<int>(code), 3, 10, QChar('0'));
}

// Format error for display
QString ErrorHandler::formatError(const ConversionError& error, bool colored) {
	if (colored) {
		return error.formatForCLI();
	} else {
		return error.formatError();
	}
}

// Get suggestions for error code
QStringList ErrorHandler::getSuggestions(ErrorCode code) {
	QStringList suggestions;

	switch (code) {
	case ErrorCode::FILE_NOT_FOUND:
		suggestions << "Check if the file exists: ls <filename>"
		            << "Use absolute path: /full/path/to/file.html"
		            << "Check current directory: pwd";
		break;

	case ErrorCode::BACKEND_NOT_AVAILABLE:
		suggestions << "Install missing backend: sudo apt-get install qtwebengine5-dev"
		            << "Check available backends: wkhtmltopdf --help | grep backend"
		            << "Rebuild with backend support: RENDER_BACKEND=webengine qmake && make";
		break;

	case ErrorCode::RENDERING_FAILED:
		suggestions << "Validate HTML: wkhtmltopdf --validate input.html"
		            << "Try different backend: --render-backend webkit"
		            << "Increase timeout: --javascript-delay 5000"
		            << "Check browser console for errors";
		break;

	case ErrorCode::NETWORK_ERROR:
		suggestions << "Check internet connection: ping 8.8.8.8"
		            << "Test URL in browser first"
		            << "Use local file instead: file:///path/to/file.html"
		            << "Check proxy settings";
		break;

	default:
		suggestions << "Check documentation: wkhtmltopdf --help"
		            << "Enable verbose output: --verbose"
		            << "Check log file for details";
		break;
	}

	return suggestions;
}

} // namespace wkhtmltopdf
