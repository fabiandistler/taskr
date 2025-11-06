#' Command Line Interface for taskr
#'
#' @description
#' Provides a CLI interface that can be called from the terminal.
#' This is typically used via Rscript.
#'
#' @name cli
NULL


#' Main CLI Entry Point
#'
#' @description
#' Processes command line arguments and executes the appropriate action.
#'
#' @param args Command line arguments
#'   (default: commandArgs(trailingOnly = TRUE))
#'
#' @return Invisibly returns exit code (0 = success, 1 = error)
#' @export
#'
#' @examples
#' \dontrun{
#' # From terminal:
#' # Rscript -e "taskr::cli_main()" list
#' # Rscript -e "taskr::cli_main()" run build
#' }
cli_main <- function(args = commandArgs(trailingOnly = TRUE)) {

  # If no args, show help
  if (length(args) == 0) {
    cli_help()
    return(invisible(0))
  }

  command <- args[1]
  rest_args <- if (length(args) > 1) args[-1] else character(0)

  # Route to appropriate handler
  result <- tryCatch({

    switch(command,
      "list" = cli_list(rest_args),
      "run" = cli_run(rest_args),
      "init" = cli_init(rest_args),
      "validate" = cli_validate(rest_args),
      "clear-cache" = cli_clear_cache(rest_args),
      "help" = cli_help(rest_args),
      {
        # If not a known command, assume it's a task name
        cli_run(args)
      }
    )

  }, error = function(e) {
    cli::cli_alert_danger("Error: {e$message}")
    return(1)
  })

  invisible(result)
}


#' CLI: List Tasks
#' @keywords internal
cli_list <- function(args) {

  # Load taskfile
  load_tasks()

  # List tasks
  list_tasks()

  return(0)
}


#' CLI: Run Task
#' @keywords internal
cli_run <- function(args) {

  if (length(args) == 0) {
    stop("No task specified. Usage: taskr run <task_name>", call. = FALSE)
  }

  task_name <- args[1]
  rest_args <- if (length(args) > 1) args[-1] else character(0)

  # Parse flags
  force <- "--force" %in% rest_args || "-f" %in% rest_args
  dry_run <- "--dry-run" %in% rest_args || "-d" %in% rest_args
  quiet <- "--quiet" %in% rest_args || "-q" %in% rest_args

  # Load taskfile
  load_tasks()

  # Run task
  run_task(
    task_name,
    force = force,
    dry_run = dry_run,
    verbose = !quiet
  )

  return(0)
}


#' CLI: Initialize Taskfile
#' @keywords internal
cli_init <- function(args) {

  template <- if (length(args) > 0) args[1] else "basic"

  taskr_init(template = template)

  return(0)
}


#' CLI: Validate Dependencies
#' @keywords internal
cli_validate <- function(args) {

  # Load taskfile
  load_tasks()

  # Validate
  validate_dependencies()

  return(0)
}


#' CLI: Clear Cache
#' @keywords internal
cli_clear_cache <- function(args) {

  clear_cache()

  return(0)
}


#' CLI: Show Help
#' @keywords internal
cli_help <- function(args = NULL) {

  help_text <- c(
    "",
    "taskr - Modern Task Runner for R Projects",
    "",
    "Usage:",
    "  Rscript -e 'taskr::cli_main()' <command> [arguments]",
    "",
    "Commands:",
    "  list               List all available tasks",
    "  run <task>         Run a specific task",
    "  init [template]    Initialize taskfile.R",
    "                     (templates: basic, package, data_pipeline)",
    "  validate           Validate task dependencies",
    "  clear-cache        Clear task cache",
    "  help               Show this help message",
    "",
    "Run Flags:",
    "  --force, -f        Force execution even if up-to-date",
    "  --dry-run, -d      Show what would run without executing",
    "  --quiet, -q        Suppress verbose output",
    "",
    "Examples:",
    "  Rscript -e 'taskr::cli_main()' list",
    "  Rscript -e 'taskr::cli_main()' run build",
    "  Rscript -e 'taskr::cli_main()' run test --force",
    "  Rscript -e 'taskr::cli_main()' init package",
    "",
    "Shorthand (if task name doesn't conflict with commands):",
    "  Rscript -e 'taskr::cli_main()' build",
    "",
    "Or from R:",
    "  source('taskfile.R')",
    "  list_tasks()",
    "  run_task('build')",
    ""
  )

  cat(paste(help_text, collapse = "\n"))

  return(0)
}
