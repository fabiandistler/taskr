# Testing taskr

This document describes how to test the taskr package.

## Prerequisites

- R (>= 4.0.0)
- devtools package
- Suggested: testthat, lintr, styler

## Quick Start

```r
# Install package from source
devtools::install()

# Run all tests
devtools::test()

# Run R CMD check
devtools::check()
```

## Test Suites

### 1. Unit Tests (`tests/testthat/`)

Standard R package tests using testthat framework.

**Run with:**
```r
devtools::test()
```

**Test files:**
- `test-task-definition.R` - Task creation and validation
- `test-dependencies.R` - Dependency resolution and cycle detection
- `test-checksum.R` - File change detection

**Coverage:**
```r
covr::package_coverage()
```

### 2. Interactive Tests (`tests/interactive_test.R`)

Comprehensive integration tests that validate the full workflow.

**Run with:**
```r
source('tests/interactive_test.R')
```

**Or from command line:**
```bash
Rscript tests/interactive_test.R
```

**Tests included:**
1. Package loading
2. Task definition
3. Task registration
4. Task listing
5. Dependency resolution
6. Task execution
7. Circular dependency detection
8. File change detection
9. Environment variables
10. Dry run mode
11. Force execution
12. Invalid task name handling
13. Task validation
14. Cache management
15. taskr_init with all templates

### 3. Manual Testing

#### Basic Workflow

```r
library(taskr)

# Initialize a project
taskr_init()

# Edit taskfile.R, then load it
source("taskfile.R")

# List tasks
list_tasks()

# Run a task
run_task("example")
```

#### Package Development Workflow

```r
# Initialize with package template
taskr_init(template = "package")

# Source taskfile
source("taskfile.R")

# Run tasks
run_task("document")
run_task("test")
run_task("check")
```

#### Data Pipeline Workflow

```r
# Initialize with data pipeline template
taskr_init(template = "data_pipeline")

# Source taskfile
source("taskfile.R")

# Run full pipeline
run_task("pipeline")
```

## Code Quality Checks

### Style Check (lintr)

```r
lintr::lint_package()
```

**Expected:** No style violations

**Current status:** ✓ All checks pass
- No lines > 80 characters
- No T/F usage (only TRUE/FALSE)
- No trailing whitespace

### Code Formatting (styler)

```r
styler::style_pkg()
```

**Expected:** No changes needed

### Syntax Validation

A Python-based syntax validator is available for quick checks without R:

```bash
./run_tests.sh
```

This checks:
- Balanced parentheses
- Balanced brackets
- Balanced braces
- Basic syntax errors

## R CMD check

Full package check:

```r
devtools::check()
```

**Expected results:**
- 0 errors
- 0 warnings
- 0 notes

## Testing in Different Environments

### Windows

```r
# Check Windows-specific functionality
devtools::check_win_devel()
devtools::check_win_release()
```

### Linux/macOS

```r
# Standard check
devtools::check()

# Check on rhub
rhub::check_for_cran()
```

### CI/CD

The package includes GitHub Actions workflows (planned):
- R CMD check on multiple platforms
- Code coverage with codecov
- lintr checks

## Common Issues and Solutions

### Issue: Tasks not found

**Solution:** Make sure you've sourced the taskfile.R:
```r
source("taskfile.R")
```

### Issue: Circular dependency error

**Solution:** Check your task dependencies:
```r
validate_dependencies()
```

### Issue: File change detection not working

**Solution:** Clear the cache and try again:
```r
clear_cache()
run_task("your_task", force = TRUE)
```

### Issue: R CMD check fails

**Solution:** Run individual checks:
```r
# Check documentation
devtools::document()

# Run tests
devtools::test()

# Check for common issues
devtools::check()
```

## Performance Testing

For performance-critical applications, benchmark your tasks:

```r
library(microbenchmark)

microbenchmark(
  run_task("your_task"),
  times = 10
)
```

## Test Coverage Goals

Current coverage: To be measured

Goals:
- Overall: > 80%
- Critical paths: > 95%
- Edge cases: > 70%

## Continuous Integration

### GitHub Actions (Planned)

```yaml
# .github/workflows/R-CMD-check.yaml
- R CMD check on Ubuntu, Windows, macOS
- Code coverage reporting
- lintr checks
- pkgdown site deployment
```

## Reporting Issues

If tests fail, please report:
1. R version (`R.version.string`)
2. Platform (`Sys.info()`)
3. Package version (`packageVersion("taskr")`)
4. Test output/error message
5. Reproducible example

Submit issues at: https://github.com/fabiandistler/taskr/issues

## Test Development

### Adding New Tests

1. Create test file in `tests/testthat/test-*.R`
2. Follow testthat structure:
   ```r
   test_that("description", {
     # Arrange
     # Act
     # Assert
     expect_*()
   })
   ```
3. Run tests: `devtools::test()`
4. Update this document

### Test Naming Conventions

- `test-*.R` for test files
- `test_that("functionality", {...})` for test cases
- Use descriptive names
- Group related tests

## References

- testthat: https://testthat.r-lib.org/
- devtools: https://devtools.r-lib.org/
- R packages book: https://r-pkgs.org/
- lintr: https://lintr.r-lib.org/
- styler: https://styler.r-lib.org/
