// -*- mode: c++; tab-width: 4; indent-tabs-mode: t; eval: (progn (c-set-style "stroustrup") (c-set-offset 'innamespace 0)); -*-
// vi:set ts=4 sts=4 sw=4 noet :
//
// Copyright 2024-2025 wkhtmltopdf authors
//
// This file is part of wkhtmltopdf.

#ifndef __ERRORS_HH__
#define __ERRORS_HH__

#include <QString>
#include <QStringList>

namespace wkhtmltopdf {

/*!
 * \brief Error codes for wkhtmltopdf operations
 */
enum class ErrorCode {
	SUCCESS = 0,

	// File errors (1-10)
	FILE_NOT_FOUND = 1,
	FILE_READ_ERROR = 2,
	FILE_WRITE_ERROR = 3,
	PERMISSION_DENIED = 4,

	// HTML/CSS errors (11-20)
	INVALID_HTML = 11,
	CSS_PARSE_ERROR = 12,
	MALFORMED_URL = 13,

	// Backend errors (21-30)
	BACKEND_NOT_AVAILABLE = 21,
	BACKEND_INIT_FAILED = 22,
	RENDERING_FAILED = 23,

	// Resource errors (31-40)
	RESOURCE_NOT_FOUND = 31,
	NETWORK_ERROR = 32,
	TIMEOUT = 33,

	// System errors (41-50)
	MEMORY_ERROR = 41,
	OUT_OF_DISK_SPACE = 42,
	SYSTEM_ERROR = 43,

	// Configuration errors (51-60)
	INVALID_OPTION = 51,
	INVALID_PAGE_SIZE = 52,
	INVALID_ORIENTATION = 53,

	// Unknown
	UNKNOWN_ERROR = 99
};

/*!
 * \brief Structured error with code, message, and suggestions
 */
struct ConversionError {
	ErrorCode code;
	QString message;
	QString file;
	int line;
	int column;
	QString suggestion;
	QStringList possibleCauses;

	ConversionError()
		: code(ErrorCode::SUCCESS), line(-1), column(-1) {}

	ConversionError(ErrorCode c, const QString& msg, const QString& suggest = QString())
		: code(c), message(msg), line(-1), column(-1), suggestion(suggest) {}

	bool isError() const {
		return code != ErrorCode::SUCCESS;
	}

	QString formatError() const;
	QString formatForCLI() const;
};

/*!
 * \brief Error handler and formatter
 */
class ErrorHandler {
public:
	/*!
	 * \brief Create a file not found error
	 */
	static ConversionError fileNotFound(const QString& filename);

	/*!
	 * \brief Create a backend not available error
	 */
	static ConversionError backendNotAvailable(const QString& backendName);

	/*!
	 * \brief Create an invalid HTML error
	 */
	static ConversionError invalidHTML(const QString& details = QString());

	/*!
	 * \brief Create a rendering failed error
	 */
	static ConversionError renderingFailed(const QString& reason = QString());

	/*!
	 * \brief Create a permission denied error
	 */
	static ConversionError permissionDenied(const QString& filename);

	/*!
	 * \brief Create a network error
	 */
	static ConversionError networkError(const QString& url, const QString& details = QString());

	/*!
	 * \brief Get error code name
	 */
	static QString errorCodeName(ErrorCode code);

	/*!
	 * \brief Get error code number as string (ERR_001 format)
	 */
	static QString errorCodeString(ErrorCode code);

	/*!
	 * \brief Format error for display
	 */
	static QString formatError(const ConversionError& error, bool colored = false);

	/*!
	 * \brief Get suggestions for an error code
	 */
	static QStringList getSuggestions(ErrorCode code);
};

} // namespace wkhtmltopdf

#endif // __ERRORS_HH__
