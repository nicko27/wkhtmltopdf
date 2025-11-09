/*
 * Example: Backend Selection for Modern CSS Support
 *
 * This example demonstrates how to select between WebKit (legacy) and
 * WebEngine (modern CSS with flex, grid, etc.) backends.
 *
 * Compile:
 *   gcc -o backend_selector backend_selector.c -lwkhtmltox
 *
 * Usage:
 *   ./backend_selector [webkit|webengine] input.html output.pdf
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wkhtmltox/pdf.h>

void print_backends() {
    printf("Available rendering backends:\n");
    printf("=============================\n\n");

    // Check WebKit availability
    if (wkhtmltopdf_is_backend_available(0)) { // 0 = WebKit
        printf("✓ WebKit (Legacy)\n");
        printf("  - Limited CSS3 support\n");
        printf("  - Smaller binary size\n");
        printf("  - No flexbox or grid\n\n");
    } else {
        printf("✗ WebKit (not available)\n\n");
    }

    // Check WebEngine availability
    if (wkhtmltopdf_is_backend_available(1)) { // 1 = WebEngine
        printf("✓ WebEngine (Modern)\n");
        printf("  - Full CSS3 support\n");
        printf("  - Flexbox and grid layout\n");
        printf("  - Modern JavaScript (ES6+)\n");
        printf("  - Larger binary size\n\n");
    } else {
        printf("✗ WebEngine (not available)\n\n");
    }
}

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
    if (argc < 4) {
        printf("Usage: %s [webkit|webengine|auto] <input.html> <output.pdf>\n\n", argv[0]);
        printf("Backends:\n");
        printf("  webkit     - Use Qt WebKit (legacy, no modern CSS)\n");
        printf("  webengine  - Use Qt WebEngine (modern CSS: flex, grid, etc.)\n");
        printf("  auto       - Auto-select best available backend\n\n");

        wkhtmltopdf_init(0);
        print_backends();
        wkhtmltopdf_deinit();
        return 1;
    }

    const char * backend_name = argv[1];
    const char * input_file = argv[2];
    const char * output_file = argv[3];

    // Initialize library
    if (!wkhtmltopdf_init(0)) {
        fprintf(stderr, "Failed to initialize wkhtmltopdf\n");
        return 1;
    }

    // Set backend based on argument
    if (strcmp(backend_name, "webkit") == 0) {
        printf("Selecting WebKit backend (legacy CSS)...\n");
        wkhtmltopdf_set_default_backend(0); // 0 = WebKit
    } else if (strcmp(backend_name, "webengine") == 0) {
        printf("Selecting WebEngine backend (modern CSS)...\n");
        if (!wkhtmltopdf_is_backend_available(1)) {
            fprintf(stderr, "Error: WebEngine backend is not available.\n");
            fprintf(stderr, "Rebuild wkhtmltopdf with RENDER_BACKEND=webengine or RENDER_BACKEND=both\n");
            wkhtmltopdf_deinit();
            return 1;
        }
        wkhtmltopdf_set_default_backend(1); // 1 = WebEngine
    } else if (strcmp(backend_name, "auto") == 0) {
        printf("Auto-selecting backend...\n");
        // Default backend is already set, no action needed
    } else {
        fprintf(stderr, "Unknown backend: %s\n", backend_name);
        fprintf(stderr, "Use 'webkit', 'webengine', or 'auto'\n");
        wkhtmltopdf_deinit();
        return 1;
    }

    // Print selected backend info
    int current_backend = wkhtmltopdf_get_default_backend();
    printf("Using backend: %s\n", current_backend == 0 ? "WebKit" : "WebEngine");

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
