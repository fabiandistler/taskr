# taskfile.R
# R Package Development Tasks

library(taskr)

define_tasks(

  task("document",
    desc = "Generate documentation with roxygen2",
    sources = c("R/**/*.R"),
    cmd = function() {
      devtools::document()
    }
  ),

  task("test",
    desc = "Run all tests",
    cmd = function() {
      devtools::test()
    }
  ),

  task("check",
    desc = "Run R CMD check",
    deps = c("document", "test"),
    cmd = function() {
      devtools::check()
    }
  ),

  task("install",
    desc = "Install package locally",
    deps = "check",
    cmd = function() {
      devtools::install()
    }
  ),

  task("build",
    desc = "Build package bundle",
    deps = "check",
    cmd = function() {
      devtools::build()
    }
  ),

  task("coverage",
    desc = "Check test coverage",
    cmd = function() {
      covr::package_coverage()
    }
  ),

  task("lint",
    desc = "Lint code style",
    cmd = function() {
      lintr::lint_package()
    }
  ),

  task("format",
    desc = "Format code with styler",
    cmd = function() {
      styler::style_pkg()
    }
  )

)
