#' Resolve Task Dependencies
#'
#' @description
#' Resolves the dependency graph for a task and returns tasks in execution order.
#' Uses topological sorting to handle complex dependency chains.
#'
#' @param task_name Name of the task to resolve dependencies for
#' @param tasks Named list of all available tasks
#'
#' @return Character vector of task names in execution order
#' @keywords internal
resolve_dependencies <- function(task_name, tasks) {

  # Check if task exists
  if (!task_name %in% names(tasks)) {
    stop("Task '", task_name, "' not found", call. = FALSE)
  }

  # Build dependency graph
  graph <- build_dependency_graph(tasks)

  # Check for cycles
  check_cycles(graph, task_name)

  # Topological sort
  sorted <- topological_sort(graph, task_name)

  sorted
}


#' Build Dependency Graph
#' @keywords internal
build_dependency_graph <- function(tasks) {

  graph <- list()

  for (name in names(tasks)) {
    task <- tasks[[name]]
    graph[[name]] <- list(
      deps = task$deps,
      visited = FALSE,
      temp_mark = FALSE
    )
  }

  graph
}


#' Check for Circular Dependencies
#' @keywords internal
check_cycles <- function(graph, start_node) {

  # Reset marks
  for (name in names(graph)) {
    graph[[name]]$visited <- FALSE
    graph[[name]]$temp_mark <- FALSE
  }

  visit <- function(node, path = character(0)) {

    if (graph[[node]]$temp_mark) {
      # Cycle detected
      cycle_path <- c(path, node)
      stop("Circular dependency detected: ",
           paste(cycle_path, collapse = " -> "),
           call. = FALSE)
    }

    if (graph[[node]]$visited) {
      return()
    }

    graph[[node]]$temp_mark <<- TRUE
    new_path <- c(path, node)

    for (dep in graph[[node]]$deps) {
      if (!dep %in% names(graph)) {
        stop("Task '", dep, "' (dependency of '", node, "') not found",
             call. = FALSE)
      }
      visit(dep, new_path)
    }

    graph[[node]]$temp_mark <<- FALSE
    graph[[node]]$visited <<- TRUE
  }

  visit(start_node)

  invisible(NULL)
}


#' Topological Sort
#' @keywords internal
topological_sort <- function(graph, start_node) {

  sorted <- character(0)
  visited <- character(0)

  visit <- function(node) {

    if (node %in% visited) {
      return()
    }

    visited <<- c(visited, node)

    # Visit dependencies first (depth-first)
    for (dep in graph[[node]]$deps) {
      visit(dep)
    }

    # Add node after its dependencies
    sorted <<- c(sorted, node)
  }

  visit(start_node)

  sorted
}


#' Get Task Execution Order
#'
#' @description
#' Returns the execution order for a task including all its dependencies.
#'
#' @param task_name Name of the task
#' @param tasks Named list of tasks (default: from task environment)
#'
#' @return Character vector of task names in execution order
#' @export
#'
#' @examples
#' \dontrun{
#' get_execution_order("check")
#' }
get_execution_order <- function(task_name, tasks = NULL) {

  if (is.null(tasks)) {
    env <- get_task_env()
    tasks <- env$tasks

    if (length(tasks) == 0) {
      stop("No tasks defined. Did you source taskfile.R?", call. = FALSE)
    }
  }

  resolve_dependencies(task_name, tasks)
}


#' Validate Task Dependencies
#'
#' @description
#' Checks if all task dependencies are valid (no cycles, all deps exist).
#'
#' @param tasks Named list of tasks (default: from task environment)
#'
#' @return TRUE if valid, otherwise raises an error
#' @export
#'
#' @examples
#' \dontrun{
#' validate_dependencies()
#' }
validate_dependencies <- function(tasks = NULL) {

  if (is.null(tasks)) {
    env <- get_task_env()
    tasks <- env$tasks

    if (length(tasks) == 0) {
      stop("No tasks defined. Did you source taskfile.R?", call. = FALSE)
    }
  }

  # Check each task
  for (name in names(tasks)) {
    tryCatch({
      resolve_dependencies(name, tasks)
    }, error = function(e) {
      stop("Invalid dependencies for task '", name, "': ", e$message,
           call. = FALSE)
    })
  }

  message("All task dependencies are valid")
  invisible(TRUE)
}
