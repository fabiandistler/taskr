#' File Change Detection using Checksums
#'
#' @description
#' Tracks file changes using MD5 checksums. Similar to how Taskfile/make
#' determines if a task needs to be re-run.
#'
#' @name checksum
NULL


#' Calculate Checksum for Files
#'
#' @param files Character vector of file paths
#' @param algo Hash algorithm to use (default: "md5")
#'
#' @return Named character vector of checksums
#' @keywords internal
calculate_checksums <- function(files, algo = "md5") {

  if (length(files) == 0) {
    return(character(0))
  }

  # Expand glob patterns
  expanded_files <- expand_file_patterns(files)

  if (length(expanded_files) == 0) {
    return(character(0))
  }

  # Calculate checksum for each file
  checksums <- vapply(expanded_files, function(f) {
    if (!file.exists(f)) {
      warning("File not found: ", f, call. = FALSE)
      return(NA_character_)
    }
    digest::digest(file = f, algo = algo)
  }, character(1))

  checksums
}


#' Expand File Patterns (Glob)
#'
#' @param patterns Character vector of file patterns (supports * and **)
#'
#' @return Character vector of matching file paths
#' @keywords internal
expand_file_patterns <- function(patterns) {

  if (length(patterns) == 0) {
    return(character(0))
  }

  all_files <- character(0)

  for (pattern in patterns) {

    # Handle ** (recursive glob)
    if (grepl("\\*\\*", pattern)) {
      files <- recursive_glob(pattern)
    } else {
      # Simple glob
      files <- Sys.glob(pattern)
    }

    all_files <- c(all_files, files)
  }

  unique(all_files)
}


#' Recursive Glob
#' @keywords internal
recursive_glob <- function(pattern) {

  # Split pattern at **
  parts <- strsplit(pattern, "\\*\\*", fixed = FALSE)[[1]]

  if (length(parts) != 2) {
    stop("Invalid ** pattern: ", pattern, call. = FALSE)
  }

  base_dir <- parts[1]
  file_pattern <- parts[2]

  # Remove leading/trailing slashes
  base_dir <- gsub("^/|/$", "", base_dir)
  file_pattern <- gsub("^/|/$", "", file_pattern)

  if (base_dir == "") base_dir <- "."

  # Find all files recursively
  all_files <- list.files(
    path = base_dir,
    pattern = glob2rx(file_pattern),
    recursive = TRUE,
    full.names = TRUE
  )

  all_files
}


#' Check if Task Needs to Run
#'
#' @description
#' Determines if a task needs to run based on source file changes.
#'
#' @param task A taskr_task object
#'
#' @return Logical: TRUE if task should run, FALSE otherwise
#' @keywords internal
needs_run <- function(task) {

  # If no sources specified, always run
  if (length(task$sources) == 0) {
    return(TRUE)
  }

  # If never run before, run it
  if (is.null(task$last_hash)) {
    return(TRUE)
  }

  # Calculate current checksums
  current_checksums <- calculate_checksums(task$sources)

  # If checksums don't match, need to run
  if (!identical(current_checksums, task$last_hash)) {
    return(TRUE)
  }

  # Otherwise, skip
  FALSE
}


#' Update Task Checksums
#'
#' @param task A taskr_task object
#'
#' @return Updated task object
#' @keywords internal
update_checksums <- function(task) {

  if (length(task$sources) > 0) {
    task$last_hash <- calculate_checksums(task$sources)
    task$last_run <- Sys.time()
  }

  task
}


#' Get Cache Directory
#' @keywords internal
get_cache_dir <- function() {
  cache_dir <- file.path(".taskr", "cache")

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }

  cache_dir
}


#' Save Task State
#'
#' @param tasks Named list of tasks
#'
#' @return Invisibly returns TRUE
#' @keywords internal
save_task_state <- function(tasks) {

  cache_dir <- get_cache_dir()
  state_file <- file.path(cache_dir, "task_state.rds")

  # Extract relevant state
  state <- lapply(tasks, function(t) {
    list(
      name = t$name,
      last_run = t$last_run,
      last_hash = t$last_hash
    )
  })

  saveRDS(state, state_file)

  invisible(TRUE)
}


#' Load Task State
#'
#' @param tasks Named list of tasks
#'
#' @return Updated tasks with restored state
#' @keywords internal
load_task_state <- function(tasks) {

  cache_dir <- get_cache_dir()
  state_file <- file.path(cache_dir, "task_state.rds")

  if (!file.exists(state_file)) {
    return(tasks)
  }

  state <- readRDS(state_file)

  # Restore state to matching tasks
  for (name in names(tasks)) {
    if (name %in% names(state)) {
      tasks[[name]]$last_run <- state[[name]]$last_run
      tasks[[name]]$last_hash <- state[[name]]$last_hash
    }
  }

  tasks
}


#' Clear Task Cache
#'
#' @description
#' Removes all cached task state, forcing all tasks to re-run.
#'
#' @return Invisibly returns TRUE
#' @export
#'
#' @examples
#' \dontrun{
#' clear_cache()
#' }
clear_cache <- function() {

  cache_dir <- get_cache_dir()

  if (dir.exists(cache_dir)) {
    unlink(cache_dir, recursive = TRUE)
    message("Task cache cleared")
  } else {
    message("No cache to clear")
  }

  invisible(TRUE)
}
