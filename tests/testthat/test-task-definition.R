test_that("task() creates valid task object", {

  t <- task("test",
    desc = "A test task",
    cmd = function() message("test")
  )

  expect_s3_class(t, "taskr_task")
  expect_equal(t$name, "test")
  expect_equal(t$desc, "A test task")
  expect_true(is.function(t$cmd))
})


test_that("task() validates inputs", {

  expect_error(
    task(123, cmd = function() {}),
    "'name' must be a single character string"
  )

  expect_error(
    task("test", desc = 123),
    "'desc' must be a single character string"
  )

  expect_error(
    task("test", cmd = NULL),
    "'cmd' must be provided"
  )

  expect_error(
    task("test", cmd = function() {}, deps = 123),
    "'deps' must be a character vector"
  )
})


test_that("define_tasks() stores tasks correctly", {

  # Clean environment
  if (exists(".taskr_env", envir = .GlobalEnv)) {
    rm(.taskr_env, envir = .GlobalEnv)
  }

  define_tasks(
    task("task1", cmd = function() 1),
    task("task2", cmd = function() 2)
  )

  env <- get_task_env()

  expect_equal(length(env$tasks), 2)
  expect_true("task1" %in% names(env$tasks))
  expect_true("task2" %in% names(env$tasks))

  # Clean up
  rm(.taskr_env, envir = .GlobalEnv)
})


test_that("define_tasks() validates task objects", {

  expect_error(
    define_tasks("not a task"),
    "not a task object"
  )
})
