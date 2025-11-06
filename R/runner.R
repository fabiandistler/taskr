#' Run a Task
#'
#' @description
#' Executes a task and all its dependencies in the correct order.
#'
#' @param task_name Name of the task to run
#' @param force Force execution even if files haven't changed (default: FALSE)
#' @param dry_run Show what would be executed without actually running
#'   (default: FALSE)
#' @param verbose Show detailed output (default: TRUE)
#'
#' @return Invisibly returns TRUE on success
#' @export
#'
#' @examples
#' \dontrun{
#' # Source your taskfile first
#' source("taskfile.R")
#'
#' # Run a task
#' run_task("build")
#'
#' # Force re-run
#' run_task("build", force = TRUE)
#'
#' # Dry run
#' run_task("build", dry_run = TRUE)
#' }
run_task <- function(task_name,
                     force = FALSE,
                     dry_run = FALSE,
                     verbose = TRUE) {

  # Get tasks from environment
  env <- get_task_env()
  tasks <- env$tasks

  if (length(tasks) == 0) {
    stop("No tasks defined. Did you source taskfile.R?", call. = FALSE)
  }

  # Check if task exists
  if (!task_name %in% names(tasks)) {
    stop("Task '", task_name, "' not found. Available tasks: ",
         paste(names(tasks), collapse = ", "),
         call. = FALSE)
  }

  # Load cached state
  tasks <- load_task_state(tasks)

  # Resolve dependencies
  execution_order <- get_execution_order(task_name, tasks)

  if (verbose) {
    cli::cli_h1("Running task: {task_name}")
    if (length(execution_order) > 1) {
      cli::cli_alert_info(
        "Execution order: {paste(execution_order, collapse = ' -> ')}"
      )
    }
  }

  # Dry run mode
  if (dry_run) {
    cli::cli_alert_info("DRY RUN MODE - No tasks will be executed")
    for (name in execution_order) {
      task <- tasks[[name]]
      should_run <- force || needs_run(task)
      status <- if (should_run) "WOULD RUN" else "WOULD SKIP (up-to-date)"
      cli::cli_alert_info("{name}: {status}")
    }
    return(invisible(TRUE))
  }

  # Execute tasks
  executed <- character(0)
  skipped <- character(0)

  for (name in execution_order) {
    task <- tasks[[name]]

    # Check if needs to run
    should_run <- force || needs_run(task)

    if (!should_run) {
      if (verbose) {
        cli::cli_alert_info("Skipping {name} (up-to-date)")
      }
      skipped <- c(skipped, name)
      next
    }

    # Execute task
    if (verbose) {
      cli::cli_alert_info("Running {name}...")
    }

    result <- execute_task(task, verbose = verbose)

    if (!result$success) {
      cli::cli_alert_danger("Task {name} failed!")
      if (!is.null(result$error)) {
        stop(result$error)
      }
      stop("Task execution failed", call. = FALSE)
    }

    # Update checksums
    tasks[[name]] <- update_checksums(task)
    executed <- c(executed, name)

    if (verbose) {
      cli::cli_alert_success("Task {name} completed")
    }
  }

  # Save state
  env$tasks <- tasks
  save_task_state(tasks)

  # Summary
  if (verbose) {
    cli::cli_h1("Summary")
    if (length(executed) > 0) {
      cli::cli_alert_success(
        paste0(
          "Executed ", length(executed), " task(s): ",
          paste(executed, collapse = ", ")
        )
      )
    }
    if (length(skipped) > 0) {
      cli::cli_alert_info(
        paste0(
          "Skipped ", length(skipped), " task(s): ",
          paste(skipped, collapse = ", ")
        )
      )
    }
  }

  invisible(TRUE)
}


#' Execute a Single Task
#'
#' @param task A taskr_task object
#' @param verbose Show output (default: TRUE)
#'
#' @return List with success status and optional error
#' @keywords internal
execute_task <- function(task, verbose = TRUE) {

  # Set environment variables
  if (length(task$env) > 0) {
    old_env <- list()
    for (name in names(task$env)) {
      old_env[[name]] <- Sys.getenv(name, unset = NA)
      do.call(Sys.setenv, task$env[name])
    }
    on.exit({
      for (name in names(old_env)) {
        if (is.na(old_env[[name]])) {
          Sys.unsetenv(name)
        } else {
          do.call(Sys.setenv, old_env[name])
        }
      }
    })
  }

  # Execute command
  result <- tryCatch({

    if (is.function(task$cmd)) {
      # Execute function
      task$cmd()
    } else {
      # Execute expression
      eval(task$cmd)
    }

    list(success = TRUE, error = NULL)

  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  result
}


#' List All Available Tasks
#'
#' @description
#' Shows all defined tasks with their descriptions.
#'
#' @param verbose Show detailed information (default: TRUE)
#'
#' @return Invisibly returns the task list
#' @export
#'
#' @examples
#' \dontrun{
#' source("taskfile.R")
#' list_tasks()
#' }
list_tasks <- function(verbose = TRUE) {

  env <- get_task_env()
  tasks <- env$tasks

  if (length(tasks) == 0) {
    message("No tasks defined. Did you source taskfile.R?")
    return(invisible(NULL))
  }

  if (verbose) {
    cli::cli_h1("Available Tasks")

    for (name in names(tasks)) {
      task <- tasks[[name]]

      cli::cli_alert_info("{name}")
      if (nzchar(task$desc)) {
        cat("    ", task$desc, "\n", sep = "")
      }
      if (length(task$deps) > 0) {
        cat(
          "    Dependencies: ",
          paste(task$deps, collapse = ", "),
          "\n",
          sep = ""
        )
      }
      if (length(task$sources) > 0) {
        cat(
          "    Sources: ",
          paste(task$sources, collapse = ", "),
          "\n",
          sep = ""
        )
      }
    }
  }

  invisible(tasks)
}


#' Source Taskfile
#'
#' @description
#' Convenience function to source the taskfile.R in the current directory.
#'
#' @param path Path to taskfile.R (default: "./taskfile.R")
#'
#' @return Invisibly returns TRUE
#' @export
#'
#' @examples
#' \dontrun{
#' load_tasks()
#' list_tasks()
#' }
load_tasks <- function(path = "taskfile.R") {

  if (!file.exists(path)) {
    stop("taskfile.R not found in ", getwd(),
         "\nRun taskr_init() to create one.",
         call. = FALSE)
  }

  source(path, local = FALSE)

  message("Tasks loaded from ", path)

  invisible(TRUE)
}
