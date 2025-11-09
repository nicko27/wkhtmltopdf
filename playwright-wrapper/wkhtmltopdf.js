#!/usr/bin/env node
/**
 * wkhtmltopdf wrapper using Playwright (Chromium)
 *
 * This is a drop-in replacement for wkhtmltopdf that uses Playwright
 * to provide modern CSS support (flexbox, grid, etc.) on macOS.
 *
 * Install: npm install playwright
 * Usage: ./wkhtmltopdf.js input.html output.pdf
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Parse command line arguments (simplified)
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        pageSize: 'A4',
        orientation: 'portrait',
        marginTop: '10mm',
        marginRight: '10mm',
        marginBottom: '10mm',
        marginLeft: '10mm',
        printBackground: true,
        input: null,
        output: null
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];

        if (arg === '--help' || arg === '-h') {
            printHelp();
            process.exit(0);
        }

        if (arg === '--version') {
            console.log('wkhtmltopdf (Playwright wrapper) 1.0.0 (with modern CSS support)');
            console.log('Using Chromium via Playwright');
            process.exit(0);
        }

        if (arg === '--page-size' && i + 1 < args.length) {
            options.pageSize = args[++i];
        } else if (arg === '--orientation' && i + 1 < args.length) {
            options.orientation = args[++i].toLowerCase();
        } else if (arg === '--margin-top' && i + 1 < args.length) {
            options.marginTop = args[++i];
        } else if (arg === '--margin-right' && i + 1 < args.length) {
            options.marginRight = args[++i];
        } else if (arg === '--margin-bottom' && i + 1 < args.length) {
            options.marginBottom = args[++i];
        } else if (arg === '--margin-left' && i + 1 < args.length) {
            options.marginLeft = args[++i];
        } else if (arg === '--no-background') {
            options.printBackground = false;
        } else if (!arg.startsWith('--')) {
            if (!options.input) {
                options.input = arg;
            } else if (!options.output) {
                options.output = arg;
            }
        }
    }

    if (!options.input || !options.output) {
        console.error('Error: Input and output files are required');
        console.error('Usage: wkhtmltopdf <input.html> <output.pdf>');
        console.error('Run with --help for more options');
        process.exit(1);
    }

    return options;
}

function printHelp() {
    console.log(`
wkhtmltopdf (Playwright wrapper) - Modern CSS support for macOS

Usage:
  wkhtmltopdf [options] <input.html> <output.pdf>

Options:
  --page-size <size>          Paper size (A4, Letter, Legal, etc.)
  --orientation <orientation> Portrait or Landscape
  --margin-top <margin>       Top margin (e.g., 10mm, 0.5in)
  --margin-right <margin>     Right margin
  --margin-bottom <margin>    Bottom margin
  --margin-left <margin>      Left margin
  --no-background             Don't print background images
  --help, -h                  Show this help
  --version                   Show version

Examples:
  # Basic conversion
  wkhtmltopdf input.html output.pdf

  # With options
  wkhtmltopdf --page-size A4 --orientation Landscape input.html output.pdf

  # Custom margins
  wkhtmltopdf --margin-top 20mm --margin-bottom 20mm input.html output.pdf

Features:
  ✅ Full CSS3 support (flexbox, grid, transforms, animations)
  ✅ Modern JavaScript (ES6+)
  ✅ Chromium-based rendering
  ✅ Same command-line interface as wkhtmltopdf

Note: This is a wrapper around Playwright using Chromium.
For the original Qt-based wkhtmltopdf, see: https://wkhtmltopdf.org
`);
}

// Convert margin string to number (Playwright uses pixels or standard units)
function parseMargin(margin) {
    return margin; // Playwright accepts units like "10mm", "1in", etc.
}

// Map page sizes
function getPageFormat(size) {
    const formats = {
        'A3': 'A3',
        'A4': 'A4',
        'A5': 'A5',
        'Letter': 'Letter',
        'Legal': 'Legal',
        'Tabloid': 'Tabloid'
    };
    return formats[size] || 'A4';
}

async function convertToPDF(options) {
    const browser = await chromium.launch({
        headless: true
    });

    try {
        const context = await browser.newContext();
        const page = await context.newPage();

        // Construct file URL or use as-is if it's already a URL
        let url = options.input;
        if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('file://')) {
            // Convert to absolute path
            const absolutePath = path.resolve(url);
            if (!fs.existsSync(absolutePath)) {
                throw new Error(`Input file not found: ${absolutePath}`);
            }
            url = 'file://' + absolutePath;
        }

        // Navigate to the page
        console.log(`Loading ${url}...`);
        await page.goto(url, {
            waitUntil: 'networkidle'
        });

        // Generate PDF
        console.log('Generating PDF...');
        await page.pdf({
            path: options.output,
            format: getPageFormat(options.pageSize),
            landscape: options.orientation === 'landscape',
            margin: {
                top: parseMargin(options.marginTop),
                right: parseMargin(options.marginRight),
                bottom: parseMargin(options.marginBottom),
                left: parseMargin(options.marginLeft)
            },
            printBackground: options.printBackground
        });

        console.log(`✓ PDF created successfully: ${options.output}`);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    } finally {
        await browser.close();
    }
}

// Main
(async () => {
    const options = parseArgs();
    await convertToPDF(options);
})();
