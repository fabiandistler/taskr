# taskr 0.1.0

## Initial Release (MVP)

### Features

* Task definition API with `task()` and `define_tasks()`
* Automatic dependency resolution with cycle detection
* File change detection using MD5 checksums
* Smart task execution (skip if files unchanged)
* Command-line interface via `cli_main()`
* Three built-in templates:
  - `basic` - Simple starter template
  - `package` - R package development workflow
  - `data_pipeline` - ETL pipeline template
* Task state caching
* Environment variable support
* Cross-platform compatibility (Windows, Linux, macOS)

### Core Functions

* `task()` - Create task definitions
* `define_tasks()` - Register tasks in environment
* `run_task()` - Execute tasks with dependency resolution
* `list_tasks()` - Display available tasks
* `taskr_init()` - Initialize taskfile.R
* `clear_cache()` - Clear task state cache

### Documentation

* Comprehensive README with examples
* Roxygen2 documentation for all exported functions
* Three template taskfiles for common use cases
* Basic test suite with testthat

### Known Limitations

* No YAML configuration support yet (planned for 0.2.0)
* No parallel execution (planned for 0.2.0)
* No RStudio Addin (planned for 0.2.0)
* Glob patterns (`**`) support is basic
