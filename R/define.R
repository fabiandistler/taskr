#' Define Tasks for a Project
#'
#' @description
#' The core task definition system for taskr. Use this to define tasks
#' in your project's `taskfile.R`.
#'
#' @param ... Task objects created with \code{\link{task}}
#' @param .env Environment in which to store tasks (default: .taskr_env)
#'
#' @return Invisibly returns the task registry
#' @export
#'
#' @examples
#' \dontrun{
#' define_tasks(
#'   task("build",
#'     desc = "Build the package",
#'     cmd = function() devtools::build()
#'   ),
#'   task("test",
#'     desc = "Run tests",
#'     deps = "build",
#'     cmd = function() devtools::test()
#'   )
#' )
#' }
define_tasks <- function(..., .env = NULL) {
  tasks <- list(...)

  # Validate all inputs are task objects
  for (i in seq_along(tasks)) {
    if (!inherits(tasks[[i]], "taskr_task")) {
      stop(
        sprintf(
          "Argument %d is not a task object. Use task() to create tasks.",
          i
        ),
        call. = FALSE
      )
    }
  }

  # Create or get task registry
  if (is.null(.env)) {
    .env <- get_task_env()
  }

  # Store tasks by name
  for (t in tasks) {
    .env$tasks[[t$name]] <- t
  }

  invisible(.env$tasks)
}


#' Create a Task Definition
#'
#' @param name Name of the task (character string)
#' @param desc Description of what the task does
#' @param cmd Function or expression to execute
#' @param deps Character vector of task names this task depends on
#' @param sources Character vector of source files to check for changes
#' @param env Named list of environment variables to set during execution
#'
#' @return A task object of class \code{taskr_task}
#' @export
#'
#' @examples
#' \dontrun{
#' task("check",
#'   desc = "Run R CMD check",
#'   deps = c("document", "test"),
#'   cmd = function() devtools::check()
#' )
#' }
task <- function(name,
                 desc = "",
                 cmd = NULL,
                 deps = character(0),
                 sources = character(0),
                 env = list()) {

  # Validate inputs
  if (!is.character(name) || length(name) != 1) {
    stop("'name' must be a single character string", call. = FALSE)
  }

  if (!is.character(desc) || length(desc) != 1) {
    stop("'desc' must be a single character string", call. = FALSE)
  }

  if (is.null(cmd)) {
    stop("'cmd' must be provided (function or expression)", call. = FALSE)
  }

  if (!is.function(cmd) && !is.call(cmd) && !is.expression(cmd)) {
    stop("'cmd' must be a function or expression", call. = FALSE)
  }

  if (!is.character(deps)) {
    stop("'deps' must be a character vector", call. = FALSE)
  }

  if (!is.character(sources)) {
    stop("'sources' must be a character vector", call. = FALSE)
  }

  if (!is.list(env)) {
    stop("'env' must be a named list", call. = FALSE)
  }

  # Create task object
  structure(
    list(
      name = name,
      desc = desc,
      cmd = cmd,
      deps = deps,
      sources = sources,
      env = env,
      last_run = NULL,
      last_hash = NULL
    ),
    class = "taskr_task"
  )
}


#' Initialize taskr in a Project
#'
#' @description
#' Creates a template \code{taskfile.R} in the current directory.
#'
#' @param path Path where to create taskfile.R (default: current directory)
#' @param template Template to use ("package", "data_pipeline", "basic")
#'
#' @return Path to created taskfile.R (invisibly)
#' @export
#'
#' @examples
#' \dontrun{
#' taskr_init()
#' taskr_init(template = "package")
#' }
taskr_init <- function(path = ".", template = "basic") {

  template <- match.arg(template, c("basic", "package", "data_pipeline"))

  taskfile_path <- file.path(path, "taskfile.R")

  if (file.exists(taskfile_path)) {
    stop("taskfile.R already exists in ", path, call. = FALSE)
  }

  # Get template
  template_file <- system.file(
    "templates",
    paste0(template, ".R"),
    package = "taskr"
  )

  if (template_file == "") {
    # If package not installed, use built-in template
    template_content <- get_builtin_template(template)
  } else {
    template_content <- readLines(template_file)
  }

  # Write template
  writeLines(template_content, taskfile_path)

  message("Created taskfile.R in ", path)
  message("Edit this file to define your tasks, then run tasks with run_task()")

  invisible(taskfile_path)
}


#' Get Built-in Template
#' @keywords internal
get_builtin_template <- function(template) {

  basic <- c(
    "# taskfile.R",
    "# Define your project tasks here",
    "",
    "library(taskr)",
    "",
    "define_tasks(",
    "  ",
    "  task(\"example\",",
    "    desc = \"An example task\",",
    "    cmd = function() {",
    "      message(\"Hello from taskr!\")",
    "    }",
    "  )",
    "  ",
    ")"
  )

  package <- c(
    "# taskfile.R",
    "# R Package Development Tasks",
    "",
    "library(taskr)",
    "",
    "define_tasks(",
    "  ",
    "  task(\"document\",",
    "    desc = \"Generate documentation\",",
    "    sources = c(\"R/**/*.R\"),",
    "    cmd = function() {",
    "      devtools::document()",
    "    }",
    "  ),",
    "  ",
    "  task(\"test\",",
    "    desc = \"Run tests\",",
    "    cmd = function() {",
    "      devtools::test()",
    "    }",
    "  ),",
    "  ",
    "  task(\"check\",",
    "    desc = \"Run R CMD check\",",
    "    deps = c(\"document\", \"test\"),",
    "    cmd = function() {",
    "      devtools::check()",
    "    }",
    "  ),",
    "  ",
    "  task(\"install\",",
    "    desc = \"Install package locally\",",
    "    deps = \"check\",",
    "    cmd = function() {",
    "      devtools::install()",
    "    }",
    "  )",
    "  ",
    ")"
  )

  data_pipeline <- c(
    "# taskfile.R",
    "# Data Pipeline Tasks",
    "",
    "library(taskr)",
    "",
    "define_tasks(",
    "  ",
    "  task(\"data:extract\",",
    "    desc = \"Extract data from source\",",
    "    cmd = function() {",
    "      source(\"scripts/extract.R\")",
    "    }",
    "  ),",
    "  ",
    "  task(\"data:transform\",",
    "    desc = \"Transform data\",",
    "    deps = \"data:extract\",",
    "    cmd = function() {",
    "      source(\"scripts/transform.R\")",
    "    }",
    "  ),",
    "  ",
    "  task(\"data:load\",",
    "    desc = \"Load data to target\",",
    "    deps = \"data:transform\",",
    "    cmd = function() {",
    "      source(\"scripts/load.R\")",
    "    }",
    "  ),",
    "  ",
    "  task(\"pipeline\",",
    "    desc = \"Run full pipeline\",",
    "    deps = c(\"data:extract\", \"data:transform\", \"data:load\")",
    "  )",
    "  ",
    ")"
  )

  switch(template,
    basic = basic,
    package = package,
    data_pipeline = data_pipeline
  )
}


#' Get or Create Task Environment
#' @keywords internal
get_task_env <- function() {
  if (!exists(".taskr_env", envir = .GlobalEnv)) {
    .GlobalEnv$.taskr_env <- new.env(parent = emptyenv())
    .GlobalEnv$.taskr_env$tasks <- list()
  }
  .GlobalEnv$.taskr_env
}


#' Print method for taskr_task
#' @export
print.taskr_task <- function(x, ...) {
  cat("<taskr_task>", x$name, "\n")
  cat("  Description:", x$desc, "\n")
  if (length(x$deps) > 0) {
    cat("  Dependencies:", paste(x$deps, collapse = ", "), "\n")
  }
  if (length(x$sources) > 0) {
    cat("  Sources:", paste(x$sources, collapse = ", "), "\n")
  }
  invisible(x)
}
