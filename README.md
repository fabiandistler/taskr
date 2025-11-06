# taskr <img src="man/figures/logo.png" align="right" height="139" alt="" />

> A modern, cross-platform task runner for R projects

[![R-CMD-check](https://github.com/fabiandistler/taskr/workflows/R-CMD-check/badge.svg)](https://github.com/fabiandistler/taskr/actions)
[![Codecov](https://codecov.io/gh/fabiandistler/taskr/branch/main/graph/badge.svg)](https://codecov.io/gh/fabiandistler/taskr)
[![CRAN status](https://www.r-pkg.org/badges/version/taskr)](https://CRAN.R-project.org/package=taskr)

## Overview

**taskr** is a modern task runner designed specifically for R workflows. Similar to `Taskfile`, `just`, or `make`, but R-native and cross-platform friendly.

### Why taskr?

- **R-Native**: Tasks are R functions, fully integrated with R's ecosystem
- **Cross-Platform**: Works seamlessly on Windows, Linux, macOS (including WSL)
- **Smart Execution**: Only re-runs tasks when source files change (checksum-based)
- **Dependency Management**: Automatic dependency resolution with cycle detection
- **Developer Friendly**: Integrates with `devtools`, `usethis`, and RStudio
- **Flexible**: Works for packages, data pipelines, Shiny apps, and more

## Installation

### From GitHub

```r
# Install from GitHub
# install.packages("remotes")
remotes::install_github("fabiandistler/taskr")
```

### From Source

```r
# Clone and install
git clone https://github.com/fabiandistler/taskr.git
R CMD INSTALL taskr
```

## Quick Start

### 1. Initialize a taskfile

```r
library(taskr)

# Create a taskfile.R in your project
taskr_init()

# Or use a template
taskr_init(template = "package")      # For R packages
taskr_init(template = "data_pipeline") # For data workflows
```

### 2. Define tasks

Edit `taskfile.R`:

```r
library(taskr)

define_tasks(

  task("build",
    desc = "Build the package",
    cmd = function() {
      devtools::build()
    }
  ),

  task("test",
    desc = "Run tests",
    cmd = function() {
      devtools::test()
    }
  ),

  task("check",
    desc = "Run R CMD check",
    deps = c("build", "test"),
    cmd = function() {
      devtools::check()
    }
  )

)
```

### 3. Run tasks

```r
# In R
source("taskfile.R")
run_task("check")

# From terminal
Rscript -e 'taskr::cli_main()' run check
```

## Core Features

### 1. Task Dependencies

Tasks automatically execute in the correct order:

```r
define_tasks(

  task("data:extract",
    desc = "Extract data from database",
    cmd = function() {
      # Extract logic
    }
  ),

  task("data:transform",
    desc = "Transform data",
    deps = "data:extract",  # Runs after extract
    cmd = function() {
      # Transform logic
    }
  ),

  task("data:load",
    desc = "Load data to warehouse",
    deps = "data:transform",  # Runs after transform
    cmd = function() {
      # Load logic
    }
  ),

  task("pipeline",
    desc = "Full ETL pipeline",
    deps = c("data:extract", "data:transform", "data:load")
  )

)

# Runs all dependencies in order
run_task("pipeline")
```

### 2. Smart File Watching

Only re-run tasks when source files change:

```r
task("document",
  desc = "Generate documentation",
  sources = c("R/**/*.R", "man/*.Rd"),  # Watch these files
  cmd = function() {
    devtools::document()
  }
)

# First run: executes
run_task("document")

# Second run: skips (files unchanged)
run_task("document")

# Force re-run
run_task("document", force = TRUE)
```

### 3. Environment Variables

Set environment variables for tasks:

```r
task("deploy",
  desc = "Deploy to production",
  env = list(
    ENV = "production",
    LOG_LEVEL = "info"
  ),
  cmd = function() {
    # Sys.getenv("ENV") == "production"
    deploy_app()
  }
)
```

### 4. Task Namespaces

Organize tasks with colons:

```r
define_tasks(

  # Data tasks
  task("data:fetch", ...),
  task("data:clean", ...),

  # Model tasks
  task("model:train", ...),
  task("model:evaluate", ...),

  # Deployment tasks
  task("deploy:staging", ...),
  task("deploy:prod", ...)

)
```

## Usage Examples

### R Package Development

```r
library(taskr)

define_tasks(

  task("document",
    desc = "Generate documentation",
    sources = "R/**/*.R",
    cmd = function() devtools::document()
  ),

  task("test",
    desc = "Run all tests",
    cmd = function() devtools::test()
  ),

  task("check",
    desc = "R CMD check",
    deps = c("document", "test"),
    cmd = function() devtools::check()
  ),

  task("install",
    desc = "Install package",
    deps = "check",
    cmd = function() devtools::install()
  ),

  task("coverage",
    desc = "Test coverage",
    cmd = function() {
      cov <- covr::package_coverage()
      print(cov)
    }
  ),

  task("ci",
    desc = "Full CI pipeline",
    deps = c("document", "test", "check", "coverage")
  )

)
```

### Data Pipeline

```r
library(taskr)

define_tasks(

  task("db:connect",
    desc = "Test database connection",
    cmd = function() {
      source("R/db_config.R")
      test_connection()
    }
  ),

  task("extract",
    desc = "Extract from Azure SQL",
    deps = "db:connect",
    sources = c("sql/extract.sql", "R/extract.R"),
    env = list(AZURE_CONN_STRING = Sys.getenv("AZURE_CONN")),
    cmd = function() {
      source("R/extract.R")
      extract_sales_data()
    }
  ),

  task("transform",
    desc = "Transform with data.table",
    deps = "extract",
    sources = c("R/transform.R"),
    cmd = function() {
      source("R/transform.R")
      transform_sales_data()
    }
  ),

  task("analyze",
    desc = "Run analysis",
    deps = "transform",
    cmd = function() {
      source("R/analysis.R")
      run_anomaly_detection()
    }
  ),

  task("report",
    desc = "Generate report",
    deps = "analyze",
    cmd = function() {
      rmarkdown::render("reports/sales_report.Rmd")
    }
  )

)
```

### Shiny App Deployment

```r
library(taskr)

define_tasks(

  task("deps:check",
    desc = "Check dependencies",
    cmd = function() {
      renv::status()
    }
  ),

  task("test:app",
    desc = "Test Shiny app",
    deps = "deps:check",
    cmd = function() {
      shinytest2::test_app()
    }
  ),

  task("docker:build",
    desc = "Build Docker image",
    deps = "test:app",
    cmd = function() {
      system("docker build -t myapp:latest .")
    }
  ),

  task("docker:push",
    desc = "Push to registry",
    deps = "docker:build",
    cmd = function() {
      system("docker push myregistry/myapp:latest")
    }
  ),

  task("deploy:prod",
    desc = "Deploy to production",
    deps = "docker:push",
    cmd = function() {
      rsconnect::deployApp(server = "prod")
    }
  )

)
```

## Command Line Interface

taskr provides a full CLI interface:

```bash
# List all tasks
Rscript -e 'taskr::cli_main()' list

# Run a task
Rscript -e 'taskr::cli_main()' run build

# Run with flags
Rscript -e 'taskr::cli_main()' run test --force
Rscript -e 'taskr::cli_main()' run check --dry-run
Rscript -e 'taskr::cli_main()' run deploy --quiet

# Initialize new taskfile
Rscript -e 'taskr::cli_main()' init package

# Validate dependencies
Rscript -e 'taskr::cli_main()' validate

# Clear cache
Rscript -e 'taskr::cli_main()' clear-cache

# Shorthand (if no conflict)
Rscript -e 'taskr::cli_main()' build
```

### Create Bash Alias (Optional)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias taskr="Rscript -e 'taskr::cli_main()'"
```

Then use:

```bash
taskr list
taskr run build
taskr build  # shorthand
```

## API Reference

### Core Functions

- `task()` - Define a task
- `define_tasks()` - Register tasks
- `run_task()` - Execute a task
- `list_tasks()` - Show all tasks
- `taskr_init()` - Initialize taskfile

### Utilities

- `get_execution_order()` - See task execution order
- `validate_dependencies()` - Check for circular dependencies
- `clear_cache()` - Clear file checksums cache
- `load_tasks()` - Source taskfile.R

### CLI

- `cli_main()` - Main CLI entry point

## Advanced Features

### Dry Run Mode

See what would execute without running:

```r
run_task("pipeline", dry_run = TRUE)
```

### Force Execution

Ignore file change detection:

```r
run_task("build", force = TRUE)
```

### Programmatic Access

```r
# Get execution order
order <- get_execution_order("check")
print(order)  # c("document", "test", "check")

# Validate all tasks
validate_dependencies()
```

## Comparison to Alternatives

| Feature | taskr | make | targets | scripts/ |
|---------|-------|------|---------|----------|
| R-native | ✅ | ❌ | ✅ | ✅ |
| Windows-friendly | ✅ | ⚠️ | ✅ | ⚠️ |
| Task dependencies | ✅ | ✅ | ✅ | ❌ |
| File change detection | ✅ | ✅ | ✅ | ❌ |
| Non-data workflows | ✅ | ✅ | ❌ | ✅ |
| RStudio integration | ✅ | ❌ | ⚠️ | ❌ |
| Declarative config | ✅ | ❌ | ❌ | ❌ |

## Roadmap

### Phase 1 (MVP) ✅
- [x] Task definition API
- [x] Dependency resolution
- [x] File change detection
- [x] CLI interface
- [x] Basic templates

### Phase 2 (Planned)
- [ ] YAML config support
- [ ] RStudio Addin
- [ ] Parallel task execution
- [ ] Better error handling
- [ ] Task hooks (pre/post)

### Phase 3 (Future)
- [ ] Azure DevOps integration
- [ ] Remote execution
- [ ] Task caching/artifacts
- [ ] Visual dependency graph

## Contributing

Contributions welcome! Please:

1. Fork the repo
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file

## Author

Fabian Distler

## Acknowledgments

Inspired by:
- [Task](https://taskfile.dev/) - Go-based task runner
- [just](https://github.com/casey/just) - Command runner
- [targets](https://docs.ropensci.org/targets/) - R pipeline toolkit
- [make](https://www.gnu.org/software/make/) - Classic build automation

## Support

- Issues: https://github.com/fabiandistler/taskr/issues
- Discussions: https://github.com/fabiandistler/taskr/discussions
