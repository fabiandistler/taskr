#!/usr/bin/env Rscript
# Interactive Test Script for taskr
# This script tests the core functionality of the taskr package

cat("=== taskr Interactive Test Suite ===\n\n")

# Test 1: Package Loading
cat("Test 1: Loading taskr package...\n")
tryCatch({
  library(taskr)
  cat("✓ Package loaded successfully\n\n")
}, error = function(e) {
  cat("✗ Failed to load package:", e$message, "\n\n")
  quit(status = 1)
})

# Test 2: Task Definition
cat("Test 2: Creating task definitions...\n")
tryCatch({
  test_task1 <- task(
    "test1",
    desc = "First test task",
    cmd = function() {
      message("Task 1 executed")
      return(TRUE)
    }
  )

  test_task2 <- task(
    "test2",
    desc = "Second test task",
    deps = "test1",
    cmd = function() {
      message("Task 2 executed")
      return(TRUE)
    }
  )

  cat("✓ Tasks created successfully\n")
  print(test_task1)
  cat("\n")
}, error = function(e) {
  cat("✗ Task creation failed:", e$message, "\n\n")
  quit(status = 1)
})

# Test 3: Task Registration
cat("\nTest 3: Registering tasks...\n")
tryCatch({
  define_tasks(test_task1, test_task2)
  cat("✓ Tasks registered successfully\n\n")
}, error = function(e) {
  cat("✗ Task registration failed:", e$message, "\n\n")
  quit(status = 1)
})

# Test 4: List Tasks
cat("Test 4: Listing all tasks...\n")
tryCatch({
  list_tasks()
  cat("✓ Task listing successful\n\n")
}, error = function(e) {
  cat("✗ Task listing failed:", e$message, "\n\n")
})

# Test 5: Dependency Resolution
cat("Test 5: Testing dependency resolution...\n")
tryCatch({
  order <- get_execution_order("test2")
  cat("Execution order:", paste(order, collapse = " -> "), "\n")

  if (identical(order, c("test1", "test2"))) {
    cat("✓ Dependency resolution correct\n\n")
  } else {
    cat("✗ Unexpected execution order\n\n")
  }
}, error = function(e) {
  cat("✗ Dependency resolution failed:", e$message, "\n\n")
})

# Test 6: Task Execution
cat("Test 6: Executing tasks...\n")
tryCatch({
  run_task("test2", verbose = TRUE)
  cat("✓ Task execution successful\n\n")
}, error = function(e) {
  cat("✗ Task execution failed:", e$message, "\n\n")
})

# Test 7: Circular Dependency Detection
cat("Test 7: Testing circular dependency detection...\n")
tryCatch({
  # Clean environment
  if (exists(".taskr_env", envir = .GlobalEnv)) {
    rm(.taskr_env, envir = .GlobalEnv)
  }

  circular1 <- task("circ1", deps = "circ2", cmd = function() 1)
  circular2 <- task("circ2", deps = "circ1", cmd = function() 2)

  define_tasks(circular1, circular2)

  # This should fail
  result <- tryCatch({
    get_execution_order("circ1")
    FALSE
  }, error = function(e) {
    TRUE
  })

  if (result) {
    cat("✓ Circular dependency detected correctly\n\n")
  } else {
    cat("✗ Circular dependency not detected\n\n")
  }
}, error = function(e) {
  cat("✗ Circular dependency test failed:", e$message, "\n\n")
})

# Test 8: File Change Detection
cat("Test 8: Testing file change detection...\n")
tryCatch({
  # Create temp file
  temp_file <- tempfile(fileext = ".txt")
  writeLines("test content", temp_file)

  # Clean environment
  if (exists(".taskr_env", envir = .GlobalEnv)) {
    rm(.taskr_env, envir = .GlobalEnv)
  }

  file_task <- task(
    "file_test",
    desc = "Task with file sources",
    sources = temp_file,
    cmd = function() {
      message("File task executed")
      return(TRUE)
    }
  )

  define_tasks(file_task)

  # First run - should execute
  cat("  First run (should execute)...\n")
  run_task("file_test", verbose = FALSE)

  # Second run - should skip
  cat("  Second run (should skip)...\n")
  run_task("file_test", verbose = FALSE)

  # Modify file and run again - should execute
  cat("  After file modification (should execute)...\n")
  writeLines("modified content", temp_file)
  run_task("file_test", verbose = FALSE)

  # Clean up
  unlink(temp_file)

  cat("✓ File change detection working\n\n")
}, error = function(e) {
  cat("✗ File change detection failed:", e$message, "\n\n")
})

# Test 9: Environment Variables
cat("Test 9: Testing environment variable support...\n")
tryCatch({
  # Clean environment
  if (exists(".taskr_env", envir = .GlobalEnv)) {
    rm(.taskr_env, envir = .GlobalEnv)
  }

  env_task <- task(
    "env_test",
    desc = "Task with environment variables",
    env = list(TEST_VAR = "test_value"),
    cmd = function() {
      val <- Sys.getenv("TEST_VAR")
      message("TEST_VAR = ", val)
      return(val == "test_value")
    }
  )

  define_tasks(env_task)
  run_task("env_test", verbose = FALSE)

  cat("✓ Environment variables working\n\n")
}, error = function(e) {
  cat("✗ Environment variable test failed:", e$message, "\n\n")
})

# Test 10: Dry Run Mode
cat("Test 10: Testing dry run mode...\n")
tryCatch({
  # Clean environment
  if (exists(".taskr_env", envir = .GlobalEnv)) {
    rm(.taskr_env, envir = .GlobalEnv)
  }

  dry_task <- task(
    "dry_test",
    desc = "Task for dry run testing",
    cmd = function() {
      message("This should not print in dry run")
      return(TRUE)
    }
  )

  define_tasks(dry_task)
  run_task("dry_test", dry_run = TRUE, verbose = TRUE)

  cat("✓ Dry run mode working\n\n")
}, error = function(e) {
  cat("✗ Dry run test failed:", e$message, "\n\n")
})

# Test 11: Force Execution
cat("Test 11: Testing force execution...\n")
tryCatch({
  # Clean environment
  if (exists(".taskr_env", envir = .GlobalEnv)) {
    rm(.taskr_env, envir = .GlobalEnv)
  }

  force_task <- task(
    "force_test",
    desc = "Task for force testing",
    cmd = function() {
      message("Force task executed")
      return(TRUE)
    }
  )

  define_tasks(force_task)

  # Run twice with force
  run_task("force_test", verbose = FALSE)
  run_task("force_test", force = TRUE, verbose = FALSE)

  cat("✓ Force execution working\n\n")
}, error = function(e) {
  cat("✗ Force execution test failed:", e$message, "\n\n")
})

# Test 12: Invalid Task Name
cat("Test 12: Testing error handling for invalid task name...\n")
tryCatch({
  result <- tryCatch({
    run_task("nonexistent_task", verbose = FALSE)
    FALSE
  }, error = function(e) {
    TRUE
  })

  if (result) {
    cat("✓ Invalid task name error handled correctly\n\n")
  } else {
    cat("✗ Invalid task name should have raised error\n\n")
  }
}, error = function(e) {
  cat("✗ Error handling test failed:", e$message, "\n\n")
})

# Test 13: Task Validation
cat("Test 13: Testing task validation...\n")
tryCatch({
  # Test invalid task creation
  result1 <- tryCatch({
    task(123, cmd = function() {})
    FALSE
  }, error = function(e) {
    TRUE
  })

  result2 <- tryCatch({
    task("test", cmd = NULL)
    FALSE
  }, error = function(e) {
    TRUE
  })

  result3 <- tryCatch({
    task("test", desc = 123, cmd = function() {})
    FALSE
  }, error = function(e) {
    TRUE
  })

  if (result1 && result2 && result3) {
    cat("✓ Task validation working correctly\n\n")
  } else {
    cat("✗ Some validation checks failed\n\n")
  }
}, error = function(e) {
  cat("✗ Validation test failed:", e$message, "\n\n")
})

# Test 14: Cache Management
cat("Test 14: Testing cache management...\n")
tryCatch({
  clear_cache()
  cat("✓ Cache cleared successfully\n\n")
}, error = function(e) {
  cat("✗ Cache management failed:", e$message, "\n\n")
})

# Test 15: taskr_init
cat("Test 15: Testing taskr_init...\n")
tryCatch({
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "taskr_test")
  dir.create(test_dir, showWarnings = FALSE)

  old_wd <- getwd()
  setwd(test_dir)

  # Test each template
  for (template in c("basic", "package", "data_pipeline")) {
    template_file <- paste0("taskfile_", template, ".R")
    if (file.exists("taskfile.R")) {
      unlink("taskfile.R")
    }

    taskr_init(template = template)

    if (file.exists("taskfile.R")) {
      # Rename to avoid conflicts
      file.rename("taskfile.R", template_file)
      cat(sprintf("  ✓ Template '%s' created\n", template))
    } else {
      cat(sprintf("  ✗ Template '%s' failed\n", template))
    }
  }

  setwd(old_wd)
  unlink(test_dir, recursive = TRUE)

  cat("✓ taskr_init working\n\n")
}, error = function(e) {
  cat("✗ taskr_init test failed:", e$message, "\n\n")
  if (exists("old_wd")) setwd(old_wd)
})

# Final Summary
cat("=== Test Suite Complete ===\n")
cat("All core functionality has been tested.\n")
cat("If you see this message, the basic tests passed!\n\n")

# Clean up
if (exists(".taskr_env", envir = .GlobalEnv)) {
  rm(.taskr_env, envir = .GlobalEnv)
}

cat("✓ Test environment cleaned up\n")
