#!/bin/bash
# Test runner script for taskr

set -e

echo "=== taskr Test Runner ==="
echo

# Check if R is available
if command -v R >/dev/null 2>&1; then
    echo "✓ R is available: $(R --version | head -1)"
    echo

    # Run interactive tests
    echo "Running interactive test suite..."
    Rscript tests/interactive_test.R

    echo
    echo "Running package tests..."
    R -e "devtools::test()"

    echo
    echo "Running R CMD check..."
    R -e "devtools::check()"

else
    echo "✗ R is not available in this environment"
    echo
    echo "To test this package, please run the following commands in an R environment:"
    echo
    echo "  # Install package"
    echo "  devtools::install()"
    echo
    echo "  # Run interactive tests"
    echo "  source('tests/interactive_test.R')"
    echo
    echo "  # Run unit tests"
    echo "  devtools::test()"
    echo
    echo "  # Run R CMD check"
    echo "  devtools::check()"
    echo
    echo "  # Check code style"
    echo "  lintr::lint_package()"
    echo "  styler::style_pkg()"
    echo
fi
