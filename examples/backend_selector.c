/*
 * Example: WebEngine-only rendering
 *
 * This example demonstrates a minimal wkhtmltopdf invocation using the
 * WebEngine backend (Chromium). Legacy WebKit support has been removed
 * from the build, so no backend selection is necessary.
 *
 * Compile:
 *   gcc -o backend_selector backend_selector.c -lwkhtmltox
 *
 * Usage:
 *   ./backend_selector input.html output.pdf
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wkhtmltox/pdf.h>

void progress_changed(wkhtmltopdf_converter * converter, int p) {
    printf("Progress: %d%%\n", p);
}

void phase_changed(wkhtmltopdf_converter * converter) {
    int phase = wkhtmltopdf_current_phase(converter);
    const char * desc = wkhtmltopdf_phase_description(converter, phase);
    printf("Phase: %s\n", desc);
}

void error_callback(wkhtmltopdf_converter * converter, const char * msg) {
    fprintf(stderr, "Error: %s\n", msg);
}

void warning_callback(wkhtmltopdf_converter * converter, const char * msg) {
    fprintf(stderr, "Warning: %s\n", msg);
}

int main(int argc, char ** argv) {
    wkhtmltopdf_global_settings * gs;
    wkhtmltopdf_object_settings * os;
    wkhtmltopdf_converter * converter;

    // Show usage if arguments are incorrect
    if (argc < 3) {
        printf("Usage: %s <input.html> <output.pdf>\n\n", argv[0]);
        printf("Backend: WebEngine only (Chromium-based)\n");
        return 1;
    }

    const char * input_file = argv[1];
    const char * output_file = argv[2];

    // Initialize library
    if (!wkhtmltopdf_init(0)) {
        fprintf(stderr, "Failed to initialize wkhtmltopdf\n");
        return 1;
    }

    // Set backend explicitly to WebEngine (1)
    if (!wkhtmltopdf_is_backend_available(1)) {
        fprintf(stderr, "Error: WebEngine backend is not available.\n");
        fprintf(stderr, "Rebuild wkhtmltopdf with RENDER_BACKEND=webengine.\n");
        wkhtmltopdf_deinit();
        return 1;
    }
    wkhtmltopdf_set_default_backend(1);
    printf("Using backend: WebEngine\n");

    // Create global settings
    gs = wkhtmltopdf_create_global_settings();
    wkhtmltopdf_set_global_setting(gs, "out", output_file);
    wkhtmltopdf_set_global_setting(gs, "size.paperSize", "A4");

    // Create converter
    converter = wkhtmltopdf_create_converter(gs);

    // Set up callbacks
    wkhtmltopdf_set_progress_changed_callback(converter, progress_changed);
    wkhtmltopdf_set_phase_changed_callback(converter, phase_changed);
    wkhtmltopdf_set_error_callback(converter, error_callback);
    wkhtmltopdf_set_warning_callback(converter, warning_callback);

    // Create object settings for input
    os = wkhtmltopdf_create_object_settings();
    wkhtmltopdf_set_object_setting(os, "page", input_file);

    // Add object to converter
    wkhtmltopdf_add_object(converter, os, NULL);

    // Perform conversion
    printf("\nConverting %s to %s...\n", input_file, output_file);
    if (!wkhtmltopdf_convert(converter)) {
        fprintf(stderr, "Conversion failed!\n");
        wkhtmltopdf_destroy_converter(converter);
        wkhtmltopdf_deinit();
        return 1;
    }

    printf("\nConversion successful!\n");

    // Get HTTP error code (if any)
    int http_error = wkhtmltopdf_http_error_code(converter);
    if (http_error != 0) {
        printf("HTTP error code: %d\n", http_error);
    }

    // Cleanup
    wkhtmltopdf_destroy_converter(converter);
    wkhtmltopdf_deinit();

    return 0;
}
