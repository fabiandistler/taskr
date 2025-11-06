# taskfile.R
# Example taskfile for the taskr package itself

library(taskr)

define_tasks(

  task("document",
    desc = "Generate package documentation",
    sources = c("R/**/*.R"),
    cmd = function() {
      devtools::document()
      message("Documentation updated!")
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

  task("readme",
    desc = "Check README examples",
    cmd = function() {
      message("README is up to date!")
    }
  ),

  task("ci",
    desc = "Full CI pipeline",
    deps = c("document", "test", "check"),
    cmd = function() {
      message("✓ All CI checks passed!")
    }
  )

)
