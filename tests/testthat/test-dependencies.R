test_that("resolve_dependencies() handles simple chain", {

  tasks <- list(
    task1 = task("task1", cmd = function() 1),
    task2 = task("task2", deps = "task1", cmd = function() 2),
    task3 = task("task3", deps = "task2", cmd = function() 3)
  )

  order <- resolve_dependencies("task3", tasks)

  expect_equal(order, c("task1", "task2", "task3"))
})


test_that("resolve_dependencies() handles multiple dependencies", {

  tasks <- list(
    task1 = task("task1", cmd = function() 1),
    task2 = task("task2", cmd = function() 2),
    task3 = task("task3", deps = c("task1", "task2"), cmd = function() 3)
  )

  order <- resolve_dependencies("task3", tasks)

  expect_true(all(c("task1", "task2", "task3") %in% order))
  expect_equal(order[3], "task3")  # task3 should be last
})


test_that("resolve_dependencies() detects circular dependencies", {

  tasks <- list(
    task1 = task("task1", deps = "task2", cmd = function() 1),
    task2 = task("task2", deps = "task1", cmd = function() 2)
  )

  expect_error(
    resolve_dependencies("task1", tasks),
    "Circular dependency"
  )
})


test_that("resolve_dependencies() detects missing dependencies", {

  tasks <- list(
    task1 = task("task1", deps = "missing", cmd = function() 1)
  )

  expect_error(
    resolve_dependencies("task1", tasks),
    "not found"
  )
})


test_that("resolve_dependencies() handles no dependencies", {

  tasks <- list(
    task1 = task("task1", cmd = function() 1)
  )

  order <- resolve_dependencies("task1", tasks)

  expect_equal(order, "task1")
})
